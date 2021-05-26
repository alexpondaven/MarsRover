module WINDOW_3x3(in_grey, clk, rst_n ,window);

	// produce a 3x3 window to convolve over
	

	//Input
	input clk, rst_n;
	input [7:0] in_grey;
	output [7:0] window[2:0][2:0]; // 3x3 window
	
	integer i,j;
	
	always@(posedge clk) begin
		if (~rst_n) begin
			for (i=0;i<3;i=i+1) begin
				for (j=0;j<3;j=j+1) begin
					window[i][j] <= 0;
				end
			end
		end
		else begin
		
		end
	end
	
	
	// use row buffers to store rows in FIFO
	// IP only has FIFO depth of power of 2
	// Use cascading FIFOs of depth 512 and 128 to get 640 (image width)
	
	