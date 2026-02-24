/*
The top level module for our uvm testbench
*/

import tb_tests::*;
import tb_config::*;
import uvm_pkg::*;

`include "uvm_macros.svh"

module tb_top;

  /********** CLK ************/
  logic clk;
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  /******** INTERFACE ********/
  tb_fifo_intf _if(clk);

  /******** DUT *************/
  fifo #(LENGTH, WIDTH, ADDR_WIDTH) dut (
    .clk(clk),
    .reset_n(_if.reset_n),
    .wr_data(_if.wr_data),
    .wr(_if.wr),
    .rd(_if.rd),
    .rd_data(_if.rd_data),
    .item_count(_if.item_count),
    .full(_if.full),
    .empty(_if.empty),
    .underflow(_if.underflow),
    .overflow(_if.overflow)
  );

  /*********** UVM TESTING ************/
  //hook the interface up to uvm_test and run
  initial begin
    uvm_config_db#(virtual tb_fifo_intf)::set(null,"uvm_test_top","des_vif",_if);
    run_test("test_1");
  end
endmodule
