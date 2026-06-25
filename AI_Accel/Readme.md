# Tiny MLP Hardware Accelerator (Verilog)

## What this project is

This is a small, fully working **neural network inference accelerator implemented directly in Verilog hardware**, not run on a CPU/GPU through software. It computes the forward pass of a 2-layer feedforward neural network (a Multi-Layer Perceptron, or MLP) entirely in digital logic — multipliers, adders, registers, and a finite state machine — with no processor, no instruction set, and no software runtime involved.

It is the first concrete step in a longer plan:

> **Build a small MLP on FPGA to prove the datapath and control logic, then scale and reuse the same building blocks for larger feedforward networks on FPGA.**

Everything here was deliberately built generic/parameterized from the start (input width, neuron count, bit width are all Verilog `parameter`s) specifically so the same RTL can be reused at larger scale later, rather than being thrown away once this bring-up design works.

This project grew directly out of the `AI_Accel` folder of the [`FPGA_Workshop`](https://github.com/roboticist-blip/FPGA_Workshop) repo, which contained the original hand-built MAC unit and 4-element "neuron" (`mac_dot.v` / `neuron.v`) that this design generalizes and scales up.

---

## Why build a neural network *in hardware* at all?

When a neural network normally runs, software on a CPU/GPU fetches weights from memory, multiplies, accumulates, and loops — instruction by instruction. That flexibility costs time and power.

A **hardware accelerator** instead builds the network's math directly out of physical logic gates and flip-flops on the FPGA fabric. Every neuron's multiply-accumulate operation happens in real silicon, in parallel, on every clock edge — there's no instruction fetch, no loop overhead, just data flowing through wires and registers. This is why dedicated NN accelerators (whether in a phone's NPU or a datacenter's TPU) are both faster and far more power-efficient than running the same network on a general-purpose CPU.

The tradeoff: hardware is far less flexible to *change* than software. That's exactly why this project starts small — prove the architecture works on a tiny, hand-checkable network before committing real silicon/FPGA area to a bigger one.

---

## Network architecture implemented

```
Input vector (4 values)
        │
        ▼
┌───────────────────┐
│   Layer 1 (Hidden) │   4 neurons, each fully connected to all 4 inputs
│   4-wide dot product│   y = ReLU( Σ(x_i · w_i) + b )
│   + bias + ReLU     │
└───────────────────┘
        │  (4 values, requantized 32-bit → 8-bit)
        ▼
┌───────────────────┐
│   Layer 2 (Output)  │   2 neurons, each fully connected to all 4 hidden outputs
│   4-wide dot product│   y = ReLU( Σ(x_i · w_i) + b )
│   + bias + ReLU     │
└───────────────────┘
        │
        ▼
Output vector (2 values)
```

This is a standard fully-connected feedforward network — the same math TensorFlow or PyTorch would compute for a `Dense(4) -> Dense(2)` model — just implemented as physical hardware instead of as a software graph.

**Number format:** fixed-point signed integers. Inputs and weights are 8-bit (INT8), internal accumulation is done in 32-bit to avoid overflow while summing, and results are saturated (clipped, not wrapped) back down to 8-bit when passed to the next layer. This is the same precision strategy used by most real-world embedded/edge NN accelerators — full floating point is unnecessary and expensive in hardware for small inference tasks like this.

**Weights:** currently hardcoded into the Verilog source as small, hand-picked integers — *not* trained weights. The point of this stage is to prove the hardware computes a dot-product + bias + ReLU correctly, not to solve a real task yet. Swapping in real trained (and quantized) weights is a later step.

---

## How a single neuron works (`neuron.v`)

Each neuron computes, in one Verilog module:

```
OUT = ReLU( (x0·w0 + x1·w1 + ... + x(N-1)·w(N-1)) + bias )
```

- The `N` multiplications happen **simultaneously** in parallel hardware (a `generate` loop instantiates N multipliers), not one after another.
- Their results are summed by a combinational adder tree.
- The bias is added.
- **ReLU** (Rectified Linear Unit) is applied: if the result is negative, output 0; otherwise pass it through unchanged. This is the standard activation function that lets neural networks model non-linear relationships — without it, stacking layers would be mathematically pointless (multiple linear layers collapse into one linear layer).
- The final result is captured in a register on the clock edge — this is the only place a clock matters in the whole neuron; the dot product itself is pure combinational logic.

`N`, the data width, and the accumulator width are all parameters — the exact same module serves as a 4-input neuron here and will serve as an 8-input or 10-input (or wider) neuron when this gets reused for a larger network, with zero code changes.

---

## Project files

| File | Purpose |
|---|---|
| `neuron.v` | One neuron: parameterized N-wide dot product + bias + ReLU, registered output |
| `neuron_layer.v` | A full layer: instantiates N_OUT neurons in parallel, all fed the same input vector |
| `requant.v` | Converts a layer's wide (32-bit) accumulator output back down to narrow (8-bit) signed format for the next layer, saturating instead of wrapping on overflow |
| `weights_l1.v` | Hardcoded weights/bias ROM for the hidden layer (4→4) |
| `weights_l2.v` | Hardcoded weights/bias ROM for the output layer (4→2) |
| `fsm_ctrl.v` | Finite state machine sequencing the pipeline (`IDLE → LOAD_INPUT → LAYER1_WAIT → LAYER2_WAIT → DONE`) and producing a clean one-cycle `done` pulse |
| `mlp_top.v` | Top-level module wiring everything above together |
| `tb_mlp_top.v` | Testbench: drives three test input vectors through the network and prints/dumps the results |
| `mlp_top.vcd` | Waveform dump from a real simulation run, viewable in GTKWave |

---

## How the pieces connect (`mlp_top.v`)

```
X_IN (4×8b)
   │
   ▼
[weights_l1 ROM] ──► [neuron_layer: 4 neurons] ──► l1_Y (4×32b, post-ReLU)
                                                       │
                                                       ▼
                                              [requant: 32b→8b, saturating]
                                                       │
                                                       ▼
                                                   l1_Yq (4×8b)
                                                       │
[weights_l2 ROM] ──────────────────────► [neuron_layer: 2 neurons] ──► Y_OUT (2×32b, post-ReLU)

[fsm_ctrl] runs alongside, sequencing timing and raising `done` when Y_OUT is valid.
```

**Timing:** because each layer's dot product is combinational logic with only the final output registered, a result takes exactly **2 clock edges** from when a new input is presented to when the final output is valid (1 edge per layer). The FSM makes this explicit instead of leaving it as an implicit timing assumption — `done` pulses high for exactly one clock cycle once `Y_OUT` is guaranteed valid.

---

## Verified simulation results

The design was compiled and simulated with Icarus Verilog (`iverilog` + `vvp`), the same toolchain used for the original workshop files, and every output was hand-traced and checked against the simulator:

| Input vector `[x0,x1,x2,x3]` | Hand-calculated output `[y0,y1]` | Simulated output `[y0,y1]` |
|---|---|---|
| `[2, 3, -1, 4]` | `[8, 8]` | `[8, 8]` ✅ |
| `[0, 0, 0, 0]` | `[0, 0]` | `[0, 0]` ✅ |
| `[5, 5, 5, 5]` | `[20, 16]` | `[20, 16]` ✅ |

All three matched exactly, confirming the datapath, requantization, and FSM timing all behave as designed.

---

## How to run it yourself

```bash
# Compile
iverilog -o mlp_sim neuron.v neuron_layer.v requant.v weights_l1.v weights_l2.v fsm_ctrl.v mlp_top.v tb_mlp_top.v

# Simulate
vvp mlp_sim

# View waveform (after simulation produces mlp_top.vcd)
gtkwave mlp_top.vcd
```

In the waveform, watch `dbg_state` step through `0→1→2→3→4→0` and confirm `y0`/`y1` settle to their final values by the time `done` pulses high.

---

## Design decisions and why

- **Combinational dot product, registered only at the output** — keeps control logic simple (no multi-cycle MAC sequencing needed) and is fast enough that an Artix-class FPGA has no trouble timing-closing it for a network this small.
- **All neurons in a layer computed in parallel** — trades FPGA area (more multipliers used at once) for speed and simplicity; reasonable for a network this small, and the same tradeoff any larger network's bigger layers will need to be re-evaluated for once area becomes a real constraint.
- **ReLU on every layer, including the output** — simple and standard for hidden layers. Note this means the network's final output can never go negative — a real modeling constraint worth remembering once real trained weights/tasks are involved, not just a hardware detail.
- **Saturating requantization between layers, not truncation** — silently wrapping an overflowed value produces a wrong-but-plausible-looking number, which is far more dangerous to debug than a value that's visibly clipped to the max/min representable value.
- **Hardcoded ROM weights for this stage** — removes weight-loading as a variable while the core compute pipeline is being proven. Runtime weight loading (UART/AXI) is a deliberately deferred next step, not an oversight.

---

## What's next

1. Bring this design into Vivado as an RTL project and check synthesis results (LUT/DSP utilization) on the target Artix part.
2. Optionally validate on real hardware (e.g. drive `Y_OUT` to LEDs or out over UART) as a hardware-in-the-loop sanity check.
3. Scale the same building blocks (`neuron.v`, `neuron_layer.v`, `requant.v`) up to a larger, real-world network topology.
4. Move from hardcoded ROM weights to runtime-loaded weights (UART or AXI) once a real trained model is being targeted.
