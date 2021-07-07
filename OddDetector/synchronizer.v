`timescale 1ns / 1ps

module synchronizer(
    input wire clk,
    input wire reset,
    input wire asynclk,
    output reg syn_clk
    );
    reg sync1;
always @(posedge clk)
begin
    if (reset) begin
        sync1 <= 1'b0;
        syn_clk <= 1'b0;
    end else
        sync1 <= asynclk;
        syn_clk <= sync1;
    end
endmodule
