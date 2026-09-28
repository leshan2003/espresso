# Synthetic input

`events/synthetic.txt` contains 12 hand-authored events, with one `row column value`
record per line in row-major order. It contains no sensor captures or experimental
data. It exercises the software entry points; it does not reproduce paper results.

The Python model reads image dimensions from its configuration. The historical
C++ implementation uses `IMGWIDTH=256` and `IMGHEIGHT=300` in `component.h`.
