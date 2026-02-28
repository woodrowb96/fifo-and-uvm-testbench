/*
This file contains components used to construct a constrained random test bench using uvm.
*/
package tb_components_pkg;
  import tb_config_pkg::*;
  import uvm_pkg::*;
  import fifo_ref_model_pkg::*;
  import tb_item_pkg::*;
  import tb_coverage_pkg::*;
  `include "uvm_macros.svh"

  /**********************************  SEQUENCE  *********************************/

  class gen_item_seq extends uvm_sequence;
    `uvm_object_utils(gen_item_seq)

    function new(string name = "gen_item_seq");
      super.new(name);
    endfunction

    //let num be rand here, and let test constrain it however it wants
    rand int num;

    //soft constraint can be overwritten later
    constraint c1 { soft num inside {[10:50]}; }

    //randomize items and send to driver
    virtual task body();
      for(int i=0;i<num;i++) begin

        //create item with UVMs factory
        Item m_item = Item::type_id::create("m_item");

        //start_item handshake with the driver and sequencer
        start_item(m_item);

        //randomize the item
        m_item.randomize();
        `uvm_info("SEQ",$sformatf("Generate new item: %s",m_item.convert2str()),UVM_HIGH)

        //tell driver and sequencer the item is ready
        finish_item(m_item);
      end
      `uvm_info("SEQ",$sformatf("Done generating %0d items",num),UVM_HIGH)
    endtask

  endclass

  /***********************  DRIVER *****************************/

  class driver extends uvm_driver #(Item);
    `uvm_component_utils(driver)

    function new(string name = "driver",uvm_component parent=null);
      super.new(name, parent);
    endfunction

    virtual tb_fifo_intf vif;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if(!uvm_config_db#(virtual tb_fifo_intf)::get(this, "","tb_fifo_vif",vif))
        `uvm_fatal("DRV", "Could not get vif")
    endfunction

    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);

      //loop, get items from the sequencer, drive them onto the interface
      forever begin
        Item m_item;
        `uvm_info("DRV",$sformatf("WAIT for item from sequence"),UVM_HIGH)
        seq_item_port.get_next_item(m_item);
        drive_item(m_item);
        seq_item_port.item_done();
      end
    endtask

    virtual task drive_item(Item m_item);
      @(vif.cb_drive);
      vif.cb_drive.wr <= m_item.wr;
      vif.cb_drive.wr_data <= m_item.wr_data;
      vif.cb_drive.rd <= m_item.rd;
    endtask
  endclass

  /***********************  MONITOR *****************************/

  class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    function new(string name = "monitor",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    //port to broadcast items to scareboard
    uvm_analysis_port #(Item) mon_analysis_port;

    virtual tb_fifo_intf vif;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      //hook up the vif
      if(!uvm_config_db#(virtual tb_fifo_intf)::get(this, "","tb_fifo_vif",vif))
        `uvm_fatal("MON", "Could not get vif")

      //create a new analysis port
      mon_analysis_port = new("mon_analysis_port",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);

      //loop, read the signals into an item, brodcast the item to the scoreboard
      forever begin
        @(vif.cb_mon);
        //make sure we are not reseting
        if(vif.reset_n) begin
          Item item = Item::type_id::create("item");
          //sample DUT inputs
          item.wr = vif.cb_mon.wr;
          item.wr_data = vif.cb_mon.wr_data;
          item.rd = vif.cb_mon.rd;
          //sample DUT outputs
          item.rd_data = vif.cb_mon.rd_data;
          item.item_count = vif.cb_mon.item_count;
          item.full = vif.cb_mon.full;
          item.empty = vif.cb_mon.empty;
          item.underflow = vif.cb_mon.underflow;
          item.overflow = vif.cb_mon.overflow;

          //send item to scoreboard
          mon_analysis_port.write(item);
          `uvm_info("MON",$sformatf("Saw item %s",item.convert2str()),UVM_HIGH)
        end
      end
    endtask
  endclass

  /****************** SUBSCRIBER *******************************************/

  class funct_cov_subscriber extends uvm_subscriber #(Item);

    `uvm_component_utils(funct_cov_subscriber)

    typedef uvm_subscriber #(Item) this_type;

    //analysis implementation, so we can recieve items and write to coverage
    uvm_analysis_imp #(Item, this_type) analysis_export;

    //our coverage
    coverage funct_cov;

    function new(string name, uvm_component parent);
      super.new(name,parent);
      analysis_export = new("analysis_export",this);
      funct_cov = new();
    endfunction

    //sample our coverage
    function void write(Item t);
      funct_cov.sample(t);
    endfunction
  endclass

  /***************** SCOREBOARD ************************************/

  class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    function new(string name = "scoreboard",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    //our reference model to score each item
    fifo_ref_model #(LENGTH, WIDTH) exp_fifo;

    //analysis implementation so we can recieve items from monitor and write() our tests
    uvm_analysis_imp #(Item,scoreboard) m_analysis_imp;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_analysis_imp = new("m_analysis_imp",this);
      exp_fifo = new();
    endfunction

    //score our item using the ref model
    virtual function void write(Item item);
      `uvm_info("SCB",$sformatf("%s",item.convert2str()),UVM_HIGH);

      //score each signal in item against the expected val from the ref_model
      if(item.underflow != exp_fifo.underflow) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_underflow=%0d, underflow=%0d",exp_fifo.underflow,item.underflow));
      end
      if(item.overflow != exp_fifo.overflow) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_overflow=%0d, overflow=%0d",exp_fifo.overflow,item.overflow));
      end
      if(item.rd_data != exp_fifo.rd_data) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_rd_data=%0d, rd_data=%0d",exp_fifo.rd_data,item.rd_data));
      end
      if(item.item_count != exp_fifo.item_count) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_item_count=%0d, item_count=%0d",exp_fifo.item_count,item.item_count));
      end
      if(item.full != exp_fifo.full) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_full=%0d, full=%0d",exp_fifo.full,item.full));
      end
      if(item.empty != exp_fifo.empty) begin
        `uvm_fatal("SCB",$sformatf("Error! exp_empty=%0d, empty=%0d",exp_fifo.empty,item.empty));
      end

      `uvm_info("SCB",$sformatf("PASS!"),UVM_LOW);


      //update the ref fifo
      exp_fifo.update(item.wr,item.rd,item.wr_data);
    endfunction
  endclass

  /******************* AGENT *************************************/

  class agent extends uvm_agent;
    `uvm_component_utils(agent)

    function new(string name = "agent",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    driver d0;
    monitor m0;
    uvm_sequencer #(Item) s0;  //a sequencer to coordinate sending the sequence to driver

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      //get each component from the UVM factory
      s0 = uvm_sequencer#(Item)::type_id::create("s0",this);
      d0 = driver::type_id::create("d0",this);
      m0 = monitor::type_id::create("m0",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

      //hook the sequencer to driver
      d0.seq_item_port.connect(s0.seq_item_export);
    endfunction
  endclass

  /*********************   ENV ********************************************/

  class env extends uvm_env;
    `uvm_component_utils(env)

    function new(string name = "env",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    agent a0;
    scoreboard sb0;
    funct_cov_subscriber fc0;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      a0 = agent::type_id::create("a0",this);
      sb0 = scoreboard::type_id::create("sb0",this);
      fc0 = funct_cov_subscriber::type_id::create("fc0",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      a0.m0.mon_analysis_port.connect(sb0.m_analysis_imp);
      a0.m0.mon_analysis_port.connect(fc0.analysis_export);
    endfunction
  endclass
endpackage
