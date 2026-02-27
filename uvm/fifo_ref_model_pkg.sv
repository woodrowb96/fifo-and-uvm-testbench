package fifo_ref_model_pkg;
  class fifo_ref_model #(parameter LENGTH, WIDTH);

    //use a bounded queue as our reference fifo
    logic [WIDTH-1:0] queue [$:LENGTH-1];

    logic [$clog2(LENGTH):0] item_count;
    logic full;
    logic empty;
    logic underflow;
    logic overflow;

    logic [WIDTH-1:0] rd_data;

    //initialize the model
    //this is the equivalent of resetting the fifo
    function new();
      full = 0;
      empty = 1;
      underflow = 0;
      overflow = 0;
      item_count = 0;
      rd_data = 0;
    endfunction

    //write and set the appropriate overflow flag
    function void write(logic wr,logic rd,logic [WIDTH-1:0] wr_data);
      if(wr && (full && !rd)) begin
        overflow = 1;
      end
      else begin
        overflow = 0;
      end

      if(wr && (!full || rd)) begin
        queue.push_back(wr_data);
      end
    endfunction


    //read and set the appropriate underflow flag
    function void read(logic rd);
      if(rd && empty) begin
        underflow = 1;
      end
      else begin
        underflow = 0;
      end

      if(rd && !empty) begin
        rd_data = queue.pop_front();
      end
    endfunction

    //update the fifo state
    function void update(logic wr, logic rd, logic [WIDTH-1:0] wr_data);
      //read, write, set overflow and underflow flags
      read(rd);
      write(wr,rd,wr_data);

      //calc full and empty flags
      full = queue.size() == LENGTH;
      empty = queue.size() == 0;

      //calc item count
      item_count = queue.size();
    endfunction
  endclass
endpackage
