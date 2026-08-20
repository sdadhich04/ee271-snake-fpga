module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, SW, LEDR, GPIO_1, CLOCK_50);
  output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  output logic [9:0]  LEDR;
  input  logic [3:0]  KEY;
  input  logic [9:0]  SW;
  output logic [35:0] GPIO_1;
  input logic CLOCK_50;

  // Turn off HEX displays except hex0 and hex1
  // assign HEX0 = '1;
  // assign HEX1 = '1;
  assign HEX2 = '1;
  assign HEX3 = '1;
  assign HEX4 = '1;
  assign HEX5 = '1;

  // Set up system base clock to 1526 Hz (50 MHz / 2**(14+1))
  logic [31:0] clk;
  logic SYSTEM_CLOCK;
  clock_divider divider (.clock(CLOCK_50), .divided_clocks(clk));
  assign SYSTEM_CLOCK = clk[13];
//	assign SYSTEM_CLOCK = CLOCK_50;

  // Set up the frequency of updating display to the led
  logic [31:0] snakeClk;
  logic SNAKE_CLOCK;
  clock_divider snakeDivider (.clock(CLOCK_50), .divided_clocks(snakeClk));
  assign SNAKE_CLOCK = snakeClk[22];
//	assign SYSTEM_CLOCK = CLOCK_50;

  //Set up LED board driver
  logic [15:0][15:0]RedPixels; // 16 x 16 array representing red LEDs
  logic [15:0][15:0]GrnPixels; // 16 x 16 array representing green LEDs
  logic [15:0][15:0]rt; // 16 x 16 array representing red LEDs
  logic [15:0][15:0]gt; // 16 x 16 array representing green LEDs

  logic RST;                   // reset - toggle this on startup
  logic disable_d;                // to freeze

  assign RST = SW[0];

  	always_comb begin
		if (RST) begin
				GrnPixels <= 0;
				RedPixels <= 0;
			end
		else begin
				GrnPixels <= gt;
				RedPixels <= rt;
			end
	 end


  /* Standard LED Driver instantiation */
  LEDDriver Driver (.CLK(SYSTEM_CLOCK), .RST(RST), .EnableCount(1'b1), .RedPixels(rt), .GrnPixels(gt), .GPIO_1(GPIO_1));

  typedef enum logic [1:0] {
    red = 2'b10
    ,green = 2'b01
    ,orange = 2'b11
    ,off = 2'b00
  } cellStateColor;

//  typedef enum logic [1:0] {
//    right = 2'b00
//    ,down = 2'b01
//    ,left = 2'b10
//    ,up = 2'b11
//  } inputDirection;

  typedef enum logic [1:0] {
    eatApple = 2'b10
    ,gameOver = 2'b01
    ,normal = 2'b00
  } collisionState;

  typedef enum logic {
    startOn = 1'b1
    ,startOff = 1'b0
  } startState;

	//user input and dffs for all button directions

  logic left1_var, left2_var, left3_var;
  basic_D_FF left1 (.d(~KEY[1]), .q(left1_var), .clk(CLOCK_50));
  basic_D_FF left2 (.d(left1_var), .q(left2_var), .clk(CLOCK_50));

  logic up1_var, up2_var, up3_var;
  basic_D_FF up1 (.d(~KEY[3]), .q(up1_var), .clk(CLOCK_50));
  basic_D_FF up2 (.d(up1_var), .q(up2_var), .clk(CLOCK_50));

  logic down1_var, down2_var, down3_var;
  basic_D_FF down1 (.d(~KEY[2]), .q(down1_var), .clk(CLOCK_50));
  basic_D_FF down2 (.d(down1_var), .q(down2_var), .clk(CLOCK_50));

  logic right1_var, right2_var, right3_var;
  basic_D_FF right1 (.d(~KEY[0]), .q(right1_var), .clk(CLOCK_50));
  basic_D_FF right2 (.d(right1_var), .q(right2_var), .clk(CLOCK_50));



  button upBtn (.clock(CLOCK_50), .reset(RST), .key_in(up2_var), .key_out(up3_var));

  button downBtn (.clock(CLOCK_50), .reset(RST), .key_in(down2_var), .key_out(down3_var));

  button leftBtn (.clock(CLOCK_50), .reset(RST), .key_in(left2_var), .key_out(left3_var));

  button rightBtn (.clock(CLOCK_50), .reset(RST), .key_in(right2_var), .key_out(right3_var));

  //controls movement of snake
  //inputDirection direction;
  logic [1:0] direction;

  snakeDirection sd (.in_right(right3_var), .in_down(down3_var), .in_left(left3_var),
    .in_up(up3_var), .clk(CLOCK_50), .reset(RST), .direction((direction)));



  logic [3:0] intX, intY;
  int score;
  randomCoordinate rd (.clk(SNAKE_CLOCK), .x(intX), .y(intY));

  logic [15:0][15:0] randomize;
  logic [15:0][15:0] isEatApple_out;
  logic eatApple_p, eatApple_n;

  int present_x, present_y;
  int next_x, next_y;

  logic isDup_curr, isDup_next;

  always_comb begin
    isDup_next = 1'b0;
    if (RST) begin
      next_x = present_x;
      next_y = present_y;
      randomize = '0;
    end
    else if (isDup_curr) begin
      next_x = intX;
      next_y = intY;
      if (randomize[next_x][next_y]) begin
        isDup_next = 1'b1;
      end
    end
    else if (eatApple_p) begin
      next_x = intX;
      next_y = intY;
      if (randomize[next_x][next_y]) begin
        isDup_next = 1'b1;
      end
      randomize[present_x][present_y] = 1'b0;
    end
    else begin
      next_x = present_x;
      next_y = present_y;
      randomize[present_x][present_y] = 1'b1;
    end
  end

  always_ff @(posedge SNAKE_CLOCK) begin
    if (RST) begin
      present_x <= 12;
      present_y <= 12;
      isDup_curr <= 1'b0;
    end
    else begin
      present_x <= next_x;
      present_y <= next_y;
      isDup_curr <= isDup_next;
    end
  end

  //Initialize score tracker



  always_comb begin
    eatApple_n = 1'b0;
    for (int row = 0; row < 16; row++) begin
      for (int col = 0; col < 16; col++) begin
        if (isEatApple_out[row][col]) begin
          eatApple_n = 1'b1;
          break;
        end
      end
      if (eatApple_n) begin
        break;
      end
    end
  end

  always_ff @(posedge CLOCK_50) begin
    if (RST) begin
      eatApple_p <= 1'b0;
    end
    else begin
      eatApple_p <= eatApple_n;
    end
  end

  scoreTracker scoreTrack (.clk(SNAKE_CLOCK), .reset(RST), .isEatApple(eatApple_p),
    .out_hex1(HEX1), .out_hex0(HEX0), .score(score));

  //Initialize each cell
//


  genvar x2, y2;
  generate
    for(x2 = 0; x2 < 16; x2 += 1) begin : row
      for (y2 = 0; y2 < 16; y2 += 1) begin : col
        // head (top-left)
        if (x2 == 0 & y2 == 15) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b1),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[0][0], gt[0][0]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[15][15], gt[15][15]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // top right
        else if (x2 == 0 & y2 == 0) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[0][15], gt[0][15]}),
          .topCell({rt[15][0], gt[15][0]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom left
        else if (x2 == 15 & y2 == 15) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[15][0], gt[15][0]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[0][15], gt[0][15]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom right
        else if (x2 == 15 & y2 == 0) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[15][15], gt[15][15]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[0][0], gt[0][0]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // top border
        else if (x2 == 0) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[15][y2], gt[15][y2]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // left border
        else if (y2 == 15) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][0], gt[x2][0]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom border
        else if (x2 == 15) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[0][y2], gt[0][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // right border
        else if (y2 == 0) begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[x2][15], gt[x2][15]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // anything that is on the center
        else begin
          cellLight #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({rt[x2][y2 + 1], gt[x2][y2 + 1]}),
          .rightCell({rt[x2][y2 - 1], gt[x2][y2 - 1]}),
          .topCell({rt[x2 - 1][y2], gt[x2 - 1][y2]}),
          .bottomCell({rt[x2 + 1][y2], gt[x2 + 1][y2]}),
          .currCell({rt[x2][y2], gt[x2][y2]}),
          .direction(direction),
          .out_red(rt[x2][y2]),
          .out_green(gt[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
      end
    end
  endgenerate

endmodule

module DE1_SoC_testbench;

  // Signals for the DUT (Device Under Test)
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  logic [9:0] LEDR;
  logic [3:0] KEY;
  logic [9:0] SW;
  logic [35:0] GPIO_1;
  logic CLOCK_50;
  logic [15:0][15:0]RedPixels; // 16 x 16 array representing red LEDs
  logic [15:0][15:0]GrnPixels;

  // Instantiate the DUT
  DE1_SoC dut (
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
    .LEDR(LEDR), .KEY(KEY), .SW(SW), .GPIO_1(GPIO_1), .CLOCK_50(CLOCK_50)
  );

  // Set up the clock
  parameter CLOCK_PERIOD = 20;
  initial begin
    CLOCK_50 = 0;
    forever #(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;
  end

  // Test Sequence
  initial begin
    // Reset the DUT
    SW[0] = 1'b1;    repeat(1) @(posedge CLOCK_50);
    SW[0] = 1'b0; 	repeat(1) @(posedge CLOCK_50);


    // Test snake movement to the right
    KEY = 4'b1110; // Press the right button (KEY[0] active low)
	 GrnPixels = 16'b1111111111111110;
	 RedPixels = 16'b1111111111111110;
    #500;

    // Test snake movement to the down
    KEY = 4'b1101; // Press the down button (KEY[2] active low)
	 GrnPixels = 16'b1111111111111101;
	 RedPixels = 16'b1111111111111101;
    #500;

    // Test snake movement to the left
    KEY = 4'b1011; // Press the left button (KEY[1] active low)
	 GrnPixels = 16'b1111111111111011;
	 RedPixels = 16'b1111111111111011;
    #500;

    // Test snake movement to the up
    KEY = 4'b0111; // Press the up button (KEY[3] active low)
	 GrnPixels = 16'b1111111111110111;
	 RedPixels = 16'b1111111111110111;
    #500;

    // Simulate snake eating an apple
    // This can be done by modifying the randomize array in the DUT if required

    #1000;

    // Stop simulation
    $stop;
  end

endmodule
