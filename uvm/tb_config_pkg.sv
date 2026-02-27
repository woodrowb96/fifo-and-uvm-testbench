/*
This file holds our uvm tb configuration
*/
package tb_config_pkg;
  //clk config
  parameter CLK_PERIOD = 50;

  //dut config
  parameter WIDTH = 8;
  parameter LENGTH = 16;
  parameter ADDR_WIDTH = $clog2(LENGTH);

  //test config
  parameter NUM_TESTS = 1000;

endpackage
