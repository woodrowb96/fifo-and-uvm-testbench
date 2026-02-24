/*
This file is the top level module for the testbench

This file 
	Defines an interface, to connect DUT to Test
	Connects Test to DUT through interface
	Starts test
*/

import tb_tests::*;
import tb_config::*;
import uvm_pkg::*;

`include "uvm_macros.svh"

module tb_top;

	//define clock
	logic clk;
	always #(CLK_PERIOD * 0.5) clk <= ~clk;

	//interface
	tb_fifo_intf _if(clk);	

	//connect DUT to interface
	fifo #(LENGTH,WIDTH,ADDR_WIDTH) dut (
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

	initial begin
		clk <= 0;
		uvm_config_db#(virtual tb_fifo_intf)::set(null,"uvm_test_top","des_vif",_if);	//connect interface to test
		run_test("test_1");							//start test
	end
endmodule
