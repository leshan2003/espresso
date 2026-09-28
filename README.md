# Espresso

Research code for **Espresso**, an architecture for processing sparse vision
events in spatiotemporal order. The repository brings together the software cost
models, FPGA RTL, and resource measurements previously maintained in
EspressoCostModel, EspressoResource, and AccSRC.

| Directory | Contents |
| --- | --- |
| [Costmodel](Costmodel/README.md) | Python and C++ cost models, with their configurations |
| [verilog/design](verilog/design) | Design RTL, grouped by revision |
| [verilog/simulation](verilog/simulation/README.md) | Testbenches and event-input simulation helpers |
| [fpga](fpga/README.md) | Vivado Tcl scripts |
| [input_example](input_example/README.md) | Small synthetic event input |
| [results/resource](results/resource/README.md) | Resource measurements and plotting code |
| [papers](papers/README.md) | Publication links and citations |
| [slides](slides/README.md) | Public architecture overview |

## Run the Python model

Use Python 3.10 or later:

```sh
python -m pip install -r requirements.txt
python Costmodel/python/run.py input_example/events/synthetic.txt
```

The included example produces **3,891 model clock cycles**. At the default
100 MHz this is 38.91 microseconds. These are synthetic smoke-test results,
not the experimental throughput reported in the papers.

Input records contain `row column value` integers in row-major order. Supply
`--config PATH` and `--clock-mhz VALUE` to select a configuration and clock.
The runner accepts absolute paths and works from other working directories.

## Build the C++ model

Use CMake 3.16 or later and a C++17 compiler:

```sh
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

```sh
./build/latencytest Costmodel/cpp/config/EspressoHarris_config.json input_example/events/synthetic.txt
```

On Windows, select a compiler generator available on your system. The executable
may be `build/latencytest.exe` or `build/Debug/latencytest.exe`.

The Python and C++ models are separate research revisions, with different image
dimensions and configuration schemas. Their algorithms have not been made
equivalent during repository consolidation. See [reproducibility notes](docs/REPRODUCIBILITY.md).

## FPGA and publications

See [FPGA instructions](fpga/README.md) for the Vivado project generator and
[Verilog sources](verilog/README.md) for the design revisions.
See [papers](papers/README.md) and [CITATION.cff](CITATION.cff) for attribution.

This release contains the generic Espresso architecture. Sensor SDKs, captures,
sensor-specific integration, private research records, and publisher proofs are
not distributed. See [release scope](docs/RELEASE_SCOPE.md).

No project-wide redistribution license has been assigned. Third-party notices
are retained in [NOTICE.md](NOTICE.md).
