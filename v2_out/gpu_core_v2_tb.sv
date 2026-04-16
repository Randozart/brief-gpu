`timescale 1ns/1ps

module gpu_core_v2_tb;

    logic clk;
    logic rst_n;

    logic [7:0] control;
    logic [7:0] status;
    logic [3:0] opcode;
    logic [15:0] ping_buffer;
    logic [15:0] pong_buffer;
    logic [15:0] result_buffer;

    // Instantiate Unit Under Test
    gpu_core_v2 uut (
        .clk(clk),
        .rst_n(rst_n),
        .control(control),
        .status(status),
        .opcode(opcode),
        .ping_buffer(ping_buffer),
        .pong_buffer(pong_buffer),
        .result_buffer(result_buffer)
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
