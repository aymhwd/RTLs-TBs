`timescale 1ns / 1ps


module PixelDataGen#(
    // Width of counters
    parameter COLOR_WIDTH = 12,
    parameter COUNTER_WIDTH = 12
    )(
    input wire clk,
    input wire [COUNTER_WIDTH-1:0] hcount, vcount,
    output wire [COLOR_WIDTH-1:0] red, blue, green

);
    reg[35:0] frame_count = 'd0;
    wire[35:0] first_pixel;
    always @ (posedge clk) begin
        if (hcount == 0 && vcount == 1124) frame_count <= frame_count+1;
        else frame_count <= frame_count;
    end 
    assign first_pixel = (frame_count == 'd0)? 36'hADEADBEEF : frame_count;
    assign red = (hcount == 0 && vcount == 1124)? first_pixel[35:24] : (hcount <= 639) ? 12'hFFF : 12'h000;
    assign green = (hcount == 0 && vcount == 1124)? first_pixel[23:12] : (hcount > 639 && hcount <= 1279) ? 12'hFFF : 12'h000;
    assign blue = (hcount == 0 && vcount == 1124)? first_pixel[11:0] : (hcount > 1279 && hcount <= 1919) ? 12'hFFF : 12'h000;

endmodule