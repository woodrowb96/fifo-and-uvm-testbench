/*
This file contains components used to construct a constrained random test bench using uvm.
*/
package tb_components_pkg;
  import tb_config::*;
  import uvm_pkg::*;
  import ref_fifo::*;
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

      //connect the virtual interface
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
      @(vif.cb);
      vif.cb.wr <= m_item.wr;
      vif.cb.wr_data <= m_item.wr_data;
      vif.cb.rd <= m_item.rd;
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
        @(vif.cb);
        //make sure we are not reseting
        if(vif.reset_n) begin
          Item item = Item::type_id::create("item");
          item.wr = vif.wr;
          item.wr_data = vif.wr_data;
          item.rd = vif.rd;
          item.rd_data = vif.cb.rd_data;
          item.item_count = vif.cb.item_count;
          item.full = vif.cb.full;
          item.empty = vif.cb.empty;
          item.underflow = vif.cb.underflow;
          item.overflow = vif.cb.overflow;

          //send item to scoreboard
          mon_analysis_port.write(item);
          `uvm_info("MON",$sformatf("Saw item %s",item.convert2str()),UVM_HIGH)
        end
      end
    endtask
  endclass

  class funct_cov_subscriber extends uvm_subscriber #(Item);
  //this class is a subscriber to the monitors analysis_port
  //it is used to collect coverage, using items that appear on the port

    `uvm_component_utils(funct_cov_subscriber)

    typedef uvm_subscriber #(Item) this_type;

    uvm_analysis_imp #(Item, this_type) analysis_export;	//will get connected to monitor analysis port

    coverage funct_cov;

    function new(string name, uvm_component parent);
      super.new(name,parent);
      analysis_export = new("analysis_export",this);
      funct_cov = new();
    endfunction

    function void write(Item t);
    //when write is called sample coverage, using item on
    //analysis_port
      funct_cov.sample(t);
    endfunction
  endclass

  class scoreboard extends uvm_scoreboard;
  //this is the testbenches scoreboard
  //it compares items recieved from monitor
  //to a reference DUT to determine correctness of DUT
    `uvm_component_utils(scoreboard)

    function new(string name = "scoreboard",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    //////vals/////

    ref_fifo #(LENGTH) exp_fifo;	//reference fifo

    uvm_analysis_imp #(Item,scoreboard) m_analysis_imp;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      m_analysis_imp = new("m_analysis_imp",this);

      exp_fifo = new();
    endfunction

    virtual function void write(Item item);
    //this function compares the item sent from monitor to
    //the reference fifo
    //It also uses the item to update the reference fifo

      `uvm_info("SCB",$sformatf("%s",item.convert2str()),UVM_LOW);	//display item values

      //check that item output matches, reference fifo output
      //If it does not match, output an error and
      //terminate the sim, using uvm_fatal
      if(item.underflow != exp_fifo.underflow)
        `uvm_fatal("SCB",$sformatf("Error! exp_underflow=%0d, underflow=%0d",exp_fifo.underflow,item.underflow));

      if(item.overflow != exp_fifo.overflow)
        `uvm_fatal("SCB",$sformatf("Error! exp_overflow=%0d, overflow=%0d",exp_fifo.overflow,item.overflow));

      if(item.rd_data != exp_fifo.rd_data)
        `uvm_fatal("SCB",$sformatf("Error! exp_rd_data=%0d, rd_data=%0d",exp_fifo.rd_data,item.rd_data));

      if(item.underflow != exp_fifo.underflow)
        `uvm_fatal("SCB",$sformatf("Error! exp_underflow=%0d, underflow=%0d",exp_fifo.underflow,item.underflow));
      if(item.overflow != exp_fifo.overflow)
        `uvm_fatal("SCB",$sformatf("Error! exp_overflow=%0d, overflow=%0d",exp_fifo.overflow,item.overflow));

      if(item.item_count != exp_fifo.item_count)
        `uvm_fatal("SCB",$sformatf("Error! exp_item_count=%0d, item_count=%0d",exp_fifo.item_count,item.item_count));

      if(item.full != exp_fifo.full)
        `uvm_fatal("SCB",$sformatf("Error! exp_full=%0d, full=%0d",exp_fifo.full,item.full));

      if(item.empty != exp_fifo.empty)
        `uvm_fatal("SCB",$sformatf("Error! exp_empty=%0d, empty=%0d",exp_fifo.empty,item.empty));

      //if item output matched ref_fifo output, then the
      //design passed
      `uvm_info("SCB",$sformatf("PASS!"),UVM_LOW);

      exp_fifo.update(item.wr,item.rd,item.wr_data);	//update the reference fifo

    endfunction
  endclass

  class agent extends uvm_agent;
  //this class is the testbenches agent
    `uvm_component_utils(agent)

    function new(string name = "agent",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    driver	d0;
    monitor	m0;
    uvm_sequencer #(Item) s0;

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      s0 = uvm_sequencer#(Item)::type_id::create("s0",this);
      d0 = driver::type_id::create("d0",this);
      m0 = monitor::type_id::create("m0",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      d0.seq_item_port.connect(s0.seq_item_export);	//connect driver to sequencer
    endfunction
  endclass

  class env extends uvm_env;
  //this class holds the testbenches environment
    `uvm_component_utils(env)

    function new(string name = "env",uvm_component parent=null);
      super.new(name,parent);
    endfunction

    agent	a0;
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
      a0.m0.mon_analysis_port.connect(sb0.m_analysis_imp);	//connect monitor and scoreboard
      a0.m0.mon_analysis_port.connect(fc0.analysis_export);	//connect monitor and functional cov subscriber
    endfunction
  endclass

endpackage
