module RGB2HSV(clk,rst_n,in_valid,red,green,blue,hue,value,sat,hsv_valid);
//conversion from RGB to HSV (or just hue)
//hue provides information on the colour independent of saturation & value

	input clk,rst_n;
	input in_valid; // when input is valid
	input [7:0] red,green,blue;
	output [7:0] hue,value,sat; //hue is in range 0-360 degrees but algorithm fits it into range 0-255
	output hsv_valid; // when output is ready
	
	//wire comparators can help
	wire r_b,r_g,b_g,b_r;
	assign r_b = red>blue;
	assign r_g = red>green;
	assign b_g = blue>green;
	assign b_r = blue>red;
	
	reg [7:0]  B_G,R_G,B_R,rgb_max,rgb_min,red1,green1,blue1;
	reg [7:0] rgb_max1,rgb_max2,rgb_max3,rgb_max4;
	
	reg [13:0] mulBG,mulRG,mulBR;
	reg [7:0] range;
	reg rmax,gmax,bmax; // not sure if it can just be 1 bit
	
	reg [13:0] divBG,divRG,divBR;
	reg [15:0] mulsat;
	reg rmax1,gmax1,bmax1,grey; // keep comparisons
	
	reg [7:0] hue_r,hue_g,hue_b;
	reg [15:0] divsat;
	reg rmax2,gmax2,bmax2,grey1;
	
	reg [7:0] hue_out;
	reg [7:0] sat_out;
	
	
	reg valid1,valid2,valid3,valid4,valid5;
	
	assign hue = hue_out;
	assign value = rgb_max4;
	assign sat = sat_out;
	assign hsv_valid = valid5;
	
	
	always @(posedge clk) begin
		if (~rst_n) begin
			valid1<=0;
			valid2<=0;
			valid3<=0;
			valid4<=0;
			valid5<=0;
		end
		else if (in_valid) begin
			//1st cycle
			B_G <= b_g ? (blue-green) : (green-blue);
			R_G <= r_g ? (red-green) : (green-red); 
			B_R <=  b_r ? (blue-red) : (red-blue); 
			
			rgb_max <= r_b ? (r_g ? red : green) : (b_g ? blue : green);
			rgb_min <= r_b ? (b_g ? green : blue) : (r_g ? green : red);
			
			red1 <= red;
			green1 <= green;
			blue1 <= blue;
			
			valid1 <= in_valid;
			
			//2nd cycle
			mulBG <= B_G*43;
			mulRG <= R_G*43;
			mulBR <= B_R*43; 
			
			range <= rgb_max - rgb_min; 
			
			rmax <= (rgb_max==red1);
			gmax <= (rgb_max==green1);
			bmax <= (rgb_max==blue1);
			
			valid2 <= valid1;
			rgb_max1 <= rgb_max;
			
			//3rd cycle
			divBG <= mulBG / range;
			divRG <= mulRG / range; 
			divBR <= mulBR / range;
			
			rmax1 <= rmax;
			gmax1 <= gmax;
			bmax1 <= bmax;
			grey <= (range==0);
			
			mulsat <= range*255;
			
			valid3 <= valid2;
			rgb_max2 <= rgb_max1;
			
			//4th cycle
			hue_r <= divBG; 
			hue_g <= divBR+85;
			hue_b <= divRG+171;
			
			rmax2 <= rmax1;
			gmax2 <= gmax1;
			bmax2 <= bmax1;
			grey1 <= grey;
			
			divsat <= mulsat/rgb_max2;
			
			valid4 <= valid3;
			rgb_max3 <= rgb_max2;
			
			//5th cycle
			hue_out <=  grey1 ? 0   : // if range=0,hue=0
							rmax2 ? hue_r :
							gmax2 ? hue_g :
									  hue_b;
			
			sat_out <= (rgb_max3==0) ? 0 : divsat;
			
			valid5 <= valid4;
			rgb_max4 <= rgb_max3;
			
		end
	
	end

	
endmodule
