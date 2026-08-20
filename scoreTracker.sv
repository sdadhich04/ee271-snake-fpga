module scoreTracker (
  input logic clk, reset
  ,input logic isEatApple
  ,output logic [6:0] out_hex1, out_hex0
  ,output int score
  );
  // ,input logic [3:0] in_hex1, in_hex0

  // use int to represent score
  int present_s, next_s;

  logic [3:0] split_hex1, split_hex0;

  // Conversion of int to 2 x 4bit value
  always_comb begin
    // get the first digit for split_hex0
    split_hex0 = logic'(present_s % 10);
    // get the second digit for split_hex1
    split_hex1 = logic'(present_s / 10);

    if (present_s > 99) begin
      next_s = 0;
      // isEatApple = 1'b0;
    end
    else if (isEatApple) begin
      next_s = present_s + 1;
    end
    else begin
      next_s = present_s;
    end


    score = present_s;
  end

  // display converted number into 7 segment display
  seg7 disp_hex1 (.bcd(split_hex1), .leds(out_hex1));
  seg7 disp_hex0 (.bcd(split_hex0), .leds(out_hex0));

  always_ff @(posedge clk) begin
    if (reset)
      present_s <= 0;
    else
      present_s <= next_s;
  end
endmodule

module scoreTracker_testbench();
  logic clk, reset;
  logic isEatApple;
  logic [6:0] out_hex1, out_hex0;
  int score;

  scoreTracker track (.*);

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); reset <= 1; isEatApple <= 0;
    @(posedge clk); reset <= 0;
    for (int i = 0; i < 150 ; i++) begin
      @(posedge clk);
    end
    $stop; // End the simulation
  end

endmodule
