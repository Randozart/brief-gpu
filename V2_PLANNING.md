# Brief-GPU V2 Planning Document

## Overview

This document captures the design discussions for the next generation of the Brief-GPU project. The project has two parallel exploration tracks:

1. **ASIC LLM Accelerator** - Hardcoded weights as logic for "speed of electricity" computation
2. **Improved GPU** - General-purpose parallel accelerator with better memory architecture

---

## Context: Why V2?

The current V1 design (256-lane SIMD accelerator) suffers from the **Von Neumann bottleneck**:
- 256 lanes × 16-bit = 4,096 bits per operation
- AXI4-Lite delivers only 32 bits per transaction
- Utilization: ~0.19% (compute sits idle waiting for data)

This is the fundamental problem we're trying to solve.

---

## Option A: ASIC LLM Accelerator

### Concept

Hardcode a small LLM's weights directly into the silicon as combinational logic. Data flows through, computation happens as electricity passes through transistors - no memory fetch required.

### Architecture

```
Input Vector → [Weight Gates (hardcoded as logic)] → Output
                ↑
           No memory fetch - weights ARE the transistors
```

### Target Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Process Node | SkyWater 130nm | Affordable open PDK |
| Model Size | 50k-100k parameters | Fits in ~10mm² |
| Quantization | 1-2 bits | Maximizes density |
| Architecture | Dataflow | Pipelined token generation |
| Interface | Parallel I/O | Can bridge to USB 3.0 |
| Estimated Cost | $10k-30k | 1mm² = ~$10-30k at 130nm |

### Practical Use Cases

- Command recognition (single-purpose)
- Character-level text generation
- Simple classification
- Tiny autocomplete

### Advantages

1. **Speed of electricity** - Computation is instantaneous (no fetch)
2. **No memory wall** - Weights are the circuit, not stored values
3. **Minimal power** - Only dynamic power for active computation
4. **Instant inference** - Model is always "ready"

### Challenges

1. Model must be very small (50k-100k params max)
2. Weights are immutable after tapeout
3. Requires ASIC tapeout (expensive, complex)
4. Limited flexibility

---

## Option B: Improved GPU (FPGA-First)

### Concept

A general-purpose parallel accelerator with internal BRAM staging, DMA engine, and ping-pong buffering to eliminate the memory wall.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        GPU Core v2                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  Buffer A    │    │  Buffer B    │    │  Result Buf  │  │
│  │  (BRAM)      │    │  (BRAM)      │    │  (BRAM)      │  │
│  │  256x16b     │    │  256x16b     │    │  256x16b     │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                   │          │
│         └──────────┬─────────┘                   │          │
│                    ▼                             │          │
│            ┌──────────────┐                      │          │
│            │   256-Lane   │                      │          │
│            │     ALU      │                      │          │
│            └──────┬───────┘                      │          │
│                   │                               │          │
│                   └───────────────┬───────────────┘          │
│                                   ▼                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              AXI4-Stream Data In/Out                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ▲                                   │
├─────────────────────────┼───────────────────────────────────┤
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │              AXI4-Lite Control (Status/Regs)         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Target Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Target | FPGA first (ASIC later) | Xilinx/AMD FPGAs |
| Lanes | 16-64 | More manageable than 256 |
| Memory | Internal BRAM staging | Decouples compute from IO |
| Buffering | Ping-pong | Overlaps load/compute/store |
| Interface | USB 3.0 or AXI4-Stream | High bandwidth |
| Cost | $200-2000 | FPGA dev board |

### Memory Map (V2)

| Address | Register | Description |
|---------|----------|--------------|
| 0x40000000 | control | 0=Idle, 1=Load A, 2=Load B, 3=Execute, 4=Read Result |
| 0x40000004 | status | 0=Idle, 1=Busy, 2=Done |
| 0x40000008 | opcode | Operation to execute |
| 0x4000000C | scalar | Scalar operand (for broadcast ops) |
| 0x40000010 | count | Element count (for partial vectors) |
| 0x40000100 | stream_addr | Base address for DMA |
| 0x40000104 | stream_count | Number of elements to transfer |

### Operation Flow

```
1. CPU writes to stream_addr + stream_count
2. CPU writes control=1 (Load A) → DMA fetches to Buffer A
3. CPU writes control=2 (Load B) → DMA fetches to Buffer B
4. CPU writes control=3 (Execute) → Compute all lanes in parallel
5. CPU writes control=4 (Read Result) → DMA streams results back
6. GPU sets status=2 (Done)
```

### Throughput Comparison

| Version | Load | Execute | Read | Total | Utilization |
|---------|------|---------|------|-------|-------------|
| V1 (current) | ~256+ | 1 | ~256+ | ~513 | 0.19% |
| V2 (BRAM) | 256 | 1 | 256 | ~513 | ~50% |
| V2 (ping-pong) | 0 (prefetch) | 1 | 0 | 1 | ~100% |

### Advantages

1. **General-purpose** - Reprogrammable for any workload
2. **FPGA-approachable** - Can prototype today
3. **Scalable** - Can increase lanes, add features
4. **Proven architecture** - Similar to TPU, GPU designs

### Challenges

1. Still needs external memory for large models
2. Interface bandwidth limits peak utilization
3. More complex than V1

---

## Interface Considerations

### Option 1: USB 3.0

| Pros | Cons |
|------|------|
| Universal compatibility | Requires USB peripheral IC |
| Any PC has it | Bandwidth limited to ~5 Gbps |
| No special hardware needed | Latency higher than PCIe |

### Option 2: Full AXI4

| Pros | Cons |
|------|------|
| Standard for SoC FPGAs | Requires Xilinx/AMD SoC |
| Supports bursts | More complex |
| High bandwidth | Not universal |

### Option 3: PCIe

| Pros | Cons |
|------|------|
| Native desktop integration | Needs free slot |
| Highest bandwidth | Complex setup |
| Standard GPU interface | Limited FPGA options |

### Recommendation

For V2, use **AXI4-Stream for data** + **AXI4-Lite for control**. This is the standard approach for accelerators and can be bridged to USB 3.0 or PCIe easily.

---

## Brief Language Features Needed

To express V2 in `.ebv` files, the compiler needs:

1. **Block RAM inference** - Mark vectors as `/ram` to generate BRAM
2. **Dual-buffer annotations** - `/ping` and `/pong` for ping-pong buffers
3. **AXI4-Stream interfaces** - New interface type for bulk data
4. **DMA engine generation** - Auto-generate fetch logic from `/dma` annotations
5. **Scalar broadcast** - Allow scalars in ALU operations without full-vector cost
6. **Hardcoded weights** - Annotations to burn weights into logic

---

## Decision Points

### Immediate Questions

1. **Budget**: What's the target cost for first tapeout (ASIC option)?
2. **Model**: Any specific model in mind, or design generic accelerator?
3. **Timeline**: Quick iteration or get right first time?
4. **Priority**: ASIC-focused, GPU-focused, or both?

### Next Steps

1. Choose which option to pursue (or pursue both)
2. Define specific model/target for chosen option
3. Update `.ebv` files to test Brief compiler capabilities
4. Generate SV and verify in simulation

---

## Related Files

- `gpu_core.ebv` - Current V1 core definition
- `gpu_interface.ebv` - Current V1 AXI4-Lite interface
- `hardware.toml` - Target hardware mapping
- `gpu_core.sv` - Generated SystemVerilog (V1)
- `gpu_interface.sv` - Generated SystemVerilog (V1)

---

*Document generated: April 2026*
*Project: Brief-GPU V2 Planning*
