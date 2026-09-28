# Espresso

Spatiotemporal ordering for sparse vision processing.

Leshan Li and collaborators · [Publications](../papers/README.md)

---

## The problem

Sparse events can avoid work on zero values. Conventional frame accumulation
delays processing and can lose that advantage. A streaming architecture must
also preserve the ordering needed by subsequent spatial operators.

---

## The architecture

```mermaid
flowchart LR
    A[Ordered sparse events] --> B[Event Scheduler]
    B --> C[Spatial operator]
    C --> D[Event Scheduler]
    D --> E[Next spatial operator]
```

The scheduler coordinates pending output windows and access to sparse values.
The released Harris pipeline combines Sobel, Gaussian/Harris, and nonmaximum
suppression stages.

---

## Scheduling and storage

- N pending FIFOs maintain candidate window addresses across rows.
- Selecting the minimum pending address preserves output order.
- A shift-hash table provides access to spatial windows without buffering the
  entire image.
- The scheduler advances through update, compare, read, and write states.

---

## Explore the implementation

- Python and C++ models: `Costmodel/`
- Design RTL: `verilog/design/`
- Testbenches and simulation helpers: `verilog/simulation/`
- FPGA Tcl scripts: `fpga/`
- Synthetic input: `input_example/`
- Resource measurements: `results/resource/`

---

## Reproduce the software smoke test

```sh
python Costmodel/python/run.py input_example/events/synthetic.txt
```

The 12 synthetic events produce 3,891 Python model cycles. This example checks
the software path; it is not a reproduction of the paper's experimental results.
