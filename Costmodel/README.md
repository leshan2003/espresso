# Cost models

| Directory | Implementation | Configuration |
| --- | --- | --- |
| `python/` | Python cycle model and `run.py` runner | `python/config/` |
| `cpp/` | Historical C++17 model and `latencytest` entry point | `cpp/config/` |

From the repository root:

```sh
python Costmodel/python/run.py input_example/events/synthetic.txt
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

The C++ executable accepts a configuration and event-file path:

```sh
./build/latencytest Costmodel/cpp/config/EspressoHarris_config.json input_example/events/synthetic.txt
```

Both models consume row-major `row column value` records. They are different
research revisions, with different image dimensions and configuration schemas;
do not interchange their JSON configurations. The supplied input yields 3,891
Python cycles and 3,890 C++ cycles. See the [reproducibility notes](../docs/REPRODUCIBILITY.md).
