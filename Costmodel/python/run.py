"""Run the research cost model without relying on the current directory."""
import argparse
import json
import math
from pathlib import Path

import numpy as np

from component import Espresso


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("events", type=Path, help="Whitespace-separated row column value records")
    parser.add_argument("--config", type=Path, default=Path(__file__).parent / "config/EspressoHarris_config.json")
    parser.add_argument("--clock-mhz", type=float, default=100.0)
    args = parser.parse_args()
    if not math.isfinite(args.clock_mhz) or args.clock_mhz <= 0:
        parser.error("--clock-mhz must be finite and positive")
    if not args.events.is_file() or not args.config.is_file():
        parser.error("Both the event file and configuration must exist")
    try:
        data = np.loadtxt(args.events, ndmin=2)
        if data.shape[0] < 2 or data.shape[1] != 3:
            raise ValueError("Expected at least two row/column/value records")
        if not np.all(np.isfinite(data)) or not np.all(data == np.floor(data)):
            raise ValueError("Event fields must be finite integers")
        model = Espresso(args.config)
        rows, cols = data[:, 0], data[:, 1]
        if np.any(rows < 0) or np.any(rows >= model.img_height) or np.any(cols < 0) or np.any(cols >= model.img_width):
            raise ValueError("Event coordinates exceed the configured image dimensions")
        if np.any(np.diff(rows * model.img_width + cols) < 0):
            raise ValueError("Events must be in nondecreasing row-major order")
        cycles = model.process_frame(args.events)
        if not cycles or cycles <= 0:
            raise ValueError("The model produced no clock cycles")
    except (OSError, ValueError, KeyError, TypeError) as exc:
        parser.error(str(exc))
    print(json.dumps({"events": len(data), "clock_cycles": cycles,
                      "clock_mhz": args.clock_mhz,
                      "latency_us": cycles / args.clock_mhz,
                      "throughput_fps": args.clock_mhz * 1e6 / cycles}, indent=2))


if __name__ == "__main__":
    main()
