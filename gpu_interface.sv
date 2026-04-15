module gpu_interface (
    input logic clk,
    input logic rst_n,
    output logic [7:0] gpu_status /* pin: A1 */,
    output logic [3:0] opcode /* pin: A2 */,
    output logic [15:0] read_data /* pin: A3 */,
    output logic [15:0] write_data /* pin: A4 */,
    output logic [15:0] addr /* pin: A5 */,
    output logic  control /* pin: A6 */,
    input logic  axi_awvalid /* pin: A7 */,
    input logic [15:0] axi_awaddr /* pin: A8 */,
    input logic  axi_wvalid /* pin: A9 */,
    input logic [15:0] axi_wdata /* pin: A10 */,
    input logic  axi_bready /* pin: A11 */,
    input logic  axi_arvalid /* pin: A12 */,
    input logic [15:0] axi_araddr /* pin: A13 */,
    input logic  axi_rready /* pin: A14 */,
    output logic  axi_rvalid /* pin: A15 */,
    output logic [15:0] axi_rdata /* pin: A16 */
);

    logic signed [15:0] vec_A [0:255];
    logic signed [15:0] vec_B [0:255];
    logic signed [15:0] vec_R [0:255];

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
        if ((op == 4)) begin
        return (a & b);
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

    // Logic for variable: vec_A
    genvar vec_A_i;
    generate
        for (vec_A_i = 0; vec_A_i < 256; vec_A_i = vec_A_i + 1) begin : vec_A_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_A[vec_A_i] <= 0;
                end else begin
                end
            end
        end
    endgenerate

    // Logic for variable: vec_B
    genvar vec_B_i;
    generate
        for (vec_B_i = 0; vec_B_i < 256; vec_B_i = vec_B_i + 1) begin : vec_B_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_B[vec_B_i] <= 0;
                end else begin
                end
            end
        end
    endgenerate

    // Logic for variable: vec_R
    genvar vec_R_i;
    generate
        for (vec_R_i = 0; vec_R_i < 256; vec_R_i = vec_R_i + 1) begin : vec_R_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_R[vec_R_i] <= 0;
                end else begin
                    if ((gpu_status == 1)) begin
                        vec_R[vec_R_i] <= vector_alu(vec_A[vec_R_i], vec_B[vec_R_i], opcode);
                    end
                end
            end
        end
    endgenerate

endmodule
