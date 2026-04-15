# GPU Core - Experimental SIMD Accelerator

A 256-lane vector ALU coprocessor written in Embedded Brief.

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

```bash
cd ../brief-lang
cargo build --release
./target/release/brief-compiler verilog ../gpu/gpu_core.ebv --hw ../gpu/hardware.toml --out ../gpu
```

Output: `gpu_core.sv`, `gpu_core_tb.sv`

## Usage

1. Write data to `vec_A` and `vec_B` (MMIO or AXI)
2. Write opcode to `opcode` register
3. Write `1` to `gpu_status` to start
4. Poll `gpu_status` until `2` (done)
5. Read results from `vec_R`

## Performance

At 100MHz: **25.6 GOPS** (256 lanes × 100M ops/sec)