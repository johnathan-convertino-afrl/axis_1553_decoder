//******************************************************************************
/// @file    tb_1553_dec.v
/// @author  JAY CONVERTINO
/// @date    2021.05.25
/// @brief   SIMPLE TEST BENCH FOR 1553... THIS NEEDS MORE... STUFF. 8^)
///
/// @LICENSE MIT
///  Copyright 2021 Jay Convertino
///
///  Permission is hereby granted, free of charge, to any person obtaining a copy
///  of this software and associated documentation files (the "Software"), to 
///  deal in the Software without restriction, including without limitation the
///  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
///  sell copies of the Software, and to permit persons to whom the Software is 
///  furnished to do so, subject to the following conditions:
///
///  The above copyright notice and this permission notice shall be included in 
///  all copies or substantial portions of the Software.
///
///  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
///  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
///  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
///  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
///  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
///  IN THE SOFTWARE.
//******************************************************************************

`timescale 1 ns/10 ps

module tb_1553;
  
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;
  reg  [1:0]  tb_din;
  wire [15:0] tb_tdata;
  wire        tb_tvalid;
  wire [7:0]  tb_tuser;
  wire        tb_tready;
  
  //1ns
  localparam CLK_PERIOD = 10;
  localparam RST_PERIOD = 1000;
  localparam CLK_SPEED_HZ = 1000000000/CLK_PERIOD;
  localparam BITS_PER_TRANS = 20 * 1000/CLK_PERIOD;
  localparam DELAY_COUNT = 0;
  
  //calculate the number of cycles the clock changes per period
  localparam integer CYCLES_PER_MHZ = CLK_SPEED_HZ / 1000000;
  //bit rate per mhz
  localparam integer BIT_RATE_PER_MHZ = CYCLES_PER_MHZ;
  //sync pulse length
  localparam integer SYNC_PULSE_LEN = BIT_RATE_PER_MHZ * 3;
  //create the bit pattern. This is based on outputing data on the negative and
  //positive. This allows the encoder to run down to 1 mhz.
  localparam [(BIT_RATE_PER_MHZ)-1:0]BIT_PATTERN = {{BIT_RATE_PER_MHZ/2{1'b1}}, {BIT_RATE_PER_MHZ/2{1'b0}}};
  //synth clock is the clock constructed by the repeating the bit pattern. 
  //this is intended to be a representation of the clock. Captured at a BIT_RATE_PER_MHZ of a 1mhz clock.
  localparam [BITS_PER_TRANS-1:0]SYNTH_CLK = {BITS_PER_TRANS{BIT_PATTERN}};
  //sync pulse
  localparam [SYNC_PULSE_LEN-1:0]sync_cmd_stat = {{SYNC_PULSE_LEN/2{1'b0}}, {SYNC_PULSE_LEN/2{1'b1}}};
  localparam [SYNC_PULSE_LEN-1:0]sync_data     = {{SYNC_PULSE_LEN/2{1'b1}}, {SYNC_PULSE_LEN/2{1'b0}}};
  
  reg [(16*BIT_RATE_PER_MHZ)-1:0] data_expand = 0;
  reg [15:0]                      data = 0;
  reg [BITS_PER_TRANS-1:0]        reg_data = 0;
  reg                             parity_gen = 0;
  
  //for loop indexs
  integer xor_index;
  integer cycle_index;
  
  integer pos_counter = 0;
  
  integer delay_counter = DELAY_COUNT;
  
  //device under test
  axis_1553_decoder #(
    .CLOCK_SPEED(CLK_SPEED_HZ),
    .SAMPLE_RATE(2000000)
  ) dut (
    .aclk(tb_data_clk),
    .arstn(~tb_rst),
    //master output
    .m_axis_tdata(tb_tdata),
    .m_axis_tvalid(tb_tvalid),
    .m_axis_tuser(tb_tuser),
    .m_axis_tready(tb_tready),
    //diff input
    .diff(tb_din)
  );
  
  //will only write tdata, not tuser
  master_axis_stimulus #(
    .BUS_WIDTH(2),
    .USER_WIDTH(8),
    .DEST_WIDTH(1),
    .FILE("out.bin")
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_data_clk),
    .s_axis_arstn(~tb_rst),
    .s_axis_tvalid(tb_tvalid),
    .s_axis_tready(tb_tready),
    .s_axis_tdata(tb_tdata),
    .s_axis_tkeep(2'b11),
    .s_axis_tlast(1'b0),
    .s_axis_tuser(tb_tuser),
    .s_axis_tdest(1'b0),
    .eof(1'b0)
  );
    
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  // produce 1553 data
  // first will be FFFF, after a delay count, then 0, then 1 and so on.
  // The previous value in data is the one currently being sent.
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      tb_din        <= 2'b11;
      pos_counter   <= 0;
      delay_counter <= DELAY_COUNT;
      data          <= ~0;
      data_expand   <= 0;
      reg_data      <= 0;
      parity_gen    <= 0;
    end else begin
      
      if(pos_counter == 0) begin
        pos_counter <= 0;
        
        if(delay_counter != DELAY_COUNT) begin
          tb_din <= ~0;
        end
        
        parity_gen <= ~(^data);
        
        //expand data for xor
        for(xor_index = 0; xor_index < 16; xor_index = xor_index + 1) begin
          for(cycle_index = (BIT_RATE_PER_MHZ*xor_index); cycle_index < (BIT_RATE_PER_MHZ*xor_index)+(BIT_RATE_PER_MHZ); cycle_index = cycle_index + 1)
            data_expand[cycle_index] <= data[xor_index];
        end
        
        delay_counter <= delay_counter - 1;
        if(delay_counter == 0) begin
          delay_counter <= DELAY_COUNT;
          pos_counter <= BITS_PER_TRANS-1;
          
          data <= data + 1;
          
          reg_data <= {sync_cmd_stat, data_expand, {BIT_RATE_PER_MHZ{parity_gen}}} ^ SYNTH_CLK;
          
          reg_data[BITS_PER_TRANS-1:BITS_PER_TRANS-SYNC_PULSE_LEN] <= sync_data;
          
          if(^data == 1'b1) begin
            reg_data[BITS_PER_TRANS-1:BITS_PER_TRANS-SYNC_PULSE_LEN] <= sync_cmd_stat;
          end
        end
      end else begin
        tb_din[0] <= reg_data[pos_counter];
        tb_din[1] <= ~reg_data[pos_counter];
        
        pos_counter <= pos_counter - 1;
      end
    end
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_1553_dec.fst");
    $dumpvars(0,tb_1553);
  end
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #10_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule

