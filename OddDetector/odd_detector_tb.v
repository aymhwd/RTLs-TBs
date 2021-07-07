`timescale 1ns / 1ps
module odd_detector_tb();

    localparam TVECTOR_ARRAY_SIZE = 11; //N
    localparam exp_out_integer = 16;    //Expected output
	localparam PERIOD_CLK = 10, PERIOD_LATCHCLK =20;
	
	reg clk;
	reg reset;
	reg [7:0] integers = 8'd0;
	reg [7:0] N;
	reg latch_in = 1'b0;
	wire [7:0] out_value;
	wire ready;
    reg [7:0] integers_array[0:TVECTOR_ARRAY_SIZE-1];
    
    integer j=0;
	integer file,stat,indx=0;
	
	odd_detector uut(
		.clk(clk),
		.reset(reset),
		.integers(integers),
		.N(N),
		.latch_in(latch_in),
		.out_value(out_value),
		.ready(ready)
		);
		
	always #(PERIOD_CLK/2) clk = ~clk;	
	
	initial begin
		$display ("Time , N\t , integers , ready\t, out_value");
		$monitor ("%g\t ,%d\t , %d\t\t, %b\t\t, %d\t", $time, N, integers, ready, out_value);
        clk = 1'b0;
        reset = 1'b1;
        read_integers;
		initialize_inputs;	
		#(3*PERIOD_CLK)
		reset = 1'b0;
		initiate_async_clk;
		
 
	end
	
	always @ (posedge latch_in) begin
        if (j < TVECTOR_ARRAY_SIZE) begin
            N = TVECTOR_ARRAY_SIZE;
            integers = integers_array[j];
            j = j + 1;
        end else begin
            j = 0;
            N = 8'd0;
            integers = 8'd0;
        end
	end
	
	always @ (posedge clk) begin : monitoring_output
			if (ready == 1'b1) begin
				if (out_value == exp_out_integer) begin
					$display ("Test Succeeded");
					$finish;
				end else $display ("Test Failed");
			end
		end
	
	
	task initialize_inputs;
        begin
            latch_in = 1'b0;
            integers = 8'd0;
            N = 8'd0;
        end
	endtask
	
	task read_integers;
	   begin
	       file = $fopen("D:/PyramidTech/6-takehome/odd_detector/odd_detector.srcs/sim_1/new/integers.txt","r");
	       while (! $feof(file)) begin
	           stat = $fscanf(file,"%d,",integers_array[indx]);
	           indx = indx+1;
	       end
	       $fclose(file);
	       
	   end
	endtask
	
	task initiate_async_clk;
        #33 //arbitrary starting point of the async clk
		repeat(TVECTOR_ARRAY_SIZE) begin
			#(PERIOD_LATCHCLK/2) latch_in = 1'b1;
			#(PERIOD_LATCHCLK/2) latch_in = 1'b0;
		end
	endtask
endmodule