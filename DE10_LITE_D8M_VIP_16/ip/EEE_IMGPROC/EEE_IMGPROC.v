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
input  [3:0]                  mode;

////////////////////////////////////////////////////////////////////////
//
parameter IMAGE_W = 11'd640;
parameter IMAGE_H = 11'd480;
parameter MESSAGE_BUF_MAX = 256;
parameter MSG_INTERVAL = 6;
parameter BB_COL_DEFAULT = 24'h0000ff;
parameter CONTRAST_DEFAULT = 8'd0;
parameter RED_THRESH_DEFAULT = 8'd128;
parameter COL_DETECT_DEFAULT = 15'd0;
parameter DIST_THRESH_DEFAULT = 11'd10;

//hsv parameters
parameter HUE_DEFAULT = 16'hff00;
parameter SAT_DEFAULT = 16'hff00;
parameter VAL_DEFAULT = 16'hff00;


parameter STORE_ROWS = 2; // number of previous pixel rows to store


wire [7:0]   red, green, blue, grey;
wire [7:0]   red_out, green_out, blue_out;

wire         sop, eop, in_valid, out_ready;
////////////////////////////////////////////////////////////////////////

// Detect red areas
wire red_detect, pink_detect, green_detect, blue_detect, yellow_detect, var_detect;

//using hsv
wire [7:0] hue,sat,value;
wire hsv_valid;

//use memory mapped parameters to control colour being detected - used for rapid testing of colours that work
assign var_detect = (hue>=hue_bound[7:0]) & (hue<=hue_bound[15:8]) & (sat>=sat_bound[7:0]) & (sat<=sat_bound[15:8]) & (value>=val_bound[7:0]) & (value<=val_bound[15:8]);

//Detected colours using HSV - values found experimentally
assign yellow_detect = (hue>=8'h20) & (hue<=8'h35) & (sat>=8'h90) & (sat<=8'hff) & (value>=8'h00) & (value<=8'hff);
assign pink_detect = (hue>=8'h00) & (hue<=8'h0e) & (sat>=8'h33) & (sat<=8'hae) & (value>=8'h60) & (value<=8'hff);
assign red_detect = (hue>=8'h00) & (hue<=8'h0e) & (sat>=8'ha6) & (sat<=8'hff) & (value>=8'h00) & (value<=8'hff);
assign green_detect = (hue>=8'h55) & (hue<=8'h6a) & (sat>=8'h4c) & (sat<=8'hb3) & (value>=8'h00) & (value<=8'hb3);
assign blue_detect = (hue>=8'h80) & (hue<=8'hff) & (sat>=8'h00) & (sat<=8'h60) & (value>=8'h10) & (value<=8'hb0);

// Find boundary of cursor box

// Highlight detected areas
wire [23:0] red_high, pink_high, green_high, blue_high, yellow_high, var_high;
assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4
//assign grey = red_detect ? 8'hff : 8'h0;
assign red_high  = red_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};
assign pink_high = pink_detect ? {8'hff, 8'h80, 8'hd5} : {grey, grey, grey};

assign green_high = green_detect ? {8'h0, 8'hff, 8'h0} : {grey, grey, grey};

assign blue_high = blue_detect ? {8'h0, 8'h0, 8'hff} : {grey, grey, grey};
assign yellow_high = yellow_detect ? {8'hff, 8'hff, 8'h0} : {grey, grey, grey};

assign var_high = var_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};


//Using submodules:


//gaussblur
wire [7:0] blur_out;
wire [7:0] blur_red_high,blur_pink_high,blur_yellow_high,blur_green_high,blur_blue_high; // blurred boolean image

//blob detection
wire [23:0] red_bb,red_bb1,red_bb2,red_bb3,red_bb4, red_bbb, pink_bbb, yellow_bbb,green_bbb,blue_bbb,bbb;
wire bb_active,bb_active1,bb_active2,bb_active3,bb_active4;
wire bbb_active_red, bbb_active_pink,bbb_active_yellow,bbb_active_green,bbb_active_blue;
wire [43:0] bb[3:0];
wire [43:0] bbb_red,bbb_pink,bbb_yellow,bbb_green,bbb_blue;
reg [10:0] left[3:0], right[3:0], top[3:0], bottom[3:0];
reg [10:0] bleft_red, bright_red, btop_red, bbottom_red; //best boundary box boundaries
reg [10:0] bleft_pink, bright_pink, btop_pink, bbottom_pink;
reg [10:0] bleft_yellow, bright_yellow, btop_yellow, bbottom_yellow;
reg [10:0] bleft_green, bright_green, btop_green, bbottom_green;
reg [10:0] bleft_blue, bright_blue, btop_blue, bbottom_blue;

assign bb_active1 = (x == left[0]) | (x == right[0]) | (y == top[0]) | (y == bottom[0]);
assign bb_active2  = (x == left[1]) | (x == right[1]) | (y == top[1]) | (y == bottom[1]);
assign bb_active3  = (x == left[2]) | (x == right[2]) | (y == top[2]) | (y == bottom[2]);
assign bb_active4  = (x == left[3]) | (x == right[3]) | (y == top[3]) | (y == bottom[3]);
assign bb_active = bb_active1 | bb_active2 | bb_active3 | bb_active4;

assign bbb_active_red = (x == bleft_red | x == bright_red)&(y>=btop_red)&(y<=bbottom_red)
								| (y == btop_red | y == bbottom_red)&(x<=bright_red)&(x>=bleft_red);
assign bbb_active_pink = (x == bleft_pink | x == bright_pink)&(y>=btop_pink)&(y<=bbottom_pink)
								| (y == btop_pink | y == bbottom_pink)&(x<=bright_pink)&(x>=bleft_pink);
assign bbb_active_yellow = (x == bleft_yellow | x == bright_yellow)&(y>=btop_yellow)&(y<=bbottom_yellow)
								| (y == btop_yellow | y == bbottom_yellow)&(x<=bright_yellow)&(x>=bleft_yellow);
assign bbb_active_green = (x == bleft_green | x == bright_green)&(y>=btop_green)&(y<=bbottom_green)
								| (y == btop_green | y == bbottom_green)&(x<=bright_green)&(x>=bleft_green);
assign bbb_active_blue = (x == bleft_blue | x == bright_blue)&(y>=btop_blue)&(y<=bbottom_blue)
								| (y == btop_blue | y == bbottom_blue)&(x<=bright_blue)&(x>=bleft_blue);

assign red_bb1 = bb_active1 ? bb_col : red_high;
assign red_bb2 = bb_active2 ? bb_col : red_high;
assign red_bb3 = bb_active3 ? bb_col : red_high;
assign red_bb4 = bb_active4 ? bb_col : red_high;
assign red_bb = bb_active ? bb_col : red_high;
assign red_bbb = bbb_active_red ? {8'hff, 8'h0, 8'h0} : red_high;
assign pink_bbb = bbb_active_pink ? {8'hff, 8'h80, 8'hd5} : pink_high;
assign yellow_bbb = bbb_active_yellow ? {8'hff, 8'hff, 8'h0} : yellow_high;
assign green_bbb = bbb_active_green ? {8'h0, 8'hff, 8'h0} : green_high;
assign blue_bbb = bbb_active_blue ? {8'h0, 8'h0, 8'hff} : blue_high;
assign bbb = bbb_active_red ? {8'hff, 8'h0, 8'h0} :
				 bbb_active_pink ? {8'hff, 8'h80, 8'hd5} :
				 bbb_active_yellow ? {8'hff, 8'hff, 8'h0} :
				 bbb_active_green ? {8'h0, 8'hff, 8'h0} :
				 bbb_active_blue ? {8'h0, 8'h0, 8'hff} :
										{red,green,blue};



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
// 3x3 blur/sobel window: {blur_out[7:0], blur_out[7:0], blur_out[7:0]}
//HSV: {hue,hue,hue},{value,value,value},{sat,sat,sat}
assign {red_out, green_out, blue_out} = ((mode==3'b001) & ~sop & packet_video) ? bbb:
														((mode==3'b011) & ~sop & packet_video) ? red_bbb:
														((mode==3'b010) & ~sop & packet_video) ? pink_bbb:
														((mode==3'b110) & ~sop & packet_video) ? {sat,sat,sat}:
														((mode==3'b111) & ~sop & packet_video) ? {value,value,value}:
														((mode==3'b101) & ~sop & packet_video) ? {hue,hue,hue}:
														((mode==3'b100) & ~sop & packet_video) ? var_high:
																										     {red,green,blue};


//Count valid pixels to get the image coordinates. Reset and detect packet type on Start of Packet.
reg [10:0] x, y;
reg packet_video;

always@(posedge clk) begin
	if (sop) begin // new frame
		x <= 11'h0;
		y <= 11'h0;
		packet_video <= (blue[3:0] == 3'h0);
		
	end
	else if (in_valid) begin
		if (x == IMAGE_W-1) begin // end of row
			x <= 11'h0;
			y <= y + 11'h1;
		end
		else begin // next pixel in row
			x <= x + 11'h1;
		end
	end
end


//Process bounding box at the end of the frame.
reg [1:0] msg_state;
reg [7:0] frame_count;
integer i;
always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets
		
		//Latch edges for display overlay on next frame
		//BB - only update at end of packet
		for (i=0;i<4;i=i+1) begin
			left[i] <= bb[i][10:0];
			right[i] <= bb[i][21:11];
			top[i] <= bb[i][32:22];
			bottom[i] <= bb[i][43:33];
		end
		//best boundary box boundaries
		bleft_red <= bbb_red[10:0];
		bright_red <= bbb_red[21:11];
		btop_red <= bbb_red[32:22];
		bbottom_red <= bbb_red[43:33];
		
		bleft_pink <= bbb_pink[10:0];
		bright_pink <= bbb_pink[21:11];
		btop_pink <= bbb_pink[32:22];
		bbottom_pink <= bbb_pink[43:33];
		
		bleft_yellow <= bbb_yellow[10:0];
		bright_yellow <= bbb_yellow[21:11];
		btop_yellow <= bbb_yellow[32:22];
		bbottom_yellow <= bbb_yellow[43:33];
		
		bleft_green <= bbb_green[10:0];
		bright_green <= bbb_green[21:11];
		btop_green <= bbb_green[32:22];
		bbottom_green <= bbb_green[43:33];
		
		bleft_blue <= bbb_blue[10:0];
		bright_blue <= bbb_blue[21:11];
		btop_blue <= bbb_blue[32:22];
		bbottom_blue <= bbb_blue[43:33];
	
		
		
		//Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
		frame_count <= frame_count - 1;
		
		if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX - 3) begin
			msg_state <= 2'b01;
			frame_count <= MSG_INTERVAL-1;
		end
	end
	
	//Cycle through message writer states once started
	if (msg_state != 2'b00) msg_state <= msg_state + 2'b01;

end
	
//Generate output messages for CPU
reg [31:0] msg_buf_in; 
wire [31:0] msg_buf_out;
reg msg_buf_wr;
wire msg_buf_rd, msg_buf_flush;
wire [7:0] msg_buf_size;
wire msg_buf_empty;

`define RED_BOX_MSG_ID "RBB"



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
//			msg_buf_in = {5'b0, x_min, 5'b0, y_min};	//Top left coordinate
			msg_buf_in = {5'b0, left[0], 5'b0, top[0]};	//Top left coordinate - may rather be bb[i][10:0] and bb[i][32:22]
			msg_buf_wr = 1'b1;
		end
		2'b11: begin
//			msg_buf_in = {5'b0, x_max, 5'b0, y_max}; //Bottom right coordinate
			msg_buf_in = {5'b0, right[0], 5'b0, bottom[0]}; //Bottom right coordinate
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
	.valid_in(in_valid), // in_valid or valid of last module?
	.data_in({red_out, green_out, blue_out, sop, eop})
);

//image processing
RGB2HSV rgb_to_hsv (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.red(red),
	.green(green),
	.blue(blue),
	.hue(hue),
	.value(value),
	.sat(sat),
	.hsv_valid(hsv_valid)
	
);

//Blurring
GAUSSBLUR_3x3 gaussblur_3x3_red (

	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.in(red_detect ? 8'hff : 0),
	.out(blur_red_high)
);
GAUSSBLUR_3x3 gaussblur_3x3_pink (

	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.in(pink_detect ? 8'hff : 0),
	.out(blur_pink_high)
);
GAUSSBLUR_3x3 gaussblur_3x3_yellow (

	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.in(yellow_detect ? 8'hff : 0),
	.out(blur_yellow_high)
);
GAUSSBLUR_3x3 gaussblur_3x3_green (

	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.in(green_detect ? 8'hff : 0),
	.out(blur_green_high)
);
GAUSSBLUR_3x3 gaussblur_3x3_blue (

	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.in(blue_detect ? 8'hff : 0),
	.out(blur_blue_high)
);

//BLURSOBEL_3x3 blursobel_3x3 (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(grey),
//	.out(blur_out)
//	
//
//);

//Bounding box detection

BB_DETECT bb_detect_red (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(blur_red_high>250), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb1(bb[0]),
	.bb2(bb[1]),
	.bb3(bb[2]),
	.bb4(bb[3]),
	.bb_out(bbb_red)
);
BB_DETECT bb_detect_pink (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(blur_pink_high>250), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_pink)
);
BB_DETECT bb_detect_yellow (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(blur_yellow_high>250), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_yellow)
);
BB_DETECT bb_detect_green (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(blur_green_high>250), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_green)
);
BB_DETECT bb_detect_blue (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(blur_blue_high>250), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_blue)
);




/////////////////////////////////
/// Memory-mapped port		 /////
/////////////////////////////////

// Addresses
`define REG_STATUS    			0
`define READ_MSG    				1
`define READ_ID    				2
`define REG_BBCOL					3 // bounding box colour
//`define REG_CONTRAST				4
//`define REG_RED_THRESH			6
//`define REG_COL_DETECT 			5 // colour detect
`define REG_DIST_THRESH 		7 // distance threshold on bounding boxes
`define REG_HUE 					4 // HSV parameters:
`define REG_SAT 					5
`define REG_VAL 					6

//Status register bits
// 31:16 - unimplemented
// 15:8 - number of words in message buffer (read only)
// 7:5 - unused
// 4 - flush message buffer (write only - read as 0)
// 3:0 - unused


// Process write

reg [7:0] reg_status;
reg [23:0] bb_col;
reg [7:0] contrast;
reg [7:0] red_thresh;
reg [14:0] col_detect;
reg [10:0] dist_thresh;
reg [15:0] hue_bound,sat_bound,val_bound;


always @ (posedge clk)
begin
	if (~reset_n)
	begin
		reg_status <= 8'b0;
		bb_col <= BB_COL_DEFAULT;
		contrast <= CONTRAST_DEFAULT;
		red_thresh <= RED_THRESH_DEFAULT;
		col_detect <= COL_DETECT_DEFAULT;
		dist_thresh <= DIST_THRESH_DEFAULT;
		hue_bound <= HUE_DEFAULT;
		sat_bound <= SAT_DEFAULT;
		val_bound <= VAL_DEFAULT;
	end
	else begin
		if(s_chipselect & s_write) begin
		   if      (s_address == `REG_STATUS)	reg_status <= s_writedata[7:0];
		   if      (s_address == `REG_BBCOL)	bb_col <= s_writedata[23:0];
//			if 	  (s_address == `REG_CONTRAST)	contrast <= s_writedata[7:0];
//			if 	  (s_address == `REG_RED_THRESH)	red_thresh <= s_writedata[7:0];
//			if 	  (s_address == `REG_COL_DETECT)	col_detect <= s_writedata[14:0];
			if 	  (s_address == `REG_DIST_THRESH)	dist_thresh <= s_writedata[10:0];
			
			if 	  (s_address == `REG_HUE)	hue_bound <= s_writedata[15:0];
			if 	  (s_address == `REG_SAT)	sat_bound <= s_writedata[15:0];
			if 	  (s_address == `REG_VAL)	val_bound <= s_writedata[15:0];
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
//		if   (s_address == `REG_CONTRAST) s_readdata <= {24'h0, contrast};
//		if   (s_address == `REG_RED_THRESH) s_readdata <= {24'h0, red_thresh};
//		if   (s_address == `REG_COL_DETECT) s_readdata <= {17'h0, col_detect};
		if   (s_address == `REG_DIST_THRESH) s_readdata <= {21'h0, dist_thresh};
		
		if   (s_address == `REG_HUE) s_readdata <= {16'h0, hue_bound};
		if   (s_address == `REG_SAT) s_readdata <= {16'h0, sat_bound};
		if   (s_address == `REG_VAL) s_readdata <= {16'h0, val_bound};
	end
	
	read_d <= s_read;
end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);
						


endmodule

