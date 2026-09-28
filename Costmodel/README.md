# Cost models

| Directory | Implementation | Configuration |
| --- | --- | --- |
| `python/` | Python cycle model and `run.py` runner | `python/config/` |
| `cpp/` | C++17 library and `latencytest` entry point | `cpp/config/` |
| `tests/` | Synthetic regressions and API checks | Recorded pre-refactor cycle counts |

From the repository root:

```sh
python Costmodel/python/run.py input_example/events/synthetic.txt
python tools/check_model.py
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

The C++ executable accepts a configuration and event-file path:

```sh
./build/latencytest Costmodel/cpp/config/EspressoHarris_config.json input_example/events/synthetic.txt
```

The Python implementation separates immutable event records and text parsing
(`events.py`), the per-clock scheduler (`scheduler.py`), frame orchestration
(`component.py`), and the CLI (`run.py`). It requires only Python's standard library.
Add `Costmodel/python` to your import path to use the model directly:

```python
from component import Espresso
from events import Event

model = Espresso("Costmodel/python/config/EspressoHarris_config.json")
cycles = model.process_events([Event((2, 3), 1), Event((8, 9), 2)])
cycles_again = model.process_events([Event((2, 3), 1), Event((8, 9), 2)])
assert cycles == cycles_again  # each call starts an independent frame
```

Both implementations expose `Espresso.process_frame(path)` and
`Espresso.process_events(events)`. C++ uses `Event{{row, column}, value}` and can
be linked through the `espresso_cost_model` CMake target. Scheduler internals
have been renamed and encapsulated; callers of the old experimental internals
should migrate to the frame APIs.

Both models consume nonempty, row-major `row column value` records. Blank lines,
`#` comments, one-event frames, and repeated coordinates are supported. They are different
research revisions, with different image dimensions and configuration schemas;
do not interchange their JSON configurations. The supplied input yields 3,891
Python cycles and 3,890 C++ cycles. See the [reproducibility notes](../docs/REPRODUCIBILITY.md).
