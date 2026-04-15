module gpu_interface (
    input logic clk,
    input logic rst_n,
    output logic [7:0] gpu_status // pin: A1,
    output logic [3:0] opcode // pin: A2,
    output logic [15:0] read_data // pin: A3,
    output logic [15:0] addr // pin: A5,
    output logic  control // pin: A6,
    output logic  axi_awvalid // pin: A7,
    output logic  axi_wvalid // pin: A9,
    output logic [15:0] axi_wdata // pin: A10,
    output logic  axi_bready // pin: A11,
    output logic [15:0] axi_araddr // pin: A13,
    output logic  axi_rready // pin: A14,
    output logic  axi_rvalid // pin: A15
);

    logic signed [15:0] vec_A [0:255];
    logic signed [15:0] vec_B [0:255];
    logic signed [15:0] vec_R [0:255];
    logic [15:0] write_data;
    logic [15:0] axi_awaddr;
    logic  axi_arvalid;
    logic [15:0] axi_rdata;

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

    // Logic for variable: read_data
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            read_data <= 0;
        end else begin
        end
    end

    // Logic for variable: write_data
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            write_data <= 0;
        end else begin
            if ((axi_awvalid && axi_wvalid)) begin
                write_data <= axi_wdata;
            end
        end
    end

    // Logic for variable: addr
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            addr <= 0;
        end else begin
            if ((axi_awvalid && axi_wvalid)) begin
                addr <= axi_awaddr;
            end
            else if (axi_arvalid) begin
                addr <= axi_araddr;
            end
        end
    end

    // Logic for variable: control
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            control <= 0;
        end else begin
            if ((axi_awvalid && axi_wvalid)) begin
                control <= 2;
            end
            else if (axi_arvalid) begin
                control <= 1;
            end
        end
    end

    // Logic for variable: axi_awvalid
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_awvalid <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_awaddr
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_awaddr <= 0;
        end else begin
        end
    end

    // Logic for variable: axi_wvalid
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_wvalid <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_wdata
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_wdata <= 0;
        end else begin
        end
    end

    // Logic for variable: axi_bready
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_bready <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_arvalid
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_arvalid <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_araddr
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_araddr <= 0;
        end else begin
        end
    end

    // Logic for variable: axi_rready
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_rready <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_rvalid
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_rvalid <= 1'b0;
        end else begin
        end
    end

    // Logic for variable: axi_rdata
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axi_rdata <= 0;
        end else begin
            if (axi_arvalid) begin
                axi_rdata <= read_data;
            end
        end
    end

endmodule
