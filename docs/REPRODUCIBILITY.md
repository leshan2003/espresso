# Reproducibility

## Software

The Python core comes from the latest local working copy of EspressoCostModel.
The C++ core comes from the separate EspressoCPP experiment. Core scheduling
algorithms were preserved; command-line input validation and path handling were
added around them.

Python uses image dimensions from JSON (256 × 320 in the Harris configuration).
C++ uses constants in `component.h` (256 × 300). Python configurations use named
layers and infer compute latency; C++ configurations use numbered layer names
and explicit `computelatency`. Do not interchange these configuration files.

The current input runners require at least two integer events, sorted by row and
column. They validate bounds before calling the historical model. Frame-end
draining behavior and the model's treatment of zero padding have not been
redesigned. The synthetic regression is a packaging check, not a validation of
the architecture or an assertion of Python/C++ equivalence.

Validated locally: Python 3, NumPy, GCC 13.2/C++17, CMake build and CTest.
The included synthetic input produces 3,891 Python cycles and 3,890 C++ cycles.
The public Python core matches the archived Python model for this input, and
the C++ core source files are unchanged apart from whitespace cleanup. The discrepancy between model revisions
is preserved and has not been diagnosed as part of repository organization.

## Hardware

The three RTL variants reuse module names and must be compiled independently.
Original testbenches may require external event files; these are not distributed.
Historical absolute event paths were replaced with `local/rtl-events/` paths.
Supply your own event fixtures and configure the simulation working directory.

The Vivado project generator targets `xczu7ev-ffvc1156-2-e`. It does not supply
board pin assignments, clock constraints, or a complete deployable board image.
Source parsing and elaboration do not establish functional or timing correctness.
Vivado 2024.1 parsed and elaborated the three top modules with `--relax`; strict
checking flags pre-existing declaration-order problems. Compatibility settings
are included in the project generator.

## Publications and data

The public repository links to published papers. Manuscript sources and original
slides are organized locally; the public overview contains no sensor imagery.
Only synthetic events are distributed with the software. Paper throughput
measurements require additional experimental inputs that are outside this release.
