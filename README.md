# Parameterisable FFT Core

A synthesizable **Radix-2 Decimation-in-Time (DIT) Cooley–Tukey FFT Core** written in Verilog, parameterisable up to **N = 512**, with an **AXI-Lite Control Interface**.

---

## Repo Link

https://github.com/acac2495/fft_core_axi

---

## Features

- 5-stage butterfly pipeline
- Fixed-point arithmetic
  - Q1.18 format for twiddle factors
  - Q8.11 format for input and FFT output data
- Ping-Pong memory addressing scheme, utilising 2 dual port BRAM modules alternately
- AXI-Lite slave wrapper with busy-protected register access
- MATLAB-generated test vectors with floating-point reference comparison

---

## Module List

| Module | Description |
|---------|-------------|
| `agu.v` | Address Generation Unit |
| `mem_proc_unit.v` | Memory and Butterfly Processing Unit |
| `top_fft.v` | Top-level FFT module |
| `fft_axi_interface.v` | AXI-Lite Slave Wrapper |
| `dual_port_ram.v` | Dual Port Memory (BRAM - Style)

---

## Architecture

*Architecture diagram coming soon.*

---

## Address Generation

An `N` point FFT requires `$clog2(N)` layers, with each layer containing N/2 butterflies of compute.
The input to the FFT comes in a bit-reversed form of the original signal.

The following formula can be used to address the butterflies for a given layer : 

Consider `i` to be the layer number, and `j` to be the butterfly number
The upper memory address in the butterfly is given as : `rotateN(2j, i)`, and the lower as `rotateN(2j + 1, i)`
Here, `rotateN(a,b)` functions as a circular left shift of `a` by `b` positions, where a is an `N` bit number.

Hence, the AGU functions as an FSM, which cycles `i` from 0 to `$clog2(N) - 1`, and `j` from 0 to `N/2 - 1` for every `i`, and keeps sending the addresses out in a pipelined manner
When the `j` cycle is complete, all butterflies of a layer are done. The FSM waits for 5 flush cycles, for the computations of the layer to complete, before moving to the next.
This avoids hazards.

---

## Memory Management and BRAM

2 'banks' of BRAM are used here : Bank A and Bank B, with separate real and imaginary versions, hence 4 memory modules in total.

The calculation starts off by loading signal data into Bank A, reading from this bank, for the first layer.
The first layer computation results are stored in Bank B.
Then, in the second layer, the data is read from Bank B, and stored into Bank A.
This alternating scheme keeps repeating, till all butterfly layers are finished.

The bank access is controlled insode `agu.v`, with a `bank_sel` signal toggling at the end of every flush cycle.

---

## Simulation

Simulation is performed using **Icarus Verilog** and **GTKWave**.

The `sim/` directory contains all testbenches.

- `axi_tb.v` – Complete FFT implementation with AXI-Lite wrapper
- `tb_1.v`, `tb_2.v`, `tb_3.v` – Intermediate module verification

The `mem_proc_unit.v` module provides the `display_fft_output` task for displaying FFT outputs in signed fixed-point real format.

### Running the Simulation

```bash
iverilog -o tb.vvp ../rtl/*.v axi_tb.v
vvp tb.vvp
gtkwave waveform.vcd
```

---

## MATLAB Verification

The MATLAB scripts generate:

- Input signal memories
- Twiddle factor memories
- Floating-point reference FFT outputs

When changing the FFT size (`N`), regenerate:

- `real_mem`
- `imag_mem`
- `real_twiddle_mem`
- `imag_twiddle_mem`

The `axi_tb.v` testbench includes a `load_data` task for loading signal samples through the AXI interface.

---

## Verification

The FFT output was verified against MATLAB reference results for multiple FFT sizes.

Observed differences are consistent with the expected quantization error introduced by the fixed-point implementation.