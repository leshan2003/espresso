# Verilog sources

`design/` contains design RTL. `simulation/` contains testbenches and file-reading
event dispatchers. Each directory groups sources by revision:

| Revision | Design directory | Design top | Simulation directory |
| --- | --- | --- | --- |
| `espresso` | `design/espresso/` | `FD_top` | `simulation/espresso/`: event dispatchers |
| `scheduler` | `design/scheduler/` | `EventScheduler5` | No testbench included |
| `accsrc` | `design/accsrc/` | `FD_top` | `simulation/accsrc/`: historical testbenches and dispatcher |

The revisions reuse module names and must be compiled independently.
The scheduler's `testfifo.v` is an experimental FIFO design with clock/data ports,
not a regression testbench or a validated general-purpose FIFO.

Use the [FPGA Tcl scripts](../fpga/README.md) to create a Vivado project. The
generator places design files in `sources_1` and simulation files in `sim_1`.
For the `accsrc` revision, the selected simulation top is `fd_top_tb`.

All three design tops parse and elaborate with Vivado 2024.1's strict checks.
`simulation/tests/nms5_tb.v` provides self-checking maximum/NMS tests for both
pipeline revisions. Run `python tools/check_rtl.py` with Icarus Verilog, or add
`--engine vivado` to use Vivado's simulation tools. The main pipeline retains
some width mismatches; see the [verification limits and functional changes](../docs/REPRODUCIBILITY.md).

See [simulation instructions](simulation/README.md) for input-file expectations.
