# Hardware Configuration Guide (.toml)

This guide explains how to configure the `hardware.toml` file for Brief-to-Verilog compilation.

## Structure

The configuration is divided into four main sections: `[project]`, `[target]`, `[memory]`, and `[io]`.

### 1. [project]
Defines metadata about the project.
```toml
[project]
name = "my_gpu"
version = "1.0.0"
```

### 2. [target]
Defines hardware-specific parameters.
```toml
[target]
fpga = "generic"        # Target architecture (generic, xilinx, ice40)
clock_hz = 100_000_000  # Base clock frequency
```

### 3. [memory]
Maps addresses to specific memory implementations.
- **flipflop**: Individual registers (best for small control signals).
- **bram**: Block RAM inference (best for large vectors).

```toml
[memory]
"0x40000000" = { size = 1, type = "flipflop", element_bits = 8 }
"0x40000010" = { size = 32, type = "bram", element_bits = 16 }
```

### 4. [io]
Maps addresses to top-level module pins and defines signal direction.
**CRITICAL**: Every signal that needs to be preserved during synthesis must be connected to an IO pin or marked as an output.

```toml
[io]
"0x40000000" = { pin = "A1", direction = "input" }
"0x40000004" = { pin = "A2", direction = "output" }
"0x40000030" = { pin = "A6", direction = "output" } # Result vectors should be marked as output
```

## Best Practices
1. **Always define direction**: While the compiler defaults some signals, explicitly setting `direction = "output"` for result buffers prevents Yosys from optimizing away the logic.
2. **Address Matching**: Ensure addresses in `.toml` match the `@ 0x...` annotations in your `.ebv` file exactly.
3. **BRAM Sizing**: Ensure `size` in `.toml` is greater than or equal to the array size in `.ebv`.
