module fifo_assert #(parameter int LENGTH = 16, parameter int WIDTH = 8)
(
  input logic clk,
  input logic reset_n,

  //DUT control
  input logic wr,
  input logic rd,

  //DUT input
  input logic [WIDTH-1:0] wr_data,

  //DUT output
  input logic [WIDTH-1:0] rd_data,
  input logic [$clog2(LENGTH):0] item_count,

  //DUT output flags
  input logic full,
  input logic empty,
  input logic underflow,
  input logic overflow
);
  /************* RESET ASSERTS ****************************/
  //NOTE: All the resets are asyncrounous. For now I chose just to check the
  //      resets using properties synced to the clk. I will look into more
  //      robust solutions later.

  //We want to make sure all the signals get reset to the right value
  property wr_addr_reset_prop;
    @(posedge clk)
    (!reset_n) |-> fifo.wr_addr == 'd0;
  endproperty

  wr_addr_reset_assert: assert property(wr_addr_reset_prop) else
    $error("[FIFO_ASSERT] (wr_addr_reset_assert): wr_addr was not reset to 0, wr_addr = %0d", fifo.wr_addr);

  property rd_addr_reset_prop;
    @(posedge clk)
    (!reset_n) |-> fifo.rd_addr == 'd0;
  endproperty

  rd_addr_reset_assert: assert property(rd_addr_reset_prop) else
    $error("[FIFO_ASSERT] (rd_addr_reset_assert): rd_addr was not reset to 0, rd_addr = %0d", fifo.rd_addr);

  property rd_data_reset_prop;
    @(posedge clk)
    (!reset_n) |-> rd_data == 'd0;
  endproperty

  rd_data_reset_assert: assert property(rd_data_reset_prop) else
    $error("[FIFO_ASSERT] (rd_data_reset_assert): rd_data was not reset to 0, rd_data = %0d", rd_data);

  property item_count_reset_prop;
    @(posedge clk)
    (!reset_n) |-> item_count == 'd0;
  endproperty

  item_count_reset_assert: assert property(item_count_reset_prop) else
    $error("[FIFO_ASSERT] (item_count_reset_assert): item_count was not reset to 0, item_count = %0d", item_count);

  property overflow_reset_prop;
    @(posedge clk)
    (!reset_n) |-> overflow == 'd0;
  endproperty

  overflow_reset_assert: assert property(overflow_reset_prop) else
    $error("[FIFO_ASSERT] (overflow_reset_assert): overflow was not reset to 0");

  property underflow_reset_prop;
    @(posedge clk)
    (!reset_n) |-> underflow == 'd0;
  endproperty

  underflow_reset_assert: assert property(underflow_reset_prop) else
    $error("[FIFO_ASSERT] (underflow_reset_assert): underflow was not reset to 0");

  /************ FULL FLAG ASSERTS ***********************/

  //we want to make sure the full flag is set and unset properly
  property full_high_prop;
    @(posedge clk) disable iff(!reset_n)
    (item_count == LENGTH) |-> full;
  endproperty

  property full_low_prop;
    @(posedge clk) disable iff(!reset_n)
    (item_count != LENGTH) |-> !full;
  endproperty

  full_high_assert: assert property(full_high_prop) else
    $error("[FIFO_ASSERT] (full_high_assert): full was not set, item_count = %0d", item_count);

  full_low_assert: assert property(full_low_prop) else
    $error("[FIFO_ASSERT] (full_low_assert): full was set incorrectly, item_count = %0d", item_count);

  /************ EMPTY FLAG ASSERTS ***********************/

  //we want to make sure the empty flag is set and unset properly
  property empty_high_prop;
    @(posedge clk) disable iff(!reset_n)
    (item_count == 'd0) |-> empty;
  endproperty

  property empty_low_prop;
    @(posedge clk) disable iff(!reset_n)
    (item_count != 'd0) |-> !empty;
  endproperty

  empty_high_assert: assert property(empty_high_prop) else
    $error("[FIFO_ASSERT] (empty_high_assert): empty was not set, item_count = %0d", item_count);

  empty_low_assert: assert property(empty_low_prop) else
    $error("[FIFO_ASSERT] (empty_low_assert): empty was set incorrectly, item_count = %0d", item_count);

  /************ WR_ADDR ASSERTS ***********************/

  //we want to make sure wr_addr doesnt exeed the upper bound
  property wr_upper_bound_prop;
    @(posedge clk)
    fifo.wr_addr <= LENGTH - 1;
  endproperty

  wr_upper_bound_assert: assert property(wr_upper_bound_prop) else
    $error("[FIFO_ASSERT] (wr_upper_bound_assert): wr_addr > (LENGTH - 1), wr_addr = %0d", fifo.wr_addr);

  //we want to make sure wr_addr increments properly
  property wr_addr_inc_prop;
    @(posedge clk) disable iff(!reset_n)
    ((wr && (~full || rd)) && (fifo.wr_addr != LENGTH - 1)) |=> (fifo.wr_addr == ($past(fifo.wr_addr) + 'd1));
  endproperty

  wr_inc_assert: assert property(wr_addr_inc_prop) else
    $error("[FIFO_ASSERT] (wr_inc_assert): wr_addr did not increment, wr_addr = %0d", fifo.wr_addr);

  //we want to make sure wr_addr wraps to 0, when it gets to the last buffer addr
  property wr_addr_wrap_prop;
    @(posedge clk) disable iff(!reset_n)
    ((wr && (~full || rd)) && (fifo.wr_addr == LENGTH - 1)) |=> (fifo.wr_addr == 'd0);
  endproperty

  wr_wrap_assert: assert property(wr_addr_wrap_prop) else
    $error("[FIFO_ASSERT] (wr_wrap_assert): wr_addr did not wrap to 0, wr_addr = %0d", fifo.wr_addr);

  /************ RD_ADDR ASSERTS ***********************/

  property rd_upper_bound_prop;
    @(posedge clk)
    fifo.rd_addr <= LENGTH - 1;
  endproperty

  rd_upper_bound_assert: assert property(rd_upper_bound_prop) else
    $error("[FIFO_ASSERT] (rd_upper_bound_assert): rd_addr > (LENGTH - 1), rd_addr = %0d", fifo.rd_addr);

  property rd_addr_inc_prop;
    @(posedge clk) disable iff(!reset_n)
    ((rd && ~empty) && (fifo.rd_addr != LENGTH - 1)) |=> (fifo.rd_addr == ($past(fifo.rd_addr) + 'd1));
  endproperty

  rd_inc_assert: assert property(rd_addr_inc_prop) else
    $error("[FIFO_ASSERT] (rd_inc_assert): rd_addr did not increment, rd_addr = %0d", fifo.rd_addr);

  property rd_addr_wrap_prop;
    @(posedge clk) disable iff(!reset_n)
    ((rd && ~empty) && (fifo.rd_addr == LENGTH - 1)) |=> (fifo.rd_addr == 'd0);
  endproperty

  rd_wrap_assert: assert property(rd_addr_wrap_prop) else
    $error("[FIFO_ASSERT] (rd_wrap_assert): rd_addr did not wrap to 0, rd_addr = %0d", fifo.rd_addr);

  /***********************  WRITE ASSERT *******************************************/

  //we want to make sure we write into the fifo properly
  property write_prop;
    @(posedge clk) disable iff(!reset_n)
    (wr && (~full || rd)) |=> (fifo.buffer[$past(fifo.wr_addr)] == $past(wr_data));
  endproperty

  write_assert: assert property(write_prop) else
    $error("[FIFO_ASSERT] (write_assert): data was not written to buffer correctly");

  /***********************  READ ASSERT *******************************************/

  //We need to get the expected rd_data from the buffer
  //  - I tried doing this with nested $past()s in the property, but xelab
  //    would elaborate it
  logic [WIDTH-1:0] expected_buffer_data;
  always_ff @(posedge clk) begin
    expected_buffer_data <= fifo.buffer[fifo.rd_addr];
  end

  //we want to make sure we read from the fifo properly
  property read_prop;
    @(posedge clk) disable iff(!reset_n)
    (rd && ~empty) |=> (rd_data == expected_buffer_data);
  endproperty

  read_assert: assert property(read_prop) else
    $error("[FIFO_ASSERT] (read_assert): data was not read from buffer correctly");

  /************  OVERFLOW ASSERT *******************************************/

  //make sure overflow gets set on the next clk cycle
  property overflow_high_prop;
    @(posedge clk) disable iff(!reset_n)
    (full && wr && !rd) |=> overflow;
  endproperty

  overflow_high_assert: assert property(overflow_high_prop) else
    $error("[FIFO_ASSERT] (overflow_high_assert): overflow was not set");

  //make sure overflow gets is not set on the next clk cycle
  property overflow_low_prop;
    @(posedge clk) disable iff(!reset_n)
    (!full || !wr || rd) |=> !overflow;
  endproperty

  overflow_low_assert: assert property(overflow_low_prop) else
    $error("[FIFO_ASSERT] (overflow_low_assert): overflow was set incorrectly");

  /************  UNDERFLOW ASSERT *******************************************/

  //make sure underflow gets set on the next clk cycle
  property underflow_high_prop;
    @(posedge clk) disable iff(!reset_n)
    (empty && rd) |=> underflow;
  endproperty

  underflow_high_assert: assert property(underflow_high_prop) else
    $error("[FIFO_ASSERT] (underflow_high_assert): underflow was not set");

  //make sure underflow gets is not set on the next clk cycle
  property underflow_low_prop;
    @(posedge clk) disable iff(!reset_n)
    (!empty || !rd) |=> !underflow;
  endproperty

  underflow_low_assert: assert property(underflow_low_prop) else
    $error("[FIFO_ASSERT] (underflow_low_assert): underflow was set incorrectly");

  /************ ITEM_COUNT ASSERT ******************************/
  logic item_count_dec_cond;
  logic item_count_inc_cond;

  assign item_count_dec_cond = (!wr && rd && !empty);
  assign item_count_inc_cond = (wr && !rd && !full) || (wr && rd && empty);

  //make sure we decrement the item_count correctly
  property item_count_dec_prop;
    @(posedge clk) disable iff(!reset_n)
    item_count_dec_cond |=> (item_count == ($past(item_count) - 'd1));
  endproperty

  item_count_dec_assert: assert property(item_count_dec_prop) else
    $error("[FIFO_ASSERT] (item_count_dec_assert): item_count did not decrement, item_count = %0d", item_count);

  //make sure we increment the item_count correctly
  property item_count_inc_prop;
    @(posedge clk) disable iff(!reset_n)
    item_count_inc_cond |=> (item_count == ($past(item_count) + 'd1));
  endproperty

  item_count_inc_assert: assert property(item_count_inc_prop) else
    $error("[FIFO_ASSERT] (item_count_inc_assert): item_count did not increment, item_count = %0d", item_count);

  //make sure we item_count is stable when it is supposed to be
  property item_count_stable_prop;
    @(posedge clk) disable iff(!reset_n)
    (!item_count_inc_cond && !item_count_dec_cond) |=> (item_count == $past(item_count));
  endproperty

  item_count_stable_assert: assert property(item_count_stable_prop) else
    $error("[FIFO_ASSERT] (item_count_stable_assert): item_count changed unexpectedly, item_count = %0d", item_count);

endmodule
