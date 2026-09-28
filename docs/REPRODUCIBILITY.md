# Reproducibility

## Software revisions

The Python and C++ implementations are distinct research revisions. Both now
separate event parsing, scheduler state, frame simulation, and command-line
handling. Model instances start with fresh state for each frame, invalid inputs
raise errors, and unused per-clock waveform allocations have been removed.
The C++ model can also be linked as the `espresso_cost_model` CMake library.

| Property | Python | C++ |
| --- | --- | --- |
| Image dimensions | JSON `imginfo`; Harris default 256 × 320 | `kImageWidth=256`, `kImageHeight=300` |
| Layer order | JSON insertion order | Lexicographic network-key order |
| Compute latency | Name-based defaults, optional `computelatency` override | Required `computelatency` per layer |
| Window scheduling | Dense, sparse, and pooling modes | Centered dense windows |
| Output values | Placeholder value 1 | Current input value |

These are timing models, not numerical convolution simulators. Do not interchange
their configuration files or assume matching cycle counts. Python uses shifted
window addresses; C++ uses centered addresses and its original integer division
at borders. Both retain the initial zero-valued previous event, same-cycle
handoff between stages, and historical frame-end behavior: stop when input is
exhausted and all schedulers are idle. Pending windows are not flushed by padding.

Input is a nonempty sequence of decimal `row column value` records, sorted in
nondecreasing row-major order. Single events and repeated coordinates are valid.
Blank lines and `#` comments are supported. Coordinates must fit the model's image
and values must fit signed 32-bit integers. Configuration errors, duplicate JSON
keys, invalid kernels, and invalid clock rates are rejected.

## Software verification

```sh
python tools/check_model.py
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

`Costmodel/tests/baselines.json` records pre-refactor cycles from commit
`16a1dadda6279830330353bdf5173327f8d92f1b`. Four synthetic patterns cover clusters,
row gaps, duplicate coordinates, and 32 × 32 patch edges. All 20 Python configuration/case
combinations and four C++ cases match their recorded cycles, including repeated
frames on one instance. Tests also cover input validation, Python configuration
reload, scheduler backpressure, and invocation from an external working directory.
The included 12-event example still produces 3,891 Python cycles and 3,890 C++ cycles.

The Python model and tests use only the standard library (Python 3.10+).
Resource plots use the dependencies in `requirements.txt`. C++ builds with C++17;
local checks used GCC 13.2. Timing regression agreement establishes preservation
on these fixtures, not correctness of the architecture across all inputs.

## Hardware changes and verification

The three RTL revisions reuse module names and must be compiled independently.
Register declarations now precede their use, duplicate declarations are removed,
and module headers describe their purpose. All three design tops and the AccSRC
`fd_top_tb` elaborate with Vivado 2024.1 without `--relax`.

Two arithmetic interface widths were corrected in both pipeline revisions:
`max5.out_max_value` and `nms5.threshold` now use `DATA_WIDTH` bits instead of one.
NMS now registers the window address and threshold alongside the first pipeline
stage, keeping metadata aligned for consecutive inputs. The repeated row-max
instances use a generate loop. These are functional fixes and can change feature
results relative to the original RTL; historical measurement tables were not rerun.

`verilog/simulation/tests/nms5_tb.v` checks full-width maxima, tie priority,
threshold comparisons, consecutive-window metadata, bubbles, and reset against
both revisions. Run with Icarus Verilog on `PATH`:

```sh
python tools/check_rtl.py
```

Or use Vivado's `xvlog`, `xelab`, and `xsim`:

```sh
python tools/check_rtl.py --engine vivado
```

Use `--vivado-bin PATH` when those tools are not on `PATH`. Logs are retained under
`build/rtl-check/`. The helper compiles each revision independently and executes
the self-checking arithmetic test; it does not run the historical file-driven
testbenches, which need external fixtures.

Remaining limitations: the main pipeline still reports width mismatches at
gradient, window, and response interfaces. Those numerical-width choices need
separate end-to-end validation. NMS has no output buffer: downstream readiness
must remain asserted for windows already in flight. The experimental scheduler
FIFO and historical testbenches are not general-purpose verified components.
Parsing, elaboration, and component tests do not establish complete pipeline
correctness, synthesis results, or timing closure.

The project generator targets `xczu7ev-ffvc1156-2-e` and requires user-supplied
board pin assignments and clock constraints before implementation.

## Publications and data

The public repository links to published papers. Manuscript sources and original
slides are organized locally; the public overview contains no sensor imagery.
Only synthetic events are distributed with the software. Paper throughput
measurements require additional experimental inputs outside this release.
