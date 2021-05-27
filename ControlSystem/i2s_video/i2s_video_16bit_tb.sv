module i2s_video_16bit_tb();

  logic pll_clk, pclk, bclk, reset, cts, vsync, datavalid;
  logic i2s_ws, i2s_data;
  reg [23:0] pixeldata;

    initial begin
      $dumpfile("i2s_video_16bit.vcd");
      $dumpvars(0,i2s_video_16bit_tb);

      pll_clk=0;
      pixeldata[23:0] = 24'h8fff7f; // r=1000, g=1111, b=0111
      vsync = 0;
      cts = 0;
      datavalid = 0;

      reset = 0;
      #1;
      reset = 1;
      #1;
      reset = 0;

      repeat (100) begin
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
      

      @(posedge pclk)
      cts = 1;

      @( posedge pclk )
      vsync = 1; // make vsync high to signal new start of frame

      @(posedge pclk)
      vsync = 0;

      @(posedge pclk)
      datavalid = 1; // signal datavalid
      

      @(posedge pclk)
      vsync = 1; // end of frame
      pixeldata = pixeldata + 1;
      
        

    end

    i2s_video_16bit dut(

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