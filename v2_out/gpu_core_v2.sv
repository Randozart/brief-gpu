module gpu_core_v2 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] cpu_control /* pin: A1 */,
    input logic [3:0] cpu_opcode /* pin: A3 */,
    input logic [15:0] cpu_write_data /* pin: A4 */,
    input logic [15:0] cpu_write_addr /* pin: A5 */,
    input logic  cpu_write_en /* pin: A6 */,
    input logic  cpu_read_en /* pin: A7 */,
    output logic [7:0] status /* pin: A2 */,
    output logic [15:0] read_data /* pin: A8 */
);

    logic [31:0] control;
    logic [31:0] opcode;
    logic signed [15:0] ping_buffer [0:31] /* synthesis syn_ramstyle = "block_ram" */ /* synthesis keep */;
    logic signed [15:0] pong_buffer [0:31] /* synthesis syn_ramstyle = "block_ram" */ /* synthesis keep */;
    logic signed [15:0] result_buffer [0:31] /* synthesis syn_ramstyle = "block_ram" */ /* synthesis keep */;

    function automatic logic signed [31:0] vector_alu(
        input logic signed [31:0] a ,
        input logic signed [31:0] b ,
        input logic [31:0] op 
    );
        if ((op == 0)) begin
        return (a + b);
        end
        if ((op == 1)) begin
        return (a - b);
        end
        if ((op == 2)) begin
        return (a * b);
        end
        if ((op == 3)) begin
        return (a ^ b);
        end
        if ((op == 4)) begin
        return (a & b);
        end
        if ((op == 5)) begin
        return (a << b);
        end
        if ((op == 6)) begin
        return (a >> b);
        end
        if ((op == 7)) begin
        if ((a < 0)) begin
        return 0;
        end
        return a;
        end
        if ((op == 8)) begin
        if ((b == 0)) begin
        return a;
        end
        return b;
        end
        return 0;
    endfunction

    // Logic for variable: control
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            control <= 0;
        end else begin
            if ((cpu_control != control)) begin
                control <= cpu_control;
            end
        end
    end

    // Logic for variable: status
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            status <= 0;
        end else begin
            if ((control == 3)) begin
                status <= 2;
            end
        end
    end

    // Logic for variable: opcode
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            opcode <= 0;
        end else begin
            if ((cpu_control != control)) begin
                opcode <= cpu_opcode;
            end
        end
    end

    // Logic for variable: ping_buffer
    genvar ping_buffer_i;
    generate
        for (ping_buffer_i = 0; ping_buffer_i < 32; ping_buffer_i = ping_buffer_i + 1) begin : ping_buffer_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    ping_buffer[ping_buffer_i] <= 0;
                end else begin
                    if ((cpu_write_en && (control == 1))) begin
                        if (ping_buffer_i == cpu_write_addr) begin
                            ping_buffer[ping_buffer_i] <= cpu_write_data;
                        end
                    end
                end
            end
        end
    endgenerate

    // Logic for variable: pong_buffer
    genvar pong_buffer_i;
    generate
        for (pong_buffer_i = 0; pong_buffer_i < 32; pong_buffer_i = pong_buffer_i + 1) begin : pong_buffer_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    pong_buffer[pong_buffer_i] <= 0;
                end else begin
                    if ((cpu_write_en && (control == 2))) begin
                        if (pong_buffer_i == cpu_write_addr) begin
                            pong_buffer[pong_buffer_i] <= cpu_write_data;
                        end
                    end
                end
            end
        end
    endgenerate

    // Logic for variable: result_buffer
    genvar result_buffer_i;
    generate
        for (result_buffer_i = 0; result_buffer_i < 32; result_buffer_i = result_buffer_i + 1) begin : result_buffer_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    result_buffer[result_buffer_i] <= 0;
                end else begin
                    if ((control == 3)) begin
                        result_buffer[result_buffer_i] <= vector_alu(ping_buffer[result_buffer_i], pong_buffer[result_buffer_i], opcode);
                    end
                end
            end
        end
    endgenerate

    // Logic for variable: read_data
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            read_data <= 0;
        end else begin
            if ((cpu_read_en && (control == 4))) begin
                read_data <= result_buffer[cpu_write_addr];
            end
        end
    end

endmodule
