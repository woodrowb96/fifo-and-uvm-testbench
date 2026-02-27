package tb_coverage_pkg;
  import tb_config_pkg::*;
  import uvm_pkg::*;
  import tb_item_pkg::*;
  `include "uvm_macros.svh"

  class coverage;

    Item m_item;

    covergroup cg;

      wr: coverpoint m_item.wr {
        bins en = {1};
        bins dis = {0};
      }
      rd: coverpoint m_item.rd {
        bins en = {1};
        bins dis = {0};
      }

      full: coverpoint m_item.full {
        bins t = {1};
        bins f = {0};
      }
      empty: coverpoint m_item.empty {
        bins t = {1};
        bins f = {0};
      }

      //cross to get corner cases
      cross_cvg: cross rd,empty,wr,full {

        //we want to read and write at the same time
        bins rd_during_wr = binsof(wr.en) && binsof(rd.en);

        //we want to wr to a full and empty fifo
        bins wr_to_full = binsof(wr.en) && binsof(full.t);
        bins wr_to_empty = binsof(wr.en) && binsof(empty.t);

        //we want to read from a full and empty fifo
        bins rd_from_empty = binsof(rd.en) && binsof(empty.t);
        bins rd_from_full = binsof(rd.en) && binsof(full.t);

        //we want to read during a write to a full fifo
        bins rd_during_wr_to_full = binsof(wr.en) && binsof(rd.en) && binsof(full.t);

        //we want to read during write to an empty fifo
        bins rd_during_wr_from_empty = binsof(wr.en) && binsof(rd.en) && binsof(empty.t);

        //we cant have a fifo that is full and empty at the same time
        illegal_bins empty_and_full = binsof(full.t) && binsof(empty.t);
      }
    endgroup

    function new();
      cg = new();
    endfunction

    function void sample(Item t);
      m_item = t;
      cg.sample();
    endfunction
  endclass
endpackage
