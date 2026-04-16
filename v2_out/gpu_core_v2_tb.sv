`timescale 1ns/1ps

module gpu_core_v2_tb;

    logic clk;
    logic rst_n;

    logic [7:0] cpu_control;
    logic [3:0] cpu_opcode;
    logic [15:0] cpu_write_data;
    logic [15:0] cpu_write_addr;
    logic cpu_write_en;
    logic cpu_read_en;
    logic [7:0] status;
    logic [15:0] read_data;

    // Instantiate Unit Under Test
    gpu_core_v2 uut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_control(cpu_control),
        .cpu_opcode(cpu_opcode),
        .cpu_write_data(cpu_write_data),
        .cpu_write_addr(cpu_write_addr),
        .cpu_write_en(cpu_write_en),
        .cpu_read_en(cpu_read_en),
        .status(status),
        .read_data(read_data)
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
