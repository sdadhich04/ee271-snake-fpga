module button (
  input   logic clock, reset, key_in,
  output logic key_out
  );


  typedef enum logic [1:0]
  {
    ready = 2'b00,
    first = 2'b01,
    second = 2'b10
  } state_e;

  state_e ps, ns;

  always_comb begin
    // stay in current state
    ns = ps;
    // FSM Next State Logic
    case (ps)
      ready: begin
        if (key_in) ns = first; // saw first 1 on key_in
        else       ns = ready;
      end
      first: begin
        if (key_in) ns = second; // saw second 1 on key_in
        else       ns = ready;
      end
      second: begin
        if (key_in) ns = second; // stay here if 1 on key_in
        else       ns = ready;
      end
      default: begin
        ns = state_e'('x);
      end
    endcase

    key_out = (ps == first);
  end

  // Sequential Logic
  always_ff @(posedge clock) begin
    if (reset) begin
      ps <= ready;
    end else begin
      ps <= ns;
    end
  end

endmodule
module button_testbench();
  logic clock, reset, key_in;
  logic key_out;

  button dut (
    .clock(clock),
    .reset(reset),
    .key_in(key_in),
    .key_out(key_out)
  );

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clock <= 0;
    forever #(CLOCK_PERIOD/2) clock <= ~clock;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clock); reset <= 1;
    @(posedge clock); reset <= 0; key_in <= 1;
    @(posedge clock); key_in <= 0;
    @(posedge clock);
    @(posedge clock); key_in <= 1;
    @(posedge clock);
    @(posedge clock);
    @(posedge clock); key_in <= 0;
    $stop; // End the simulation
  end
endmodule
