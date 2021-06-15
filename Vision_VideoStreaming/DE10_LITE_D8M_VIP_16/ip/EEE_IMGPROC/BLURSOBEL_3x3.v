module BLURSOBEL_3x3(clk,rst_n,in_valid,in,out);

	input clk,rst_n,in_valid;
	input [7:0] in;
	output [7:0] out;
	
	//Blur and sobel in one operation
	// 1/16[6; 12; 6] * [1 0 -1]

	wire [7:0] p00,p01,p02,p10,p11,p12,p20,p21,p22;

	reg [9:0] p0,p1,p2; // row convolutions
	
	reg [9:0] p;
	
	always @(posedge clk) begin
		if (~rst_n) begin
//			p00 <= 0;
//			p01 <= 0;
//			p02 <= 0;
//			p10 <= 0;
//			p11 <= 0;
//			p12 <= 0;
//			p20 <= 0;
//			p21 <= 0;
//			p22 <= 0;
			
			p0 <= 0;
			p1 <= 0;
			p2 <= 0;
			p <= 0;
		end
		else begin
		 //row convolutions
			p0 <= p00 - p02;
			p1 <= p10 - p12;
			p2 <= p20 - p22;
			
			//convolve rows
			p <= 3*(p0[9:3] + p1[9:2] + p2[9:3]);
		
		end
	end
	
	assign out = p;

//	//assign out = p00[7:4]+p01[7:3]+p02[7:4]+p10[7:3]+p11[7:2]+p12[7:3]+p20[7:4]+p21[7:3]+p22[7:4];
	
//	assign out = p12;


WINDOW_3x3 window (
	.in_grey(in),
	.in_valid(in_valid),
	.clk(clk), 
	.rst_n(rst_n),
	.p00(p00),
	.p01(p01),
	.p02(p02),
	.p10(p10),
	.p11(p11),
	.p12(p12),
	.p20(p20),
	.p21(p21),
	.p22(p22)
	);
	
endmodule

