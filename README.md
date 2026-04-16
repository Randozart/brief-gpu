# GPU Core - Experimental SIMD Accelerator

A vector ALU coprocessor written in [Brief](https://github.com/Randozart/brief-lang).

## Architecture

### V1 (Legacy)
- **256 parallel lanes** of 16-bit computation
- **AXI4-Lite interface** for MMIO
- Flip-flop based vector storage (Resource intensive)

### V2 (Current)
- **32 parallel lanes** (Scalable)
- **Hardcoded Block RAM (BRAM)** staging area via `hardware_lib`
- **Spec-driven validation**: Compiler cross-verifies `.ebv` logic against `hardware.toml` constraints
- **Modular Interface Support**: AXI4-Lite (control) and AXI4-Stream (data) support via spec library
- **Extended ISA**: Added Bitwise XOR (`^`), Shift Left (`<<`), and Shift Right (`>>`)

## Hardware Specification System

Brief-Verilog now uses a three-layer hardware specification system:

1. **Brief (`.ebv`)**: Pure behavioral logic and data flow.
2. **Hardware Library (`hardware_lib/`)**: Reusable specifications for interfaces (AXI, PCIe, USB), memory types (BRAM, FF, ROM), and target FPGAs/ASICs.
3. **Project Config (`hardware.toml`)**: Maps project variables to specific hardware resources and interfaces.

## Memory Map (V2 Default)

| Address | Register | Description |
|---------|-----------|--------------|
| 0x40000000 | control | 0=Idle, 3=Execute |
| 0x40000004 | status | 0=Idle, 1=Running, 2=Done |
| 0x40000008 | opcode | Operation to execute |
| 0x40000010 | ping_buffer[32] | Input vector A (BRAM) |
| 0x40000020 | pong_buffer[32] | Input vector B (BRAM) |
| 0x40000030 | result_buffer[32] | Result vector (BRAM) |

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

## Compilation

V2 requires a hardware configuration file:

```bash
./brief-compiler verilog gpu_core_v2.ebv --hw gpu_core_v2.toml --out v2_out
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
