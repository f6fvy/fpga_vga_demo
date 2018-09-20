// Laurent Haas - F6FVY
// Sept 2018

`timescale 1 ns / 100 ps

module vga_demo_tb();
	reg	clk;						// 50 MHz 20 ns

	wire	red, green, blue;		// VGA outputs
	wire	hsync, vsync;

	vga_demo dut(
	.clk(clk),
	
	.red(red),
	.green(green),
	.blue(blue),
	.hsync(hsync),
	.vsync(vsync)
	);
	
	initial begin
		clk = 1'b0;
		forever begin
			#10 clk = ~clk;		// 20 ns period
		end
	end

endmodule