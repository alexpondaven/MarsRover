module WINDOW_3x3_TEST(
	input clk, 
	input rst_n,
	output [7:0] p00,p01,p02,p10,p11,p12,p20,p21,p22, // 3x3 window
	
	// debug signals for row buffer 1
	output full,
	output empty,
	output [9:0] used,
	output almost_full,
	output rdreq,
	output wrreq,
	output [7:0] fifo_out
	);

reg [7:0] in_grey;
	
always @(posedge clk) begin
	if (~rst_n) begin
		in_grey <= 8'b0;
	end
	else begin
		in_grey <= in_grey + 8'b1;
	end
end

WINDOW_3x3 window_inst (
	.clk(clk),
	.rst_n(rst_n),
	.in_grey(in_grey),
	.in_valid(1'b1),
	.p00(p00),
	.p01(p01),
	.p02(p02),
	.p10(p10),
	.p11(p11),
	.p12(p12),
	.p20(p20),
	.p21(p21),
	.p22(p22),
	.full(full),
	.empty(empty),
	.used(used),
	.almost_full(almost_full),
	.rdreq(rdreq),
	.wrreq(wrreq),
	.fifo_out(fifo_out)
	
);

endmodule

