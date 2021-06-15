module RGB2HSV_TEST(clk,rst_n,red,green,blue,hue,value,sat,hsv_valid);

	input clk,rst_n;
	output [7:0] red,green,blue,hue,value,sat;
	output hsv_valid;
	
	assign blue = in[7:0];
	assign green = in[15:8];
	assign red = in[23:16];
	
	reg [23:0] in;
	
	always @(posedge clk) begin
		if (~rst_n) begin
			in<=0;
		end
		else begin
			in <= in+24'h0f0a14;
		end
	end

RGB2HSV rgb2hsv (
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(1),
	.red(red),
	.green(green),
	.blue(blue),
	.hue(hue),
	.value(value),
	.sat(sat),
	.hsv_valid(hsv_valid)
);

	
endmodule
