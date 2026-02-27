package tb_item_pkg;
  import tb_config_pkg::*;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class Item extends uvm_sequence_item;
    `uvm_object_utils(Item)

    //input
    rand logic wr;
    rand logic [WIDTH-1:0]  wr_data;
    rand logic rd;

    //output
    logic [WIDTH-1:0] rd_data;
    logic [ADDR_WIDTH:0] item_count;
    logic empty;
    logic full;
    logic underflow;
    logic overflow;

    virtual function string convert2str();
      return $sformatf("wr=%0d, wr_data=%0d, rd=%0d, rd_data=%0d, item_count=%0d, empty=%0d,full=%0d, underflow=%0d, overflow=%0d",
          wr,wr_data,rd,rd_data,item_count,empty,full,underflow,overflow);
    endfunction

    function new(string name = "Item");
      super.new(name);
    endfunction
  endclass
endpackage
