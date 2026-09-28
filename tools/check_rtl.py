"""Elaborate independent RTL revisions and run synthetic arithmetic regressions."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", choices=("iverilog", "vivado"), default="iverilog")
    parser.add_argument("--vivado-bin", type=Path, help="Vivado bin directory, if not on PATH")
    args = parser.parse_args()

    def tool(name):
        if args.vivado_bin:
            candidate = args.vivado_bin / (name + ".bat" if os.name == "nt" else name)
            if candidate.exists():
                return str(candidate.resolve())
        found = shutil.which(name)
        if not found:
            parser.error(f"Required tool not found: {name}")
        return found

    names = ("iverilog", "vvp") if args.engine == "iverilog" else ("xvlog", "xelab", "xsim")
    executables = {name: tool(name) for name in names}
    output = ROOT / "build/rtl-check"
    output.mkdir(parents=True, exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix=args.engine + "-", dir=output))
    print(f"RTL logs: {scratch}", flush=True)

    def run(name, arguments, directory, log):
        result = subprocess.run([executables[name], *map(str, arguments)], cwd=directory,
                                capture_output=True, text=True, errors="replace", timeout=180)
        text = result.stdout + result.stderr
        (directory / log).write_text(text, encoding="utf-8")
        if result.returncode:
            raise RuntimeError(f"{name} failed; see {directory / log}\n{text[-4000:]}")
        return text

    for variant in ("espresso", "scheduler", "accsrc"):
        directory = scratch / variant
        directory.mkdir()
        files = sorted((ROOT / "verilog/design" / variant).glob("*.v"))
        files += sorted((ROOT / "verilog/simulation" / variant).glob("*.v"))
        top = "EventScheduler5" if variant == "scheduler" else "FD_top"
        tops = [top] + (["fd_top_tb"] if variant == "accsrc" else [])
        arithmetic = variant != "scheduler"
        if arithmetic:
            files.append(ROOT / "verilog/simulation/tests/nms5_tb.v")
            tops.append("nms5_tb")
        if args.engine == "vivado":
            run("xvlog", files, directory, "compile.log")
        for module in tops:
            if args.engine == "iverilog":
                run("iverilog", ["-g2012", "-s", module, "-o", module + ".vvp", *files], directory, module + ".log")
            else:
                run("xelab", [module, "-s", module + "_check"], directory, module + ".log")
        if arithmetic:
            if args.engine == "iverilog":
                result = run("vvp", ["nms5_tb.vvp"], directory, "simulation.log")
            else:
                result = run("xsim", ["nms5_tb_check", "-runall"], directory, "simulation.log")
            if "PASS: max5 and nms5" not in result:
                raise RuntimeError(f"Arithmetic test did not pass: {directory / 'simulation.log'}")
        print(f"{variant}: strict elaboration passed" + ("; arithmetic regression passed" if arithmetic else ""), flush=True)


if __name__ == "__main__":
    main()
