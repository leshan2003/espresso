# FPGA sources

| Variant | Source | Top module | Purpose |
| --- | --- | --- | --- |
| `espresso` | `espresso/rtl/` | `FD_top` | Main Harris feature-extraction pipeline |
| `scheduler` | `scheduler/rtl/` | `EventScheduler5` | September 2025 scheduler experiment |
| `accsrc` | `accsrc/design_sources/` | `FD_top` | Earlier AccSRC design, with historical testbenches |

These are separate revisions with overlapping module names. Do not combine
their source lists into a single design.

With Vivado available on `PATH`:

```sh
vivado -mode batch -source hardware/create_project.tcl -tclargs espresso
```

Use `scheduler` or `accsrc` for the other variants. The generator locates source
files relative to itself and creates the project under `build/vivado/VARIANT`.
It refuses to overwrite an existing project. The target is the ZCU104 device
`xczu7ev-ffvc1156-2-e`; provide your own board and timing constraints.

All three top modules were parsed and elaborated with Vivado 2024.1's `--relax`
option. The generator sets this compatibility option for simulation because
the historical RTL contains declarations after use. Warnings remain; functional
simulation, synthesis, and timing closure are not established by this check.

AccSRC's original design and simulation sources are consolidated here. File-based
testbenches expect `local/rtl-events/` relative to the simulation working
directory. These event fixtures are intentionally not included. Some historical
testbenches are experimental and are not part of the automated smoke test.

Other original Vivado projects, checkpoints, reports, and working-copy histories
remain in the local archive. Generated vendor output is not included in Git.
