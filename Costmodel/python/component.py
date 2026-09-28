"""Public cost-model API: configuration loading and independent frame simulation."""

import json
from pathlib import Path
from typing import Iterable

from events import Event, load_events, validate_events
from scheduler import EventScheduler, State


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate configuration key: {key}")
        result[key] = value
    return result


def _integer(value, name: str, minimum: int = 1) -> int:
    if type(value) is not int or value < minimum:
        raise ValueError(f"{name} must be an integer >= {minimum}")
    return value


class Espresso:
    """Estimate cycles for row-major event frames using the Python model revision.

    Layer order is the order of entries in the JSON network. Each frame starts
    with fresh scheduler state. Like the research implementation, a frame ends
    when input is exhausted and all schedulers return to UPDATE; no padding or
    final-window flush is inserted. This is a timing model, not a pixel simulator.
    """

    def __init__(self, config_file: str | Path):
        self.load_config(config_file)

    def load_config(self, config_file: str | Path) -> None:
        """Validate a configuration before replacing the current architecture."""
        with Path(config_file).open(encoding="utf-8") as handle:
            config = json.load(handle, object_pairs_hook=_unique_object)
        if not isinstance(config, dict):
            raise ValueError("Configuration must be an object")
        network, image = config.get("network"), config.get("imginfo")
        if not isinstance(network, dict) or not network:
            raise ValueError("network must be a nonempty object")
        if not isinstance(image, dict):
            raise ValueError("imginfo must specify img_width and img_height")
        width = _integer(image.get("img_width"), "img_width")
        height = _integer(image.get("img_height"), "img_height")
        layers = []
        for name, params in network.items():
            if not name or not isinstance(params, dict):
                raise ValueError("Every layer needs a name and parameter object")
            kernel = _integer(params.get("kernelsize"), f"{name}.kernelsize")
            data_width = _integer(params.get("datawidth"), f"{name}.datawidth")
            if kernel > min(width, height):
                raise ValueError(f"{name}: kernel exceeds the image dimensions")
            if ("pool" in name and kernel != 2) or ("pool" not in name and kernel % 2 == 0):
                raise ValueError(f"{name}: pooling needs kernel 2; other kernels must be odd")
            # Keep the exact-name defaults of the original model, including sparse layers.
            default_latency = {"sobel": 1, "gaussian_harris": 3, "nms": 2}.get(name, 1)
            latency = _integer(params.get("computelatency", default_latency), f"{name}.computelatency", 0)
            layers.append((name, kernel, data_width, width, height, latency))
        self.network, self.imginfo = network, image
        self.img_width, self.img_height = width, height
        self._layers = layers
        self.layernum = len(layers)
        self.architecture = self._new_architecture()

    def _new_architecture(self) -> list[EventScheduler]:
        return [EventScheduler(*parameters) for parameters in self._layers]

    def process_frame(self, event_file: str | Path) -> int:
        return self.process_events(load_events(event_file, self.img_width, self.img_height))

    def process_events(self, events: Iterable[Event]) -> int:
        """Simulate a fresh frame, keeping the historical same-cycle stage handoff."""
        frame = validate_events(events, self.img_width, self.img_height)
        self.architecture = self._new_architecture()
        event_index, cycles = 0, 0
        while event_index < len(frame) or any(stage.state != State.UPDATE for stage in self.architecture):
            cycles += 1
            forwarded = None
            for index, stage in enumerate(self.architecture):
                if stage.state == State.READ:
                    ready = index == self.layernum - 1 or self.architecture[index + 1].state == State.UPDATE
                    output = stage.step(ready=ready)
                    if output is not None:
                        forwarded = output
                elif stage.state == State.UPDATE:
                    if index == 0:
                        incoming = frame[event_index] if event_index < len(frame) else None
                        stage.step(incoming)
                        if incoming is not None:
                            event_index += 1
                    else:
                        stage.step(forwarded)
                        forwarded = None
                else:
                    stage.step()
        return cycles
