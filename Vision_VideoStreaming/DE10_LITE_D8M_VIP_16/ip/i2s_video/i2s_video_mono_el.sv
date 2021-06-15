module i2s_video_mono_el (
  input reset,
  input mclk,
  output i2s_bclk,
  output pclk, //pixel clock

  input cts,
  output i2s_data,
  output i2s_ws,

  input datavalid,

  input [95:0] disp_data,
  input v_sync

);

reg init;
initial init=1;

logic [7:0] pixel1, pixel2, pixel3, pixel4;
logic [31:0] pixel;
logic [4:0] counter;
logic [3:0] bclk_counter;
initial bclk_counter = 0;
logic send_frame;
logic bclk;
reg ws;

logic pixel_out;

assign bclk = bclk_counter[3];
always_ff @( posedge mclk ) begin
  bclk_counter <= bclk_counter +1;
  
end


  // make 8-bit color in 3-3-2 bits
  assign pixel1 = {disp_data[23:21] ,  disp_data[15:13] , disp_data[7:6]};
  assign pixel2 = {disp_data[47:45] , disp_data[39:37] , disp_data[31:30]};
  assign pixel3 = {disp_data[71:69], disp_data[63:61], disp_data[55:54]};
  assign pixel4 = {disp_data[95:93], disp_data[87:85], disp_data[79:78]};

  // change to little endian
  assign pixel[31:24] = pixel4[7:0];
  assign pixel[23:16] = pixel3[7:0];
  assign pixel[15:8] = pixel2[7:0];
  assign pixel[7:0] = pixel1[7:0];


  assign i2s_bclk = bclk & datavalid & send_frame;
  assign i2s_ws = ws;
  assign pclk = !i2s_ws;
  assign i2s_data = pixel_out & datavalid & send_frame;

  assign pixel_out = pixel[counter];


// esp will sample data on posedge of clk, so make changes on negedge
always_ff @( negedge bclk ) begin

  // manage counter and generate pclk
  if (counter == 5'd0) begin
    // pclk <= 1;
    ws <= 0;
  end

  counter <= counter - 1;


  if (counter == 5'd16) begin
    ws <= 1;
  end
  

  if (init) begin
	  counter <= 5'd0;
	  // pclk <= 0;
    init <= 0;
    ws <= 0;
  end

  
end


// end of frame
always_ff @( posedge v_sync ) begin
 if (cts) begin
   send_frame <= 1;
 end else begin
	 send_frame <= 0;
 end
 
end



endmodule
