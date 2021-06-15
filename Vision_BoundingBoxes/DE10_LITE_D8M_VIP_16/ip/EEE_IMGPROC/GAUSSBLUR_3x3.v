module GAUSSBLUR_3x3(clk,rst_n,in_valid,in,out);

	input clk,rst_n,in_valid;
	input [7:0] in;
	output [7:0] out;

	// gaussian blur on 3x3 window
	// Gaussian blur - using separable filter technique (reduces matrix multiplication from O(n^2) to O(n)
	// Good blur to remove high frequency noise but preserve edges by weighting the center pixel more (gaussian distribution)
	// Convolution with 1/16[1 2 1; 2 4 2; 1 2 1] = 1/16([1 2 1] * [1 2 1])
	// 1. Horizontal convolution with [1 2 1]
	// 2. Vertical convolution with [1 2 1] on result of 1.
	// 3. Divide by 16 (to preserve intensity)

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
			p0 <= p00 + 2*p01 + p02;
			p1 <= p10 + 2*p11 + p12;
			p2 <= p20 + 2*p21 + p22;
			
			//convolve rows
			p <= p0[9:2] + 2*p1[9:2] + p2[9:2];
		
		end
	end
	
	assign out = p[9:2];

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

