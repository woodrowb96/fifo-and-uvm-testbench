/*
This contains our uvm tests for the testbech.
*/

package tb_tests;
  import tb_components::*;
  import tb_config::*;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  /************************ BASE TEST ******************************/
  class base_test extends uvm_test;

    //register the class with the uvm factory
    `uvm_component_utils(base_test)

    /**** MEMBER VARS *****/
    virtual tb_fifo_intf vif;
    env e0;
    gen_item_seq seq;

    /**** MEMBER FUNCTS/TESTS *****/
    //NEW
    function new(string name = "base_test",uvm_component parent = null);
      super.new(name, parent);
    endfunction

    //BUILD
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      //get an environment from the uvm factory
      e0 = env::type_id::create("e0",this);

      //get the vif handle and assign it to vif
      if(!uvm_config_db#(virtual tb_fifo_intf)::get(this, "","tb_fifo_vif",vif))
        `uvm_fatal("TEST", "Could not get vif")

      //agent a0 will use this vif
      uvm_config_db#(virtual tb_fifo_intf)::set(this,"e0.a0.*","tb_fifo_vif",vif);

      //get the sequence from the uvm factory
      seq = gen_item_seq::type_id::create("seq");

      //randomize the number of sequences we gen
      seq.randomize();
    endfunction	

    //RUN
    virtual task run_phase(uvm_phase phase);
      //start our objection
      phase.raise_objection(this);

      //our test
      apply_reset();            //reset the interface
      seq.start(e0.a0.s0);      //start generating sequences
      #(CLK_PERIOD*1.5)         //wait a bit, so the last trans can get processed

      //testing is done so drop our objection
      phase.drop_objection(this);
    endtask

    //RESET
    virtual task apply_reset();	
      //should probably move this into the interface
      vif.reset_n <= 0;
      repeat(1) @(posedge vif.clk);	
      vif.reset_n <= 1;
      repeat(1) @(posedge vif.clk);	
    endtask
  endclass

  /************************ TEST 1 ******************************/
  class test_1 extends base_test;
    `uvm_component_utils(test_1)

    function new(string name = "test_1",uvm_component parent = null);
      super.new(name,parent);
    endfunction

    //BUILD
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      seq.randomize() with { num == NUM_TESTS; };
    endfunction
  endclass
endpackage
