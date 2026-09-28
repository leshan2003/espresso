"""Cycle-level scheduler for the Python research revision.

This models scheduling latency, not the numerical convolution. Output events
carry the placeholder value 1, as in the original Python implementation.
"""

from collections import deque
from enum import IntEnum

from events import Event


class State(IntEnum):
    UPDATE = 0
    COMPARE = 1
    READ = 2
    WRITE = 3


class EventScheduler:
    """One four-state scheduler with pending output-window addresses."""

    def __init__(self, kernel_name: str, kernel_size: int, data_width: int,
                 img_width: int, img_height: int, compute_latency: int):
        self.kernel_name = kernel_name
        self.kernel_size = kernel_size
        self.data_width = data_width
        self.img_width = img_width
        self.img_height = img_height
        self.half_kernel = kernel_size // 2
        self.compute_latency = compute_latency
        self.mode = "pool" if "pool" in kernel_name else "sparse" if "sparse" in kernel_name else "dense"
        self.pending = [deque() for _ in range(kernel_size if self.mode == "dense" else 1)]
        self.state = State.UPDATE
        self.current_event = Event()
        self.previous_event = Event()
        self.output_address = 0
        self.current_row = 0
        self.write_done = False
        self.write_clock = 0
        self.write_completed = False
        self.compute_done = False
        self.compute_clock = 0

    def absolute_address(self, address: tuple[int, int]) -> int:
        return address[0] * self.img_width + address[1]

    def _enqueue_windows(self) -> None:
        row, column = self.current_event.addr2d
        if self.mode == "pool":
            address = (row if row % 2 else row + 1, column if column % 2 else column + 1)
            if not self.pending[0] or self.pending[0][-1] != address:
                self.pending[0].append(address)
        elif self.mode == "sparse":
            self.pending[0].append((row + self.half_kernel, column + self.half_kernel))
        else:
            previous_row, previous_column = self.previous_event.addr2d
            # Overlapping windows on the same row contribute only the new columns.
            full_window = row != previous_row or column >= previous_column + self.kernel_size
            start = 0 if full_window else self.kernel_size - (column - previous_column)
            for offset_column in range(start, self.kernel_size):
                for offset_row, queue in enumerate(self.pending):
                    queue.append((row + offset_row, column + offset_column))

    def _next_address(self) -> int | None:
        return min((self.absolute_address(queue[0]) for queue in self.pending if queue), default=None)

    def step(self, event: Event | None = None, *, ready: bool = False) -> Event | None:
        """Advance exactly one clock, returning an output only on a ready handshake."""
        if self.state == State.UPDATE:
            if event is not None:
                self.previous_event, self.current_event = self.current_event, event
                self._enqueue_windows()
                self.state = State.COMPARE
        elif self.state == State.COMPARE:
            address = self._next_address()
            # Preserve this revision's window-readiness rule (different from C++).
            if address is not None and address < self.absolute_address(self.current_event.addr2d):
                self.output_address = address
                for queue in self.pending:
                    if queue and self.absolute_address(queue[0]) == address:
                        queue.popleft()
                self.state = State.READ
                self.compute_done = False
            else:
                self.state = State.WRITE
                self.write_done = False
                self.write_clock = 0
                self.write_completed = False
        elif self.state == State.READ:
            if self.compute_done:
                if ready:
                    self.state = State.COMPARE
                    self.compute_done = False
                    return Event(divmod(self.output_address, self.img_width), 1)
            elif self.compute_clock < self.compute_latency:
                self.compute_clock += 1
            else:
                self.compute_clock = 0
                self.compute_done = True
        elif self.state == State.WRITE:
            if self.write_completed:
                self.state = State.UPDATE
                self.write_completed = False
                self.write_done = False
            elif self.write_done:
                if self.write_clock < 1:
                    self.write_clock += 1
                else:
                    self.write_clock = 0
                    self.write_completed = True
            elif self.current_row < self.current_event.addr2d[0] - self.kernel_size + 1:
                self.current_row += 1
            else:
                self.write_done = True
        return None
