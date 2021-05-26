module EEE_IMGPROC(
	// global clock & reset
	clk,
	reset_n,
	
	// mm slave
	s_chipselect,
	s_read,
	s_write,
	s_readdata,
	s_writedata,
	s_address,

	// stream sink
	sink_data,
	sink_valid,
	sink_ready,
	sink_sop,
	sink_eop,
	
	// streaming source
	source_data,
	source_valid,
	source_ready,
	source_sop,
	source_eop,
	
	// conduit
	mode
	
);


// global clock & reset
input	clk;
input	reset_n;

// mm slave
input							s_chipselect;
input							s_read;
input							s_write;
output	reg	[31:0]	s_readdata;
input	[31:0]				s_writedata;
input	[2:0]					s_address;


// streaming sink
input	[23:0]            	sink_data;
input								sink_valid;
output							sink_ready;
input								sink_sop;
input								sink_eop;

// streaming source
output	[23:0]			  	   source_data;
output								source_valid;
input									source_ready;
output								source_sop;
output								source_eop;

// conduit export
input  [1:0]                  mode;

////////////////////////////////////////////////////////////////////////
//
parameter IMAGE_W = 11'd640;
parameter IMAGE_H = 11'd480;
parameter MESSAGE_BUF_MAX = 256;
parameter MSG_INTERVAL = 6;
parameter BB_COL_DEFAULT = 24'h0000ff;
parameter CONTRAST_DEFAULT = 8'd0;
parameter RED_THRESH_DEFAULT = 8'd128;

parameter STORE_ROWS = 2; // number of previous pixel rows to store


wire [7:0]   red, green, blue, grey;
wire [7:0]   red_out, green_out, blue_out;

wire         sop, eop, in_valid, out_ready;
////////////////////////////////////////////////////////////////////////

// Detect red areas
wire red_detect;
wire green_detect;
assign red_detect = red[7] & ~green[7] & ~blue[7];
assign green_detect = ~red[7] & green[7] & ~blue[7];

// Find boundary of cursor box

// Highlight detected areas
wire [23:0] red_high, green_high;
assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4
//assign grey = red_detect ? 8'hff : 8'h0;
assign red_high  = red_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};
assign green_high = green_detect ? {8'h0, 8'hff, 8'h0} : {grey, grey, grey};

// Show bounding box
wire [23:0] new_image;
wire bb_active;
assign bb_active = (x == left) | (x == right) | (y == top) | (y == bottom);
assign new_image = bb_active ? bb_col : red_high;






// Contrast - can help with edge detection
/*
wire [7:0] contrast_factor;
assign contrast_factor = (8'd259 * (contrast + 8'd255)) / (8'd255 * (8'd259 - contrast));

function [7:0] apply_contrast;
	input [7:0] colour;
	reg [7:0] contrast_colour;
	begin
		contrast_colour = contrast_factor * (colour - 8'd128) + 8'd128;
		if (contrast_colour < 8'd0) begin
			apply_contrast = 8'd0;
		end
		else if (contrast_colour > 8'd255) begin
			apply_contrast = 8'd255;
		end
		else begin
			apply_contrast = contrast_colour;
		end
	end
endfunction

wire [23:0] contrast_image;
assign contrast_image = {apply_contrast(red), apply_contrast(green), apply_contrast(blue)}; // contrast image
*/


// Edge detection - horizontally
// - difference in intensity compared to previous pixel
reg [7:0] prev_grey; // intensity of the pixel to the left
wire [7:0] diff_grey; // intensity difference between left pixel and current pixel
assign diff_grey = (grey>prev_grey) ? {grey-prev_grey, grey-prev_grey, grey-prev_grey} : {prev_grey-grey, prev_grey-grey, prev_grey-grey};

// Sharpen - use convolution with [-1 5 -1]
reg [7:0] pp_grey; // previous previous grey
wire [7:0] conv_grey;
assign conv_grey = 5*prev_grey - pp_grey - conv_grey;

//Noise reduction
// Median filter:
//wire [7:0] med_grey;
//assign med_grey = ((pp_grey >= prev_grey && prev_grey >= grey)||(grey >= prev_grey && prev_grey >= pp_grey)) ? prev_grey :
//						((prev_grey >= pp_grey && pp_grey >= grey)||(grey >= pp_grey && pp_grey >= prev_grey))     ? pp_grey :
//																																					grey;


// PLAN
// Gaussian blur on red & black image
// find red_detect again on blurred image
// do sobel 3x3 on that

																																				
// Gaussian blur - using separable filter technique (reduces matrix multiplication from O(n^2) to O(n)
// Good blur to remove high frequency noise but preserve edges by weighting the center pixel more (gaussian distribution)
// Convolution with 1/16[1 2 1; 2 4 2; 1 2 1] = 1/16([1 2 1] * [1 2 1])
// 1. Horizontal convolution with [1 2 1]
// 2. Vertical convolution with [1 2 1] on result of 1.
// 3. Divide by 16 (to preserve intensity)
wire [11:0] horizontal_blur; // 10 bits to allow for overflow
wire [11:0] vertical_blur;
//wire [7:0] red_pix; // 8'hff if red_detect, otherwise 0
//assign red_pix = red_detect ? 8'hff : 0;
assign horizontal_blur = (red_detect + 2*prev_red + pp_red)/8'd4;
/* Trying 5x5 
wire [11:0] inter_blur;
assign inter_blur = (x>4) ? (grey+(prev_row[x-1][0]<<2)+(prev_row[x-2][0]<<3)-(prev_row[x-2][0]<<1)+(prev_row[x-3][0]<<2)+prev_row[x-4][0]) : grey;
assign horizontal_blur = (x>4) ? inter_blur[11:4] : grey;
//assign horizontal_blur = (x>4) ? (grey + prev_row[x-1][0] + prev_row[x-2][0]+prev_row[x-3][0])/5 : grey; // breaks
*/
assign vertical_blur = (horizontal_blur + 2*prev_hor_blur[x][0] + prev_hor_blur[x][1])/8'd4;

wire [7:0] red_blur_detect; // red image has been blurred - only take red pixels that are high enough
assign red_blur_detect = (vertical_blur > red_thresh) ? 8'hff : 0;

//Sobel operator 3x3
wire [11:0] horizontal_sobel_x, horizontal_sobel_y;
reg [11:0] vertical_sobel_x, vertical_sobel_y; // sobelx and sobely are edge detections in x and y axes
//assign horizontal_sobel_x = red_detect ? pp_grey-8'hff : pp_grey; // [1 0 -1]
//assign horizontal_sobel_y = red_detect ? 8'hff+2*prev_grey+pp_grey : 2*prev_grey+pp_grey; // [1 2 1]
//using gaussian blur output:
assign horizontal_sobel_x = red_blur_detect ? pp_bred-8'hff : pp_bred; // [1 0 -1]
assign horizontal_sobel_y = red_blur_detect ? 8'hff+2*prev_bred+pp_bred : 2*prev_bred+pp_bred; // [1 2 1]
//assign vertical_blur = horizontal_blur + 2*prev_hor_blur[x][0] + prev_hor_blur[x][1];
reg [11:0] inter_vert_x, inter_vert_y, sobel, sobel_bb;
always @(*) begin
	inter_vert_x = horizontal_sobel_x + 2*prev_hor_sobel_x[x][0] + prev_hor_sobel_x[x][1]; // [1 2 1]
	if (inter_vert_x < 8'd0) begin
		vertical_sobel_x = 8'd0;
	end
	else if (inter_vert_x > 8'd255) begin
		vertical_sobel_x = 8'd255;
	end
	else begin
		vertical_sobel_x = inter_vert_x;
	end
	
	inter_vert_y =  prev_hor_sobel_y[x][1] - horizontal_sobel_y; //[1 0 -1]
	if (inter_vert_y < 8'd0) begin
		vertical_sobel_y = 8'd0;
	end
	else if (inter_vert_y > 8'd255) begin
		vertical_sobel_y = 8'd255;
	end
	else begin
		vertical_sobel_y = inter_vert_y;
	end
	
	sobel = (vertical_sobel_x+vertical_sobel_y)>>1; //average?
	
	sobel_bb = bb_active ? bb_col : sobel;
	
	red_blur_detect
end
//find magnitude of vertical_sobel_x and vertical_sobel_y



// 5x5 Gaussian blur
// same as 3x3 but with [1 4 6 4 1] separable filter
/*
wire [13:0] horizontal_5blur;
wire [13:0] vertical_5blur;
assign horizontal_5blur = (x>4) ? (grey+(prev_row[x-1][0]<<2)+(prev_row[x-2][0]<<3)-(prev_row[x-2][0]<<1)+(prev_row[x-3][0]<<2)+prev_row[x-4][0])>>4: // divide by 16
											grey; // if x coord is <3, can't apply full convolution
assign vertical_5blur = (horizontal_blur+4*prev_hor_blur[x][0]+6*prev_hor_blur[x][1]+4*prev_hor_blur[x][2]+prev_hor_blur[x][3])>>4;
*/											



// Switch output pixels depending on mode switch
// Don't modify the start-of-packet word - it's a packet discriptor
// Don't modify data in non-video packets
// Normal rgb: {red,green,blue}
// Pixel by pixel edge detection: {diff_grey, diff_grey, diff_grey}
// contrasted image: contrast_image
// Convolution grey edge detection: {conv_grey, conv_grey, conv_grey}
// Median filter grey: {med_grey, med_grey, med_grey}
// Horizontal blur grey: {horizontal_blur[7:0],horizontal_blur[7:0],horizontal_blur[7:0]}
// 3x3 gaussian blur grey: {vertical_blur[7:0], vertical_blur[7:0], vertical_blur[7:0]}
// 5x5 gaussian blur grey: {vertical_5blur[7:0], vertical_5blur[7:0], vertical_5blur[7:0]}
assign {red_out, green_out, blue_out} = ((mode==2'b01) & ~sop & packet_video) ? {red_blur_detect[7:0], red_blur_detect[7:0], red_blur_detect[7:0]}:
													 //((mode==2'b10) & ~sop & packet_video) ? {diff_grey, diff_grey, diff_grey} :
																										  {grey,grey,grey};

//Count valid pixels to get the image coordinates. Reset and detect packet type on Start of Packet.
reg [10:0] x, y;
reg packet_video;
// store previous row of grey pixels 
reg [11:0] prev_row [IMAGE_W-11'h1:0][1:0];
//store previous horizontal_blurs
reg [7:0] prev_hor_blur [IMAGE_W-11'h1:0][STORE_ROWS-1:0];

//sobel row storage
reg [7:0] prev_hor_sobel_x [IMAGE_W-11'h1:0][STORE_ROWS-1:0];
reg [7:0] prev_hor_sobel_y [IMAGE_W-11'h1:0][STORE_ROWS-1:0];
//reg [7:0] prev_sobel [IMAGE_W-11'h1:0][STORE_ROWS-1:0];
integer i, j;

//red detect storage
reg prev_red, pp_red;
reg prev_bred, pp_bred;

always@(posedge clk) begin
	if (sop) begin // new frame
		x <= 11'h0;
		y <= 11'h0;
		packet_video <= (blue[3:0] == 3'h0);
		prev_grey <= 8'h0;
		pp_grey <= 8'h0;
		prev_red <= 8'h0;
		pp_red <= 8'h0;
		prev_bred <= 8'h0;
		pp_bred <= 8'h0;
		for (i=0;i<IMAGE_W;i=i+1) begin
			prev_row[i][0] <= 11'h0;
			prev_row[i][1] <= 11'h0;
			//for (j=0;j<STORE_ROWS;j=j+1) begin
			//	prev_hor_blur[i][j] <= 8'h0;
			//end
			
		end
		
	end
	else if (in_valid) begin
		if (x == IMAGE_W-1) begin // end of row
			x <= 11'h0;
			y <= y + 11'h1;
			prev_grey <= 8'h0;
			pp_grey <= 8'h0;
			prev_red <= 8'h0;
			pp_red <= 8'h0;
			prev_bred <= 8'h0;
			pp_bred <= 8'h0;
		end
		else begin // next pixel in row
			x <= x + 11'h1;
			pp_red <= prev_red;
			prev_red <= red_detect; // red detection
			
			pp_bred <= prev_bred;
			prev_bred <= red_blur_detect;
			
			
			pp_grey <= prev_grey;
			prev_grey <= grey;
		end

		prev_row[x][1] <= prev_row[x][0];
		prev_row[x][0] <= vertical_blur;
		
		//prev_hor_blur[x][3] <= prev_hor_blur[x][2];
		//prev_hor_blur[x][2] <= prev_hor_blur[x][1];
		prev_hor_blur[x][1] <= prev_hor_blur[x][0];
		prev_hor_blur[x][0] <= horizontal_blur;
		
		prev_hor_sobel_x[x][1] <= prev_hor_sobel_x[x][0];
		prev_hor_sobel_x[x][0] <= horizontal_sobel_x;
		
		prev_hor_sobel_y[x][1] <= prev_hor_sobel_y[x][0];
		prev_hor_sobel_y[x][0] <= horizontal_sobel_y;
		
//		prev_sobel[x][1] <= prev_sobel[x][0];
//		prev_sobel[x][0] <= sobel;
		
	end
end

//Add requirement for boundary box to update 





//Find first and last red pixels
reg [10:0] x_min, y_min, x_max, y_max;
always@(posedge clk) begin
	if (red_blur_detect && in_valid) begin	//Update bounds when the pixel is red 
		//update bounding box only if neighbouring pixels are also grey
		if (x < x_min) x_min <= x;
		if (x > x_max) x_max <= x;
		if (y < y_min) y_min <= y;
		y_max <= y;
	end
	if (sop & in_valid) begin	//Reset bounds on start of packet
		x_min <= IMAGE_W-11'h1;
		x_max <= 0;
		y_min <= IMAGE_H-11'h1;
		y_max <= 0;
	end
end

//Process bounding box at the end of the frame.
reg [1:0] msg_state;
reg [10:0] left, right, top, bottom;
reg [7:0] frame_count;
always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets
		
		//Latch edges for display overlay on next frame
		left <= x_min;
		right <= x_max;
		top <= y_min;
		bottom <= y_max;
		
		
		//Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
		frame_count <= frame_count - 1;
		
		if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX - 3) begin
			msg_state <= 2'b01;
			frame_count <= MSG_INTERVAL-1;
		end
	end
	
	//Cycle through message writer states once started
	if (msg_state != 2'b00) msg_state <= msg_state + 2'b01;
	
	//boundary box values
	bb_width <= x_max-x_min;
	dist_from_centre <= (bb_mid<(IMAGE_W/2)) ? (IMAGE_W/2) - bb_mid : bb_mid - (IMAGE_W/2);

end
	
//Generate output messages for CPU
reg [31:0] msg_buf_in; 
wire [31:0] msg_buf_out;
reg msg_buf_wr;
wire msg_buf_rd, msg_buf_flush;
wire [7:0] msg_buf_size;
wire msg_buf_empty;

`define RED_BOX_MSG_ID "RBB"

reg [10:0] bb_width;
wire [11:0] bb_mid;
reg [10:0] dist_from_centre;

assign bb_mid = (x_max+x_min)>>1;



always@(*) begin	//Write words to FIFO as state machine advances
	case(msg_state)
		2'b00: begin
			msg_buf_in = 32'b0;
			msg_buf_wr = 1'b0;
		end
		2'b01: begin
			msg_buf_in = `RED_BOX_MSG_ID;	//Message ID
			msg_buf_wr = 1'b1;
		end
		2'b10: begin
			//msg_buf_in = {5'b0, x_min, 5'b0, y_min};	//Top left coordinate
			msg_buf_in = {21'b0,bb_width}; // horizontal size
			msg_buf_wr = 1'b1;
		end
		2'b11: begin
			//msg_buf_in = {5'b0, x_max, 5'b0, y_max}; //Bottom right coordinate
			msg_buf_in = {21'b0, dist_from_centre}; // distance of bb centre to screen centre
			msg_buf_wr = 1'b1;
		end
	endcase
end


//Output message FIFO
MSG_FIFO	MSG_FIFO_inst (
	.clock (clk),
	.data (msg_buf_in),
	.rdreq (msg_buf_rd),
	.sclr (~reset_n | msg_buf_flush),
	.wrreq (msg_buf_wr),
	.q (msg_buf_out),
	.usedw (msg_buf_size),
	.empty (msg_buf_empty)
	);


//Streaming registers to buffer video signal
STREAM_REG #(.DATA_WIDTH(26)) in_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(sink_ready),
	.valid_out(in_valid),
	.data_out({red,green,blue,sop,eop}),
	.ready_in(out_ready),
	.valid_in(sink_valid),
	.data_in({sink_data,sink_sop,sink_eop})
);

STREAM_REG #(.DATA_WIDTH(26)) out_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(out_ready),
	.valid_out(source_valid),
	.data_out({source_data,source_sop,source_eop}),
	.ready_in(source_ready),
	.valid_in(in_valid),
	.data_in({red_out, green_out, blue_out, sop, eop})
);


/////////////////////////////////
/// Memory-mapped port		 /////
/////////////////////////////////

// Addresses
`define REG_STATUS    			0
`define READ_MSG    				1
`define READ_ID    				2
`define REG_BBCOL					3 // bounding box colour
`define REG_CONTRAST				4
`define REG_RED_THRESH			5

//Status register bits
// 31:16 - unimplemented
// 15:8 - number of words in message buffer (read only)
// 7:5 - unused
// 4 - flush message buffer (write only - read as 0)
// 3:0 - unused


// Process write

reg  [7:0]   reg_status;
reg	[23:0]	bb_col;
reg [7:0] contrast;
reg [7:0] red_thresh;

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		reg_status <= 8'b0;
		bb_col <= BB_COL_DEFAULT;
		contrast <= CONTRAST_DEFAULT;
		red_thresh <= RED_THRESH_DEFAULT;
	end
	else begin
		if(s_chipselect & s_write) begin
		   if      (s_address == `REG_STATUS)	reg_status <= s_writedata[7:0];
		   if      (s_address == `REG_BBCOL)	bb_col <= s_writedata[23:0];
			if 	  (s_address == `REG_CONTRAST)	contrast <= s_writedata[7:0];
			if 	  (s_address == `REG_RED_THRESH)	red_thresh <= s_writedata[7:0];
		end
	end
end


//Flush the message buffer if 1 is written to status register bit 4
assign msg_buf_flush = (s_chipselect & s_write & (s_address == `REG_STATUS) & s_writedata[4]);


// Process reads
reg read_d; //Store the read signal for correct updating of the message buffer

// Copy the requested word to the output port when there is a read.
always @ (posedge clk)
begin
   if (~reset_n) begin
	   s_readdata <= {32'b0};
		read_d <= 1'b0;
	end
	
	else if (s_chipselect & s_read) begin
		if   (s_address == `REG_STATUS) s_readdata <= {16'b0,msg_buf_size,reg_status};
		if   (s_address == `READ_MSG) s_readdata <= {msg_buf_out};
		if   (s_address == `READ_ID) s_readdata <= 32'h1234EEE2;
		if   (s_address == `REG_BBCOL) s_readdata <= {8'h0, bb_col};
		if   (s_address == `REG_CONTRAST) s_readdata <= {24'h0, contrast};
		if   (s_address == `REG_RED_THRESH) s_readdata <= {24'h0, red_thresh};
	end
	
	read_d <= s_read;
end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);
						


endmodule

