`timescale 1ns/1ps

module gpu_core_tb;

    logic clk;
    logic rst_n;

    logic [7:0] gpu_status;
    logic [3:0] opcode;

    // Instantiate Unit Under Test
    gpu_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .gpu_status(gpu_status),
        .opcode(opcode)
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
