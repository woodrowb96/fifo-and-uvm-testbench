package tb_coverage_pkg;

  import tb_config::*;
  import uvm_pkg::*;
  import tb_item_pkg::*;
  `include "uvm_macros.svh"

  class coverage;
  //this class defines functional coverage for the testbench

  //the testbench should cover the following scenarios
    //rd and wr at same time
    //wr to full fifo
    //wr to empty fifo
    //rd from full fifo
    //rd from empty fifo
    //rd and wr at same time to full fifo
    //rd and wr at same time to an empty fifo

    Item m_item;

    covergroup cg;
      wr: coverpoint m_item.wr {
        bins en = {1};		//wr is enabled
        bins dis = {0};		//wr is disabled
      }
      rd: coverpoint m_item.rd {
        bins en = {1};		//rd is enabled
        bins dis = {0};		//rd is disabled
      }

      full: coverpoint m_item.full {
        bins t = {1};		//full is true
        bins f = {0};		//full is false
      }
      empty: coverpoint m_item.empty {
        bins t = {1};		//empty is true
        bins f = {0};		//empty is false
      }

      cross_cvg: cross rd,empty,wr,full {
        //rd and wr at same time
        bins rd_during_wr = binsof(wr.en) && binsof(rd.en);

        //wr to full and empty fifo
        bins wr_to_full = binsof(wr.en) && binsof(full.t);
        bins wr_to_empty = binsof(wr.en) && binsof(empty.t);

        //rd from empty and full fifo
        bins rd_from_empty = binsof(rd.en) && binsof(empty.t);
        bins rd_from_full = binsof(rd.en) && binsof(full.t);


        //rd and wr at same time to full and empty fifo
        bins rd_during_wr_to_full = binsof(wr.en) && binsof(rd.en) && binsof(full.t);
        bins rd_during_wr_from_empty = binsof(wr.en) && binsof(rd.en) && binsof(empty.t);

        //full and empty should never both be full at
        //same time
        illegal_bins empty_and_full = binsof(full.t) && binsof(empty.t);
      }
    endgroup

    function new();
      cg = new();
    endfunction

    function void sample(Item t);
    //subscriber can call this function to sample coverage
      m_item = t;
      cg.sample();
    endfunction
  endclass

endpackage
