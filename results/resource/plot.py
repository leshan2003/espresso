"""Plot the original one-layer FPGA resource measurements."""
import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parents[2] / "build/figures/resource-one-layer.png")
    args = parser.parse_args()
    measurements = {
        "K3-EVS-LUT": [9073, 10041, 11467, 15364],
        "K3-EVS-FF": [4096, 4929, 6559, 9860],
        "K5-EVS-LUT": [34736, 36061, 40627, 49379],
        "K5-EVS-FF": [6898, 8319, 11071, 16673],
    }
    x = np.arange(4)
    fig, ax = plt.subplots(figsize=(10, 5))
    for index, (label, values) in enumerate(measurements.items()):
        ax.bar(x + (index - 1.5) * 0.2, values, width=0.2, label=label)
    ax.set_xticks(x, ["4bit", "8bit", "16bit", "32bit"])
    ax.set(xlabel="Bit width", ylabel="Resource count", title="Resource of one-layer Espresso architecture")
    ax.legend()
    fig.tight_layout()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=300)
    plt.close(fig)
    print(args.output)


if __name__ == "__main__":
    main()
