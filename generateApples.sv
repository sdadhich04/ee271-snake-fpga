module generateApples (
  input logic clk, reset,
  input logic [15:0][15:0] RedPixels, // 16x16 array of red LEDs
  input logic [15:0][15:0] GrnPixels, // 16x16 array of green LEDs
  output logic [3:0] x, y
  );

  typedef enum logic [1:0] {
    red = 2'b10,
    green = 2'b01,
    orange = 2'b11,
    off = 2'b00
  } cellStateColor;

  typedef struct packed {
    int xCoordinate;
    int yCoordinate;
  } state;

  state present_s, next_s;
  state modified;

  randomCoordinate getRandom(.clk(clk), .x(next_s.xCoordinate), .y(next_s.yCoordinate));

  logic isFound;
  int newX, newY;

  // Algorithm to verify whether next_s is valid
  always_comb begin
    isFound = 1'b0;
    modified = present_s;
    newX = -1;
    newY = -1;

    if (RedPixels[next_s.xCoordinate][next_s.yCoordinate] || GrnPixels[next_s.xCoordinate][next_s.yCoordinate]) begin

      // Check right side if it's off
      if (~RedPixels[next_s.xCoordinate][next_s.yCoordinate + 1] &&
          ~GrnPixels[next_s.xCoordinate][next_s.yCoordinate + 1]) begin
        newX = next_s.xCoordinate;
        newY = next_s.yCoordinate + 1;
      end
      // Check left side if it's off
      else if (~RedPixels[next_s.xCoordinate][next_s.yCoordinate - 1] &&
               ~GrnPixels[next_s.xCoordinate][next_s.yCoordinate - 1]) begin
        newX = next_s.xCoordinate;
        newY = next_s.yCoordinate - 1;
      end
      // Check top side if it's off
      else if (~RedPixels[next_s.xCoordinate - 1][next_s.yCoordinate] &&
               ~GrnPixels[next_s.xCoordinate - 1][next_s.yCoordinate]) begin
        newX = next_s.xCoordinate - 1;
        newY = next_s.yCoordinate;
      end
      // Check bottom side if it's off
      else if (~RedPixels[next_s.xCoordinate + 1][next_s.yCoordinate] &&
               ~GrnPixels[next_s.xCoordinate + 1][next_s.yCoordinate]) begin
        newX = next_s.xCoordinate + 1;
        newY = next_s.yCoordinate;
      end
      // If all surrounding cells are on, find an empty cell iteratively
      else begin
        for (int row = 0; row < 16 && !isFound; row += 1) begin
          for (int col = 0; col < 16 && !isFound; col += 1) begin
            if (~RedPixels[row][col] && ~GrnPixels[row][col]) begin
              newX = row;
              newY = col;
              isFound = 1'b1;
            end
          end
        end
      end
    end

    // Update coordinates based on newX and newY
    if (newX != -1 && newY != -1) begin
      x = newX;
      y = newY;
    end else begin
      x = next_s.xCoordinate;
      y = next_s.yCoordinate;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      present_s.xCoordinate <= 12;
      present_s.yCoordinate <= 12;
    end else begin
      present_s <= next_s;
    end
  end
endmodule

module generateApples_testbench();
  logic clk, reset;
  logic [15:0][15:0] RedPixels;
  logic [15:0][15:0] GrnPixels;
  logic [3:0] x, y;

  generateApples dut (.*);

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD / 2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); RedPixels <= '0; GrnPixels <= '0;
    @(posedge clk); RedPixels[12][12] <= 1; RedPixels[11][12] <= 1; RedPixels[13][12] <= 1; RedPixels[12][11] <= 1; RedPixels[12][13] <= 1;
    @(posedge clk); RedPixels[0][0] <= 1;
    @(posedge clk); reset <= 1;
    @(posedge clk); reset <= 0;
    for (int i = 0; i < 10; i++) begin
      @(posedge clk);
    end
    $stop; // End the simulation
  end
endmodule
