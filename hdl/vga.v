// VGA generator (640 x 480 / 60 Hz / 8 color)

// Laurent Haas - F6FVY
// Sept 2018

/*
	Warning : This code uses a 25 MHz clock, which is slightly out of spec (25.125 MHz).
	
	Modern monitors handle this difference, but YMMV.
*/

module vga(
	input						clk,						// 25 MHz clock (40 ns) - Pixel clock
	input		[2:0] 		pixel,					// RGB pixel to display
	
	output	reg			hsync, vsync,			// VGA sync outputs
	output					red, green, blue,		// VGA RGB data outputs
	output	reg [9:0]	hpos, vpos,				// Current Pixel position
	output					active,					// Active screen area flag (pixel within 640 x 480)
	output					tick						// Pulse when entering the blanking area
);

// VGA 640 x 480 parameters

// Horizontal parameters expressed in pixels
// Vertical parameters expressed in lines

// Source : https://timetoexplore.net/blog/arty-fpga-vga-verilog-01

	localparam
	HPIXELS = 640,
	HA = HPIXELS - 1,									// Hor. active area (0 to 639 = 640 pixels)
	HFP = HA + 16,										// Hor. front porch end position
	HSYNC = HFP + 96,									// Hor. sync end position
	HBP = HSYNC + 48,									// Hor. back porch end position
	
	VPIXELS = 480,
	VA = VPIXELS - 1,									// Vert. active area (0 to 479 = 480 pixels)
	VFP = VA + 11,										// Vert. front porch end position
	VSYNC = VFP + 2,									// Vert. sync end position
	VBP = VSYNC + 31;									// Vert. back porch end position

	initial begin
		hsync = 1'b1;
		vsync = 1'b1;
		hpos = 10'd0;
		vpos = 10'd0;
	end
	
	assign active = ((hpos <= HA) & (vpos <= VA));
	assign tick = ((hpos == HPIXELS) & (vpos == VPIXELS));
	
	// Sync generation
	
	always @ (posedge clk) begin
		if (hpos >= HBP) begin
			hpos <= 0;
			hsync <= 1;
			if (vpos >= VBP) begin
				vpos <= 0;
				vsync <= 1;
			end
			else begin
				if (vpos >= VSYNC)
					vsync <= 1;
				else if (vpos >= VFP)
					vsync <= 0;
				else if (vpos >= VA)
					vsync <= 1;
				vpos <= vpos + 10'd1;
			end
		end
		else begin
			if (hpos >= HSYNC)
				hsync <= 1;
			else if (hpos >= HFP)
				hsync <= 0;
			else if (hpos >= HA)
				hsync <= 1;
			hpos <= hpos + 10'd1;
		end
	end
	
	// Pixel colors sent only in the active area
	
	assign red = active ? pixel[0] : 1'b0;
	assign green = active ? pixel[1] : 1'b0;
	assign blue = active ? pixel[2] : 1'b0;
	
endmodule