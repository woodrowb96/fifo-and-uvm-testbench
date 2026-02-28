import tb_config_pkg::*;

interface tb_fifo_intf(input clk);
  logic reset_n;

  logic [WIDTH-1:0] wr_data;
  logic wr;
  logic rd;

  logic [WIDTH-1:0] rd_data;
  logic [$clog2(LENGTH):0] item_count;
  logic full;
  logic empty;
  logic underflow;
  logic overflow;

  clocking cb_drive @(posedge clk);
    default output #1;
    output wr_data, wr, rd;
  endclocking

  //cb_mon will monitor all the signals before cb_drive drieves the next item into the DUT
  clocking cb_mon @(posedge clk);
    default input #1step;
    input rd, wr, wr_data, rd_data, item_count, full, empty, underflow, overflow;
  endclocking
endinterface
