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
- Count-and-Rotate address generation
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

---

## Architecture

*Architecture diagram coming soon.*

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