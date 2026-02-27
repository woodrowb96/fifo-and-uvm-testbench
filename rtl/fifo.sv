/*
  A Circular Buffer FIFO

Clock:
  clk: Both reads and writes are synced to the posedge of the clk

Reset:
  reset_n: active low async reset

Control:
  wr: active high write enable
  rd: active high read enable

Input:
  wr_data: write data pushed onto the front of the FIFO
          - clocked in @(posedge clk)
          - write data is not stored in FIFO until the clk cycle after wr is set

Output:
  rd_data: read data popped off the back of the FIFO
          - clocked out @(posedge clk)
          - rd_data will read out the data that is stored in the FIFO
            DURING the clk cycle rd is asserted, but it is not output onto
            rd_data until the NEXT clk cycle

  item_count: the amount of items currently inside the fifo

Output Flags:
  full: high if item_count == LENGTH

  empty: high if item_count == 0

  overflow: high for 1 clk cycle, on the cycle after an overflow

  underflow: high for 1 clk cycle, on the cycle after an underflow
*/

module fifo#(parameter LENGTH = 16, WIDTH = 8)
(
  input logic clk,
  input logic reset_n,

  //control
  input logic wr,
  input logic rd,

  //input
  input logic [WIDTH-1:0] wr_data,

  //output
  output logic [WIDTH-1:0] rd_data,
  output logic [$clog2(LENGTH) :0] item_count,

  //output flags
  output logic full,
  output logic empty,
  output logic underflow,
  output logic overflow
);
  logic [WIDTH-1:0] buffer [LENGTH-1:0];

  logic [$clog2(LENGTH)-1:0] wr_addr;
  logic [$clog2(LENGTH)-1:0] rd_addr;

  //calc empty and full flags
  assign full = (item_count == LENGTH);
  assign empty = (item_count == 'd0);

  /****************** WRITE **************************/
  //We can only write into the fifo if (wr && (~full || rd))
  //
  //NOTE:(~full || rd)  we can write into a full buffer if rd is set.
  //     We are reading so that clears up a space as we're filling it.
  /***************************************************/
  always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n) begin
      for(int i=0;i<LENGTH;i++) begin
        buffer[i] <= '0;
      end
      wr_addr <= '0;
    end
    else if(wr && (~full || rd)) begin
      wr_addr <= wr_addr + 'd1;
      buffer[wr_addr]  <= wr_data;
    end
  end

  /************* READ *****************************/
  //We can only read if (rd && ~empty)
  /************************************************/
  always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n) begin
      rd_addr	<= 'd0;
      rd_data <= 'd0;
    end
    else if(rd && ~empty) begin
      rd_addr <= rd_addr + 'd1;
      rd_data <= buffer[rd_addr];
    end
  end

  /****************** CALC OVERFLOW ********************/
  //We overflow if: (full && wr && !rd)
  //  - So if we write to a full buffer
  //  - AND we are not reading to clear up a space
  //
  //If we overflow flag is set for 1 cycle, on the cycle after overflow happened
  /****************************************************/
  always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n) begin
      overflow <= 'd0;
    end
    else if(full && wr && !rd) begin
      overflow <= 'd1;
    end
    else begin
      overflow <= 'd0;
    end
  end

  /****************** CALC UNDERFLOW ********************/
  //We underflow if: (empty && rd)
  //  - So if we read from an empty buffer
  //
  //If we underflow flag is set for 1 cycle, on the cycle after underflow happened
  //
  //Note: wr does not get us out of an underflow, writes dont get
  //      written in the next clk cycle so its not available to read yet
  /****************************************************/
  always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n) begin
      underflow <= 'd0;
    end
    else if(empty && rd) begin
      underflow <= 'd1;
    end
    else begin
      underflow <= 'd0;
    end
  end

  /***************** CALC ITEMCOUNT *********************/
  //We look at {wr,rd,!full,!empty} signals to determine what calc is
  //needed to get an accurate item count
  /******************************************************/
  always_ff @(posedge clk, negedge reset_n)
    if(!reset_n) begin
      item_count <= 'd0;
    end
    else begin
      casez({wr,rd,!full,!empty})
        4'b01?1: begin                        //if we are only reading and buffer is not empty
          item_count <= item_count - 'd1;     //decrement the item count
        end
        4'b101?: begin                        //if we are only writing and the buffer is not full
          item_count <= item_count + 'd1;     //increment the item count
        end
        4'b1110: begin                        //if we write during an underflow, the rd fails but the wr succeeds
          item_count <= item_count + 'd1;     //increment the item count
        end
        default: begin                        //all other scenarios
          item_count <= item_count;           //item count is stable
        end
      endcase
    end
endmodule
