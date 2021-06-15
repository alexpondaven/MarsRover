module BB_DETECT(clk,rst_n,in_valid,sop,dist_thresh,in,x,y,bb1,bb2,bb3,bb4,bb_out, bb_filled_out);

	input clk,rst_n,in_valid,sop;
	input [10:0] dist_thresh; // distance threshold between bounding boxes
	input in; // e.g. red_detect (detected or not)
	input [10:0] x,y;
	output [43:0] bb1,bb2,bb3,bb4;
	output [43:0] bb_out; // best bounding box
	output [7:0] bb_filled_out; //percentage of pixels in best bounding box
	
	
	parameter NUM_BB = 4;
	parameter IMAGE_W = 11'd640;
	parameter IMAGE_H = 11'd480;

	//find multiple bounding boxes for given colour
	// each one stores xmin,xmax,ymin,ymax (each 11 bits)
	
	//bounding box bb[0]=xmin,bb[1]=xmax,bb[2]=ymin,bb[3]=ymax
	reg [10:0]  bb [3:0][NUM_BB-1:0];
	reg [10:0] bbb [3:0]; //best bounding box
	//accumulator for pixels in bounding box
	reg [18:0] bb_acc [NUM_BB-1:0]; // number of pixels in bounding box
	reg [26:0] bb_acc_255 [NUM_BB-1:0]; //bb_acc*255
	reg [7:0] bb_filled [NUM_BB-1:0]; // bb_acc*255/area
	reg [7:0] bbb_filled; //best bounding box accumulator
	
	assign bb_filled_out = bbb_filled;
	
	
	wire [NUM_BB-1:0] close;
	reg [NUM_BB-1:0] bb_used; // 1 if bounding box is stored, 0 if not
	reg dist_y[NUM_BB-1:0], dist_y1[NUM_BB-1:0], dist_y2[NUM_BB-1:0]; // 11 bit or 1 bit?
	
	reg [10:0] xwidth [NUM_BB-1:0]; // store x widths of all bounding boxes
	reg [10:0] ywidth [NUM_BB-1:0]; // store y widths of all bounding boxes
	reg [10:0] xwidth1 [NUM_BB-1:0]; 
	reg [10:0] ywidth1 [NUM_BB-1:0];
	reg [10:0] bxwidth, bywidth; //best bounding box widths
	reg [10:0] diff_width [NUM_BB-1:0]; // absolute difference between xwidth and ywidth
	reg [10:0] bdiff_width;
	
	//criteria regs
	reg min_size [NUM_BB-1:0];
	reg more_square [NUM_BB-1:0];
	reg square_like [NUM_BB-1:0];
	reg bigger [NUM_BB-1:0];
	
	reg [18:0] area[NUM_BB-1:0];
	
	
	//assign 2d array of bounding box limits to large bus for each bounding box (less output ports to worry about)
	assign bb1 = {bb[3][0],bb[2][0],bb[1][0],bb[0][0]};
	assign bb2 = {bb[3][1],bb[2][1],bb[1][1],bb[0][1]};
	assign bb3 = {bb[3][2],bb[2][2],bb[1][2],bb[0][2]};
	assign bb4 = {bb[3][3],bb[2][3],bb[1][3],bb[0][3]};
	assign bb_out = {bbb[3],bbb[2],bbb[1],bbb[0]};
	
//	reg [2:0] bb_cnt; // counter for number of bounding boxes
	
	integer i,j,k;
	reg found;

	//check distances to all existing bounding boxes
//	assign dist_y[0] = (y-bb[3][0])<dist_thresh;
//	assign dist_y[1] = (y-bb[3][1])<dist_thresh;
//	assign dist_y[2] = (y-bb[3][2])<dist_thresh;
//	assign dist_y[3] = (y-bb[3][3])<dist_thresh;
	
	
	
	assign close[0] = (x<bb[0][0]) ? (bb[0][0]-x+y-bb[3][0])<dist_thresh :
				  (x>bb[1][0]) ? (x-bb[1][0]+y-bb[3][0])<dist_thresh :
										dist_y[0];
	assign close[1] = (x<bb[0][1]) ? (bb[0][1]-x+y-bb[3][1])<dist_thresh :
				  (x>bb[1][1]) ? (x-bb[1][1]+y-bb[3][1])<dist_thresh :
										dist_y[1];
	assign close[2] = (x<bb[0][2]) ? (bb[0][2]-x+y-bb[3][2])<dist_thresh :
				  (x>bb[1][2]) ? (x-bb[1][2]+y-bb[3][2])<dist_thresh :
										dist_y[2];
	assign close[3] = (x<bb[0][3]) ? (bb[0][3]-x+y-bb[3][3])<dist_thresh :
				  (x>bb[1][3]) ? (x-bb[1][3]+y-bb[3][3])<dist_thresh :
										dist_y[3];
										
//	assign xwidth[0] = bb[1][0] - bb[0][0];
//	assign xwidth[1] = bb[1][1] - bb[0][1];
//	assign xwidth[2] = bb[1][2] - bb[0][2];
//	assign xwidth[3] = bb[1][3] - bb[0][3];
//	
//	assign ywidth[0] = bb[3][0] - bb[2][0];
//	assign ywidth[1] = bb[3][1] - bb[2][1];
//	assign ywidth[2] = bb[3][2] - bb[2][2];
//	assign ywidth[3] = bb[3][3] - bb[2][3];
	
										
//	assign bdiff_width = (bxwidth>bywidth) ? (bxwidth-bywidth) : (bywidth-bxwidth);
//	assign diff_width[0] = (xwidth[0]>ywidth[0]) ? (xwidth[0]-ywidth[0]) : (ywidth[0]-xwidth[0]);
//	assign diff_width[1] = (xwidth[1]>ywidth[1]) ? (xwidth[1]-ywidth[1]) : (ywidth[1]-xwidth[1]);
//	assign diff_width[2] = (xwidth[2]>ywidth[2]) ? (xwidth[2]-ywidth[2]) : (ywidth[2]-xwidth[2]);
//	assign diff_width[3] = (xwidth[3]>ywidth[3]) ? (xwidth[3]-ywidth[3]) : (ywidth[3]-xwidth[3]);
	
	//Find first and last red pixels
	always@(posedge clk) begin
		
		// boundary boxes
		if (in && in_valid) begin	//Update bounds when the pixel is red
			//check if first pixel
			//Note that first 2 cases could be combined
			if (bb_used==0) begin // instantiate first bounding box at first pixel
				bb[0][0] <= x;
				bb[1][0] <= x;
				bb[2][0] <= y;
				bb[3][0] <= y;
				
				bb_acc[0] <= 1; //1 pixel in new bounding box
				bb_used[0] <= 1; // 0th bounding box being used
				
				xwidth[0] <=0;
				ywidth[0] <= 0;
				diff_width[0] <=0;
				min_size[0] <=0;
				more_square[0] <=0;
				square_like[0] <=0;
				bigger[0] <=0;
			end
			else if ((close==4'b0) & (bb_used < 4'b1111)) begin // no bounding boxes are close - instantiate new one in first free position (bb_used=0)
				//need to find first valid position in bb_used
				found=0;
				for (i=0;i<NUM_BB & ~found;i=i+1) begin
					if (~bb_used[i]) begin
						bb[0][i] <= x;
						bb[1][i] <= x;
						bb[2][i] <= y;
						bb[3][i] <= y;
						
						bb_acc[i] <= 1;
						bb_used[i] <= 1;
						
						xwidth[i] <=0;
						ywidth[i] <= 0;
						diff_width[i] <=0;
						min_size[i] <=0;
						more_square[i] <=0;
						square_like[i] <=0;
						bigger[i] <=0;
						
						found=1;
					end
				end
				
				
			end
			else begin // update first bounding box that it is closest to
				found=0;
				for (j=0;j<NUM_BB & ~found;j=j+1) begin
					if (close[j] & bb_used[j]) begin // close to bounding box
						if (x < bb[0][j]) bb[0][j] <= x;
						if (x > bb[1][j]) bb[1][j] <= x;
						if (y < bb[2][j]) bb[2][j] <= y;
						bb[3][j] <= y;
						bb_acc[j] <= bb_acc[j] + 1; //accumulate number of pixels in bounding box
						found = 1;
					end
				end
				
			end
		end
		
		//loop through all valid bounding boxes - if dist_y is 0, bounding box is done, can decide whether it is good or not
		
		for (k=0;k<NUM_BB;k=k+1) begin
			
			//find widths of bounding boxes every cycle
			xwidth[k] <= bb[1][k] - bb[0][k];
			ywidth[k] <= bb[3][k] - bb[2][k];
			xwidth1[k] <= xwidth[k]; // store xwidth and ywidth for extra cycle to synchronise data
			ywidth1[k] <= ywidth[k];

			diff_width[k] <= (xwidth[k]>ywidth[k]) ? (xwidth[k]-ywidth[k]) : (ywidth[k]-xwidth[k]);
			min_size[k] <= (xwidth1[k]>10)&(ywidth1[k]>10);
			more_square[k] <= diff_width[k]<bdiff_width; // is xwidth and ywidth closer together (more square like)
			square_like[k] <= diff_width[k]<(bdiff_width+100); // allow it to be similar ratio
			bigger[k] <= (xwidth1[k]>bxwidth) & (ywidth1[k]>bywidth); // are the widths larger than the best bounding box widths
			
			dist_y[k] <= (y-bb[3][k])<dist_thresh;
			dist_y1[k] <= dist_y[k];
			dist_y2[k] <= dist_y1[k];
			
			//Majority pixel
			bb_acc_255[k] <= bb_acc[k]*255;
			area[k] <= xwidth[k] * ywidth[k];
			bb_filled[k] <= (area[k]==0) ? 0 : (bb_acc_255[k] / area[k]);
			
			if ((~dist_y2[k] | y==(IMAGE_H-1)) & bb_used[k]) begin //done adding new pixels to bounding box
				//decide whether to keep bounding box or remove it
				//Computing criteria for best bounding box to be replaced
//				if ((bdiff_width>50) ? (more_square[k] & min_size[k]) : ((bigger[k] | (bb_filled[k] >= bbb_filled)) & square_like[k] & min_size[k])) begin
				if ((bdiff_width>50) ? (more_square[k] & min_size[k]) : (bigger[k] & square_like[k] & min_size[k])) begin
					//set bbb to bb[k]
					bbb[0] <= bb[0][k];
					bbb[1] <= bb[1][k];
					bbb[2] <= bb[2][k];
					bbb[3] <= bb[3][k];
					bxwidth <= xwidth[k];
					bywidth <= ywidth[k];
					bdiff_width <= diff_width[k];
					
					bbb_filled <= bb_filled[k];
				end
				//bb[k] is basically done updating, not used anymore
				bb_used[k]<=0;
				
			end
		end
		
		
		if (sop & in_valid) begin	//Reset bounds on start of packet
			//re-initialise all bounds - to know when bounding box is invalid
			bb[0][0] <= 0;
			bb[1][0] <= 0;
			bb[2][0] <= 0;
			bb[3][0] <= 0;
			bb[0][1] <= 0;
			bb[1][1] <= 0;
			bb[2][1] <= 0;
			bb[3][1] <= 0;
			bb[0][2] <= 0;
			bb[1][2] <= 0;
			bb[2][2] <= 0;
			bb[3][2] <= 0;
			bb[0][3] <= 0;
			bb[1][3] <= 0;
			bb[2][3] <= 0;
			bb[3][3] <= 0;
			
			bbb[0] <=0;
			bbb[1] <=0;
			bbb[2] <=0;
			bbb[3] <=0;
			
			bxwidth<=0;
			bywidth<=0;
			bdiff_width<=0;
			
			bbb_filled <= 0;
			
//			bb_cnt <=0; // reset number of bounding boxes
			bb_used <=0;
		end
	end
	
	
endmodule
