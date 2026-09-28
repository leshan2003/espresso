# Resource occupancy

`chart1.png`, `chart2.png`, and `resourcelist.png` are the figures previously
published in EspressoResource. CSV tables preserve the visible worksheet values
from its resource spreadsheet without embedding document metadata or comments.

Regenerate the one-layer resource plot with:

```sh
python results/resource/plot.py --output build/figures/resource-one-layer.png
```

The plot's hard-coded measurement arrays are retained from the original
experiment. The image files and tables document historical measurements; this
repository does not rerun synthesis to regenerate them automatically.
