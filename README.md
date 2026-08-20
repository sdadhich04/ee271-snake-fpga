# FPGA Snake on a 16x16 LED Matrix

SystemVerilog implementation of a Snake-style game for the Terasic DE1-SoC board and a 16x16 LED matrix.

## What It Includes

- `DE1_SoC.sv`: top-level board integration for switches, buttons, HEX displays, LEDs, GPIO, and game timing.
- `LEDDriver.sv`: matrix display driver for red and green pixel planes.
- `cellLight.sv`: per-cell game-state logic for body movement, apple interaction, and collisions.
- `snakeDirection.sv`: direction FSM driven by board inputs.
- `scoreTracker.sv` and `seg7.sv`: score state and seven-segment display output.
- `button.sv`, `clock_divider.sv`, `randomCoordinate.sv`, and `LSFR9.sv`: support logic for input conditioning, clocking, and pseudo-random apple placement.
- `collisionDetector.sv`, `generateApples.sv`, and `playField.sv`: retained design modules and testbench material. The final top level appears to fold portions of this logic into `cellLight.sv`.

## Scope

This is a post-course portfolio curation of the HDL source. Quartus project products, reports, board media, and course documents are intentionally not bundled.

## Suggested Workflow

Use `DE1_SoC.sv` as the hardware top level for Quartus review. Individual modules include testbenches that can be adapted for simulation with a SystemVerilog-capable simulator.
