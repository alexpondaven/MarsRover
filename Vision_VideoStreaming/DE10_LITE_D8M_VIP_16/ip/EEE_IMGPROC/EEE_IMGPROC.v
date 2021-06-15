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

//colour parameters
parameter HUE_MIN_Y = 8'h20;
parameter HUE_MAX_Y = 8'h35;
parameter SAT_MIN_Y = 8'h90;
parameter SAT_MAX_Y = 8'hff;
parameter VAL_MIN_Y = 8'h00;
parameter VAL_MAX_Y = 8'hff;

parameter HUE_MIN_P = 8'h00;
parameter HUE_MAX_P = 8'h0e;
parameter SAT_MIN_P = 8'h33;
parameter SAT_MAX_P = 8'hae;
parameter VAL_MIN_P = 8'h60;
parameter VAL_MAX_P = 8'hff;

parameter HUE_MIN_R = 8'h00;
parameter HUE_MAX_R = 8'h0e;
parameter SAT_MIN_R = 8'ha6;
parameter SAT_MAX_R = 8'hff;
parameter VAL_MIN_R = 8'h00;
parameter VAL_MAX_R = 8'hff;

parameter HUE_MIN_G = 8'h55;
parameter HUE_MAX_G = 8'h6a;
parameter SAT_MIN_G = 8'h4c;
parameter SAT_MAX_G = 8'hb3;
parameter VAL_MIN_G = 8'h00;
parameter VAL_MAX_G = 8'hb3;

parameter HUE_MIN_B = 8'h80;
parameter HUE_MAX_B = 8'hff;
parameter SAT_MIN_B = 8'h00;
parameter SAT_MAX_B = 8'h60;
parameter VAL_MIN_B = 8'h10;
parameter VAL_MAX_B = 8'hb0;

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
reg [7:0] hue_min_r,hue_max_r,sat_min_r,sat_max_r,val_min_r,val_max_r;
reg [7:0] hue_min_p,hue_max_p,sat_min_p,sat_max_p,val_min_p,val_max_p;
reg [7:0] hue_min_y,hue_max_y,sat_min_y,sat_max_y,val_min_y,val_max_y;
reg [7:0] hue_min_g,hue_max_g,sat_min_g,sat_max_g,val_min_g,val_max_g;
reg [7:0] hue_min_b,hue_max_b,sat_min_b,sat_max_b,val_min_b,val_max_b;

always @ (posedge clk) begin
	if (~reset_n) begin
	//set default value for HSV thresholds
		hue_min_r <= HUE_MIN_R;
		hue_max_r <= HUE_MAX_R;
		sat_min_r <= SAT_MIN_R;
		sat_max_r <= SAT_MAX_R;
		val_min_r <= VAL_MIN_R;
		val_max_r <= VAL_MAX_R;
		
		hue_min_p <= HUE_MIN_P;
		hue_max_p <= HUE_MAX_P;
		sat_min_p <= SAT_MIN_P;
		sat_max_p <= SAT_MAX_P;
		val_min_p <= VAL_MIN_P;
		val_max_p <= VAL_MAX_P;
		
		hue_min_y <= HUE_MIN_Y;
		hue_max_y <= HUE_MAX_Y;
		sat_min_y <= SAT_MIN_Y;
		sat_max_y <= SAT_MAX_Y;
		val_min_y <= VAL_MIN_Y;
		val_max_y <= VAL_MAX_Y;
		
		hue_min_g <= HUE_MIN_G;
		hue_max_g <= HUE_MAX_G;
		sat_min_g <= SAT_MIN_G;
		sat_max_g <= SAT_MAX_G;
		val_min_g <= VAL_MIN_G;
		val_max_g <= VAL_MAX_G;
		
		hue_min_b <= HUE_MIN_B;
		hue_max_b <= HUE_MAX_B;
		sat_min_b <= SAT_MIN_B;
		sat_max_b <= SAT_MAX_B;
		val_min_b <= VAL_MIN_B;
		val_max_b <= VAL_MAX_B;
	end
	else begin
		//update HSV thresholds according to memory mapped registers
		case(color_select[3:0])
			4'h1: begin
				if (color_select[7:4]==2) hue_min_r <= hue_bound[7:0];
				else if (color_select[7:4]==1) hue_max_r <= hue_bound[15:8];
				else if (color_select[7:4]==4) sat_min_r <= sat_bound[7:0];
				else if (color_select[7:4]==3) sat_max_r <= sat_bound[15:8];
				else if (color_select[7:4]==6) val_min_r <= val_bound[7:0];
				else if (color_select[7:4]==5) val_max_r <= val_bound[15:8];
			end
			4'h2: begin
				if (color_select[7:4]==2) hue_min_p <= hue_bound[7:0];
				else if (color_select[7:4]==1) hue_max_p <= hue_bound[15:8];
				else if (color_select[7:4]==4) sat_min_p <= sat_bound[7:0];
				else if (color_select[7:4]==3) sat_max_p <= sat_bound[15:8];
				else if (color_select[7:4]==6) val_min_p <= val_bound[7:0];
				else if (color_select[7:4]==5) val_max_p <= val_bound[15:8];
			end
			4'h3: begin
				if (color_select[7:4]==2) hue_min_y <= hue_bound[7:0];
				else if (color_select[7:4]==1) hue_max_y <= hue_bound[15:8];
				else if (color_select[7:4]==4) sat_min_y <= sat_bound[7:0];
				else if (color_select[7:4]==3) sat_max_y <= sat_bound[15:8];
				else if (color_select[7:4]==6) val_min_y <= val_bound[7:0];
				else if (color_select[7:4]==5) val_max_y <= val_bound[15:8];
			end
			4'h4: begin
				if (color_select[7:4]==2) hue_min_g <= hue_bound[7:0];
				else if (color_select[7:4]==1) hue_max_g <= hue_bound[15:8];
				else if (color_select[7:4]==4) sat_min_g <= sat_bound[7:0];
				else if (color_select[7:4]==3) sat_max_g <= sat_bound[15:8];
				else if (color_select[7:4]==6) val_min_g <= val_bound[7:0];
				else if (color_select[7:4]==5) val_max_g <= val_bound[15:8];
			end
			4'h5: begin
				if (color_select[7:4]==2) hue_min_b <= hue_bound[7:0];
				else if (color_select[7:4]==1) hue_max_b <= hue_bound[15:8];
				else if (color_select[7:4]==4) sat_min_b <= sat_bound[7:0];
				else if (color_select[7:4]==3) sat_max_b <= sat_bound[15:8];
				else if (color_select[7:4]==6) val_min_b <= val_bound[7:0];
				else if (color_select[7:4]==5) val_max_b <= val_bound[15:8];
			
			end
		endcase
	end
end



//use memory mapped parameters to control colour being detected - used for rapid testing of colours that work
assign var_detect = (hue>=hue_bound[7:0]) & (hue<=hue_bound[15:8]) & (sat>=sat_bound[7:0]) & (sat<=sat_bound[15:8]) & (value>=val_bound[7:0]) & (value<=val_bound[15:8]);

//Detected colours using HSV - values found experimentally
//assign yellow_detect = (hue>=8'h20) & (hue<=8'h35) & (sat>=8'h90) & (sat<=8'hff) & (value>=8'h00) & (value<=8'hff);
//assign pink_detect = (hue>=8'h00) & (hue<=8'h0e) & (sat>=8'h33) & (sat<=8'hae) & (value>=8'h60) & (value<=8'hff);
//assign red_detect = (hue>=8'h00) & (hue<=8'h0e) & (sat>=8'ha6) & (sat<=8'hff) & (value>=8'h00) & (value<=8'hff);
//assign green_detect = (hue>=8'h55) & (hue<=8'h6a) & (sat>=8'h4c) & (sat<=8'hb3) & (value>=8'h00) & (value<=8'hb3);
//assign blue_detect = (hue>=8'h80) & (hue<=8'hff) & (sat>=8'h00) & (sat<=8'h60) & (value>=8'h10) & (value<=8'hb0);

assign red_detect = (hue>=hue_min_r) & (hue<=hue_max_r) & (sat>=sat_min_r) & (sat<=sat_max_r) & (value>=val_min_r) & (value<=val_max_r);
assign pink_detect = (hue>=hue_min_p) & (hue<=hue_max_p) & (sat>=sat_min_p) & (sat<=sat_max_p) & (value>=val_min_p) & (value<=val_max_p);
assign yellow_detect = (hue>=hue_min_y) & (hue<=hue_max_y) & (sat>=sat_min_y) & (sat<=sat_max_y) & (value>=val_min_y) & (value<=val_max_y);
assign green_detect = (hue>=hue_min_g) & (hue<=hue_max_g) & (sat>=sat_min_g) & (sat<=sat_max_g) & (value>=val_min_g) & (value<=val_max_g);
assign blue_detect = (hue>=hue_min_b) & (hue<=hue_max_b) & (sat>=sat_min_b) & (sat<=sat_max_b) & (value>=val_min_b) & (value<=val_max_b);


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
//Outputs of bb_detect
wire [43:0] bb[3:0];
wire [43:0] bbb_red,bbb_pink,bbb_yellow,bbb_green,bbb_blue;
wire [43:0] bbb_red_inter, bbb_pink_inter; // intermediate wires to go into red_pink_decide module
//Bounds
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

//draw bounding boxes as closed rectangles
assign bbb_active_red = (x == bleft_red | x == bright_red)&(y>=btop_red)&(y<=bbottom_red)
								| (y == btop_red | y == bbottom_red)&(x<=bright_red)&(x>=bleft_red)
								| (x == (bleft_red-1) | x == (bright_red-1))&(y>=(btop_red-1))&(y<=(bbottom_red-1))
								| (y == (btop_red-1) | y == (bbottom_red-1))&(x<=(bright_red-1))&(x>=(bleft_red-1));
assign bbb_active_pink = (x == bleft_pink | x == bright_pink)&(y>=btop_pink)&(y<=bbottom_pink)
								| (y == btop_pink | y == bbottom_pink)&(x<=bright_pink)&(x>=bleft_pink)
								| (x == (bleft_pink-1) | x == (bright_pink-1))&(y>=(btop_pink-1))&(y<=(bbottom_pink-1))
								| (y == (btop_pink-1) | y == (bbottom_pink-1))&(x<=(bright_pink-1))&(x>=(bleft_pink-1));
assign bbb_active_yellow = (x == bleft_yellow | x == bright_yellow)&(y>=btop_yellow)&(y<=bbottom_yellow)
								| (y == btop_yellow | y == bbottom_yellow)&(x<=bright_yellow)&(x>=bleft_yellow)
								| (x == (bleft_yellow-1) | x == (bright_yellow-1))&(y>=(btop_yellow-1))&(y<=(bbottom_yellow-1))
								| (y == (btop_yellow-1) | y == (bbottom_yellow-1))&(x<=(bright_yellow-1))&(x>=(bleft_yellow-1));
assign bbb_active_green = (x == bleft_green | x == bright_green)&(y>=btop_green)&(y<=bbottom_green)
								| (y == btop_green | y == bbottom_green)&(x<=bright_green)&(x>=bleft_green)
								| (x == (bleft_green-1) | x == (bright_green-1))&(y>=(btop_green-1))&(y<=(bbottom_green-1))
								| (y == (btop_green-1) | y == (bbottom_green-1))&(x<=(bright_green-1))&(x>=(bleft_green-1));
assign bbb_active_blue = (x == bleft_blue | x == bright_blue)&(y>=btop_blue)&(y<=bbottom_blue)
								| (y == btop_blue | y == bbottom_blue)&(x<=bright_blue)&(x>=bleft_blue)
								| (x == (bleft_blue-1) | x == (bright_blue-1))&(y>=(btop_blue-1))&(y<=(bbottom_blue-1))
								| (y == (btop_blue-1) | y == (bbottom_blue-1))&(x<=(bright_blue-1))&(x>=(bleft_blue-1));

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
reg [3:0] msg_state;
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
			msg_state <= 4'b0001;
			frame_count <= MSG_INTERVAL-1;
		end
	end
	
	//Cycle through message writer states once started
	if (msg_state != 4'b0000) msg_state <= msg_state + 4'b0001;

end
	
//Generate output messages for CPU
reg [31:0] msg_buf_in; 
wire [31:0] msg_buf_out;
reg msg_buf_wr;
wire msg_buf_rd, msg_buf_flush;
wire [7:0] msg_buf_size;
wire msg_buf_empty;

`define RED_BOX_MSG_ID "RBB"
`define PINK_BOX_MSG_ID "PBB"
`define YELLOW_BOX_MSG_ID "YBB"
`define GREEN_BOX_MSG_ID "GBB"
`define BLUE_BOX_MSG_ID "BBB"



always@(*) begin	//Write words to FIFO as state machine advances
	case(msg_state)
		4'h0: begin
			msg_buf_in = 32'b0;
			msg_buf_wr = 1'b0;
		end
		
		4'h1: begin
			msg_buf_in = `RED_BOX_MSG_ID;	//Message ID
			msg_buf_wr = 1'b1;
		end
		4'h2: begin
//			msg_buf_in = {5'b0, x_min, 5'b0, y_min};	//Top left coordinate
			msg_buf_in = {5'b0, bleft_red, 5'b0, btop_red};	//Top left coordinate - may rather be bb[i][10:0] and bb[i][32:22]
			msg_buf_wr = 1'b1;
		end
		4'h3: begin
//			msg_buf_in = {5'b0, x_max, 5'b0, y_max}; //Bottom right coordinate
			msg_buf_in = {5'b0, bright_red, 5'b0, bbottom_red}; //Bottom right coordinate
			msg_buf_wr = 1'b1;
		end
		
		4'h4: begin
			msg_buf_in = `PINK_BOX_MSG_ID;
			msg_buf_wr = 1'b1;
		end
		4'h5: begin
			msg_buf_in = {5'b0, bleft_pink, 5'b0, btop_pink};
			msg_buf_wr = 1'b1;
		end
		4'h6: begin
			msg_buf_in = {5'b0, bright_pink, 5'b0, bbottom_pink}; 
			msg_buf_wr = 1'b1;
		end
		
		4'h7: begin
			msg_buf_in = `YELLOW_BOX_MSG_ID;
			msg_buf_wr = 1'b1;
		end
		4'h8: begin
			msg_buf_in = {5'b0, bleft_yellow, 5'b0, btop_yellow};
			msg_buf_wr = 1'b1;
		end
		4'h9: begin
			msg_buf_in = {5'b0, bright_yellow, 5'b0, bbottom_yellow}; 
			msg_buf_wr = 1'b1;
		end
		
		4'ha: begin
			msg_buf_in = `GREEN_BOX_MSG_ID;	
			msg_buf_wr = 1'b1;
		end
		4'hb: begin
			msg_buf_in = {5'b0, bleft_green, 5'b0, btop_green};
			msg_buf_wr = 1'b1;
		end
		4'hc: begin
			msg_buf_in = {5'b0, bright_green, 5'b0, bbottom_green}; 
			msg_buf_wr = 1'b1;
		end
		
		4'hd: begin
			msg_buf_in = `BLUE_BOX_MSG_ID;
			msg_buf_wr = 1'b1;
		end
		4'he: begin
			msg_buf_in = {5'b0, bleft_blue, 5'b0, btop_blue};
			msg_buf_wr = 1'b1;
		end
		4'hf: begin
			msg_buf_in = {5'b0, bright_blue, 5'b0, bbottom_blue}; 
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
//GAUSSBLUR_3x3 gaussblur_3x3_red (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(red_detect ? 8'hff : 0),
//	.out(blur_red_high)
//);
//GAUSSBLUR_3x3 gaussblur_3x3_pink (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(pink_detect ? 8'hff : 0),
//	.out(blur_pink_high)
//);
//GAUSSBLUR_3x3 gaussblur_3x3_yellow (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(yellow_detect ? 8'hff : 0),
//	.out(blur_yellow_high)
//);
//GAUSSBLUR_3x3 gaussblur_3x3_green (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(green_detect ? 8'hff : 0),
//	.out(blur_green_high)
//);
//GAUSSBLUR_3x3 gaussblur_3x3_blue (
//
//	.clk(clk),
//	.rst_n(reset_n),
//	.in_valid(in_valid),
//	.in(blue_detect ? 8'hff : 0),
//	.out(blur_blue_high)
//);

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
	.in(red_detect), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb1(bb[0]),
	.bb2(bb[1]),
	.bb3(bb[2]),
	.bb4(bb[3]),
	.bb_out(bbb_red_inter)
);
BB_DETECT bb_detect_pink (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(pink_detect), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_pink_inter)
);
BB_DETECT bb_detect_yellow (
	.clk(clk),
	.rst_n(reset_n),
	.in_valid(in_valid),
	.sop(sop),
	.dist_thresh(dist_thresh),
	.in(yellow_detect), // find boundary box on red_detect
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
	.in(green_detect), // find boundary box on red_detect
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
	.in(blue_detect), // find boundary box on red_detect
	.x(x),
	.y(y),
	.bb_out(bbb_blue)
);

RED_PINK_DECIDE red_pink_decide (
	.clk(clk),
	.rst_n(reset_n),
	.bbb_red(bbb_red_inter),
	.bbb_pink(bbb_pink_inter),
	.bbb_red_out(bbb_red),
	.bbb_pink_out(bbb_pink)

);

/////////////////////////////////
/// Memory-mapped port		 /////
/////////////////////////////////

// Addresses
`define REG_STATUS    			0
`define READ_MSG    				1
`define READ_ID    				2
//`define REG_BBCOL					3 // bounding box colour
`define REG_COLSEL 				3
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

reg [7:0] color_select; //select what colour is being selected for hsv bounds



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
		
		color_select <= 0;
	end
	else begin
		if(s_chipselect & s_write) begin
		   if      (s_address == `REG_STATUS)	reg_status <= s_writedata[7:0];
//		   if      (s_address == `REG_BBCOL)	bb_col <= s_writedata[23:0];
//			if 	  (s_address == `REG_CONTRAST)	contrast <= s_writedata[7:0];
//			if 	  (s_address == `REG_RED_THRESH)	red_thresh <= s_writedata[7:0];
//			if 	  (s_address == `REG_COL_DETECT)	col_detect <= s_writedata[14:0];
			if 	  (s_address == `REG_DIST_THRESH)	dist_thresh <= s_writedata[10:0];
			
			if 	  (s_address == `REG_HUE)	hue_bound <= s_writedata[15:0];
			if 	  (s_address == `REG_SAT)	sat_bound <= s_writedata[15:0];
			if 	  (s_address == `REG_VAL)	val_bound <= s_writedata[15:0];
			if 	  (s_address == `REG_COLSEL)	color_select <= s_writedata[7:0];
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
//		if   (s_address == `REG_BBCOL) s_readdata <= {8'h0, bb_col};
//		if   (s_address == `REG_CONTRAST) s_readdata <= {24'h0, contrast};
//		if   (s_address == `REG_RED_THRESH) s_readdata <= {24'h0, red_thresh};
//		if   (s_address == `REG_COL_DETECT) s_readdata <= {17'h0, col_detect};
		if   (s_address == `REG_DIST_THRESH) s_readdata <= {21'h0, dist_thresh};
		
		if   (s_address == `REG_HUE) s_readdata <= {16'h0, hue_bound};
		if   (s_address == `REG_SAT) s_readdata <= {16'h0, sat_bound};
		if   (s_address == `REG_VAL) s_readdata <= {16'h0, val_bound};
		if   (s_address == `REG_COLSEL) s_readdata <= {24'h0, color_select};
	end
	
	read_d <= s_read;
end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);
						


endmodule

