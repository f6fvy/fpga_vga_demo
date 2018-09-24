// VGA generator (640 x 480 / 60 Hz / 8 color)

// Laurent Haas - F6FVY
// Sept 2018

/*
	Warning : This code uses a 50 MHz mater clock,
	which generates a 25 MHz pixel clock,
	slightly out of spec (25.125 MHz).

	Modern monitors handle this difference, but YMMV.
*/

module vga(
	input						clk,										// 50 MHz / 20 ns
	input						reset,
	input	[2:0]				pixel_rgb,								// Current pixel RGB data to be displayed

	output					hsync, vsync,							// VGA sync signals
	output					red, green, blue,						// VGA RGB data
	output					active,									// Active when pixel inside the 640 x 480 area
	output					ptick,									// Pixel clock (25 MHz - all signals are stable on front edge)
	output [9:0]			xpos, ypos,								// Current pixel position
	output					ftick										// Frame clock (60 Hz - all signals are stable on front edge)
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

	// Instead of creating a separate 25-MHz clock domain and violating
	// the "synchronous design methodology", we generate a 25-MHz enable tick
	// to enable or pause the counting.
	
	// The tick is also routed to the p_tick port as an output signal
	// to coordinate operation of the pixel generation circuit.
	
	// Mod-2 counter

	reg		mod2_r;
	wire		mod2_next;
	wire		ptick_w;
	
	// Sync counters

	reg  [9:0]	hcount, hcount_next;
	reg  [9:0]	vcount, vcount_next;
	
	// Sync output buffers
	
	// To remove potential glitches, output buffers are inserted for the hsync and vsync signals. This leads 
	// to a one-clock-cycle delay. We also add a similar buffer for the rgb signal in the pixel 
	// generation circuit to compensate for the delay.
	
	reg			vsync_r, hsync_r;
	wire			vsync_next, hsync_next;
	
	// RGB signal buffer
	
	reg			red_r, green_r, blue_r;

	// Frame output buffered
	
	reg			ftick_r;
	wire			ftick_next;
	
	// Status signals

	wire			h_end, v_end;

	// Body
	
	// Registers

always @ (posedge clk or posedge reset) begin
	if  (reset) begin
		mod2_r <= 1'b0;
		
		vcount <= 0;
		hcount <= 0;
		
		vsync_r <= 1'b0;
		hsync_r <= 1'b0;
		
		red_r <= 1'b0;
		green_r <= 1'b0;
		blue_r <= 1'b0;
		
		ftick_r <= 1'b0;
	end
	else begin
		mod2_r <= mod2_next;
		
		vcount <= vcount_next;
		hcount <= hcount_next;
		
		vsync_r <= vsync_next;
		hsync_r <= hsync_next;
		
		red_r <= pixel_rgb[0];
		green_r <= pixel_rgb[1];
		blue_r <= pixel_rgb[2];
		
		ftick_r <= ftick_next;
	end
end

	// Mod-2 circuit to generate the 25 MHz tick
	
	assign mod2_next = ~mod2_r;
	assign ptick_w = mod2_r;

	// Status  signals

	// End of horizontal line counter (799)

	assign h_end = (hcount == HBP);

	// End of vertical (524)

	assign v_end = (vcount == VBP);

	// Next-state logic of mod-800 horizontal sync counter

	always @(*) begin
		if  (ptick_w)  // 25 MHz pixel tick
			if (h_end)	// End of line ?
				hcount_next = 0;
			else
				hcount_next = hcount + 10'd1;
		else
			hcount_next = hcount;
	end

	// Next-state logic of mod-525 vertical sync counter

	always @(*) begin
		if (ptick_w & h_end)	// 25 MHz pixel tick and end of line
			if (v_end)	// End of screen ?
				vcount_next = 0;
			else
				vcount_next = vcount + 10'd1;
		else
			vcount_next = vcount;
	end

	// Horizontal and vertical sync, and f_tick, buffered to avoid glitches
	
	// hsync_next reset between 656 and 752
	
	assign	hsync_next = ~((hcount > HFP) && (hcount <= HSYNC));

	// vsync_next reset between 491 and 493
	
	assign	vsync_next = ~((vcount > VFP) && (vcount <= VSYNC));
	
	// f_tick_next set when the current position enters the blanking area
	
	assign	ftick_next = (hcount == HPIXELS) && (vcount == VPIXELS);

	// active when the current position is inside the visible area
	
	assign	active = (hcount <= HA) && (vcount <= VA);

	// Outputs

	assign	hsync = hsync_r;
	assign	vsync = vsync_r;
	assign	xpos = hcount;
	assign	ypos = vcount;
	assign	ptick = ptick_w;
	assign	ftick = ftick_r;

	assign	red = active ? red_r : 1'b0;
	assign	green = active ? green_r : 1'b0;
	assign	blue = active ? blue_r : 1'b0;
endmodule
