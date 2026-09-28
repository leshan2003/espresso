"""Event records and the shared, validated text-input format."""

from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterable


@dataclass(frozen=True, slots=True)
class Event:
    """One sparse pixel value at a (row, column) address."""

    addr2d: tuple[int, int] = (0, 0)
    value: int = 0


def validate_events(events: Iterable[Event], width: int, height: int) -> list[Event]:
    """Materialize a nonempty, row-major frame without truncating input values."""
    frame = []
    previous_address = -1
    for index, event in enumerate(events, start=1):
        if not isinstance(event, Event):
            raise ValueError(f"Event {index}: expected an Event record")
        row, column = event.addr2d
        if any(type(value) is not int for value in (row, column, event.value)):
            raise ValueError(f"Event {index}: fields must be integers")
        if not (0 <= row < height and 0 <= column < width):
            raise ValueError(f"Event {index}: coordinates exceed {height} rows by {width} columns")
        if not -(2**31) <= event.value < 2**31:
            raise ValueError(f"Event {index}: value must fit a signed 32-bit integer")
        address = row * width + column
        if address < previous_address:
            raise ValueError(f"Event {index}: events must be in nondecreasing row-major order")
        previous_address = address
        frame.append(event)
    if not frame:
        raise ValueError("The event frame is empty")
    return frame


def load_events(path: str | Path, width: int, height: int) -> list[Event]:
    """Read decimal row/column/value records; blank lines and # comments are allowed."""
    events = []
    with Path(path).open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            fields = line.partition("#")[0].split()
            if not fields:
                continue
            try:
                if len(fields) != 3 or any(re.fullmatch(r"[+-]?[0-9]+", field) is None for field in fields):
                    raise ValueError
                # int() rejects fractional/scientific notation, unlike float-to-int casts.
                row, column, value = (int(field, 10) for field in fields)
            except ValueError:
                raise ValueError(f"{path}:{line_number}: expected three decimal integers") from None
            events.append(Event((row, column), value))
    return validate_events(events, width, height)
