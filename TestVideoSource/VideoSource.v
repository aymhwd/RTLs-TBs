`timescale 1 ps / 1 ps

	module VideoSource #
	(
//    SMPTE Standard 	
//	  Name        1920x1080p60                  Vertical Timings
//    Standard      SMPTE 274M                  Active Lines        1080    
//    VIC                   16                  Front Porch            4
//    Short Name         1080p                  Sync Width             5    
//    Aspect Ratio        16:9                  Back Porch            36
//                                              Blanking Total        45 
//    Pixel Clock        148.5 MHz              Total Lines         1125
//    TMDS Clock       1,485.0 MHz              Sync Polarity        pos
//    Pixel Time           6.7 ns ±0.5%         Active Pixels  2,073,600
//    Horizontal Freq.  67.500 kHz              Data Rate           3.56 Gbps
//    Line Time           14.8 ?s               
//    Vertical Freq.    60.000 Hz                Frame Memory (Kbits)
//    Frame Time          16.7 ms                8-bit Memory     16,200
//                                              12-bit Memory     24,300    
//    Horizontal Timings                        24-bit Memory     48,600
//    Active Pixels       1920                  32-bit Memory     64,800
//    Front Porch           88
//    Sync Width            44
//    Back Porch           148
//    Blanking Total       280
//    Total Pixels        2200
//    Sync Polarity        pos


		// Users to add parameters here
        // Width of counters
        parameter COLOR_WIDTH = 12,
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
        output wire active_video,
        output wire [3*COLOR_WIDTH-1:0] vid_data,
        output wire hblank, hsync, vblank, vsync,
        output wire [COUNTER_WIDTH-1:0] hcount, vcount,
		input wire  clk,
		// Global Reset Signal. This Signal is Active LOW
		input wire  resetn,
		input wire start			//Start generation

	);
    wire[COLOR_WIDTH-1:0] red, green, blue;
    assign vid_data = {red,green,blue};
    //wire [COUNTER_WIDTH-1:0] hcount, vcount;
    wire reset;
    assign active_video = ~hblank && ~vblank;
    assign reset = ~resetn;
    BlankSyncGen #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .HSYNC_ON(HSYNC_ON),
        .HSYNC_OFF(HSYNC_OFF),
        .HBLANK_ON(HBLANK_ON),
        .HBLANK_OFF(HBLANK_OFF),
        .VSYNC_ON(VSYNC_ON),
        .VSYNC_OFF(VSYNC_OFF),
        .VBLANK_ON(VBLANK_ON),
        .VBLANK_OFF(VBLANK_OFF)
    ) BlankSyncGen_0(
        .clk(clk),
        .reset(reset),
		.enable(start),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .hblank(hblank),
        .vblank(vblank)
    );
    
    PixelDataGen#(
            .COLOR_WIDTH(COLOR_WIDTH),
            .COUNTER_WIDTH(COUNTER_WIDTH)
            )
    PixelDataGen_0(
        .clk(clk),
        .hcount(hcount),
        .vcount(vcount),
        .red(red),
        .blue(blue),
        .green(green)
        //.active_video(active_video)
    );
    

	endmodule