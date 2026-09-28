"""Regression and invalid-input checks for the public Python entry point."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "src/cost_model/run.py"


def main():
    with tempfile.TemporaryDirectory() as temporary:
        result = subprocess.run([sys.executable, str(RUNNER), str(ROOT / "examples/events/synthetic.txt")],
                                cwd=temporary, capture_output=True, text=True, check=True, timeout=30)
        output = json.loads(result.stdout)
        assert output["clock_cycles"] == 3891, output
        assert output["events"] == 12, output
        assert output["latency_us"] == 38.91, output
        bad = Path(temporary) / "invalid.txt"
        for content in ("1 2 3\n", "2 0 1\n1 0 1\n", "0 256 1\n1 0 1\n", "0 0 1.5\n1 0 1\n"):
            bad.write_text(content, encoding="utf-8")
            result = subprocess.run([sys.executable, str(RUNNER), str(bad)], cwd=temporary,
                                    capture_output=True, text=True, timeout=30)
            assert result.returncode != 0 and "error:" in result.stderr, result
    print("Python model regression, external working directory, and invalid-input checks passed.")


if __name__ == "__main__":
    main()
