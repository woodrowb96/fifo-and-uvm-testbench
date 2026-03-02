# FIFO and UVM Testbench

A SystemVerilog FIFO and UVM coverage-driven testbench with constrained-random stimulus, a reference model scoreboard, and functional coverage.

## RTL

Parameterized circular-buffer FIFO with configurable depth and width.

## UVM Testbench

Coverage-driven UVM testbench.

### Coverage Model

- Coverpoints for `{rd, wr, full, empty}` signals
- Cross coverage to hit corner cases: write to full, read from empty, simultaneous read/write

### Testbench

 Constrained-randomization inside a UVM Sequence, written to exercise full coverage
    - `uvm_driver`
    - `uvm_monitor`
    - `uvm_subscriber` to collect coverage
    - `uvm_scoreboard` that uses the reference model to score each item
    - `uvm_agent` `uvm_env` and `uvm_test` to structure everything

### Assertions

SVA assertion module bound to the FIFO, checking the following properties:

- **Reset behavior** - all registered signals reset to correct values
- **Full/empty flags** - set and cleared based on item_count
- **Pointer bounds** - wr_addr and rd_addr pointers stay within valid range
- **Pointer increment/wrap** - addresses both increment and wrap to 0 when they get to the end of the buffer
- **Write/read data** - data written to and read from the buffer correctly
- **Overflow/underflow flags** - set and cleared under the correct conditions
- **Item count** - increments, decrements, and stays stable correctly

## How to Run

I wrote two bash scripts to compile and simulate the project using Xilinx Vivado.

Note: You don't need to run ./xsim_comp on everything before running ./xsim_sim.
The sim script uses the filelist to compile all the dependencies first.

```bash
./xsim_comp rtl/fifo               # compile the rtl
./xsim_sim.sh uvm/tb_top.sv        # full simulation
./xsim_sim.sh -g uvm/tb_top.sv     # GUI mode
```

## Results

**Testbench Waveform:**

![Screenshot from 2023-06-28 17-01-47](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/5d03c2ac-f166-45aa-a45f-7859c42824dc)

**UVM Summary:**

![Screenshot from 2023-06-28 17-05-26](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/6bfd9886-a726-4f36-9f48-faeac40ad174)

**Coverage Report:**

<img width="872" height="1732" alt="coverage" src="https://github.com/user-attachments/assets/06d27503-4e3f-4d8f-a9b7-e297ac5191d2" />
