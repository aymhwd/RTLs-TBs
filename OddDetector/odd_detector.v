`timescale 1ns / 1ps

module odd_detector(
    input wire clk,
    input wire reset,
    input wire [7:0] integers,
    input wire [7:0] N,
    input wire latch_in,
    
    output wire [7:0] out_value,
    output wire ready
    );
    
	//State names
	parameter[1:0] 
	STATE_IDLE = 2'd0,		STATE_INGEST = 2'd1,		STATE_PROCESS = 2'd2;
	//Input registers
    reg[7:0] integers_reg;
    reg[7:0] N_reg;
	//output registers
	reg [7:0] out_value_reg, out_value_next;
	reg ready_reg, ready_next;

	//register array
	reg[7:0] mem_int_reg[0:255];
	reg[7:0] mem_int_next[0:255];
	//Internal registers
	reg [1:0] state_reg, state_next;						//FSM state Register
	reg [7:0] opcnt_reg = 8'h00, opcnt_next;				//Number of operations count
	reg [7:0] input_index_reg, input_index_next;			//Index of input integers in the clock domain of latch_in
	reg [7:0] decoy_iindex_reg, decoy_iindex_next;			//Index of input integers in the clock domain of clk
	reg [7:0] xor_reg, xor_next;							//Temporary XOR register for XOR iterational operations
	integer i = 0;
	integer j = 0;
	integer row = 0;

	
    //Synchronizing the input latch clock
    wire sync_latch_in;
    synchronizer clk_sync(
    .clk(clk),
    .reset(reset),
    .asynclk(latch_in),
    .syn_clk(sync_latch_in));
	
	wire[7:0] sync_integers;
	genvar k;
	generate
		for (k=0; k<8; k=k+1) begin	: integers_synchronizers
		synchronizer integers_sync(
		.clk(clk),
		.reset(reset),
		.asynclk(integers[k]),
		.syn_clk(sync_integers[k]));
		end
	endgenerate
	
	wire[7:0] sync_N;
	genvar l;
	generate
		for (l=0; l<8; l=l+1) begin	: N_synchronizers
		synchronizer integers_sync(
		.clk(clk),
		.reset(reset),
		.asynclk(N[l]),
		.syn_clk(sync_N[l]));
		end
	endgenerate
	
    assign out_value = out_value_reg;
	assign ready = ready_reg;
	
	always @* begin
		//setting default values
		state_next = state_reg;
        input_index_next = input_index_reg;
		decoy_iindex_next = decoy_iindex_reg;
		out_value_next = out_value_reg;
		for (j = 0; j<256; j=j+1) begin
			mem_int_next[j] = mem_int_reg[j];
		end
		ready_next = 1'b0;
		opcnt_next = opcnt_reg;
		case (state_reg)
			STATE_IDLE: begin
				if(N_reg > 8'd0) begin //No Incoming numbers, remain idle
					state_next = STATE_INGEST;
				end else begin
					state_next = STATE_IDLE;
				end	
			end
			
			STATE_INGEST: begin
				if (decoy_iindex_reg < N_reg) begin	//Store the input integer
					mem_int_next[decoy_iindex_reg] = integers_reg;
					input_index_next = input_index_reg + 8'h01;
					decoy_iindex_next = input_index_reg+ 8'h01;
					state_next = STATE_INGEST;
				end else begin	//Last input is stored
				    decoy_iindex_next = 8'h00;
				    state_next = STATE_PROCESS;
					xor_next = mem_int_reg[0];
				end
			end
			
			STATE_PROCESS: begin
				if (opcnt_reg < N_reg) begin
					opcnt_next = opcnt_reg + 8'd1;
					xor_next = xor_reg^mem_int_reg[opcnt_reg+8'd1];
				end else begin
					opcnt_next = 8'd0;
					ready_next = 1'b1;
					out_value_next = xor_reg;
					state_next = STATE_IDLE;
				end
			end
		endcase
		
	end
	
    always @ (posedge sync_latch_in, posedge reset) begin
		if (reset) begin
			input_index_reg <= 8'h00;
			N_reg <= 8'h00;
		end else begin
			if(input_index_reg == N_reg-8'd1) 
				input_index_reg <= 8'h00;
			else
				input_index_reg <= input_index_next;
			integers_reg <= sync_integers;
			N_reg <= sync_N;
		end
		
    end
	
	always @ (posedge clk, posedge reset) begin
		if (reset) begin
			state_reg <= STATE_IDLE;
			for (i = 0; i<256; i=i+1) begin
				mem_int_reg[i] <= 8'h00;
			end
			ready_reg <= 1'b0;
			decoy_iindex_reg <= 8'h00;
			opcnt_reg <= 8'h00;
			out_value_reg <= 8'h00;
			xor_reg <= 8'h00;
		end else begin
			state_reg <= state_next;
			for (i = 0; i<256; i=i+1) begin
				mem_int_reg[i] <= mem_int_next[i];
			end
			ready_reg <= ready_next;
			xor_reg <= xor_next;
			decoy_iindex_reg <= decoy_iindex_next;
			opcnt_reg <= opcnt_next;
			out_value_reg <= out_value_next;
		end
	end    
endmodule
