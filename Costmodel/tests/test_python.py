"""Synthetic timing regressions and public API contracts (no captured data)."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Costmodel/python"))
from component import Espresso
from events import Event, load_events
from scheduler import EventScheduler, State

CONFIG = ROOT / "Costmodel/python/config/EspressoHarris_config.json"


class ModelTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.scratch = Path(self.temporary.name)

    def fixture(self, content, name="events.txt"):
        path = self.scratch / name
        path.write_text(content, encoding="utf-8")
        return path

    def test_recorded_cycles_and_repeated_frames(self):
        baseline = json.loads(Path(__file__).with_name("baselines.json").read_text())
        for case in baseline["cases"]:
            events = [Event((row, column), value) for row, column, value in case["events"]]
            for name, expected in case["python_cycles"].items():
                with self.subTest(case=case["name"], config=name):
                    model = Espresso(CONFIG.with_name(name + ".json"))
                    self.assertEqual(model.process_events(events), expected)
                    self.assertEqual(model.process_events(iter(events)), expected)

    def test_reload_replaces_architecture_and_is_atomic(self):
        model = Espresso(CONFIG)
        two_layers = CONFIG.with_name("EspressoHarris_2layer_config.json")
        model.load_config(two_layers)
        self.assertEqual(model.layernum, 2)
        expected = model.process_events([Event((2, 2), 1)])
        with self.assertRaises(ValueError):
            model.load_config(self.fixture('{"network": {}}', "bad.json"))
        self.assertEqual(model.layernum, 2)
        self.assertEqual(model.process_events([Event((2, 2), 1)]), expected)

    def test_text_input_comments_single_and_duplicates(self):
        path = self.fixture("# synthetic\n\n+2 3 -1 # comment\n")
        self.assertEqual(load_events(path, 256, 320), [Event((2, 3), -1)])
        self.assertGreater(Espresso(CONFIG).process_frame(path), 0)
        path = self.fixture("2 3 -1\n2 3 +2\n")
        self.assertEqual(len(load_events(path, 256, 320)), 2)

    def test_invalid_text_and_direct_api(self):
        for text in ("", "# empty\n", "0 0 1.5", "0+0 1", "0 0 1 4", "0 0 1e2",
                     "0 0 2147483648", "0 256 1", "320 0 1", "-1 0 1", "2 0 1\n1 0 1"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                load_events(self.fixture(text), 256, 320)
        model = Espresso(CONFIG)
        for events in ([], [Event((-1, 0), 1)], [Event((0, 0), True)],
                       [Event((0, 0), 2**31)], [Event((2, 0), 1), Event((1, 0), 1)], [object()]):
            with self.subTest(events=events), self.assertRaises(ValueError):
                model.process_events(events)

    def test_invalid_configuration(self):
        valid = json.loads(CONFIG.read_text())
        invalid = ["[]", '{}', '{"network":{},"network":{}}']
        invalid.append('{"imginfo":{"img_width":256,"img_height":320},'
                       '"network":{"layer":{"kernelsize":3,"kernelsize":5,"datawidth":8}}}')
        invalid.append(json.dumps(valid) + " trailing")
        for field, value in (("kernelsize", 2), ("kernelsize", 999), ("datawidth", 0),
                             ("computelatency", -1), ("kernelsize", True)):
            config = json.loads(json.dumps(valid))
            config["network"][next(iter(config["network"]))][field] = value
            invalid.append(json.dumps(config))
        valid["imginfo"]["img_width"] = 0
        invalid.append(json.dumps(valid))
        for text in invalid:
            with self.subTest(text=text), self.assertRaises(ValueError):
                Espresso(self.fixture(text, "bad.json"))

    def test_scheduler_holds_output_until_ready(self):
        stage = EventScheduler("sobel", 3, 8, 256, 320, 1)
        stage.step(Event((2, 2), 1))
        for _ in range(100):
            if stage.state == State.UPDATE:
                break
            stage.step(ready=True)
        self.assertEqual(stage.state, State.UPDATE)
        stage.step(Event((8, 8), 1))
        for _ in range(100):
            if stage.state == State.READ and stage.compute_done:
                break
            stage.step()
        self.assertTrue(stage.compute_done)
        address = stage.output_address
        for _ in range(5):
            self.assertIsNone(stage.step(ready=False))
            self.assertEqual(stage.output_address, address)
        self.assertEqual(stage.step(ready=True), Event(divmod(address, 256), 1))
        self.assertEqual(stage.state, State.COMPARE)

    def test_cli_from_external_directory(self):
        command = [sys.executable, str(ROOT / "Costmodel/python/run.py"),
                   str(ROOT / "input_example/events/synthetic.txt")]
        result = subprocess.run(command, cwd=self.scratch, capture_output=True, text=True, check=True, timeout=30)
        output = json.loads(result.stdout)
        self.assertEqual((output["clock_cycles"], output["events"], output["latency_us"]), (3891, 12, 38.91))
        for clock in ("0", "-1", "nan", "inf", "100junk"):
            result = subprocess.run(command + ["--clock-mhz", clock], cwd=self.scratch,
                                    capture_output=True, text=True, timeout=30)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("error:", result.stderr)


if __name__ == "__main__":
    unittest.main()
