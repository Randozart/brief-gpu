# Compiler Fix Plan: Vector IO Preservation

## Problem
The Brief compiler currently skips `Vector` types when generating top-level module ports in `verilog.rs`. Consequently, computation results stored in vectors (like `result_buffer`) are not connected to any output, causing synthesis tools (Yosys) to optimize away the entire GPU core logic.

## Technical Changes

### 1. verilog.rs: `emit_header`
Modify the port generation loop to support `Type::Vector`.
- Calculate total bit width (`element_bits * vector_size`).
- Create a flattened `output logic [N:0]` port for the vector.

### 2. verilog.rs: `emit_type_signals`
Add synthesis attributes to vectors to prevent optimization.
- Add `/* synthesis keep */` or `(* keep = 1 *)` to internal vector declarations.

### 3. verilog.rs: `emit_logic`
Ensure top-level vector ports are continuously assigned from their internal array representations.

## Verification
1. Run compilation: `./brief-compiler verilog gpu_core_v2.ebv --hw gpu_core_v2.toml`
2. Inspect `v2_out/gpu_core_v2.sv`:
    - Confirm `result_buffer` appears in the `module` port list.
    - Confirm internal `result_buffer` array drives the output port.
