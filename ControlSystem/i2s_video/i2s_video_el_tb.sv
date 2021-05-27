module i2s_video_el_tb();

  logic pll_clk, pclk, bclk, reset, cts, vsync, datavalid;
  logic i2s_ws, i2s_data;
  reg [95:0] pixeldata;

    initial begin
      $dumpfile("i2s_video.vcd");
      $dumpvars(0,i2s_video_el_tb);

      pll_clk=0;
      pixeldata[95:0] = 96'h000000303030b0b0b0ffffff; // 0000 0000, 0011 0000, 1011 0000, 1111 1111
      vsync = 0;
      cts = 0;
      datavalid = 0;

      reset = 0;
      #1;
      reset = 1;
      #1;
      reset = 0;

      repeat (150) begin
        pll_clk = !pll_clk;
        #1;
        pll_clk = !pll_clk;
        #1;
      end

      $finish(0);
    end

    initial begin
      // reset = 1;
      // @( posedge pll_clk )
      // reset = 0;

      @(posedge pclk)
      datavalid = 1; // signal datavalid

      @(posedge pclk)
      cts = 1;

      @( posedge pclk )
      vsync = 1; // make vsync high to signal new start of frame

      @(posedge pclk)
      vsync = 0;

      @(posedge pclk)
      cts = 0;
      
      

      @(posedge pclk)
      cts = 0;

      
        

    end

    i2s_video_mono_el dut(
      .reset(reset),
      .mclk(pll_clk),
      .pclk(pclk),
      .i2s_bclk(bclk),
      .cts(cts),

      .v_sync(vsync),
      .datavalid(datavalid),

      .i2s_ws(i2s_ws),
      .i2s_data(i2s_data),

      .disp_data(pixeldata)


    );

endmodule