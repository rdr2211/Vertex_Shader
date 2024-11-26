// Vertex Shader

module vertex_shader (
  input clk,
  input rst,
  input [15:0] A1,
  input [15:0] A2,
  input [15:0] A3,
  input [15:0] A4,
  input [15:0] B1,
  input [15:0] B2,
  input [15:0] B3,
  input [15:0] B4,
  input [15:0] C1,
  input [15:0] C2,
  input [15:0] C3,
  input [15:0] C4,
  input [15:0] D1,
  input [15:0] D2,
  input [15:0] D3,
  input [15:0] D4,
  input [15:0] X,
  input [15:0] Y,
  input [15:0] Z,
  output [15:0] P,
  output [15:0] Q,
  output [15:0] R,
  output [15:0] S
);

  reg [15:0] A1_reg; 
  reg [15:0] A2_reg;
  reg [15:0] A3_reg;
  reg [15:0] A4_reg;
  reg [15:0] B1_reg;
  reg [15:0] B2_reg;
  reg [15:0] B3_reg;
  reg [15:0] B4_reg;
  reg [15:0] C1_reg;
  reg [15:0] C2_reg;
  reg [15:0] C3_reg;
  reg [15:0] C4_reg;
  reg [15:0] D1_reg;
  reg [15:0] D2_reg;
  reg [15:0] D3_reg;
  reg [15:0] D4_reg;
  reg [15:0] X_reg;
  reg [15:0] Y_reg;
  reg [15:0] Z_reg;


 always @(posedge clk or posedge rst) begin
      if (rst)
      begin
      A1_reg <= 16'b0;
      A2_reg <= 16'b0;
      A3_reg <= 16'b0;
      A4_reg <= 16'b0;
      B1_reg <= 16'b0;
      B2_reg <= 16'b0;
      B3_reg <= 16'b0;
      B4_reg <= 16'b0;
      C1_reg <= 16'b0;
      C2_reg <= 16'b0;
      C3_reg <= 16'b0;
      C4_reg <= 16'b0;
      D1_reg <= 16'b0;
      D2_reg <= 16'b0;
      D3_reg <= 16'b0;
      D4_reg <= 16'b0;
      X_reg <= 16'b0;
      Y_reg <= 16'b0;
      Z_reg <= 16'b0;
      end 
      else
      begin
      A1_reg <= A1;
      A2_reg <= A2;
      A3_reg <= A3;
      A4_reg <= A4;
      B1_reg <= B1;
      B2_reg <= B2;
      B3_reg <= B3;
      B4_reg <= B4;
      C1_reg <= C1;
      C2_reg <= C2;
      C3_reg <= C3;
      C4_reg <= C4;
      D1_reg <= D1;
      D2_reg <= D2;
      D3_reg <= D3;
      D4_reg <= D4;
      X_reg <= X;
      Y_reg <= Y;
      Z_reg <= Z;
      end
    end

wire [15:0] mult1_wire, mult2_wire, mult3_wire, mult4_wire, mult5_wire, mult6_wire, mult7_wire, mult8_wire, mult9_wire, mult10_wire, mult11_wire, mult12_wire, mult13_wire, mult14_wire, mult15_wire, mult16_wire;

reg [15:0] reg_mult1, reg_mult2, reg_mult3, reg_mult4, reg_mult5, reg_mult6, reg_mult7, reg_mult8, reg_mult9, reg_mult10, reg_mult11, reg_mult12, reg_mult13, reg_mult14, reg_mult15, reg_mult16;

Floating_point_multiplier mult1 (
.clk(clk),
.rst(rst),
.A(A1_reg), .B(X_reg), 
.result(mult1_wire)
);

Floating_point_multiplier mult2 (
.clk(clk),
.rst(rst),
.A(A2_reg), .B(Y_reg), 
.result(mult2_wire)
);

Floating_point_multiplier mult3 (
.clk(clk),
.rst(rst),
.A(A3_reg), .B(Z_reg), 
.result(mult3_wire)
);

Floating_point_multiplier mult4 (
.clk(clk),
.rst(rst),
.A(A4_reg), .B(16'b0011110000000000), 
.result(mult4_wire)
);

Floating_point_multiplier mult5 (
.clk(clk),
.rst(rst),
.A(B1_reg), .B(X_reg), 
.result(mult5_wire)
);

Floating_point_multiplier mult6 (
.clk(clk),
.rst(rst),
.A(B2_reg), .B(Y_reg), 
.result(mult6_wire)
);

Floating_point_multiplier mult7 (
.clk(clk),
.rst(rst),
.A(B3_reg), .B(Z_reg), 
.result(mult7_wire)
);

Floating_point_multiplier mult8 (
.clk(clk),
.rst(rst),
.A(B4_reg), .B(16'b0011110000000000), 
.result(mult8_wire)
);

Floating_point_multiplier mult9 (
.clk(clk),
.rst(rst),
.A(C1_reg), .B(X_reg), 
.result(mult9_wire)
);

Floating_point_multiplier mult10 (
.clk(clk),
.rst(rst),
.A(C2_reg), .B(Y_reg), 
.result(mult10_wire)
);

Floating_point_multiplier mult11 (
.clk(clk),
.rst(rst),
.A(C3_reg), .B(Z_reg), 
.result(mult11_wire)
);

Floating_point_multiplier mult12 (
.clk(clk),
.rst(rst),
.A(C4_reg), .B(16'b0011110000000000), 
.result(mult12_wire)
);

Floating_point_multiplier mult13 (
.clk(clk),
.rst(rst),
.A(D1_reg), .B(X_reg), 
.result(mult13_wire)
);

Floating_point_multiplier mult14 (
.clk(clk),
.rst(rst),
.A(D2_reg), .B(Y_reg), 
.result(mult14_wire)
);

Floating_point_multiplier mult15 (
.clk(clk),
.rst(rst),
.A(D3_reg), .B(Z_reg), 
.result(mult15_wire)
);

Floating_point_multiplier mult16 (
.clk(clk),
.rst(rst),
.A(D4_reg), .B(16'b0011110000000000), 
.result(mult16_wire)
);


  always @(posedge clk or posedge rst) begin
      if (rst)
      begin
      reg_mult1 <= 16'b0;
      reg_mult2 <= 16'b0;
      reg_mult3 <= 16'b0;
      reg_mult4 <= 16'b0;
      reg_mult5 <= 16'b0;
      reg_mult6 <= 16'b0;
      reg_mult7 <= 16'b0;
      reg_mult8 <= 16'b0;
      reg_mult9 <= 16'b0;
      reg_mult10 <= 16'b0;
      reg_mult11 <= 16'b0;
      reg_mult12 <= 16'b0;
      reg_mult13 <= 16'b0;
      reg_mult14 <= 16'b0;
      reg_mult15 <= 16'b0;
      reg_mult16 <= 16'b0;
      end
      else
      begin
      reg_mult1 <= mult1_wire;
      reg_mult2 <= mult2_wire;
      reg_mult3 <= mult3_wire;
      reg_mult4 <= mult4_wire;
      reg_mult5 <= mult5_wire;
      reg_mult6 <= mult6_wire;
      reg_mult7 <= mult7_wire;
      reg_mult8 <= mult8_wire;
      reg_mult9 <= mult9_wire;
      reg_mult10 <= mult10_wire;
      reg_mult11 <= mult11_wire;
      reg_mult12 <= mult12_wire;
      reg_mult13 <= mult13_wire;
      reg_mult14 <= mult14_wire;
      reg_mult15 <= mult15_wire;
      reg_mult16 <= mult16_wire;
      end
    end
    



// second stage 

wire [15:0] add1_wire, add2_wire, add3_wire, add4_wire, add5_wire, add6_wire, add7_wire, add8_wire;

reg [15:0] reg1_add1, reg1_add2, reg1_add3, reg1_add4, reg1_add5, reg1_add6, reg1_add7, reg1_add8;

fp_adder_16_bit add1(
.clock(clk),
.reset(rest),
.operand_a(reg_mult1),
.operand_b(reg_mult2),
.result(add1_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);

fp_adder_16_bit add2(
.clock(clk),
.reset(rest),
.operand_a(reg_mult3),
.operand_b(reg_mult4),
.result(add2_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add3(
.clock(clk),
.reset(rest),
.operand_a(reg_mult5),
.operand_b(reg_mult6),
.result(add3_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add4(
.clock(clk),
.reset(rest),
.operand_a(reg_mult7),
.operand_b(reg_mult8),
.result(add4_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add5(
.clock(clk),
.reset(rest),
.operand_a(reg_mult9),
.operand_b(reg_mult10),
.result(add5_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add6(
.clock(clk),
.reset(rest),
.operand_a(reg_mult11),
.operand_b(reg_mult12),
.result(add6_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add7(
.clock(clk),
.reset(rest),
.operand_a(reg_mult13),
.operand_b(reg_mult14),
.result(add7_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


fp_adder_16_bit add8(
.clock(clk),
.reset(rest),
.operand_a(reg_mult15),
.operand_b(reg_mult16),
.result(add8_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


  always @(posedge clk or posedge rst) begin
      if (rst)
      begin
      reg1_add1 <= 16'b0;
      reg1_add2 <= 16'b0;
      reg1_add3 <= 16'b0;
      reg1_add4 <= 16'b0;
      reg1_add5 <= 16'b0;
      reg1_add6 <= 16'b0;
      reg1_add7 <= 16'b0;
      reg1_add8 <= 16'b0;
      end
      else
      begin
      reg1_add1 <= add1_wire;
      reg1_add2 <= add2_wire;
      reg1_add3 <= add3_wire;
      reg1_add4 <= add4_wire;
      reg1_add5 <= add5_wire;
      reg1_add6 <= add6_wire;
      reg1_add7 <= add7_wire;
      reg1_add8 <= add8_wire;
      end
    end





// third stage 
wire [15:0] final_add1_wire, final_add2_wire, final_add3_wire, final_add4_wire;

reg [15:0] reg2_add1, reg2_add2, reg2_add3, reg2_add4;

fp_adder_16_bit final_add1(
.clock(clk),
.reset(rest),
.operand_a(reg1_add1),
.operand_b(reg1_add2),
.result(final_add1_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);

fp_adder_16_bit final_add2(
.clock(clk),
.reset(rest),
.operand_a(reg1_add3),
.operand_b(reg1_add4),
.result(final_add2_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);

fp_adder_16_bit final_add3(
.clock(clk),
.reset(rest),
.operand_a(reg1_add5),
.operand_b(reg1_add6),
.result(final_add3_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);

fp_adder_16_bit final_add4(
.clock(clk),
.reset(rest),
.operand_a(reg1_add7),
.operand_b(reg1_add8),
.result(final_add4_wire),
.overflow_flag(),
.underflow_flag(),
.zero_flag(),
.infinity_flag(),
.NaN_flag()
);


always @(posedge clk or posedge rst) begin
      if (rst)
      begin
      reg2_add1 <= 16'b0;
      reg2_add2 <= 16'b0;
      reg2_add3 <= 16'b0;
      reg2_add4 <= 16'b0;
      end
      else
      begin
      reg2_add1 <= final_add1_wire;
      reg2_add2 <= final_add2_wire;
      reg2_add3 <= final_add3_wire;
      reg2_add4 <= final_add4_wire;
      end
    end

assign P = final_add1_wire;
assign Q = final_add2_wire;
assign R = final_add3_wire;
assign S = final_add4_wire;

endmodule

`include "Floating_point_multiplier.v"
`include "Floating_point_Adder.v"