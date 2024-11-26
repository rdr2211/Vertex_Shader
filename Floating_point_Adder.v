module fp_adder_16_bit (
    input clock,
    input reset,
    input [15:0] operand_a,
    input [15:0] operand_b,
    output reg [15:0] result,
    output reg overflow_flag,
    output reg underflow_flag,
    output reg zero_flag,
    output reg infinity_flag,
    output reg NaN_flag
);

    // Internal signals for module connections
    wire [4:0] exp_a, exp_b;
    wire [10:0] mant_a, mant_b;
    wire sign_a, sign_b;
    wire [4:0] big_exponent;
    wire [10:0] big_mantissa_int;
    wire [13:0] aligned_mantissa_int;
    wire [14:0] resultant_mantissa_int;
    wire final_sign;
    wire [12:0] normalized_mantissa;
    wire [4:0] normalized_exponent;
    wire op_int;
    wire zero_flag_int;
    wire infinity_flag_int;
    wire NaN_flag_int;
    wire overflow_flag_int;
    wire underflow_flag_int;
    wire [15:0] result_int;

    // Pipeline registers for each stage
    reg [15:0] reg_operand_a, reg_operand_b;

    reg [4:0] reg_big_exponent;
    reg [10:0] reg_big_mantissa;
    reg [13:0] reg_aligned_mantissa;
    reg reg_op_int, reg_final_sign;

    reg [14:0] reg_resultant_mantissa;

    reg [12:0] reg_normalized_mantissa;
    reg [4:0] reg_normalized_exponent;
    reg reg_zero_flag;
    reg reg_infinity_flag;
    reg reg_NaN_flag;
  
    wire final_operation = 0;

    // Register before extractor block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_operand_a <= 0;
            reg_operand_b <= 0;
        end else begin
            reg_operand_a <= operand_a;
            reg_operand_b <= operand_b;
        end
    end

    // Extraction block
    extractor extract (
        .operand_a(reg_operand_a),
        .operand_b(reg_operand_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .zero_flag(zero_flag_int),
        .infinity_flag(infinity_flag_int),
        .NaN_flag(NaN_flag_int)
    );

    // Alignment block
    alignment_block align (
        .sign_m(sign_a),
        .sign_n(sign_b),
        .exp_m(exp_a),
        .exp_n(exp_b),
        .mant_m(mant_a),
        .mant_n(mant_b),
        .aligned_mantissa(aligned_mantissa_int),
        .big_exponent(big_exponent),
        .big_mantissa(big_mantissa_int),
        .final_sign(final_sign),
        .operation_int(op_int)
    );

    // Register after alignment block
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_big_exponent <= 0;
            reg_big_mantissa <= 0;
            reg_aligned_mantissa <= 0;
            reg_op_int <= 0;
            reg_final_sign <= 0;
            reg_zero_flag <= 0;
            reg_infinity_flag <= 0;
            reg_NaN_flag <= 0;
        end else begin
            reg_big_exponent <= big_exponent;
            reg_big_mantissa <= big_mantissa_int;
            reg_aligned_mantissa <= aligned_mantissa_int;
            reg_op_int <= op_int;
            reg_final_sign <= final_sign;
            reg_zero_flag <= zero_flag_int;
            reg_infinity_flag <= infinity_flag_int;
            reg_NaN_flag <= NaN_flag_int;
        end
    end

    // Addition/subtraction stage
    addition_block add_sub (
        .aligned_mantissa(reg_aligned_mantissa),
        .big_mantissa(reg_big_mantissa),
        .operation_int(reg_op_int),
        .final_operation(final_operation),
        .resultant_mantissa(resultant_mantissa_int)
    );

    // Normalization stage
    normalization_block normalize (
        .resultant_mantissa(resultant_mantissa_int),
        .big_exponent(reg_big_exponent),
        .final_operation(final_operation),
        .zero_flag(reg_zero_flag),
        .normalized_mantissa(normalized_mantissa),
        .normalized_exponent(normalized_exponent)
    );

    // Rounding stage
    rounding_block round (
        .normalized_mantissa(normalized_mantissa),
        .normalized_exponent(normalized_exponent),
        .sign(reg_final_sign),
        .infinity_flag(reg_infinity_flag),
        .NaN_flag(reg_NaN_flag),
        .result(result_int),
        .overflow_flag(overflow_flag_int),
        .underflow_flag(underflow_flag_int)
    );

    // Register for output after rounding
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            result <= 0;
            overflow_flag <= 0;
            underflow_flag <= 0;
            zero_flag <= 0;
            infinity_flag <= 0;
            NaN_flag <= 0;
        end else begin
            result <= result_int;
            overflow_flag <= overflow_flag_int;
            underflow_flag <= underflow_flag_int;
            zero_flag <= reg_zero_flag;
            infinity_flag <= reg_infinity_flag;
            NaN_flag <= reg_NaN_flag;
        end
    end

endmodule

module extractor (
    input [15:0] operand_a,  // 16-bit input operand A
    input [15:0] operand_b,  // 16-bit input operand B
    output reg [4:0] exp_a,   // 5-bit exponent of A
    output reg [4:0] exp_b,   // 5-bit exponent of B
    output reg [10:0] mant_a,  // 11-bit mantissa of A (including hidden bit)
    output reg [10:0] mant_b,  // 11-bit mantissa of B (including hidden bit)
    output reg sign_a,        // Sign of A
    output reg sign_b,        // Sign of B
    output reg zero_flag,     // Zero flag
    output reg infinity_flag, // Infinity flag
    output reg NaN_flag       // NaN flag
);

    always @(*) begin
        // Initialize outputs
        zero_flag = 1'b0;
        infinity_flag = 1'b0;
        NaN_flag = 1'b0;

        // Extract sign and exponent
        sign_a = operand_a[15]; // Sign bit of A
        sign_b = operand_b[15]; // Sign bit of B

        exp_a = operand_a[14:10]; // Exponent bits of A
        exp_b = operand_b[14:10]; // Exponent bits of B

        // Check for zero, infinity, and NaN for operand A
        if (operand_a == 16'b0) begin
            zero_flag = 1'b1;
            mant_a = 11'b0; // Set mantissa to 0 for zero
        end else begin
            if (|operand_a[9:0] == 1'b1) begin
                mant_a = {1'b1, operand_a[9:0]}; // Implicit leading 1 for hidden bit
            end else begin
                mant_a = {1'b0, operand_a[9:0]}; // Implicit leading 0 for zero mantissa
            end
        end

        // Check for zero, infinity, and NaN for operand B
        if (operand_b == 16'b0) begin
            zero_flag = 1'b1;
            mant_b = 11'b0; // Set mantissa to 0 for zero
        end else begin
            if (|operand_b[9:0] == 1'b1) begin
                mant_b = {1'b1, operand_b[9:0]}; // Implicit leading 1 for hidden bit
            end else begin
                mant_b = {1'b0, operand_b[9:0]}; // Implicit leading 0 for zero mantissa
            end
        end

	zero_flag = ~mant_a[10] & ~mant_b[10];

        // Check for infinity and NaN for A
        if (exp_a == 5'b11111 && operand_a[9:0] == 10'b0) begin
            infinity_flag = 1'b1; // Check if A is infinity
        end else if (exp_a == 5'b11111 && operand_a[9:0] != 10'b0) begin
            NaN_flag = 1'b1; // Check if A is NaN
        end

        // Check for infinity and NaN for B
        if (exp_b == 5'b11111 && operand_b[9:0] == 10'b0) begin
            infinity_flag = 1'b1; // Check if B is infinity
        end else if (exp_b == 5'b11111 && operand_b[9:0] != 10'b0) begin
            NaN_flag = 1'b1; // Check if B is NaN
        end
    end

endmodule

module alignment_block (
    input sign_m,
    input sign_n,
    input [4:0] exp_m,              // Exponent of mantissa M
    input [4:0] exp_n,              // Exponent of mantissa N
    input [10:0] mant_m,            // Mantissa of M (10 bits)
    input [10:0] mant_n,            // Mantissa of N (10 bits)
    output reg [13:0] aligned_mantissa, // Aligned mantissa with guard, round, and sticky bits (14 bits)
    output reg [4:0] big_exponent,  // Big exponent
    output reg [10:0] big_mantissa,  // Big mantissa
    output reg final_sign,
    output reg operation_int
);

    wire [5:0] exp_diff;             // Absolute difference
    wire [10:0] man_diff;
    wire bigSel;

    // Calculate exponent difference
    kogge_stone_adder_6bit add1 (.A({1'b0, exp_m[4:0]}), .B({1'b1, ~exp_n[4:0]}), .cin(1'b1), .sum(exp_diff));
  kogge_stone_adder_11bit add2 (.x({1'b0, mant_m[9:0]}), .y({1'b1, ~mant_n[9:0]}), .sum(man_diff), .cin(1'b1));
  
    wire expDiffIsZero;
    assign expDiffIsZero = ~|exp_diff;
    wire manDiffIsZero;
    assign manDiffIsZero = ~|man_diff;

    // Determine the larger value based on exponents and mantissas
    assign bigSel = expDiffIsZero ? man_diff[10] : exp_diff[5];

    wire [3:0] shiftRtAmt = (exp_diff > 11) ? 4'b1011 : exp_diff[3:0];

    // Determine addition or subtraction based on signs
    wire operation = sign_m ^ sign_n;

    // Select the big and little mantissas for alignment
    wire signOut = bigSel ? sign_n : sign_m;
    wire [10:0] bigMan = bigSel ? mant_n : mant_m;
    wire [10:0] lilMan = bigSel ? mant_m : mant_n;

    // Shift the smaller mantissa to align with the larger one
    wire [10:0] shiftedMan;
    barrel_shifter_right_11bit rightShift (.in(lilMan), .ctrl(shiftRtAmt), .out(shiftedMan));

    // Define guard, round, and sticky bits
    wire guard = ((shiftRtAmt == 0) || (exp_diff > 11)) ? 1'b0 : lilMan[shiftRtAmt - 1];
    wire round = ((shiftRtAmt <= 1) || (exp_diff > 11)) ? 1'b0 : lilMan[shiftRtAmt - 2];

    // Mask to determine sticky bit by tracking bits shifted out
    reg [10:0] mask;
    always @(*) begin
        casez ({shiftRtAmt, (exp_diff > 11)})
            5'b00000: mask = 11'b00000000000;
            5'b00010: mask = 11'b00000000000;
            5'b00100: mask = 11'b00000000001;
            5'b00110: mask = 11'b00000000011;
            5'b01000: mask = 11'b00000000111;
            5'b01010: mask = 11'b00000001111;
            5'b01100: mask = 11'b00000011111;
            5'b01110: mask = 11'b00000111111;
            5'b10000: mask = 11'b00001111111;
            5'b10010: mask = 11'b00011111111;
            5'b10100: mask = 11'b00111111111;
            5'b10110: mask = 11'b01111111111;
            5'b????1: mask = 11'b11111111111;
            default: mask = 11'b00000000000;
        endcase
    end

    wire sticky = |(lilMan & mask);

    // Combine shifted mantissa, guard, round, and sticky bits
    wire [13:0] alignedMan = {shiftedMan, guard, round, sticky};

    assign aligned_mantissa = alignedMan;
    assign big_exponent = exp_m >= exp_n ? exp_m : exp_n;
    assign big_mantissa = bigMan;
    assign final_sign = signOut;
    assign operation_int = operation;
endmodule

module addition_block (
    input [13:0] aligned_mantissa,      // Aligned Mantissa (from alignment block, 14 bits)
    input [10:0] big_mantissa,           // Big Mantissa (from alignment block, 11 bits)
    input operation_int,
    input final_operation,                // Final operation (0: add, 1: subtract)
    output reg [14:0] resultant_mantissa // Resultant Mantissa (14 bits)
);
  wire [14:0] add_sum, sub_sum;
    reg [14:0] SDm_fa; // Sum/Difference for full adder output (14 bits to accommodate overflow)
    reg temp_sign;     // Temporary sign for the result
    reg operation;
  
    kogge_stone_adder_15bit add3(.x({1'b0, aligned_mantissa}), .y({1'b0, big_mantissa, 3'b0}), .sum(add_sum), .cin(1'b0));
  
    kogge_stone_adder_15bit sub1(.x({1'b0, big_mantissa, 3'b0}), .y({1'b0, ~aligned_mantissa}), .sum(sub_sum), .cin(1'b1));
  
    always @(*) begin
        // Initialize outputs
        resultant_mantissa = 0;
        SDm_fa = 0;
	
	operation = final_operation ^ operation_int;	

        // Check the final operation
        if (operation == 1'b0) begin // Addition
            // Add the aligned mantissa and big mantissa
            SDm_fa = add_sum;
        end else begin // Subtraction
            // Subtract the small mantissa from the big mantissa
            SDm_fa = sub_sum;
	      SDm_fa[14] = 0;
        end

        // Assign the resultant mantissa directly from the sum/difference
        resultant_mantissa = SDm_fa[14:0]; // Capture the upper 13 bits for the resultant mantissa        
    end
endmodule

module normalization_block (
    input [14:0] resultant_mantissa,      // 14-bit mantissa from addition block
    input [4:0] big_exponent,              // 5-bit exponent from alignment block
    input final_operation,
    input zero_flag,
    output reg [12:0] normalized_mantissa, // 13-bit normalized mantissa for rounding
    output reg [4:0] normalized_exponent    // 5-bit normalized exponent
);

    wire [3:0] leading_zero_count = 0;         // 4-bit leading zero count from priority encoder
    reg [14:0] shifted_mantissa;           // Mantissa after left shift
    wire [14:0] shifted_mantissa_temp; 
    reg AS;
    reg SS;
    wire [3:0] normAmt;
    wire [3:0] rawNormAmt;
    lzd14 lzd(resultant_mantissa[13:0], rawNormAmt, valid);
    assign normAmt = valid ? rawNormAmt : 4'b0;
  wire [14:0] resultant_mantissa_1bit;
  barrel_shifter_right_15bit_by_1bit rightShifter_1bit(.in(resultant_mantissa), .ctrl(1'b1), .out(resultant_mantissa_1bit));
    
    barrel_shifter_left_15bit leftShifter(.in(resultant_mantissa), .ctrl(normAmt), .out(shifted_mantissa_temp));
    always @(*) begin
        // Default values
        normalized_mantissa = resultant_mantissa[12:0];
        normalized_exponent = big_exponent;
	shifted_mantissa = 0;

	if (resultant_mantissa[14] == 1 && final_operation == 0) begin
	    if (zero_flag == 1) begin
            	AS = 1; SS = 0;
            end else begin
                AS = 1; SS = 1;
            end
    	end else begin
            AS = 0; SS = 0;
    	end
        
        shifted_mantissa = SS ? resultant_mantissa_1bit : resultant_mantissa;
        normalized_exponent = AS ? big_exponent + 1 : big_exponent;

    // Handle the case when there's a carry bit and non-zero mantissa
    if (shifted_mantissa[13] == 1) begin
        normalized_mantissa = shifted_mantissa[12:0];
    end
    // Handle normal leading-zero cases
    else if (shifted_mantissa[13] == 0 && AS == 0 && SS == 0) begin
        // Normalize for leading zeros
        if (normAmt < 13 && |resultant_mantissa == 1) begin
            // Left shift based on leading zero count if resultant_mantissa < 1
            shifted_mantissa = shifted_mantissa_temp;
            normalized_mantissa = shifted_mantissa[12:0];
            normalized_exponent = big_exponent + ~normAmt + 1;
        end 
        else if(normAmt == 13) begin
            normalized_exponent = big_exponent + ~normAmt + 1;
            normalized_mantissa = 0;
        end
    end    
    end
endmodule

module lzd14( 
    input [13:0] a,
    output [3:0] position,
    output valid 
);
    wire [2:0] pUpper, pLower;
    wire vUpper, vLower;

    lzd8 lzd8_1( a[13:6], pUpper[2:0], vUpper ); 
    lzd8 lzd8_2( {a[5:0], 2'b0}, pLower[2:0], vLower );  

    assign valid = vUpper | vLower;
    assign position[3] = ~vUpper;
    assign position[2] = vUpper ? pUpper[2] : pLower[2];
    assign position[1] = vUpper ? pUpper[1] : pLower[1];
    assign position[0] = vUpper ? pUpper[0] : pLower[0];
endmodule

 module lzd8( input [7:0] a,
    output [2:0] position,
    output valid );
    wire [1:0] pUpper, pLower;
    wire vUpper, vLower;
    lzd4 lzd4_1( a[7:4], pUpper[1:0], vUpper );
    lzd4 lzd4_2( a[3:0], pLower[1:0], vLower );
    assign valid = vUpper | vLower;
    assign position[2] = ~vUpper;
    assign position[1] = vUpper ? pUpper[1] : pLower[1];
    assign position[0] = vUpper ? pUpper[0] : pLower[0];
 endmodule

 module lzd4( input [3:0] a,
    output [1:0] position,
    output valid );
    wire pUpper, pLower, vUpper, vLower;
    lzd2 lzd2_1( a[3:2], pUpper, vUpper );
    lzd2 lzd2_2( a[1:0], pLower, vLower );
    assign valid = vUpper | vLower;
    assign position[1] = ~vUpper;
    assign position[0] = vUpper ? pUpper : pLower;
 endmodule

 module lzd2( input [1:0] a,
    output position,
    output valid );
    assign valid = a[1] | a[0];
    assign position = ~a[1];
 endmodule

module rounding_block (
    input [12:0] normalized_mantissa,  // Normalized 13-bit mantissa (including guard, round, sticky bits)
    input [4:0] normalized_exponent,   // Normalized 5-bit exponent
    input sign,                        // Final sign bit
    input infinity_flag,               // Flag indicating if the value is infinity
    input NaN_flag,                    // Flag indicating if the value is NaN
    output reg [15:0] result,          // Final 16-bit floating-point result
    output reg overflow_flag,          // Overflow flag
    output reg underflow_flag          // Underflow flag
);

    reg [4:0] final_exponent;          // Final exponent after rounding
    reg [9:0] final_mantissa;          // Final mantissa after rounding
    reg round_bit, guard_bit, sticky_bit; // Extracted PGRS bits

    always @(*) begin
        // Initialize flags
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;

        // Default values for exponent and mantissa
        final_exponent = normalized_exponent;
        final_mantissa = normalized_mantissa[12:3]; // Extract the top 10 bits

        // Extract PGRS bits
        guard_bit = normalized_mantissa[2];
        round_bit = normalized_mantissa[1];
        sticky_bit = normalized_mantissa[0];

        // Perform rounding based on the PGRS bits
        if (guard_bit && (round_bit || sticky_bit || final_mantissa[0])) begin
            // Round up if guard = 1 and (round = 1, sticky = 1, or mantissa is odd)
            final_mantissa = final_mantissa + 1'b1;
        end

        // Check for overflow (exponent too large)
        if (final_exponent == 5'b11111) begin
            overflow_flag = 1'b1;
            final_mantissa = 10'b0000000000; // Set mantissa to 0 for infinity
        end

        // Check for underflow (exponent too small)
        if (final_exponent == 5'b00000 && final_mantissa == 10'b0000000000) begin
            underflow_flag = 1'b1;
        end

        // Handle NaN case
        if (NaN_flag) begin
            final_exponent = 5'b11111;   // Set exponent to max (for NaN)
            final_mantissa = 10'b1111111111; // Set mantissa to all 1s for NaN
        end

        // Handle infinity case
        if (infinity_flag) begin
            final_exponent = 5'b11111;   // Set exponent to max (for infinity)
            final_mantissa = 10'b0000000000; // Set mantissa to 0 for infinity
        end

        // Pack the result into a 16-bit floating-point format
        result = {sign, final_exponent, final_mantissa};
    end
endmodule

module kogge_stone_adder_6bit (
    input [5:0] A,      // 6-bit input A
    input [5:0] B,      // 6-bit input B
    input cin,          // Carry-in
    output [5:0] sum   // 6-bit sum output
);

    // Internal wires for propagate and generate signals
    wire [5:0] P, G;           // Initial Propagate and Generate signals
    wire [5:0] G1, P1;         // Stage 1
    wire [5:0] G2, P2;         // Stage 2
    wire [5:0] G3, P3;         // Stage 3
    wire [5:0] G4;             // Stage 4 (final stage, only for generate)

    // Generate and Propagate signals for each bit
    assign P = A ^ B;          // Propagate: P[i] = A[i] ^ B[i]
    assign G = A & B;          // Generate: G[i] = A[i] & B[i]

    // Stage 1
    assign G1[0] = G[0] | (P[0] & cin);   // Carry generation for bit 0
    assign G1[1] = G[1] | (P[1] & G[0]);
    assign G1[2] = G[2] | (P[2] & G[1]);
    assign G1[3] = G[3] | (P[3] & G[2]);
    assign G1[4] = G[4] | (P[4] & G[3]);
    assign G1[5] = G[5] | (P[5] & G[4]);
    
    assign P1[0] = P[0] & cin;            // Propagate with carry-in
    assign P1[1] = P[1] & P[0];
    assign P1[2] = P[2] & P[1];
    assign P1[3] = P[3] & P[2];
    assign P1[4] = P[4] & P[3];
    assign P1[5] = P[5] & P[4];

    // Stage 2
    assign G2[0] = G1[0];
    assign G2[1] = G1[1];
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    assign G2[3] = G1[3] | (P1[3] & G1[1]);
    assign G2[4] = G1[4] | (P1[4] & G1[2]);
    assign G2[5] = G1[5] | (P1[5] & G1[3]);

    assign P2[0] = P1[0];
    assign P2[1] = P1[1];
    assign P2[2] = P1[2] & P1[0];
    assign P2[3] = P1[3] & P1[1];
    assign P2[4] = P1[4] & P1[2];
    assign P2[5] = P1[5] & P1[3];

    // Stage 3
    assign G3[0] = G2[0];
    assign G3[1] = G2[1];
    assign G3[2] = G2[2];
    assign G3[3] = G2[3] | (P2[3] & G2[0]);
    assign G3[4] = G2[4] | (P2[4] & G2[1]);
    assign G3[5] = G2[5] | (P2[5] & G2[2]);

    assign P3[0] = P2[0];
    assign P3[1] = P2[1];
    assign P3[2] = P2[2];
    assign P3[3] = P2[3] & P2[0];
    assign P3[4] = P2[4] & P2[1];
    assign P3[5] = P2[5] & P2[2];

    // Stage 4 (final stage)
    assign G4[0] = G3[0];
    assign G4[1] = G3[1];
    assign G4[2] = G3[2];
    assign G4[3] = G3[3];
    assign G4[4] = G3[4] | (P3[4] & G3[0]);
    assign G4[5] = G3[5] | (P3[5] & G3[1]);

    // Final Sum and Carry-Out
    assign sum[0] = P[0] ^ cin;           // Sum bit 0 with carry-in
    assign sum[1] = P[1] ^ G4[0];
    assign sum[2] = P[2] ^ G4[1];
    assign sum[3] = P[3] ^ G4[2];
    assign sum[4] = P[4] ^ G4[3];
    assign sum[5] = P[5] ^ G4[4];                  

endmodule

// 11-bit Kogge-Stone Adder
module kogge_stone_adder_11bit(x, y, sum, cin);
    // Kogge-Stone adder for 11-bit inputs
  input [10:0] x, y;  // 11-bit inputs
    input cin;          // Carry-in
  output [10:0] sum;   // 11-bit sum output

  wire [10:0] G_Z, P_Z,  // Intermediate wires
               G_A, P_A, 
               G_B, P_B, 
               G_C, P_C,
               G_D, P_D;

    // Level 1
    gray_cell level_0A(cin, P_Z[0], G_Z[0], G_A[0]);
    black_cell level_1A(G_Z[0], P_Z[1], G_Z[1], P_Z[0], G_A[1], P_A[1]);
    black_cell level_2A(G_Z[1], P_Z[2], G_Z[2], P_Z[1], G_A[2], P_A[2]);
    black_cell level_3A(G_Z[2], P_Z[3], G_Z[3], P_Z[2], G_A[3], P_A[3]);
    black_cell level_4A(G_Z[3], P_Z[4], G_Z[4], P_Z[3], G_A[4], P_A[4]);
    black_cell level_5A(G_Z[4], P_Z[5], G_Z[5], P_Z[4], G_A[5], P_A[5]);
    black_cell level_6A(G_Z[5], P_Z[6], G_Z[6], P_Z[5], G_A[6], P_A[6]);
    black_cell level_7A(G_Z[6], P_Z[7], G_Z[7], P_Z[6], G_A[7], P_A[7]);
    black_cell level_8A(G_Z[7], P_Z[8], G_Z[8], P_Z[7], G_A[8], P_A[8]);
    black_cell level_9A(G_Z[8], P_Z[9], G_Z[9], P_Z[8], G_A[9], P_A[9]);
    black_cell level_10A(G_Z[9], P_Z[10], G_Z[10], P_Z[9], G_A[10], P_A[10]);

    // Level 2
    gray_cell level_1B(cin, P_A[1], G_A[1], G_B[1]);
    gray_cell level_2B(G_A[0], P_A[2], G_A[2], G_B[2]);
    black_cell level_3B(G_A[1], P_A[3], G_A[3], P_A[1], G_B[3], P_B[3]);
    black_cell level_4B(G_A[2], P_A[4], G_A[4], P_A[2], G_B[4], P_B[4]);
    black_cell level_5B(G_A[3], P_A[5], G_A[5], P_A[3], G_B[5], P_B[5]);
    black_cell level_6B(G_A[4], P_A[6], G_A[6], P_A[4], G_B[6], P_B[6]);
    black_cell level_7B(G_A[5], P_A[7], G_A[7], P_A[5], G_B[7], P_B[7]);
    black_cell level_8B(G_A[6], P_A[8], G_A[8], P_A[6], G_B[8], P_B[8]);
    black_cell level_9B(G_A[7], P_A[9], G_A[9], P_A[7], G_B[9], P_B[9]);
    black_cell level_10B(G_A[8], P_A[10], G_A[10], P_A[8], G_B[10], P_B[10]);

    // Level 3
    gray_cell level_3C(cin, P_B[3], G_B[3], G_C[3]);
    gray_cell level_4C(G_A[0], P_B[4], G_B[4], G_C[4]);
    gray_cell level_5C(G_B[1], P_B[5], G_B[5], G_C[5]);
    gray_cell level_6C(G_B[2], P_B[6], G_B[6], G_C[6]);
    black_cell level_7C(G_B[3], P_B[7], G_B[7], P_B[3], G_C[7], P_C[7]);
    black_cell level_8C(G_B[4], P_B[8], G_B[8], P_B[4], G_C[8], P_C[8]);
    black_cell level_9C(G_B[5], P_B[9], G_B[9], P_B[5], G_C[9], P_C[9]);
    black_cell level_10C(G_B[6], P_B[10], G_B[10], P_B[6], G_C[10], P_C[10]);
  
    // Level 4
  	gray_cell level_7D(cin, P_C[7], G_C[7], G_D[7]);
  	gray_cell level_8D(G_A[0], P_C[8], G_C[8], G_D[8]);
  	gray_cell level_9D(G_B[1], P_C[9], G_C[9], G_D[9]);
  	gray_cell level_10D(G_B[2], P_C[10], G_C[10], G_D[10]);


    // XOR for sum calculation
    and_xor level_Z0(x[0], y[0], P_Z[0], G_Z[0]);
    and_xor level_Z1(x[1], y[1], P_Z[1], G_Z[1]);
    and_xor level_Z2(x[2], y[2], P_Z[2], G_Z[2]);
    and_xor level_Z3(x[3], y[3], P_Z[3], G_Z[3]);
    and_xor level_Z4(x[4], y[4], P_Z[4], G_Z[4]);
    and_xor level_Z5(x[5], y[5], P_Z[5], G_Z[5]);
    and_xor level_Z6(x[6], y[6], P_Z[6], G_Z[6]);
  	and_xor level_Z7(x[7], y[7], P_Z[7], G_Z[7]);
  	and_xor level_Z8(x[8], y[8], P_Z[8], G_Z[8]);
  	and_xor level_Z9(x[9], y[9], P_Z[9], G_Z[9]);
  	and_xor level_Z10(x[10], y[10], P_Z[10], G_Z[10]);

    // Sum output using XOR with propagate and generate signals
    xor(sum[0], cin, P_Z[0]);
    xor(sum[1], G_A[0], P_Z[1]);
    xor(sum[2], G_B[1], P_Z[2]);
    xor(sum[3], G_B[2], P_Z[3]);
    xor(sum[4], G_C[3], P_Z[4]);
    xor(sum[5], G_C[4], P_Z[5]);
  	xor(sum[6], G_C[5], P_Z[6]);
  	xor(sum[7], G_C[6], P_Z[7]);
  	xor(sum[8], G_D[7], P_Z[8]);
  	xor(sum[9], G_D[8], P_Z[9]);
  	xor(sum[10], G_D[9], P_Z[10]);

endmodule

module barrel_shifter_right_11bit (
    input [10:0] in,          // 11-bit input data
    input [3:0] ctrl,         // 4-bit control signal for shift amount (0 to 10)
    output [10:0] out         // 11-bit output data after shifting
);

  wire [10:0] x, y, z;

  // Stage 1: 8-bit shift right (shift by 2^3)
  mux2X1  mux1  (.in0(in[10]), .in1(1'b0), .sel(ctrl[3]), .out(x[10]));
  mux2X1  mux2  (.in0(in[9]),  .in1(1'b0), .sel(ctrl[3]), .out(x[9]));
  mux2X1  mux3  (.in0(in[8]),  .in1(1'b0), .sel(ctrl[3]), .out(x[8]));
  mux2X1  mux4  (.in0(in[7]),  .in1(1'b0), .sel(ctrl[3]), .out(x[7]));
  mux2X1  mux5  (.in0(in[6]),  .in1(1'b0), .sel(ctrl[3]), .out(x[6]));
  mux2X1  mux6  (.in0(in[5]),  .in1(1'b0), .sel(ctrl[3]), .out(x[5]));
  mux2X1  mux7  (.in0(in[4]),  .in1(1'b0), .sel(ctrl[3]), .out(x[4]));
  mux2X1  mux8  (.in0(in[3]),  .in1(1'b0), .sel(ctrl[3]), .out(x[3]));
  mux2X1  mux9  (.in0(in[2]),  .in1(in[10]), .sel(ctrl[3]), .out(x[2]));
  mux2X1  mux10 (.in0(in[1]),  .in1(in[9]), .sel(ctrl[3]), .out(x[1]));
  mux2X1  mux11 (.in0(in[0]),  .in1(in[8]),  .sel(ctrl[3]), .out(x[0]));

  // Stage 2: 4-bit shift right (shift by 2^2)
  mux2X1  mux12 (.in0(x[10]), .in1(1'b0), .sel(ctrl[2]), .out(y[10]));
  mux2X1  mux13 (.in0(x[9]),  .in1(1'b0), .sel(ctrl[2]), .out(y[9]));
  mux2X1  mux14 (.in0(x[8]),  .in1(1'b0), .sel(ctrl[2]), .out(y[8]));
  mux2X1  mux15 (.in0(x[7]),  .in1(1'b0),  .sel(ctrl[2]), .out(y[7]));
  mux2X1  mux16 (.in0(x[6]),  .in1(x[10]),  .sel(ctrl[2]), .out(y[6]));
  mux2X1  mux17 (.in0(x[5]),  .in1(x[9]),  .sel(ctrl[2]), .out(y[5]));
  mux2X1  mux18 (.in0(x[4]),  .in1(x[8]),  .sel(ctrl[2]), .out(y[4]));
  mux2X1  mux19 (.in0(x[3]),  .in1(x[7]),  .sel(ctrl[2]), .out(y[3]));
  mux2X1  mux20 (.in0(x[2]),  .in1(x[6]),  .sel(ctrl[2]), .out(y[2]));
  mux2X1  mux21 (.in0(x[1]),  .in1(x[5]),  .sel(ctrl[2]), .out(y[1]));
  mux2X1  mux22 (.in0(x[0]),  .in1(x[4]),  .sel(ctrl[2]), .out(y[0]));

  // Stage 3: 2-bit shift right (shift by 2^1)
  mux2X1  mux23 (.in0(y[10]), .in1(1'b0), .sel(ctrl[1]), .out(z[10]));
  mux2X1  mux24 (.in0(y[9]),  .in1(1'b0), .sel(ctrl[1]), .out(z[9]));
  mux2X1  mux25 (.in0(y[8]),  .in1(y[10]),  .sel(ctrl[1]), .out(z[8]));
  mux2X1  mux26 (.in0(y[7]),  .in1(y[9]),  .sel(ctrl[1]), .out(z[7]));
  mux2X1  mux27 (.in0(y[6]),  .in1(y[8]),  .sel(ctrl[1]), .out(z[6]));
  mux2X1  mux28 (.in0(y[5]),  .in1(y[7]),  .sel(ctrl[1]), .out(z[5]));
  mux2X1  mux29 (.in0(y[4]),  .in1(y[6]),  .sel(ctrl[1]), .out(z[4]));
  mux2X1  mux30 (.in0(y[3]),  .in1(y[5]),  .sel(ctrl[1]), .out(z[3]));
  mux2X1  mux31 (.in0(y[2]),  .in1(y[4]),  .sel(ctrl[1]), .out(z[2]));
  mux2X1  mux32 (.in0(y[1]),  .in1(y[3]),  .sel(ctrl[1]), .out(z[1]));
  mux2X1  mux33 (.in0(y[0]),  .in1(y[2]),  .sel(ctrl[1]), .out(z[0]));

  // Stage 4: 1-bit shift right (shift by 2^0)
  mux2X1  mux34 (.in0(z[10]), .in1(1'b0), .sel(ctrl[0]), .out(out[10]));
  mux2X1  mux35 (.in0(z[9]),  .in1(z[10]), .sel(ctrl[0]), .out(out[9]));
  mux2X1  mux36 (.in0(z[8]),  .in1(z[9]),  .sel(ctrl[0]), .out(out[8]));
  mux2X1  mux37 (.in0(z[7]),  .in1(z[8]),  .sel(ctrl[0]), .out(out[7]));
  mux2X1  mux38 (.in0(z[6]),  .in1(z[7]),  .sel(ctrl[0]), .out(out[6]));
  mux2X1  mux39 (.in0(z[5]),  .in1(z[6]),  .sel(ctrl[0]), .out(out[5]));
  mux2X1  mux40 (.in0(z[4]),  .in1(z[5]),  .sel(ctrl[0]), .out(out[4]));
  mux2X1  mux41 (.in0(z[3]),  .in1(z[4]),  .sel(ctrl[0]), .out(out[3]));
  mux2X1  mux42 (.in0(z[2]),  .in1(z[3]),  .sel(ctrl[0]), .out(out[2]));
  mux2X1  mux43 (.in0(z[1]),  .in1(z[2]),  .sel(ctrl[0]), .out(out[1]));
  mux2X1  mux44 (.in0(z[0]),  .in1(z[1]),  .sel(ctrl[0]), .out(out[0]));

endmodule

module mux2X1 (
    input in0,               // Input 0
    input in1,               // Input 1
    input sel,               // Select signal
    output out              // Output
);
  assign out = (sel) ? in1 : in0;  // Select between in0 and in1 based on sel
endmodule


module kogge_stone_adder_15bit(x, y, sum, cin);
    // Kogge-Stone adder for 15-bit inputs
    input [14:0] x, y;    // 15-bit inputs
    input cin;             // Carry-in
    output [14:0] sum;    // 15-bit sum output

    wire [14:0] G_Z, P_Z,  // Intermediate wires
                G_A, P_A, 
                G_B, P_B, 
                G_C, P_C,
                G_D, P_D;

    // Level 1
    gray_cell level_0A(cin, P_Z[0], G_Z[0], G_A[0]);
    black_cell level_1A(G_Z[0], P_Z[1], G_Z[1], P_Z[0], G_A[1], P_A[1]);
    black_cell level_2A(G_Z[1], P_Z[2], G_Z[2], P_Z[1], G_A[2], P_A[2]);
    black_cell level_3A(G_Z[2], P_Z[3], G_Z[3], P_Z[2], G_A[3], P_A[3]);
    black_cell level_4A(G_Z[3], P_Z[4], G_Z[4], P_Z[3], G_A[4], P_A[4]);
    black_cell level_5A(G_Z[4], P_Z[5], G_Z[5], P_Z[4], G_A[5], P_A[5]);
    black_cell level_6A(G_Z[5], P_Z[6], G_Z[6], P_Z[5], G_A[6], P_A[6]);
    black_cell level_7A(G_Z[6], P_Z[7], G_Z[7], P_Z[6], G_A[7], P_A[7]);
    black_cell level_8A(G_Z[7], P_Z[8], G_Z[8], P_Z[7], G_A[8], P_A[8]);
    black_cell level_9A(G_Z[8], P_Z[9], G_Z[9], P_Z[8], G_A[9], P_A[9]);
    black_cell level_10A(G_Z[9], P_Z[10], G_Z[10], P_Z[9], G_A[10], P_A[10]);
    black_cell level_11A(G_Z[10], P_Z[11], G_Z[11], P_Z[10], G_A[11], P_A[11]);
    black_cell level_12A(G_Z[11], P_Z[12], G_Z[12], P_Z[11], G_A[12], P_A[12]);
    black_cell level_13A(G_Z[12], P_Z[13], G_Z[13], P_Z[12], G_A[13], P_A[13]);
    black_cell level_14A(G_Z[13], P_Z[14], G_Z[14], P_Z[13], G_A[14], P_A[14]);

    // Level 2
    gray_cell level_1B(cin, P_A[1], G_A[1], G_B[1]);
    gray_cell level_2B(G_A[0], P_A[2], G_A[2], G_B[2]);
    black_cell level_3B(G_A[1], P_A[3], G_A[3], P_A[1], G_B[3], P_B[3]);
    black_cell level_4B(G_A[2], P_A[4], G_A[4], P_A[2], G_B[4], P_B[4]);
    black_cell level_5B(G_A[3], P_A[5], G_A[5], P_A[3], G_B[5], P_B[5]);
    black_cell level_6B(G_A[4], P_A[6], G_A[6], P_A[4], G_B[6], P_B[6]);
    black_cell level_7B(G_A[5], P_A[7], G_A[7], P_A[5], G_B[7], P_B[7]);
    black_cell level_8B(G_A[6], P_A[8], G_A[8], P_A[6], G_B[8], P_B[8]);
    black_cell level_9B(G_A[7], P_A[9], G_A[9], P_A[7], G_B[9], P_B[9]);
    black_cell level_10B(G_A[8], P_A[10], G_A[10], P_A[8], G_B[10], P_B[10]);
    black_cell level_11B(G_A[9], P_A[11], G_A[11], P_A[9], G_B[11], P_B[11]);
    black_cell level_12B(G_A[10], P_A[12], G_A[12], P_A[10], G_B[12], P_B[12]);
    black_cell level_13B(G_A[11], P_A[13], G_A[13], P_A[11], G_B[13], P_B[13]);
    black_cell level_14B(G_A[12], P_A[14], G_A[14], P_A[12], G_B[14], P_B[14]);

    // Level 3
    gray_cell level_3C(cin, P_B[3], G_B[3], G_C[3]);
    gray_cell level_4C(G_A[0], P_B[4], G_B[4], G_C[4]);
    gray_cell level_5C(G_B[1], P_B[5], G_B[5], G_C[5]);
    gray_cell level_6C(G_B[2], P_B[6], G_B[6], G_C[6]);
    black_cell level_7C(G_B[3], P_B[7], G_B[7], P_B[3], G_C[7], P_C[7]);
    black_cell level_8C(G_B[4], P_B[8], G_B[8], P_B[4], G_C[8], P_C[8]);
    black_cell level_9C(G_B[5], P_B[9], G_B[9], P_B[5], G_C[9], P_C[9]);
    black_cell level_10C(G_B[6], P_B[10], G_B[10], P_B[6], G_C[10], P_C[10]);
    black_cell level_11C(G_B[7], P_B[11], G_B[11], P_B[7], G_C[11], P_C[11]);
    black_cell level_12C(G_B[8], P_B[12], G_B[12], P_B[8], G_C[12], P_C[12]);
    black_cell level_13C(G_B[9], P_B[13], G_B[13], P_B[9], G_C[13], P_C[13]);
    black_cell level_14C(G_B[10], P_B[14], G_B[14], P_B[10], G_C[14], P_C[14]);

    // Level 4
    gray_cell level_7D(cin, P_C[7], G_C[7], G_D[7]);
    gray_cell level_8D(G_A[0], P_C[8], G_C[8], G_D[8]);
    gray_cell level_9D(G_B[1], P_C[9], G_C[9], G_D[9]);
    gray_cell level_10D(G_B[2], P_C[10], G_C[10], G_D[10]);
    gray_cell level_11D(G_B[3], P_C[11], G_C[11], G_D[11]);
    gray_cell level_12D(G_B[4], P_C[12], G_C[12], G_D[12]);
    gray_cell level_13D(G_B[5], P_C[13], G_C[13], G_D[13]);
    gray_cell level_14D(G_B[6], P_C[14], G_C[14], G_D[14]);

    // XOR for sum calculation
    and_xor level_Z0(x[0], y[0], P_Z[0], G_Z[0]);
    and_xor level_Z1(x[1], y[1], P_Z[1], G_Z[1]);
    and_xor level_Z2(x[2], y[2], P_Z[2], G_Z[2]);
    and_xor level_Z3(x[3], y[3], P_Z[3], G_Z[3]);
    and_xor level_Z4(x[4], y[4], P_Z[4], G_Z[4]);
    and_xor level_Z5(x[5], y[5], P_Z[5], G_Z[5]);
    and_xor level_Z6(x[6], y[6], P_Z[6], G_Z[6]);
    and_xor level_Z7(x[7], y[7], P_Z[7], G_Z[7]);
    and_xor level_Z8(x[8], y[8], P_Z[8], G_Z[8]);
    and_xor level_Z9(x[9], y[9], P_Z[9], G_Z[9]);
    and_xor level_Z10(x[10], y[10], P_Z[10], G_Z[10]);
    and_xor level_Z11(x[11], y[11], P_Z[11], G_Z[11]);
    and_xor level_Z12(x[12], y[12], P_Z[12], G_Z[12]);
    and_xor level_Z13(x[13], y[13], P_Z[13], G_Z[13]);
    and_xor level_Z14(x[14], y[14], P_Z[14], G_Z[14]);

    // Sum output using XOR with propagate and generate signals
    xor(sum[0], cin, P_Z[0]);
    xor(sum[1], G_A[0], P_Z[1]);
    xor(sum[2], G_B[1], P_Z[2]);
    xor(sum[3], G_B[2], P_Z[3]);
    xor(sum[4], G_C[3], P_Z[4]);
    xor(sum[5], G_C[4], P_Z[5]);
    xor(sum[6], G_C[5], P_Z[6]);
    xor(sum[7], G_C[6], P_Z[7]);
    xor(sum[8], G_D[7], P_Z[8]);
    xor(sum[9], G_D[8], P_Z[9]);
    xor(sum[10], G_D[9], P_Z[10]);
    xor(sum[11], G_D[10], P_Z[11]);
    xor(sum[12], G_D[11], P_Z[12]);
    xor(sum[13], G_D[12], P_Z[13]);
    xor(sum[14], G_D[13], P_Z[14]);

endmodule

module barrel_shifter_left_15bit (
  input [14:0] in,          // 11-bit input data
    input [3:0] ctrl,         // 4-bit control signal for shift amount (0 to 10)
  output [14:0] out         // 11-bit output data after shifting
);

  wire [14:0] x, y, z;

  // Stage 1: 8-bit shift left (shift by 2^3)
  mux2X1  mux1  (.in0(in[14]), .in1(in[6]), .sel(ctrl[3]), .out(x[14]));
  mux2X1  mux2  (.in0(in[13]),  .in1(in[5]), .sel(ctrl[3]), .out(x[13]));
  mux2X1  mux3  (.in0(in[12]),  .in1(in[4]), .sel(ctrl[3]), .out(x[12]));
  mux2X1  mux4  (.in0(in[11]),  .in1(in[3]), .sel(ctrl[3]), .out(x[11]));
  mux2X1  mux5  (.in0(in[10]), .in1(in[2]), .sel(ctrl[3]), .out(x[10]));
  mux2X1  mux6  (.in0(in[9]),  .in1(in[1]), .sel(ctrl[3]), .out(x[9]));
  mux2X1  mux7  (.in0(in[8]),  .in1(in[0]), .sel(ctrl[3]), .out(x[8]));
  mux2X1  mux8  (.in0(in[7]),  .in1(1'b0), .sel(ctrl[3]), .out(x[7]));
  mux2X1  mux9  (.in0(in[6]),  .in1(1'b0), .sel(ctrl[3]), .out(x[6]));
  mux2X1  mux10  (.in0(in[5]),  .in1(1'b0), .sel(ctrl[3]), .out(x[5]));
  mux2X1  mux11  (.in0(in[4]),  .in1(1'b0), .sel(ctrl[3]), .out(x[4]));
  mux2X1  mux12  (.in0(in[3]),  .in1(1'b0), .sel(ctrl[3]), .out(x[3]));
  mux2X1  mux13  (.in0(in[2]),  .in1(1'b0), .sel(ctrl[3]), .out(x[2]));
  mux2X1  mux14 (.in0(in[1]),  .in1(1'b0), .sel(ctrl[3]), .out(x[1]));
  mux2X1  mux15 (.in0(in[0]),  .in1(1'b0),  .sel(ctrl[3]), .out(x[0]));

  // Stage 2: 4-bit shift left (shift by 2^2)
  mux2X1  mux16 (.in0(x[14]), .in1(x[10]), .sel(ctrl[2]), .out(y[14]));
  mux2X1  mux17 (.in0(x[13]),  .in1(x[9]), .sel(ctrl[2]), .out(y[13]));
  mux2X1  mux18 (.in0(x[12]),  .in1(x[8]), .sel(ctrl[2]), .out(y[12]));
  mux2X1  mux19 (.in0(x[11]),  .in1(x[7]),  .sel(ctrl[2]), .out(y[11]));
  mux2X1  mux20 (.in0(x[10]), .in1(x[6]), .sel(ctrl[2]), .out(y[10]));
  mux2X1  mux21 (.in0(x[9]),  .in1(x[5]), .sel(ctrl[2]), .out(y[9]));
  mux2X1  mux22 (.in0(x[8]),  .in1(x[4]), .sel(ctrl[2]), .out(y[8]));
  mux2X1  mux23 (.in0(x[7]),  .in1(x[3]),  .sel(ctrl[2]), .out(y[7]));
  mux2X1  mux24 (.in0(x[6]),  .in1(x[2]),  .sel(ctrl[2]), .out(y[6]));
  mux2X1  mux25 (.in0(x[5]),  .in1(x[1]),  .sel(ctrl[2]), .out(y[5]));
  mux2X1  mux26 (.in0(x[4]),  .in1(x[0]),  .sel(ctrl[2]), .out(y[4]));
  mux2X1  mux27 (.in0(x[3]),  .in1(1'b0),  .sel(ctrl[2]), .out(y[3]));
  mux2X1  mux28 (.in0(x[2]),  .in1(1'b0),  .sel(ctrl[2]), .out(y[2]));
  mux2X1  mux29 (.in0(x[1]),  .in1(1'b0),  .sel(ctrl[2]), .out(y[1]));
  mux2X1  mux30 (.in0(x[0]),  .in1(1'b0),  .sel(ctrl[2]), .out(y[0]));

  // Stage 3: 2-bit shift left (shift by 2^1)
  mux2X1  mux31 (.in0(y[14]), .in1(y[12]), .sel(ctrl[1]), .out(z[14]));
  mux2X1  mux32 (.in0(y[13]),  .in1(y[11]), .sel(ctrl[1]), .out(z[13]));
  mux2X1  mux33 (.in0(y[12]),  .in1(y[10]),  .sel(ctrl[1]), .out(z[12]));
  mux2X1  mux34 (.in0(y[11]),  .in1(y[9]),  .sel(ctrl[1]), .out(z[11]));
  mux2X1  mux35 (.in0(y[10]), .in1(y[8]), .sel(ctrl[1]), .out(z[10]));
  mux2X1  mux36 (.in0(y[9]),  .in1(y[7]), .sel(ctrl[1]), .out(z[9]));
  mux2X1  mux37 (.in0(y[8]),  .in1(y[6]),  .sel(ctrl[1]), .out(z[8]));
  mux2X1  mux38 (.in0(y[7]),  .in1(y[5]),  .sel(ctrl[1]), .out(z[7]));
  mux2X1  mux39 (.in0(y[6]),  .in1(y[4]),  .sel(ctrl[1]), .out(z[6]));
  mux2X1  mux40 (.in0(y[5]),  .in1(y[3]),  .sel(ctrl[1]), .out(z[5]));
  mux2X1  mux41 (.in0(y[4]),  .in1(y[2]),  .sel(ctrl[1]), .out(z[4]));
  mux2X1  mux42 (.in0(y[3]),  .in1(y[1]),  .sel(ctrl[1]), .out(z[3]));
  mux2X1  mux43 (.in0(y[2]),  .in1(y[0]),  .sel(ctrl[1]), .out(z[2]));
  mux2X1  mux44 (.in0(y[1]),  .in1(1'b0),  .sel(ctrl[1]), .out(z[1]));
  mux2X1  mux45 (.in0(y[0]),  .in1(1'b0),  .sel(ctrl[1]), .out(z[0]));

  // Stage 4: 1-bit shift left (shift by 2^0)
  mux2X1  mux46 (.in0(z[14]), .in1(z[13]), .sel(ctrl[0]), .out(out[14]));
  mux2X1  mux47 (.in0(z[13]),  .in1(z[12]), .sel(ctrl[0]), .out(out[13]));
  mux2X1  mux48 (.in0(z[12]),  .in1(z[11]),  .sel(ctrl[0]), .out(out[12]));
  mux2X1  mux49 (.in0(z[11]),  .in1(z[10]),  .sel(ctrl[0]), .out(out[11]));
  mux2X1  mux50 (.in0(z[10]), .in1(z[9]), .sel(ctrl[0]), .out(out[10]));
  mux2X1  mux51 (.in0(z[9]),  .in1(z[8]), .sel(ctrl[0]), .out(out[9]));
  mux2X1  mux52 (.in0(z[8]),  .in1(z[7]),  .sel(ctrl[0]), .out(out[8]));
  mux2X1  mux53 (.in0(z[7]),  .in1(z[6]),  .sel(ctrl[0]), .out(out[7]));
  mux2X1  mux54 (.in0(z[6]),  .in1(z[5]),  .sel(ctrl[0]), .out(out[6]));
  mux2X1  mux55 (.in0(z[5]),  .in1(z[4]),  .sel(ctrl[0]), .out(out[5]));
  mux2X1  mux56 (.in0(z[4]),  .in1(z[3]),  .sel(ctrl[0]), .out(out[4]));
  mux2X1  mux57 (.in0(z[3]),  .in1(z[2]),  .sel(ctrl[0]), .out(out[3]));
  mux2X1  mux58 (.in0(z[2]),  .in1(z[1]),  .sel(ctrl[0]), .out(out[2]));
  mux2X1  mux59 (.in0(z[1]),  .in1(z[0]),  .sel(ctrl[0]), .out(out[1]));
  mux2X1  mux60 (.in0(z[0]),  .in1(1'b0),  .sel(ctrl[0]), .out(out[0]));

endmodule

module barrel_shifter_right_15bit_by_1bit (
  input [14:0] in,          // 11-bit input data
    input ctrl,         // 4-bit control signal for shift amount (0 to 10)
  output [14:0] out         // 11-bit output data after shifting
);

  // Stage 1: 8-bit shift right (shift by 2^0)
  mux2X1  mux1  (.in0(in[14]), .in1(1'b0), .sel(ctrl), .out(out[14]));
  mux2X1  mux2  (.in0(in[13]),  .in1(in[14]), .sel(ctrl), .out(out[13]));
  mux2X1  mux3  (.in0(in[12]),  .in1(in[13]), .sel(ctrl), .out(out[12]));
  mux2X1  mux4  (.in0(in[11]),  .in1(in[12]), .sel(ctrl), .out(out[11]));
  mux2X1  mux5  (.in0(in[10]), .in1(in[11]), .sel(ctrl), .out(out[10]));
  mux2X1  mux6  (.in0(in[9]),  .in1(in[10]), .sel(ctrl), .out(out[9]));
  mux2X1  mux7  (.in0(in[8]),  .in1(in[9]), .sel(ctrl), .out(out[8]));
  mux2X1  mux8  (.in0(in[7]),  .in1(in[8]), .sel(ctrl), .out(out[7]));
  mux2X1  mux9  (.in0(in[6]),  .in1(in[7]), .sel(ctrl), .out(out[6]));
  mux2X1  mux10  (.in0(in[5]),  .in1(in[6]), .sel(ctrl), .out(out[5]));
  mux2X1  mux11  (.in0(in[4]),  .in1(in[5]), .sel(ctrl), .out(out[4]));
  mux2X1  mux12  (.in0(in[3]),  .in1(in[4]), .sel(ctrl), .out(out[3]));
  mux2X1  mux13  (.in0(in[2]),  .in1(in[3]), .sel(ctrl), .out(out[2]));
  mux2X1  mux14 (.in0(in[1]),  .in1(in[2]), .sel(ctrl), .out(out[1]));
  mux2X1  mux15 (.in0(in[0]),  .in1(in[1]),  .sel(ctrl), .out(out[0]));

endmodule

`include "Floating_point_multiplier.v"