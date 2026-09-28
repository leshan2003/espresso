"""Run the cost-model regression suite from any working directory."""
from pathlib import Path
import subprocess
import sys

if __name__ == "__main__":
    tests = Path(__file__).resolve().parents[1] / "Costmodel/tests"
    sys.exit(subprocess.call([sys.executable, "-m", "unittest", "discover", "-s", str(tests), "-p", "test_python.py", "-v"]))
