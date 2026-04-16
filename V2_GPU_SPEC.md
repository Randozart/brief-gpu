# Brief-Verilog V2 GPU Design Specification

## Overview

This document defines the V2 GPU architecture for Brief-Verilog, implementing the hardware_lib specification system and a reduced-lane design optimized for practical use.

## 1. Hardware Specification System

### 1.1 Architecture

Three-layer separation:

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Brief (.ebv)                                      │
│  - Behavior, logic, data flow                               │
│  - NO assumptions about implementation                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Hardware Spec Library (hardware_lib/)             │
│  - Interface definitions                                   │
│  - Memory types                                            │
│  - Target specifications                                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Compiler                                          │
│  - Reads .ebv + hardware.toml                               │
│  - Validates against spec                                   │
│  - Generates appropriate .sv                               │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Directory Structure

```
brief-compiler/
├── src/
│   └── (compiler changes)
└── hardware_lib/
    ├── interfaces/
    │   ├── axi4-lite.toml
    │   ├── axi4-stream.toml
    │   ├── axi4-full.toml
    │   └── parallel.toml
    ├── memory/
    │   ├── bram.toml
    │   ├── distributed.toml
    │   ├── rom.toml
    │   └── flipflop.toml
    └── targets/
        ├── generic.toml
        ├── xc7a35t.toml
        └── sky130.toml
```

### 1.3 Required hardware.toml Fields

```toml
[project]
name = "gpu_core_v2"          # Required: project name
version = "1.0.0"              # Required: semver

[target]                       # Required: target specification
fpga = "xc7a35tcpg236-1"       # Required: target device
clock_hz = 100_000_000        # Required: clock frequency

[interface]                   # Required: interface type from hardware_lib
name = "axi4-lite"

[memory]                      # Required: memory map
"0x40001000" = { size = 256, type = "bram", element_bits = 16 }

[io]                          # Optional: pin mappings
"0x40000000" = { pin = "A1" }
```

### 1.4 hardware_lib Spec Format

#### Interface Spec (hardware_lib/interfaces/axi4-lite.toml)

```toml
[interface]
name = "axi4-lite"
version = "1.0.0"
description = "AXI4-Lite protocol for register access"

[signals]
awvalid = { bits = 1, direction = "input" }
awaddr = { bits = "address_width", direction = "input" }
wvalid = { bits = 1, direction = "input" }
wdata = { bits = "data_width", direction = "input" }
bready = { bits = 1, direction = "input" }
arvalid = { bits = 1, direction = "input" }
araddr = { bits = "address_width", direction = "input" }
rready = { bits = 1, direction = "input" }
rvalid = { bits = 1, direction = "output" }
rdata = { bits = "data_width", direction = "output" }

[parameters]
address_width = { default = 16, min = 8, max = 32 }
data_width = { default = 32, min = 8, max = 512 }

[constraints]
max_address = "2^address_width - 1"
alignment = "data_width / 8"
```

#### Memory Spec (hardware_lib/memory/bram.toml)

```toml
[memory]
name = "bram"
version = "1.0.0"
description = "Block RAM for large vector storage"

[synthesis]
attribute = "syn_ramstyle = \"block_ram\""

[parameters]
size = { required = true, description = "number of elements" }
element_bits = { required = true, description = "bits per element" }
```

#### Memory Spec (hardware_lib/memory/flipflop.toml)

```toml
[memory]
name = "flipflop"
version = "1.0.0"
description = "Register (flip-flop) for small storage"

[synthesis]
attribute = "logic"

[parameters]
size = { required = true, description = "number of elements" }
element_bits = { required = true, description = "bits per element" }
```

#### Target Spec (hardware_lib/targets/generic.toml)

```toml
[target]
name = "generic"
version = "1.0.0"
description = "Generic target with no device-specific constraints"

[constraints]
max_bram_kb = 1000
max_lut = 100000
max_dsp = 500
```

### 1.5 Validation Rules

| Rule | Condition | Error Message |
|------|-----------|---------------|
| Required fields | Missing required field in hardware.toml | "Missing required field '[section].[key]'" |
| Address validity | Address not aligned to element size | "Address 0x{addr} not aligned to {bits}-bit boundary" |
| Memory type valid | Type not in hardware_lib | "Unknown memory type '{type}'. Available: bram, distributed, rom, flipflop" |
| Interface valid | Interface not in hardware_lib | "Unknown interface '{name}'. Available: axi4-lite, axi4-stream..." |
| Address overlap | Two memory regions overlap | "Memory region at 0x{addr1} overlaps with 0x{addr2}" |
| Vector size match | Vector element count > memory size | "Vector of {count} elements exceeds memory size {size}" |
| Bit width compatible | Vector bits > interface data width | "Vector requires {bits} bits, interface provides {width}" |

### 1.6 Compiler Requirements

1. **No hardcoded interface types** - Compiler knows nothing about specific interfaces; it reads from hardware_lib
2. **hardware.toml REQUIRED** - Compilation fails without it (even a simple one)
3. **Block on validation failure** - No .sv generated if validation fails
4. **Multi-target support** - Same .ebv can target different hardware via different .toml files

---

## 2. V2 GPU Design

### 2.1 Core Specifications

| Parameter | V1 | V2 |
|-----------|----|----|
| Lanes | 256 | 32 |
| Element bits | 16 | 16 |
| Memory | FF (flip-flops) | BRAM |
| Interface | AXI4-Lite | Via hardware_lib |
| Throughput | 0.19% utilization | Target: 50%+ |

### 2.2 Architecture

```
┌─────────────────────────────────────────────────────┐
│                  GPU Core V2                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────┐      ┌─────────────┐              │
│  │ Ping Buffer │      │ Pong Buffer │   BRAM       │
│  │ (32 x 16b)  │      │ (32 x 16b)  │              │
│  └──────┬──────┘      └──────┬──────┘              │
│         │                    │                      │
│         └─────────┬──────────┘                      │
│                   ▼                                  │
│            ┌──────────┐                             │
│            │ ALU Array│   32 lanes                   │
│            └────┬─────┘                             │
│                 ▼                                   │
│          ┌───────────┐                              │
│          │  Result   │    BRAM                       │
│          │  Buffer   │   (32 x 16b)                  │
│          └───────────┘                              │
│                   │                                  │
│                   ▼                                  │
│         ┌─────────────────┐                        │
│         │  Stream Output  │  (via hardware_lib)    │
│         └─────────────────┘                        │
│                                                     │
│  Control: Start/Done/Status registers (FF)        │
└─────────────────────────────────────────────────────┘
```

### 2.3 Memory Map (V2)

| Address | Register | Type | Size |
|---------|----------|------|------|
| 0x40000000 | control | flipflop | 8-bit |
| 0x40000004 | status | flipflop | 8-bit |
| 0x40000008 | opcode | flipflop | 4-bit |
| 0x40000010 | ping_buffer | bram | 32×16-bit |
| 0x40000020 | pong_buffer | bram | 32×16-bit |
| 0x40000030 | result_buffer | bram | 32×16-bit |

### 2.4 Brief (.ebv) Specification

```brief
// gpu_core_v2.ebv - 32-lane GPU with BRAM

// === Control Registers ===
let control: UInt @ 0x40000000 /0..7 = 0;  // 0=Idle, 1=Load Ping, 2=Load Pong, 3=Execute, 4=Read
let status: UInt @ 0x40000004 /0..7 = 0;   // 0=Idle, 1=Busy, 2=Done
let opcode: UInt @ 0x40000008 /0..3 = 0;

// === 32-element vectors ===
let ping_buffer: Int[32] @ 0x40000010 / x16;
let pong_buffer: Int[32] @ 0x40000020 / x16;
let result_buffer: Int[32] @ 0x40000030 / x16;

// === ALU Definition ===
defn vector_alu(a: Int, b: Int, op: UInt) -> Int [true][true] {
    [op == 0] term a + b;       // Addition
    [op == 1] term a - b;       // Subtraction
    [op == 2] term a * b;       // Multiplication
    [op == 3] term a ^ b;       // XOR
    [op == 4] term a & b;       // AND
    [op == 5] term a << b;      // Shift left
    [op == 6] term a >> b;      // Shift right
    [op == 7] {                 // ReLU
        [a < 0] term 0;
        term a;
    };
    [op == 8] {                 // Max-like selection
        [b == 0] term a;
        term b;
    };
    term 0; 
};

// === Execute Transaction ===
rct txn execute [control == 3][status == 2] {
    &result_buffer = vector_alu(ping_buffer, pong_buffer, opcode);
    &status = 2;
    term;
};
```

### 2.5 hardware.toml for V2

```toml
[project]
name = "gpu_core_v2"
version = "1.0.0"

[target]
fpga = "generic"
clock_hz = 100_000_000

[interface]
name = "axi4-lite"
address_width = 16
data_width = 32

[memory]
# Control registers (flip-flops)
"0x40000000" = { size = 1, type = "flipflop", element_bits = 8 }
"0x40000004" = { size = 1, type = "flipflop", element_bits = 8 }
"0x40000008" = { size = 1, type = "flipflop", element_bits = 4 }

# Vector buffers (BRAM)
"0x40000010" = { size = 32, type = "bram", element_bits = 16 }
"0x40000020" = { size = 32, type = "bram", element_bits = 16 }
"0x40000030" = { size = 32, type = "bram", element_bits = 16 }

[io]
"0x40000000" = { pin = "A1" }
"0x40000004" = { pin = "A2" }
"0x40000008" = { pin = "A3" }
"0x40000010" = { pin = "A4" }
"0x40000020" = { pin = "A5" }
"0x40000030" = { pin = "A6" }
```

---

## 3. Implementation Phases

| Phase | Task | Description |
|-------|------|-------------|
| 1 | Create hardware_lib | Add interface/memory/target specs to brief-compiler |
| 2 | Update compiler | Add hardware.toml parsing + validation logic |
| 3 | Create V2 .ebv | 32-lane design |
| 4 | Create V2 hardware.toml | Complete spec for validation |
| 5 | Compile + verify | Run through compiler, verify .sv output |
| 6 | Simulate | Run testbench, verify correctness |

---

## 4. Compiler Changes Required

| Component | Change |
|-----------|--------|
| `parser.rs` | Add hardware.toml parsing |
| `ast.rs` | Add hardware config types (interface, memory, target specs) |
| `verilog.rs` | Read memory type from config, generate BRAM (`syn_ramstyle`) vs FF |
| `main.rs` | Require `--hw` flag, validate .ebv against .toml before generation |

---

## 5. Files to Create/Modify

### New Files

```
brief-compiler/hardware_lib/
├── interfaces/
│   └── axi4-lite.toml
├── memory/
│   ├── bram.toml
│   └── flipflop.toml
└── targets/
    └── generic.toml
```

### Modified Files

```
brief-compiler/src/
├── ast.rs           (add HardwareConfig types)
├── parser.rs        (add hardware.toml parsing)
├── verilog.rs       (add BRAM generation from config)
└── main.rs          (require --hw flag)

brief-gpu/
├── gpu_core_v2.ebv  (new)
├── gpu_core_v2.toml (new)
└── V2_PLANNING.md   (update)
```

---

## 6. Notes

- hardware_lib is exclusive to .ebv files (not .bv or .rbv)
- .ebv MUST have accompanying hardware.toml to compile
- Validation failures block generation (no faulty code)
- Same .ebv can target different hardware via different .toml files

---

*Document version: 1.0*
*Last updated: April 2026*
