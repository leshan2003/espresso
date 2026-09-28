# FPGA Tcl scripts

With Vivado available on `PATH`, run from the repository root:

```sh
vivado -mode batch -source fpga/create_project.tcl -tclargs espresso
```

Choose `espresso`, `scheduler`, or `accsrc`. `create_project.tcl` locates sources
relative to its own path, so it can also be invoked from another directory using
the script's absolute path.

The script loads `verilog/design/VARIANT/` into `sources_1` and any files in
`verilog/simulation/VARIANT/` into `sim_1`. For `accsrc`, the simulation top is
`fd_top_tb`; the other variants do not include a complete testbench.

Projects are generated under `build/vivado/VARIANT/`, and an existing project
will not be overwritten. The device is `xczu7ev-ffvc1156-2-e` (ZCU104). Provide
your own board pin assignments and timing constraints before implementation.

The script enables Vivado's `--relax` simulation compatibility option for
historical declaration-order issues. It does not launch synthesis or simulation.
Build output and vendor-generated files are excluded from Git.
