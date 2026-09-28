# Simulation sources

- `espresso/`: file-reading event dispatchers for the main pipeline; a complete
  pipeline testbench is not included in this release.
- `accsrc/`: historical testbenches and their file-reading event dispatcher.
  `fd_top_tb.v` is the default testbench selected by the project generator.
- `tests/`: self-checking synthetic component tests. `nms5_tb.v` runs against
  either pipeline revision and needs no external event files.

Compile each directory with the matching revision under `../design/`. Do not
combine revisions: they reuse module names.

File-driven testbenches expect `local/rtl-events/` relative to the simulation
working directory. They read separate hexadecimal value, row, and column files.
Those historical inputs are not distributed. The three-column decimal fixture
in `input_example/events/synthetic.txt` is for the software models and cannot be
used directly as a Verilog input file.

Some historical testbenches are experimental and are not automated regression
tests. Supply your own fixtures and select the testbench appropriate to the
design being evaluated.

Run the automated component tests from the repository root with
`python tools/check_rtl.py` (Icarus Verilog) or
`python tools/check_rtl.py --engine vivado`. Each revision is compiled separately;
logs and generated simulation files stay under `build/rtl-check/`.
