module WINDOW_3x3(in_grey,in_valid, clk, rst_n ,p00,p01,p02,p10,p11,p12,p20,p21,p22, full, empty, used, almost_full, rdreq, wrreq, fifo_out);

	// produce a 3x3 window to convolve over
	

	//Input
	input clk, rst_n;
	input in_valid;
	input [7:0] in_grey;
	output reg [7:0] p00,p01,p02,p10,p11,p12,p20,p21,p22; // 3x3 window
	output full;
	output empty;
	output [9:0] used;
	output almost_full;
	output rdreq;
	output wrreq;
	output [7:0] fifo_out;
	
	
	
	always@(posedge clk) begin
		if (~rst_n) begin
			p00 <= 0;
			p01 <= 0;
			p02 <= 0;
			p10 <= 0;
			p11 <= 0;
			p12 <= 0;
			p20 <= 0;
			p21 <= 0;
			p22 <= 0;
		end
		else begin
			if (in_valid) begin
				//assigning registers
				p22 <= in_grey;
				p21 <= p22;
				p20 <= p21;
				p12 <= out_1;
				p11 <= p12;
				p10 <= p11;
				p02 <= out_2;
				p01 <= p02;
				p00 <= p01;
				
				// read when almost full (639 words in buffer since it takes 2 cycles to go from almost_full -> rdreq -> out)
				if (almost_full_1) begin // if buffer1 is full - read and write
					rdreq_1 <= 1'b1;
					wrreq_1 <= 1'b1;
				end
				else begin // if not full, just write
					rdreq_1 <= 1'b0;
					wrreq_1 <= 1'b1;
				end
				
				//row buffer 2
				if (almost_full_2) begin // if buffer2 is full - read and write
					rdreq_2 <= 1'b1;
					wrreq_2 <= 1'b1;
				end
				else if (almost_full_1) begin //if not full, only write if buffer 1 is full
					rdreq_2 <= 1'b0;
					wrreq_2 <= 1'b1;
				end
				else begin
					rdreq_2 <= 1'b0;
					wrreq_2 <= 1'b0;
				end
			end
			else begin
				// don't read or write if pixel is not valid
				rdreq_1 <= 1'b0;
				wrreq_1 <= 1'b0;
				rdreq_2 <= 1'b0;
				wrreq_2 <= 1'b0;
			end
		
		end
	end
	
	
	// use row buffers to store rows in FIFO
	// IP only has FIFO depth of power of 2
	// Use cascading FIFOs of depth 512 and 128 to get 640 (image width)
reg rdreq_1, wrreq_1, rdreq_2, wrreq_2;
wire empty_1, full_1, almost_full_1, empty_2, full_2, almost_full_2;
wire [7:0] out_1;
wire [7:0] out_2;
wire [9:0] used_1, used_2;

assign empty = empty_2;
assign full = full_2;
assign used = used_2;
assign almost_full = almost_full_2;
assign wrreq = wrreq_2;
assign rdreq = rdreq_2;
assign fifo_out = out_2;

	
ROW_BUFF	row_buff_1 (
	.clock ( clk ),
	.data ( in_grey ),
	.rdreq ( rdreq_1 ),
	.sclr ( ~rst_n ),
	.wrreq ( wrreq_1 ),
	.empty ( empty_1 ),
	.full ( full_1 ),
	.almost_full ( almost_full_1 ),
	.q ( out_1 ),
	.usedw (used_1)
	);
	
ROW_BUFF	row_buff_2 (
	.clock ( clk ),
	.data ( out_1 ), // out_1 or p12
	.rdreq ( rdreq_2 ),
	.sclr ( ~rst_n ),
	.wrreq ( wrreq_2 ),
	.empty ( empty_2 ),
	.full ( full_2 ),
	.almost_full ( almost_full_2 ),
	.q ( out_2 ),
	.usedw (used_2)
	);
	
endmodule
