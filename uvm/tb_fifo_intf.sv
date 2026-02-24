import tb_config::*;

interface tb_fifo_intf(input clk);
  logic reset_n;

  logic [WIDTH-1:0] wr_data;
  logic wr;
  logic rd;

  logic [WIDTH-1:0] rd_data;
  logic [ADDR_WIDTH:0] item_count;
  logic full;
  logic empty;
  logic underflow;
  logic overflow;

  clocking cb @(posedge clk);
    default input #0 output #1;
    output wr_data, wr, rd;
    input rd_data, item_count, full, empty, underflow, overflow;
  endclocking
endinterface
