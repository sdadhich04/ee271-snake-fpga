# FPGA Snake

A SystemVerilog implementation of a Snake-style game. The top-level module is `DE1_SoC`, which connects the game to a 16x16 red/green LED-matrix expansion board, board keys, switch `SW[0]` for reset, two seven-segment displays for the score, and the board GPIO header.

## Hardware and tools

- **Target board:** Terasic DE1-SoC, identified by the `DE1_SoC` top-level module and the `CLOCK_50`, `KEY`, `SW`, `HEX`, `LEDR`, and `GPIO_1` interfaces.
- **Display:** a 16x16 two-color LED-matrix expansion board driven through the 36-pin `GPIO_1` interface.
- **Source language:** SystemVerilog.

The checkout does not include a Quartus project, device selection, pin-assignment file, programming image, or display wiring documentation. Therefore, the exact FPGA device setting, pin assignments, and a reproducible flash procedure cannot be determined from this repository alone.

## What it does

`DE1_SoC.sv` divides the 50 MHz board clock, samples the four active-low key inputs, updates snake movement and apple placement, detects gameplay events, drives the LED matrix, and sends the score to `HEX0` and `HEX1`. Supporting modules implement input conditioning, direction state, pseudo-random coordinates, cell state, collision-related logic, matrix driving, and seven-segment decoding.

## Build and program

1. In a SystemVerilog-capable FPGA toolchain, create a project for the DE1-SoC board and add the `.sv` files in this repository.
2. Set `DE1_SoC` as the top-level module.
3. Supply the board and LED-matrix pin assignments; they are not present in this checkout.
4. Compile the design and use the toolchain's programmer with the resulting programming file and the board connection.

Because the required project configuration and pin constraints are absent, these steps are a setup outline, not a verified build or flashing procedure.

## Credits

The Git history records Sparsh Dadhich for the repository's initial portfolio curation. No module-level author or team credits are identified in the checkout.
