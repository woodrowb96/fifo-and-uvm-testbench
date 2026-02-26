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

- Constrained-randomization inside a UVM Sequence, written to exercise full coverage
    - `uvm_driver`
    - `uvm_monitor`
    - `uvm_subscriber` to collect coverage
    - `uvm_scoreboard` that uses the reference model to score each item
    - `uvm_agent` `uvm_env` and `uvm_test` to structure everything

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

![Screenshot from 2023-06-28 17-09-50](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/6f710173-d3a0-4907-92f8-172507740d29)
