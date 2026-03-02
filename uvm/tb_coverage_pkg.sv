package tb_coverage_pkg;
  import tb_config_pkg::*;
  import uvm_pkg::*;
  import tb_item_pkg::*;
  `include "uvm_macros.svh"

  class coverage;

    Item m_item;

    covergroup cg;
      //we want to cover writting and reading into the fifo
      wr: coverpoint m_item.wr {
        bins en = {1};
        bins dis = {0};
      }
      rd: coverpoint m_item.rd {
        bins en = {1};
        bins dis = {0};
      }

      //We want to cover the following interesting rd wr crosses
      wr_x_rd: cross wr, rd {
        bins rd_during_wr = binsof(rd.en) && binsof(wr.en);
        bins rd_only      = binsof(rd.en) && binsof(wr.dis);
        bins wr_only      = binsof(rd.dis) && binsof(wr.en);
        bins neither      = binsof(rd.dis) && binsof(wr.dis);
      }

      //We want to write and read all_ones, all_zeros.
      wr_data: coverpoint m_item.wr_data iff(m_item.wr) {
        bins all_ones = {'1};
        bins all_zero = {'0};
        bins others = default;
      }
      rd_data: coverpoint m_item.rd_data iff(m_item.rd) {
        bins all_ones = {'1};
        bins all_zero = {'0};
        bins others = default;
      }

      //We want to the following item_count corners
      item_count: coverpoint m_item.item_count {
        bins empty = {'0};
        bins almost_full = {LENGTH - 1};
        bins full = {LENGTH};

        //we want to go from full-to-empty, and empty-to-full at some point in testing
        //  -Note: This isnt a linear sweep, when we are in the [*1:$] section
        //         we can go up and down. We just want to cover going from
        //         full-to-empty and empty-to-full, without much care how we
        //         get there, just that we started at 0 and went up to LENGTH,
        //         and vice versa.
        // bins full_to_empty = ('0 => [1:LENGTH-1][*1:$] => LENGTH);
        // bins empty_to_full = (LENGTH => [1:LENGTH-1][*1:$] => '0);

        /******************* VIVADO BUG ****************************/
        //I have the above transitions commented out. They compile and
        //elaborate fine, but during simulation I get the following seemingly
        //unrelated message:
        //      ERROR: unexpected exception when evaluating tcl command
        //        while executing
        //        "write_xsim_coverage"
        //I dont know? I know its those two lines, because it goes away when
        //they get commented out. The tcl file seems unrelated to all this so 
        //it must maybe be some weird bug? I dont know, for now ill comment it 
        //out even though id like to cover it.
        /************************************************************/
      }

      //we want to cross item_count with all combos of readin and writting
      rd_x_wr_item_count: cross rd, wr, item_count;

      //We want to:
      //  - cover having a full and an empty fifo.
      //
      //We want to:
      //  - assert the flag, then reassert it at some later point
      full: coverpoint m_item.full {
        bins t = {1};
        bins f = {0};

        //transitions
        bins reassert = (1 => 0[*1:$] => 1);  //1 then 0, then at any later point 1 again
      }
      empty: coverpoint m_item.empty {
        bins t = {1};
        bins f = {0};

        //transitions
        bins reassert = (1 => 0[*1:$] => 1);  //1 then 0, then at any later point 1 again
      }

      //we want to write and read from full and empty fifos
      wr_to_full: coverpoint (m_item.wr && m_item.full) {
        bins hit = {1};
      }
      rd_from_empty: coverpoint (m_item.rd && m_item.empty) {
        bins hit = {1};
      }
      wr_to_empty: coverpoint (m_item.wr && m_item.empty) {
        bins hit = {1};
      }
      rd_from_full: coverpoint (m_item.rd && m_item.full) {
        bins hit = {1};
      }

      //we want to:
      //  - rd during a write to full (wont cause an overflow)
      //  - !rd during a write to full (will cause an overflow)
      rd_x_wr_to_full: cross rd, wr_to_full {
        bins rd_en = binsof(wr_to_full.hit) && binsof(rd.en);
        bins rd_dis = binsof(wr_to_full.hit) && binsof(rd.dis);
      }

      //we want to:
      //  - wr during a read from empty (write suceeds, item_count++, causes an underflow)
      //  - !wr during a read from empty (item_count stable, causes an underflow)
      wr_x_rd_from_empty: cross wr, rd_from_empty {
        bins wr_en = binsof(rd_from_empty.hit) && binsof(wr.en);
        bins wr_dis = binsof(rd_from_empty.hit) && binsof(wr.dis);
      }

      //We want to:
      //  - overflow and underflow the fifo
      //
      //We want to:
      //  - assert overflow, then deassert, then reassert each flag
      //  - hit back to back over/underflows for each flag
      //
      //Note: The Over/underflow flags are only asserted for 1 clk cycle.
      //      So both transition bins check transitions on back-to-back clk cycles,
      //      since that is the interesting corner behavior for the 
      //      over/underflow flags. (vs doing 1=>0[*1:$]=>1 like in the full flag)
      overflow: coverpoint m_item.overflow {
        bins t = {1};
        bins f = {0};

        //transitions
        bins reassert = (1 => 0 => 1);
        bins back_to_back = (1[*2]);
      }
      underflow: coverpoint m_item.underflow {
        bins t = {1};
        bins f = {0};

        //transitions
        bins reassert = (1 => 0 => 1);
        bins back_to_back = (1[*2]);
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
