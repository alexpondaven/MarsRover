module RED_PINK_DECIDE(clk,rst_n,bbb_red,bbb_pink,bbb_red_out,bbb_pink_out);
	
	input clk,rst_n;
	input [43:0] bbb_red,bbb_pink; // bounding box limits for red and pink balls
//	input [18:0] red_filled,pink_filled; // accumulated number of pixels in each bounding box
	
	output [43:0] bbb_red_out,bbb_pink_out;
	
	parameter range = 15;
	
	wire [10:0] left_red,right_red,top_red,bottom_red;
	wire [10:0] left_pink,right_pink,top_pink,bottom_pink;
	//wire overlap,left_overlap,right_overlap,top_overlap,bottom_overlap,red_best;
	wire red_inside,pink_inside,inside;
	
	assign left_red = bbb_red[10:0];
	assign right_red = bbb_red[21:11];
	assign top_red = bbb_red[32:22];
	assign bottom_red = bbb_red[43:33];
	
	assign left_pink = bbb_pink[10:0];
	assign right_pink = bbb_pink[21:11];
	assign top_pink = bbb_pink[32:22];
	assign bottom_pink = bbb_pink[43:33];
	
	//check if red&pink bounds overlap
//	assign left_overlap = (left_red > (left_pink-range)) & (left_red<(right_pink-range));
//	assign right_overlap = (right_red < (right_pink+range)) & (right_red>(left_pink+range));
//	assign top_overlap = (top_red > (top_pink-range)) & (top_red<(bottom_pink-range));
//	assign bottom_overlap = (bottom_red < (bottom_pink+range)) & (bottom_red>(top_pink+range));

	//assign overlap = left_overlap | right_overlap | top_overlap | bottom_overlap;
							
	
//	assign red_best = red_filled > pink_filled;
	
	//if overlap, output the one with the larger concentration of pixels
	//otherwise, output the same bounds
//	assign bbb_red_out = overlap ? (red_best ? bbb_red : 44'b0 ) : bbb_red;
//	assign bbb_pink_out = overlap ? (red_best ? 44'h0 : bbb_pink ) : bbb_pink;

	assign red_inside  = ((left_red >= left_pink) & (right_red <= right_pink))
								| ((left_red >= left_pink+range) & (right_red <= right_pink+range))
								| ((left_red >= left_pink-range) & (right_red <= right_pink-range))
								| ((top_red >= top_pink) & (bottom_red <= bottom_pink))
								| ((top_red >= top_pink+range) & (bottom_red <= bottom_pink+range))
								| ((top_red >= top_pink-range) & (bottom_red <= bottom_pink-range));
	assign pink_inside = ((left_pink >= left_red) & (right_pink <= right_red)) 
								| ((left_pink >= left_red+range) & (right_pink <= right_red+range)) 
								| ((left_pink >= left_red-range) & (right_pink <= right_red-range)) 
								| ((top_pink >= top_red) & (bottom_pink <= bottom_red))
								| ((top_pink >= top_red+range) & (bottom_pink <= bottom_red+range))
								| ((top_pink >= top_red-range) & (bottom_pink <= bottom_red-range));

	//output the larger bounding box
	assign bbb_red_out  = red_inside  ? 44'h0 : bbb_red;
	assign bbb_pink_out = pink_inside ? 44'h0 : bbb_pink;
	

endmodule
