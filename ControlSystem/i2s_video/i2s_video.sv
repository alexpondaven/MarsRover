module i2s_video (
  input reset,
  input mclk,
  output i2s_bclk,
  output reg pclk, //pixel clock

  input cts,
  output i2s_data,
  output i2s_ws,

  input datavalid,

  input [23:0] disp_data,
  input v_sync

);

reg init;
initial init=1;
assign reset_ind = init;

wire [3:0] mVGA_B;
wire [3:0] mVGA_G;
wire [3:0] mVGA_R;
wire [11:0] pixel;
logic [3:0] counter;

logic send_frame;

wire [3:0] nullwire;
reg [1:0] ws;

logic pixel_out;




  // make pixel data 4 bits
  assign  {mVGA_R[3:0], nullwire[3:0], mVGA_G[3:0], nullwire[3:0], mVGA_B[3:0], nullwire[3:0]} = disp_data;
  assign pixel = {mVGA_R[3:0], mVGA_G[3:0], mVGA_B[3:0]};

  assign i2s_bclk = mclk & datavalid & send_frame;
  assign i2s_ws = ws[1];
  assign i2s_data = pixel_out & datavalid & send_frame;

always @(*) begin
  case (counter)
    4'd0 : pixel_out = pixel[11];
    4'd1 : pixel_out = pixel[10];
    4'd2 : pixel_out = pixel[9];
    4'd3 : pixel_out = pixel[8];
    4'd4 : pixel_out = pixel[7];
    4'd5 : pixel_out = pixel[6];
    4'd6 : pixel_out = pixel[5];
    4'd7 : pixel_out = pixel[4];
    4'd8 : pixel_out = pixel[3];
    4'd9 : pixel_out = pixel[2];
    4'd10 : pixel_out = pixel[1];
    4'd11 : pixel_out = pixel[0];
    default: pixel_out = pixel[11];
  endcase
  
end


// esp will sample data on posedge of clk, so make changes on negedge
always_ff @( negedge mclk ) begin

  // manage counter and generate pclk
  if (counter == 4'd11) begin
    counter <= 4'd0;
    pclk <= 1;
    ws <= ws+1;
  end else begin
    counter <= counter + 1;
  end

  if (counter == 4'd5) begin
    pclk <= 0;
  end
  

  if (init) begin
	  counter <= 4'd0;
	  pclk <= 0;
    init <= 0;
    ws <= 0;
  end

  
end


// end of frame
always_ff @( negedge v_sync ) begin
 if (cts) begin
   send_frame <= 1;
 end else begin
	 send_frame <= 0;
 end
 
end



endmodule