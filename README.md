# MIPS_CPU
single core MIPS multicycle CPU.

designed every component from scratch in modelsim and synthesized using quartus prime.

**design features**:

FSM based controller for all stages of pipeline to control the datapath.

performs operations : add, addi, sub, branch, jump, mul

detects overflow using overflow circuit and asserts overflow flag

designed carry look ahead adder to speedup arthematic operations
