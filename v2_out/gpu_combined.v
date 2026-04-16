module gpu_core_v2 (
	clk,
	rst_n,
	cpu_control,
	cpu_opcode,
	cpu_write_data,
	cpu_write_addr,
	cpu_write_en,
	cpu_read_en,
	status,
	read_data
);
	input wire clk;
	input wire rst_n;
	input wire [7:0] cpu_control;
	input wire [3:0] cpu_opcode;
	input wire [15:0] cpu_write_data;
	input wire [15:0] cpu_write_addr;
	input wire cpu_write_en;
	input wire cpu_read_en;
	output reg [7:0] status;
	output reg [15:0] read_data;
	reg [31:0] control;
	reg [31:0] opcode;
	reg signed [15:0] ping_buffer [0:31];
	reg signed [15:0] pong_buffer [0:31];
	reg signed [15:0] result_buffer [0:31];
	function automatic signed [31:0] vector_alu;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		input reg [31:0] op;
		reg [0:1] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			if (op == 0) begin
				vector_alu = a + b;
				_sv2v_jump = 2'b11;
			end
			if (_sv2v_jump == 2'b00) begin
				if (op == 1) begin
					vector_alu = a - b;
					_sv2v_jump = 2'b11;
				end
				if (_sv2v_jump == 2'b00) begin
					if (op == 2) begin
						vector_alu = a * b;
						_sv2v_jump = 2'b11;
					end
					if (_sv2v_jump == 2'b00) begin
						if (op == 3) begin
							vector_alu = a ^ b;
							_sv2v_jump = 2'b11;
						end
						if (_sv2v_jump == 2'b00) begin
							if (op == 4) begin
								vector_alu = a & b;
								_sv2v_jump = 2'b11;
							end
							if (_sv2v_jump == 2'b00) begin
								if (op == 5) begin
									vector_alu = a << b;
									_sv2v_jump = 2'b11;
								end
								if (_sv2v_jump == 2'b00) begin
									if (op == 6) begin
										vector_alu = a >> b;
										_sv2v_jump = 2'b11;
									end
									if (_sv2v_jump == 2'b00) begin
										if (op == 7) begin
											if (a < 0) begin
												vector_alu = 0;
												_sv2v_jump = 2'b11;
											end
											if (_sv2v_jump == 2'b00) begin
												vector_alu = a;
												_sv2v_jump = 2'b11;
											end
										end
										if (_sv2v_jump == 2'b00) begin
											if (op == 8) begin
												if (b == 0) begin
													vector_alu = a;
													_sv2v_jump = 2'b11;
												end
												if (_sv2v_jump == 2'b00) begin
													vector_alu = b;
													_sv2v_jump = 2'b11;
												end
											end
											if (_sv2v_jump == 2'b00) begin
												vector_alu = 0;
												_sv2v_jump = 2'b11;
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	endfunction
	always @(posedge clk)
		if (!rst_n)
			control <= 0;
		else if (cpu_control != control)
			control <= cpu_control;
	always @(posedge clk)
		if (!rst_n)
			status <= 0;
		else if (control == 3)
			status <= 2;
	always @(posedge clk)
		if (!rst_n)
			opcode <= 0;
		else if (cpu_control != control)
			opcode <= cpu_opcode;
	genvar _gv_ping_buffer_i_1;
	generate
		for (_gv_ping_buffer_i_1 = 0; _gv_ping_buffer_i_1 < 32; _gv_ping_buffer_i_1 = _gv_ping_buffer_i_1 + 1) begin : ping_buffer_logic
			localparam ping_buffer_i = _gv_ping_buffer_i_1;
			always @(posedge clk)
				if (!rst_n)
					ping_buffer[ping_buffer_i] <= 0;
				else if (cpu_write_en && (control == 1)) begin
					if (ping_buffer_i == cpu_write_addr)
						ping_buffer[ping_buffer_i] <= cpu_write_data;
				end
		end
	endgenerate
	genvar _gv_pong_buffer_i_1;
	generate
		for (_gv_pong_buffer_i_1 = 0; _gv_pong_buffer_i_1 < 32; _gv_pong_buffer_i_1 = _gv_pong_buffer_i_1 + 1) begin : pong_buffer_logic
			localparam pong_buffer_i = _gv_pong_buffer_i_1;
			always @(posedge clk)
				if (!rst_n)
					pong_buffer[pong_buffer_i] <= 0;
				else if (cpu_write_en && (control == 2)) begin
					if (pong_buffer_i == cpu_write_addr)
						pong_buffer[pong_buffer_i] <= cpu_write_data;
				end
		end
	endgenerate
	genvar _gv_result_buffer_i_1;
	generate
		for (_gv_result_buffer_i_1 = 0; _gv_result_buffer_i_1 < 32; _gv_result_buffer_i_1 = _gv_result_buffer_i_1 + 1) begin : result_buffer_logic
			localparam result_buffer_i = _gv_result_buffer_i_1;
			always @(posedge clk)
				if (!rst_n)
					result_buffer[result_buffer_i] <= 0;
				else if (control == 3)
					result_buffer[result_buffer_i] <= vector_alu(ping_buffer[result_buffer_i], pong_buffer[result_buffer_i], opcode);
		end
	endgenerate
	always @(posedge clk)
		if (!rst_n)
			read_data <= 0;
		else if (cpu_read_en && (control == 4))
			read_data <= result_buffer[cpu_write_addr];
endmodule
