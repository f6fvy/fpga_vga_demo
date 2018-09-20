// VGA demo

// Laurent Haas - F6FVY
// Sept 2018

module vga_demo(
	input			clk,						// 50 MHz / 20 ns

	output		red, green, blue,		// VGA color outputs
	output		hsync, vsync			// VGA sync outputs
);

	reg			clk_25;					// Clock 25 MHz

	wire	[9:0]	hpos, vpos;				// Current pixel position
	wire 			active;					// Active screen area flag
	wire			tick;						// Pulse coming from the VGA generator when entering into the blanking area (60 Hz)
	
	reg	[2:0]	pixel;					// Current pixel RGB color
	reg	[6:0]	count;					// Counter for pattern
	reg	[3:0]	pattern;					// Current pattern (0 - 15)

	initial begin
		clk_25 = 1'b0;
		pixel = 3'b0;	// Black
		count = 7'b0;
		pattern = 4'b0;
	end

	vga vga_gen(
		.clk(clk_25),
		.pixel(pixel),
		
		.hsync(hsync),
		.vsync(vsync),
		.red(red),
		.green(green),
		.blue(blue), 
		.hpos(hpos),
		.vpos(vpos),
		.active(active),
		.tick(tick)
	);
	
	// 25 MHz clock generator

	always @ (posedge clk) begin
		clk_25 <= ~clk_25;
	end

	// Hello World!
		
	localparam					
	HW_WIDTH = 80,											// Bitmap dimensions
	HW_HEIGHT = 7;
	
	reg[0:HW_WIDTH - 1]	hello_world_line;			// Content of the current HW line

	wire [7:0] hpos_block_4;							// hpos expressed in block of 4 x 4 pixels
	wire [7:0] vpos_block_4;							// vpos expressed in block of 4 x 4 pixels
	
	assign hpos_block_4 = hpos[9:2];
	assign vpos_block_4 = vpos[9:2];
	
	reg[6:0]	hpos_hw;										// Current hpos in the HW "bitmap"
	reg[2:0] vpos_hw;										// Current vpos in the HW "bitmap"

	always @(*) begin
		case(vpos_hw)
			0: 			hello_world_line = 80'b10000010000000000000000000000000000000010000010000000000000000000000000000000010;
			1: 			hello_world_line = 80'b10000010111111010000001000000011110000010010010011110011111001000000111110000010;
			2: 			hello_world_line = 80'b10000010100000010000001000000100001000010010010100001010000101000000100001000010;
			3: 			hello_world_line = 80'b11111110111110010000001000000100001000010010010100001010000101000000100001000010;
			4: 			hello_world_line = 80'b10000010100000010000001000000100001000010010010100001011111001000000100001000000;
			5: 			hello_world_line = 80'b10000010100000010000001000000100001000010010010100001010001001000000100001000010;
			6: 			hello_world_line = 80'b10000010111111011111101111110011110000001101100011110010000101111110111110000010;
			default :	hello_world_line = 80'b00000000000000000000000000000000000000000000000000000000000000000000000000000000;
		endcase
	end
	
	// Position of the HW bitmap on the screen (expressed in 4 x 4 blocks)
	
	localparam
	HW_H_POS_START = 8'd40,
	HW_H_POS_END = HW_H_POS_START + HW_WIDTH,
	
	HW_V_POS_START = 8'd55,
	HW_VPOS_END = HW_V_POS_START + HW_HEIGHT;

	// Pattern counter (pattern changes every second)
	
	always @(posedge tick) begin
		if (count >= 60) begin
			count <= 7'd0;
			pattern <= pattern + 4'b1;
		end
		else begin
			count <= count + 7'b1;
		end
	end
		
	// Paint screen depending on the pattern

	always @(posedge clk_25) begin
		if (! active)
			pixel <= 3'b0;
		else begin
			if (! pattern[3])	begin	// 0 to 7
				if (pattern == 3'd0) begin	// Pattern 0 -> Hello World!
					if ((hpos_block_4 >= HW_H_POS_START) & (hpos_block_4 < HW_H_POS_END) & (vpos_block_4 >= HW_V_POS_START) & (vpos_block_4 < HW_VPOS_END)) begin
						hpos_hw = hpos_block_4 - HW_H_POS_START;
						vpos_hw = vpos_block_4 - HW_V_POS_START;
						pixel <= (hello_world_line[hpos_hw] ? 3'b111 : 3'b0);
					end	
				end
				else
					pixel <= pattern[2:0];	// Fill screen with color 1 to 7
			end
			else begin	// 8 to 15
				if (! pattern[2]) begin	// 8 to 11
					pixel <= (hpos[5] ^ vpos[5] ? {1'b0, pattern[1:0]} : ~{1'b0, pattern[1:0]});	// Checker (32 x 32 pixels blocks)
				end
				else begin	// 12 to 15
					pixel <= pattern[0] ? (hpos[7:5] + pattern[1:0]) :(vpos[7:5] + pattern[1:0]);	// Bars (32 pixels wide)
				end
			end
		end
	end

endmodule