module gpu_core (
    input logic clk,
    input logic rst_n,
    output logic [7:0] gpu_status // pin: A1,
    output logic [3:0] opcode // pin: A2
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

    // Logic for variable: gpu_status
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            gpu_status <= 0;
        end else begin
            if ((gpu_status == 1)) begin
                gpu_status <= 2;
            end
        end
    end

    // Logic for variable: opcode
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            opcode <= 0;
        end else begin
        end
    end

    // Logic for variable: vec_A
    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : vec_A_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_A[i] <= 0;
                end else begin
                end
            end
        end
    endgenerate

    // Logic for variable: vec_B
    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : vec_B_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_B[i] <= 0;
                end else begin
                end
            end
        end
    endgenerate

    // Logic for variable: vec_R
    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : vec_R_logic
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    vec_R[i] <= 0;
                end else begin
                    if ((gpu_status == 1)) begin
                        vec_R[i] <= vector_alu(vec_A, vec_B, opcode);
                    end
                end
            end
        end
    endgenerate

endmodule
