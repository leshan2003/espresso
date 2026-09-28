# Verilog sources

`design/` contains design RTL. `simulation/` contains testbenches and file-reading
event dispatchers. Each directory groups sources by revision:

| Revision | Design directory | Design top | Simulation directory |
| --- | --- | --- | --- |
| `espresso` | `design/espresso/` | `FD_top` | `simulation/espresso/`: event dispatchers |
| `scheduler` | `design/scheduler/` | `EventScheduler5` | No testbench included |
| `accsrc` | `design/accsrc/` | `FD_top` | `simulation/accsrc/`: historical testbenches and dispatcher |

The revisions reuse module names and must be compiled independently.
The scheduler's `testfifo.v` is a FIFO design with clock/data ports, not a testbench.

Use the [FPGA Tcl scripts](../fpga/README.md) to create a Vivado project. The
generator places design files in `sources_1` and simulation files in `sim_1`.
For the `accsrc` revision, the selected simulation top is `fd_top_tb`.

All three design tops were parsed and elaborated with Vivado 2024.1's `--relax`
option. Historical declaration-order warnings remain. This check does not
establish functional correctness, synthesis results, or timing closure.

See [simulation instructions](simulation/README.md) for input-file expectations.
