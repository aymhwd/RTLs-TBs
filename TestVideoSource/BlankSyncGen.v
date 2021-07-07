`timescale 1ns / 1ps

module BlankSyncGen #(
    // Width of counters
   parameter COUNTER_WIDTH = 12,
  // Horizontal timing parameters
 parameter HSYNC_ON = 2007,      //Active + Front
 parameter HSYNC_OFF = 2051,     //Active + Front + SyncWidth
 parameter HBLANK_ON = 1919,     //Active Pixels in the line
 parameter HBLANK_OFF = 2199,    //Total Pixels     
                 
 // Vertical timing parameters
 parameter VSYNC_ON = 1083,       //Active + Front
 parameter VSYNC_OFF = 1088,      //Active + Front + SyncWidth   
 parameter VBLANK_ON = 1079,      //Active Lines in the frame
 parameter VBLANK_OFF = 1124      //Total lines

)
(
    input wire clk, reset, enable,
    output reg [COUNTER_WIDTH-1:0] hcount, vcount,
    output reg hsync, vsync, hblank, vblank
);
wire hsync_on, hsync_off, hblank_on, hblank_off, vsync_on, vsync_off, vblank_on, vblank_off;
    // Determines when to turn on sync and blank signals
    assign hsync_on = (hcount == HSYNC_ON);
    assign hsync_off = (hcount == HSYNC_OFF);
    assign hblank_on = (hcount == HBLANK_ON);
    assign hblank_off = (hcount == HBLANK_OFF);
    assign vsync_on = (vcount == VSYNC_ON);
    assign vsync_off = (vcount == VSYNC_OFF);
    assign vblank_on = (vcount == VBLANK_ON);
    assign vblank_off = (vcount == VBLANK_OFF);
    
  
    
    // Horizontal counter
    always @(posedge clk or negedge reset) begin
        if(reset)
            hcount <= {COUNTER_WIDTH{1'b0}};
        else if (enable == 1'b1 && hcount <= HBLANK_OFF - 1)
            hcount <= hcount + 1;
        else
            hcount <= {COUNTER_WIDTH{1'b0}};
    end
    
    // Horizontal Sync
    always @(posedge clk or negedge reset) begin
        if(reset)
            hsync <= 1'b0;
        else if (enable == 1'b1 && hsync_on)
            hsync <= 1'b1;
        else if (enable == 1'b1 && hsync_off)
            hsync <= 1'b0;
        else
            hsync <= hsync;
    end
    
    // Horizontal Blank
    always @(posedge clk or negedge reset) begin
        if(reset)
            hblank <= 1'b0;
        else if (enable == 1'b1 && hblank_on)
            hblank <= 1'b1;
        else if (enable == 1'b1 && hblank_off)
            hblank <= 1'b0;
        else
            hblank <= hblank;
    end

    // Vertical counter
    always @(posedge clk or negedge reset) begin
        if(reset)
            vcount = {COUNTER_WIDTH{1'b0}};
        else if (enable == 1'b1 && hsync_on) begin
            if(vcount <= VBLANK_OFF - 1)
                vcount <= vcount + 1;
            else
                vcount <= {COUNTER_WIDTH{1'b0}};
        end else
            vcount <= vcount;
    end
    
    // Vertical Sync
    always @(posedge clk or negedge reset) begin
        if(reset)
            vsync = 1'b0;
        else if (enable == 1'b1 && vsync_on)
            vsync <= 1'b1;
        else if (enable == 1'b1 && vsync_off)
            vsync <= 1'b0;
        else
            vsync = vsync;
    end
    
    // Vertical Blank
    always @(posedge clk or negedge reset) begin
        if(reset)
            vblank <= 1'b0;
        else if (enable == 1'b1 && vblank_on)
            vblank <= 1'b1;
        else if (enable == 1'b1 && vblank_off)
            vblank <= 1'b0;
        else
            vblank <= vblank;
    end

endmodule