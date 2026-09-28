# Synthetic input

`events/synthetic.txt` contains 12 hand-authored events, with one `row column value`
record per line in row-major order. It contains no sensor captures or experimental
data. It exercises the software entry points; it does not reproduce paper results.

The Python model reads image dimensions from its configuration. The historical
C++ implementation uses `kImageWidth=256` and `kImageHeight=300` in `component.h`.

Frames must contain at least one event. Blank lines and `#` comments are allowed;
repeated coordinates are allowed when the sequence remains in row-major order.
Each value must fit a signed 32-bit integer. The same validation applies to files
and the model's in-memory event API.
