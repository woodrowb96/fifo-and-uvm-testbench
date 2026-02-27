/*
The top level module for our uvm testbench
*/

import tb_tests_pkg::*;
import tb_config_pkg::*;
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
  tb_fifo_intf intf(clk);

  /******** DUT *************/
  fifo #(LENGTH, WIDTH) dut (
    .clk(clk),
    .reset_n(intf.reset_n),
    .wr_data(intf.wr_data),
    .wr(intf.wr),
    .rd(intf.rd),
    .rd_data(intf.rd_data),
    .item_count(intf.item_count),
    .full(intf.full),
    .empty(intf.empty),
    .underflow(intf.underflow),
    .overflow(intf.overflow)
  );

  /*********** UVM TESTING ************/
  //register 
  initial begin
    //register vif with config_db so test components can get it
    uvm_config_db#(virtual tb_fifo_intf)::set(null,"uvm_test_top","tb_fifo_vif",intf);
    run_test("test_1");
  end
endmodule
