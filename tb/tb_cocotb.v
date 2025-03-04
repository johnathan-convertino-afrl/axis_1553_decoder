//******************************************************************************
// file:    tb_coctb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/03/04
//
// about:   Brief
// Test bench wrapper for cocotb
//
// license: License MIT
// Copyright 2024 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: tb_cocotb
 *
 * This core is a MIL-STD-1553 to AXI streaming decoder.
 * It uses the postive edge of a clock to sample data.
 * This restricts the core to 2 Mhz and above for a sample clock.
 *
 * Parameters:
 *
 *   CLOCK_SPEED      - This is the aclk frequency in Hz, must be 2 MHz or above.
 *   SAMPLE_RATE      - 2 MHz or above rate that is an even divisor of CLOCK_SPEED
 *   BIT_SLICE_OFFSET - Changes the bit that is selected for data reduction.
 *   INVERT_DATA      - Will invert all decoded data.
 *   SAMPLE_SELECT    - Changes the bit that is sampled for data capture.
 *
 * Ports:
 *
 *   aclk           - Clock for all logic
 *   arstn          - Negative reset
 *   m_axis_tdata   - Output data for 1553 decoder.
 *   m_axis_tvalid  - When active high the output data is valid.
 *   m_axis_tuser   - Information about the AXIS data {TYY,NA,I,P}
 *
 *                    Bits explained below:
 *                  --- Code
 *                    - TYY = TYPE OF DATA
 *                          - 000 NA
 *                          - 001 REG (NOT IMPLIMENTED)
 *                          - 010 DATA
 *                          - 100 CMD/STATUS
 *                    - NA  = RESERVED FOR FUTURE USE.
 *                    - D   = DELAY BEFORE DATA
 *                          - 1 = Delay of 4us or more before data
 *                          - 0 = No delay between data
 *                    - P   = PARITY
 *                          - 1 = GOOD
 *                          - 0 = BAD
 *                  ---
 *
 *   m_axis_tready  - When active high the destination device is ready for data.
 *   diff           - Output data in TTL differential format.
 */
module tb_cocotb #(
    parameter CLOCK_SPEED = 20000000,
    parameter SAMPLE_RATE = 2000000,
    parameter BIT_SLICE_OFFSET = 0,
    parameter INVERT_DATA = 0,
    parameter SAMPLE_SELECT = 0
  )
  (
    input             aclk,
    input             arstn,
    output  [15:0]    m_axis_tdata,
    output            m_axis_tvalid,
    output  [ 7:0]    m_axis_tuser,
    input             m_axis_tready,
    input   [ 1:0]    diff
  );
  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end
  
  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, axis_1553_decoder
   */
   axis_1553_decoder #(
    .CLOCK_SPEED(CLOCK_SPEED),
    .SAMPLE_RATE(SAMPLE_RATE),
    .BIT_SLICE_OFFSET(BIT_SLICE_OFFSET),
    .INVERT_DATA(INVERT_DATA),
    .SAMPLE_SELECT(SAMPLE_SELECT)
  ) dut (
    .aclk(aclk),
    .arstn(arstn),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tuser(m_axis_tuser),
    .m_axis_tready(m_axis_tready),
    .diff(diff)
  );
  
endmodule

