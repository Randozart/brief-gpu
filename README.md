# GPU Core - Experimental SIMD Accelerator

A 256-lane vector ALU coprocessor written in [Brief](https://github.com/Randozart/brief-lang).

## Architecture

- **256 parallel lanes** of 16-bit computation
- **4-bit opcode** (16 instructions, 9 defined)
- **MMIO interface** for CPU communication
- **AXI4-Lite interface** for SoC integration

## Operations (Opcodes)

| Opcode | Operation | Description |
|--------|----------|------------|
| 0 | Add | `a + b` |
| 1 | Sub | `a - b` |
| 2 | Mul | `a * b` |
| 3 | XOR | `a ^ b` |
| 4 | AND | `a & b` |
| 5 | Shl | `a << b` |
| 6 | Shr | `a >> b` |
| 7 | ReLU | `max(0, a)` |
| 8 | Mask | `b == 0 ? a : b` |

## Memory Map

| Address | Register | Description |
|---------|-----------|--------------|
| 0x40000000 | gpu_status | 0=Idle, 1=Running, 2=Done |
| 0x40000004 | opcode | Operation to execute |
| 0x40001000 | vec_A[256] | Input vector A |
| 0x40002000 | vec_B[256] | Input vector B |
| 0x40003000 | vec_R[256] | Result vector |

## Compilation

Assuming brief-lang and brief-gpu share the same folder:

```bash
cd ../brief-lang
cargo build --release
./target/release/brief-compiler verilog ../brief-gpu/gpu_core.ebv --hw ../brief-gpu/hardware.toml --out ../gpu
```

Output: `gpu_core.sv`, `gpu_core_tb.sv`

## Usage

1. Write data to `vec_A` and `vec_B` (MMIO or AXI)
2. Write opcode to `opcode` register
3. Write `1` to `gpu_status` to start
4. Poll `gpu_status` until `2` (done)
5. Read results from `vec_R`

## Performance & Efficiency Benchmarks

### 1. Raw Compute Throughput (Peak)
- **Parallelism:** 256 Lanes
- **Operation Width:** 16-bit Signed Integers
- **Clock Speed:** 100 MHz (per `hardware.toml`)
- **Cycles per Compute:** 1 Cycle
- **Peak Performance:** **25.6 GOPS** (Giga-Operations Per Second)
- **Peak Internal Bandwidth:** **409.6 Gbps**

### 2. Efficiency Analysis

#### Hardware Density
The design utilizes a **Spatial Architecture**. Unlike a CPU which reuses a few ALUs over time (temporal), this design maps all 256 ALUs onto the silicon fabric simultaneously.
- **Estimated Registers:** ~12,288 bits for vector storage.
- **ALU Efficiency:** 100% utilization of compute resources during the execution cycle.

#### IO Utilization (The Bottleneck)
While the core is capable of 25.6 GOPS, the overall system efficiency is currently limited by the AXI-Lite MMIO interface.
- **Loading Data (256 writes):** ~256 cycles
- **Execution:** 1 cycle
- **Retrieving Data (256 reads):** ~256 cycles
- **Total Pipeline Cycles:** ~513 cycles
- **Real-World Utilization Ratio:** **~0.19%**

*Note: To improve efficiency, a DMA engine capable of burst transfers should be implemented.*

### 3. Simulation & Verification
The design includes a SystemVerilog testbench for cycle-accurate verification.

**Run Simulation:**
```bash
iverilog -g2012 -o gpu_sim gpu_interface_tb.sv gpu_interface.sv gpu_core.sv
vvp gpu_sim
```

**View Waveforms:**
```bash
gtkwave waveform.vcd
```
