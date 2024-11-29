# LiTerm : An Independent File Editor, Assembler, and Processor

### Final Project  for MIT 6.205 Fall 2024


We present a design for a terminal-based text editor fully supported in hardware on a Xilinx FPGA. We utilize a independent RISC-V processor that runs assembler code located in instruction memory. Separate from the processor exists a terminal-based text editor that accepts PS2 keyboard input and allows for dynamic program file editing. We propose a system that performs the reduction of assembly code to binaries entirely on the FPGA. Performance and output are measured through a debugger communicating over UART and a separate MMO visualization of data memory.

### Collaborators:

Simon Opsahl (sopsahl@mit.edu)

Ziyad Hassan (zhassan3@mit.edu)

Tsegazeab Beteselassie (tsegaz@mit.edu)


