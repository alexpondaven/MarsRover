module GAUSSBLUR_3x3_TEST(
	input clk, 
	input rst_n,
	output [7:0] out
	
	
	);

reg [7:0] in;

always @(posedge clk) begin
	if (~rst_n) begin
		in <= 8'b0;
	end
	else begin
		in <= 8'hff;
	end
end
	
	
GAUSSBLUR_3x3 gaussblur (
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(1'b1),
	.in(in),
	.out(out)

);


endmodule
