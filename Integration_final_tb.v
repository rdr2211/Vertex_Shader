
module vertex_shader_tb;

  // Input signals
  reg clk;
  reg rst;
  reg [15:0] A1, A2, A3, A4, B1, B2, B3, B4, C1, C2, C3, C4, D1, D2, D3, D4;
  reg [15:0] X, Y, Z;

  // Output signals
  wire [15:0] P, Q, R, S;

  // File handlers
  integer input_file, output_file, scan_status;

  // Instantiate the DUT
  vertex_shader dut (
    .clk(clk),
    .rst(rst),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .B1(B1),
    .B2(B2),
    .B3(B3),
    .B4(B4),
    .C1(C1),
    .C2(C2),
    .C3(C3),
    .C4(C4),
    .D1(D1),
    .D2(D2),
    .D3(D3),
    .D4(D4),
    .X(X),
    .Y(Y),
    .Z(Z),
    .P(P),
    .Q(Q),
    .R(R),
    .S(S)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // Initialize inputs
    clk = 0;
    rst = 1;

    // Initialize constants for A1, A2, ..., D4
    A1 = 16'b1100000101101101;
    A2 = 16'b1100000101001000;
    A3 = 16'b1011111100111011;
    A4 = 16'b0100110000001110;
    B1 = 16'b0100001111101011;
    B2 = 16'b0100010110001101;
    B3 = 16'b0011111111100110;
    B4 = 16'b1100110111111101;
    C1 = 16'b1100011010100010;
    C2 = 16'b1100010110101001;
    C3 = 16'b1011111010100000;
    C4 = 16'b0100111111010000;
    D1 = 16'b1011100101101100;
    D2 = 16'b1011100110001001;
    D3 = 16'b1011001111111000;
    D4 = 16'b0100010000001100;

    // Open the input and output files
    input_file = $fopen("teapot_input.txt", "r");
    output_file = $fopen("teapot_output.txt", "w");

    if (input_file == 0 || output_file == 0) begin
      $display("Error: Unable to open file.");
    end

    // Release reset
    #10 rst = 0;

    // Read input values and simulate
    while (!$feof(input_file)) begin
      // Read a line from the input file
      scan_status = $fscanf(input_file, "%b,%b,%b\n", X, Y, Z);

      
      // Check for valid read
      if (scan_status != 3) begin
        $display("Error: Failed to read input data.");
      end


      // Wait for outputs to stabilize
      #10;

      // Write the outputs to the output file
      $fwrite(output_file, "%b,%b,%b,%b\n", P, Q, R, S);
    end

    // Close files and finish simulation
    $fclose(input_file);
    $fclose(output_file);
    $finish;
  end
endmodule

