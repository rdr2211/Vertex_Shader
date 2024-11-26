
module Floating_point_multiplier_tb;

  reg clk;
  reg rst;
  reg [15:0] A, B;
  wire [15:0] result;

  // Instantiate the DUT (Device Under Test)
  Floating_point_multiplier uut (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .result(result)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
  end

  // Test stimulus
  initial begin
    // Initialize inputs
    rst = 1;
    A = 16'b0;
    B = 16'b0;

    // Apply reset
    #10;
    @(posedge clk)
    rst = 0;
    #10;
    // Test case 1: Multiplying two positive numbers
    A = 16'b0011100111111110; // Example binary representation for 3.0
    B = 16'b1011110101011010; // Example binary representation for 3.0
    repeat (2) @(posedge clk)
    #10;
    $display("Test 1 - A: %b, B: %b, Result: %b", A, B, result);

    // Test case 2: Multiplying positive and negative numbers
    A = 16'b1100001000000000; // Example binary representation for -3.0
    B = 16'b0100000000000000; // Example binary representation for 2.0
    repeat (2) @(posedge clk)
    #10;
    $display("Test 2 - A: %b, B: %b, Result: %b", A, B, result);

    // Test case 3: Multiplying negative numbers
    A = 16'b1100000000000000; // Example binary representation for -2.0
    B = 16'b1100000000000000; // Example binary representation for -2.0
    repeat (2) @(posedge clk)
    #10;
    $display("Test 3 - A: %b, B: %b, Result: %b", A, B, result);

    // Test case 4: Multiplying with zero
    A = 16'b0100001000000000; // Example binary representation for 3.0
    B = 16'b0000000000000000; // Zero
    repeat (2) @(posedge clk)
    #10;
    $display("Test 4 - A: %b, B: %b, Result: %b", A, B, result);

    // Finish the simulation
    $stop;
  end

endmodule


