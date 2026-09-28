"""Run the cost model on decimal row/column/value event records."""

import argparse
import json
import math
from pathlib import Path

from component import Espresso
from events import load_events


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("events", type=Path, help="Event text file (blank lines and # comments allowed)")
    parser.add_argument("--config", type=Path, default=Path(__file__).parent / "config/EspressoHarris_config.json")
    parser.add_argument("--clock-mhz", type=float, default=100.0)
    args = parser.parse_args()
    if not math.isfinite(args.clock_mhz) or args.clock_mhz <= 0:
        parser.error("--clock-mhz must be finite and positive")
    try:
        model = Espresso(args.config)
        events = load_events(args.events, model.img_width, model.img_height)
        cycles = model.process_events(events)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps({
        "events": len(events),
        "clock_cycles": cycles,
        "clock_mhz": args.clock_mhz,
        "latency_us": cycles / args.clock_mhz,
        "throughput_fps": args.clock_mhz * 1e6 / cycles,
    }, indent=2))


if __name__ == "__main__":
    main()
