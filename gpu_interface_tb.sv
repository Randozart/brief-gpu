`timescale 1ns/1ps

module gpu_interface_tb;

    logic clk;
    logic rst_n;

    logic [7:0] gpu_status;
    logic [3:0] opcode;
    logic [15:0] read_data;
    logic [15:0] addr;
    logic control;
    logic axi_awvalid;
    logic axi_wvalid;
    logic [15:0] axi_wdata;
    logic axi_bready;
    logic [15:0] axi_araddr;
    logic axi_rready;
    logic axi_rvalid;

    // Instantiate Unit Under Test
    gpu_interface uut (
        .clk(clk),
        .rst_n(rst_n),
        .gpu_status(gpu_status),
        .opcode(opcode),
        .read_data(read_data),
        .addr(addr),
        .control(control),
        .axi_awvalid(axi_awvalid),
        .axi_wvalid(axi_wvalid),
        .axi_wdata(axi_wdata),
        .axi_bready(axi_bready),
        .axi_araddr(axi_araddr),
        .axi_rready(axi_rready),
        .axi_rvalid(axi_rvalid)
    );

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Stimulus
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uut);

        rst_n = 0;
        #20 rst_n = 1;

        // Let it run for 1000ns
        #1000;
        $display("Simulation finished.");
        $finish;
    end

endmodule
