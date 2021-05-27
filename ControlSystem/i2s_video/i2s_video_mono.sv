module i2s_video_mono (
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

logic [9:0] pixel;
logic [2:0] counter;

logic send_frame;

reg [1:0] ws;

logic pixel_out;




  // make monochrome color
  assign pixel = ({2'd0, disp_data[23:16]} + {2'd0, disp_data[15:8]} + {2'd0, disp_data[7:0]})/3;


  assign i2s_bclk = mclk & datavalid & send_frame;
  assign i2s_ws = ws[1];
  assign i2s_data = pixel_out & datavalid & send_frame;

always @(*) begin
  case (counter)
    3'd0 : pixel_out = pixel[7];
    3'd1 : pixel_out = pixel[6];
    3'd2 : pixel_out = pixel[5];
    3'd3 : pixel_out = pixel[4];
    3'd4 : pixel_out = pixel[3];
    3'd5 : pixel_out = pixel[2];
    3'd6 : pixel_out = pixel[1];
    3'd7 : pixel_out = pixel[0];
    default: pixel_out = pixel[7];
  endcase
  
end


// esp will sample data on posedge of clk, so make changes on negedge
always_ff @( negedge mclk ) begin

  // manage counter and generate pclk
  if (counter == 3'd7) begin
    counter <= 3'd0;
    pclk <= 1;
    ws <= ws+1;
  end else begin
    counter <= counter + 1;
  end

  if (counter == 3'd3) begin
    pclk <= 0;
  end
  

  if (init) begin
	  counter <= 3'd0;
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