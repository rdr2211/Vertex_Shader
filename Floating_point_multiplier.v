//////////////////////////////////////
//FLOATING POINT MULTIPLIER
//////////////////////////////////////

// Floating point multiplier

module Floating_point_multiplier (
    input clk,
    input rst,
  input [15:0] A,
  input [15:0] B,
  output [15:0] result
);
  
  reg reg_SA, reg_SB;
  reg [4:0] reg_EA, reg_EB;
  reg [9:0] reg_MA, reg_MB;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      reg_EA <= 5'b0;
      reg_EB <= 5'b0;
      reg_MA <= 10'b0;
      reg_MB <= 10'b0;
      reg_SA <= 1'b0;
      reg_SB <= 1'b0;
    end
    else begin
      reg_EA <= A[14:10];
      reg_EB <= B[14:10];
      reg_MA <= A[9:0];
      reg_MB <= B[9:0];
      reg_SA <= A[15];
      reg_SB <= B[15];
    end
  end
   
      wire [23:0] result_int;
  wire [11:0] MA_int, MB_int;
  assign MA_int = (|reg_EA[4:0]) ? {2'b01, reg_MA} : {2'b00, reg_MA};
  assign MB_int = (|reg_EB[4:0]) ? {2'b01, reg_MB} : {2'b00, reg_MB};
      
  Booth_Multiplier mult (.M(MA_int), .Q({MB_int}), .product(result_int));

      reg [21:0] reg_M;
      reg [4:0] reg_EA_final, reg_EB_final;
      reg reg_SA_final, reg_SB_final;
      
      always @(posedge clk or posedge rst) begin
        if(rst) begin
          reg_M <= 22'b0;
          reg_EA_final <= 5'b0;
          reg_EB_final <= 5'b0;
          reg_SA_final <= 1'b0;
          reg_SB_final <= 1'b0;
        end
        else begin
          reg_M <= result_int[21:0];
          reg_EA_final <= reg_EA;
          reg_EB_final <= reg_EB;
          reg_SA_final <= reg_SA;
          reg_SB_final <= reg_SB;
        end
      end
    

      assign result[0] = (reg_M[21] == 1'b1) ? reg_M[11] : reg_M[10];
      assign result[1] = (reg_M[21] == 1'b1) ? reg_M[12] : reg_M[11];
      assign result[2] = (reg_M[21] == 1'b1) ? reg_M[13] : reg_M[12];
      assign result[3] = (reg_M[21] == 1'b1) ? reg_M[14] : reg_M[13];
      assign result[4] = (reg_M[21] == 1'b1) ? reg_M[15] : reg_M[14];
      assign result[5] = (reg_M[21] == 1'b1) ? reg_M[16] : reg_M[15];
      assign result[6] = (reg_M[21] == 1'b1) ? reg_M[17] : reg_M[16];
      assign result[7] = (reg_M[21] == 1'b1) ? reg_M[18] : reg_M[17];
      assign result[8] = (reg_M[21] == 1'b1) ? reg_M[19] : reg_M[18];
      assign result[9] = (reg_M[21] == 1'b1) ? reg_M[20] : reg_M[19];

      wire C0, C1, C2, C3, C4;
      assign result[10] = (reg_M[21] == 1'b1) ? ((reg_EA_final[0] ^ reg_EB_final[0] ^ 1'b1) ^ 1'b1) : ((reg_EA_final[0] ^ reg_EB_final[0]) ^ 1'b1);
                                                                                   assign C0 = (reg_M[21] == 1'b1) ? (((reg_EA_final[0] & reg_EB_final[0]) | ((reg_EA_final[0] ^ reg_EB_final[0]) & 1'b1)) & 1'b1) : ((reg_EA_final[0] & reg_EB_final[0]) & 1'b1);
                                                                                   assign result[11] = reg_EA_final[1] ^ reg_EB_final[1] ^ C0;
      assign C1 = (reg_EA_final[1] & reg_EB_final[1]) | ((reg_EA_final[1] ^ reg_EB_final[1]) & C0);
      assign result[12] = reg_EA_final[2] ^ reg_EB_final[2] ^ C1;
      assign C2 = (reg_EA_final[2] & reg_EB_final[2]) | ((reg_EA_final[2] ^ reg_EB_final[2]) & C1);
      assign result[13] = reg_EA_final[3] ^ reg_EB_final[3] ^ C2;
      assign C3 = (reg_EA_final[3] & reg_EB_final[3]) | ((reg_EA_final[3] ^ reg_EB_final[3]) & C2);
      assign result[14] = (reg_EA_final[4] ^ reg_EB_final[4] ^ C3) ^ 1'b1;
      assign C4 = ((reg_EA_final[4] & reg_EB_final[4]) | ((reg_EA_final[4] ^ reg_EB_final[4]) & C3)) & 1'b1;
      assign result[15] = reg_SA_final ^ reg_SB_final;

endmodule







//////////////////////////
//BOOTH MULTIPLIER
//////////////////////////                                                                                                       

module Booth_Multiplier(input wire [11:0] M, input wire [11:0] Q,
                        output wire [23:0] product);
    
  wire [23:0] PP1,PP2,PP3,PP4,PP5,PP6;
    Booth_Encoder Stage1 (
        .M(M),
        .Q(Q),
        .PP1(PP1),
        .PP2(PP2),
        .PP3(PP3),
        .PP4(PP4),
        .PP5(PP5),
        .PP6(PP6)
    );
    //Addition Stage
  // wire [23:0] product_temp;
    Wallace_Tree Stage2(.PP1(PP1),.PP2(PP2),.PP3(PP3),.PP4(PP4),
    .PP5(PP5),.PP6(PP6),.product(product));
endmodule

module Booth_Encoder(input wire [11:0] M, input wire [11:0] Q,
                     output wire [23:0] PP1,PP2,PP3,PP4,PP5,PP6);
    //M is 12-bit multiplicand, Q is 12-bit multiplier
    //PP1~6 is 24-bit partial product

    //Booth Encoding of multiplier
    wire Q_init = 1'b0; //Q(-1)
  
    //We will have 6 windows for a 12-bit signed multiplier
    wire [2:0] W1,W2,W3,W4,W5,W6,W7,W8;
  
    //Each window is in the form of [Qi+1,Qi,Qi-1]
    //There is one-bit overlap bewtween each window
    assign W1 = {Q[1],Q[0],Q_init};
    assign W2 = {Q[3],Q[2],Q[1]};
    assign W3 = {Q[5],Q[4],Q[3]};
    assign W4 = {Q[7],Q[6],Q[5]};
    assign W5 = {Q[9],Q[8],Q[7]};
    assign W6 = {Q[11],Q[10],Q[9]};
    
  
    //Then we need to calculate partial product PPi
    //First we need to sign-extend the multiplicand M
    wire [23:0] M_se = {{12{M[11]}},M};
  
    //Then, we need to decode those windows to have partial product for Wallace tree
    //Five different flags of Booth Encoding
    wire [23:0] PP_zero = 32'b0;
    wire [23:0] PP_pos_M = M_se;
    wire [23:0] PP_neg_M;
    KSA_top_level KSA_for_PP_neg_M(.x(~M_se),.y(24'b0),.cin(1'b1),.sum(PP_neg_M),.cout());
    wire [23:0] PP_pos_2M = M_se<<1;
    wire [23:0] PP_neg_2M = PP_neg_M<<1;
    
    //Partial Product 1
    wire [23:0] PP1_flag;
    assign PP1_flag = (W1[2])?(W1[1]?(W1[0]?PP_zero:PP_neg_M):(W1[0]?PP_neg_M:PP_neg_2M))
    :(W1[1]?(W1[0]?PP_pos_2M:PP_pos_M):(W1[0]?PP_pos_M:PP_zero));
    assign PP1 = PP1_flag;
  
    //Partial Product 2
    wire [23:0] PP2_flag;
    assign PP2_flag = (W2[2])?(W2[1]?(W2[0]?PP_zero:PP_neg_M):(W2[0]?PP_neg_M:PP_neg_2M))
    :(W2[1]?(W2[0]?PP_pos_2M:PP_pos_M):(W2[0]?PP_pos_M:PP_zero));
    assign PP2 = PP2_flag<<2;
    
    //Partial Product 3
    wire [23:0] PP3_flag;
    assign PP3_flag = (W3[2])?(W3[1]?(W3[0]?PP_zero:PP_neg_M):(W3[0]?PP_neg_M:PP_neg_2M))
    :(W3[1]?(W3[0]?PP_pos_2M:PP_pos_M):(W3[0]?PP_pos_M:PP_zero));
    assign PP3 = PP3_flag<<4;
    
    //Partial Product 4
    wire [23:0] PP4_flag;
    assign PP4_flag = (W4[2])?(W4[1]?(W4[0]?PP_zero:PP_neg_M):(W4[0]?PP_neg_M:PP_neg_2M))
    :(W4[1]?(W4[0]?PP_pos_2M:PP_pos_M):(W4[0]?PP_pos_M:PP_zero));
    assign PP4 = PP4_flag<<6;
  
    //Partial Product 5
    wire [23:0] PP5_flag;
    assign PP5_flag = (W5[2])?(W5[1]?(W5[0]?PP_zero:PP_neg_M):(W5[0]?PP_neg_M:PP_neg_2M))
    :(W5[1]?(W5[0]?PP_pos_2M:PP_pos_M):(W5[0]?PP_pos_M:PP_zero));
    assign PP5 = PP5_flag<<8;
  
    //Partial Product 6
    wire [23:0] PP6_flag;
    assign PP6_flag = (W6[2])?(W6[1]?(W6[0]?PP_zero:PP_neg_M):(W6[0]?PP_neg_M:PP_neg_2M))
    :(W6[1]?(W6[0]?PP_pos_2M:PP_pos_M):(W6[0]?PP_pos_M:PP_zero));
    assign PP6 = PP6_flag<<10;
endmodule

module CSA(input wire [23:0] A,B,D,
           output wire [23:0] PS, PC);
    //A + B + D
    //PS stands for Partial Sum
    //PC stands for Partial Carry
    FA FA0(.a(A[0]),.b(B[0]),.cin(D[0]),.sum(PS[0]),.cout(PC[0]));
    FA FA1(.a(A[1]),.b(B[1]),.cin(D[1]),.sum(PS[1]),.cout(PC[1]));
    FA FA2(.a(A[2]),.b(B[2]),.cin(D[2]),.sum(PS[2]),.cout(PC[2]));
    FA FA3(.a(A[3]), .b(B[3]), .cin(D[3]), .sum(PS[3]), .cout(PC[3]));
    FA FA4(.a(A[4]), .b(B[4]), .cin(D[4]), .sum(PS[4]), .cout(PC[4]));
    FA FA5(.a(A[5]), .b(B[5]), .cin(D[5]), .sum(PS[5]), .cout(PC[5]));
    FA FA6(.a(A[6]), .b(B[6]), .cin(D[6]), .sum(PS[6]), .cout(PC[6]));
    FA FA7(.a(A[7]), .b(B[7]), .cin(D[7]), .sum(PS[7]), .cout(PC[7]));
    FA FA8(.a(A[8]), .b(B[8]), .cin(D[8]), .sum(PS[8]), .cout(PC[8]));
    FA FA9(.a(A[9]), .b(B[9]), .cin(D[9]), .sum(PS[9]), .cout(PC[9]));
    FA FA10(.a(A[10]), .b(B[10]), .cin(D[10]), .sum(PS[10]), .cout(PC[10]));
    FA FA11(.a(A[11]), .b(B[11]), .cin(D[11]), .sum(PS[11]), .cout(PC[11]));
    FA FA12(.a(A[12]), .b(B[12]), .cin(D[12]), .sum(PS[12]), .cout(PC[12]));
    FA FA13(.a(A[13]), .b(B[13]), .cin(D[13]), .sum(PS[13]), .cout(PC[13]));
    FA FA14(.a(A[14]), .b(B[14]), .cin(D[14]), .sum(PS[14]), .cout(PC[14]));
    FA FA15(.a(A[15]), .b(B[15]), .cin(D[15]), .sum(PS[15]), .cout(PC[15]));
    FA FA16(.a(A[16]), .b(B[16]), .cin(D[16]), .sum(PS[16]), .cout(PC[16]));
    FA FA17(.a(A[17]), .b(B[17]), .cin(D[17]), .sum(PS[17]), .cout(PC[17]));
    FA FA18(.a(A[18]), .b(B[18]), .cin(D[18]), .sum(PS[18]), .cout(PC[18]));
    FA FA19(.a(A[19]), .b(B[19]), .cin(D[19]), .sum(PS[19]), .cout(PC[19]));
    FA FA20(.a(A[20]), .b(B[20]), .cin(D[20]), .sum(PS[20]), .cout(PC[20]));
    FA FA21(.a(A[21]), .b(B[21]), .cin(D[21]), .sum(PS[21]), .cout(PC[21]));
    FA FA22(.a(A[22]), .b(B[22]), .cin(D[22]), .sum(PS[22]), .cout(PC[22]));
    FA FA23(.a(A[23]), .b(B[23]), .cin(D[23]), .sum(PS[23]), .cout(PC[23]));
endmodule

module FA(input wire a,b,cin,
output wire sum,cout);
    assign sum = a^b^cin;
    assign cout = (a&b)|(a&cin)|(b&cin);
endmodule

module Wallace_Tree(input wire [23:0] PP1,PP2,PP3,PP4,PP5,PP6,
                    output wire [23:0] product);
    //Stage-1
    wire [23:0] S1A1_PS,S1A1_PC,S1A2_PS,S1A2_PC;
    CSA Stage1_CSA1(.A(PP1),.B(PP2),.D(PP3),.PS(S1A1_PS),.PC(S1A1_PC));
    CSA Stage1_CSA2(.A(PP4),.B(PP5),.D(PP6),.PS(S1A2_PS),.PC(S1A2_PC));
  
    //Stage-2
    wire [23:0] S2A1_PS,S2A1_PC;
    CSA Stage2_CSA1(.A(S1A1_PS),.B(S1A1_PC<<1),.D(S1A2_PS),.PS(S2A1_PS),.PC(S2A1_PC));
    
    //Stage-3
  wire [23:0] S3A1_PC,S3A1_PS;
  CSA Stage3_CSA(.A(S2A1_PS),.B(S2A1_PC<<1),.D(S1A2_PC<<1),.PS(S3A1_PS),.PC(S3A1_PC));
    
    //Stage-4
  KSA_top_level Stage5_KSA(.x(S3A1_PS),.y({S3A1_PC[22:0],1'b0}),.cin(1'b0),.sum(product),.cout());
endmodule

module KSA_top_level(x, y, sum, cin, cout);
    // Kogge Stone adder for 24-bit inputs
  input [23:0] x, y;  // 24-bit inputs
  input cin;           // Carry-in
  output [23:0] sum;   // 24-bit sum output
  output cout;

  wire [23:0] G_Z, P_Z,   // Intermediate wires
              G_A, P_A, 
              G_B, P_B, 
              G_C, P_C,
              G_D, P_D,
              G_E, P_E;

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
  black_cell level_15A(G_Z[14], P_Z[15], G_Z[15], P_Z[14], G_A[15], P_A[15]);
  black_cell level_16A(G_Z[15], P_Z[16], G_Z[16], P_Z[15], G_A[16], P_A[16]);
  black_cell level_17A(G_Z[16], P_Z[17], G_Z[17], P_Z[16], G_A[17], P_A[17]);
  black_cell level_18A(G_Z[17], P_Z[18], G_Z[18], P_Z[17], G_A[18], P_A[18]);
  black_cell level_19A(G_Z[18], P_Z[19], G_Z[19], P_Z[18], G_A[19], P_A[19]);
  black_cell level_20A(G_Z[19], P_Z[20], G_Z[20], P_Z[19], G_A[20], P_A[20]);
  black_cell level_21A(G_Z[20], P_Z[21], G_Z[21], P_Z[20], G_A[21], P_A[21]);
  black_cell level_22A(G_Z[21], P_Z[22], G_Z[22], P_Z[21], G_A[22], P_A[22]);
  black_cell level_23A(G_Z[22], P_Z[23], G_Z[23], P_Z[22], G_A[23], P_A[23]);

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
  black_cell level_15B(G_A[13], P_A[15], G_A[15], P_A[13], G_B[15], P_B[15]);
  black_cell level_16B(G_A[14], P_A[16], G_A[16], P_A[14], G_B[16], P_B[16]);
  black_cell level_17B(G_A[15], P_A[17], G_A[17], P_A[15], G_B[17], P_B[17]);
  black_cell level_18B(G_A[16], P_A[18], G_A[18], P_A[16], G_B[18], P_B[18]);
  black_cell level_19B(G_A[17], P_A[19], G_A[19], P_A[17], G_B[19], P_B[19]);
  black_cell level_20B(G_A[18], P_A[20], G_A[20], P_A[18], G_B[20], P_B[20]);
  black_cell level_21B(G_A[19], P_A[21], G_A[21], P_A[19], G_B[21], P_B[21]);
  black_cell level_22B(G_A[20], P_A[22], G_A[22], P_A[20], G_B[22], P_B[22]);
  black_cell level_23B(G_A[21], P_A[23], G_A[23], P_A[21], G_B[23], P_B[23]);

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
  black_cell level_15C(G_B[11], P_B[15], G_B[15], P_B[11], G_C[15], P_C[15]);
  black_cell level_16C(G_B[12], P_B[16], G_B[16], P_B[12], G_C[16], P_C[16]);
  black_cell level_17C(G_B[13], P_B[17], G_B[17], P_B[13], G_C[17], P_C[17]);
  black_cell level_18C(G_B[14], P_B[18], G_B[18], P_B[14], G_C[18], P_C[18]);
  black_cell level_19C(G_B[15], P_B[19], G_B[19], P_B[15], G_C[19], P_C[19]);
  black_cell level_20C(G_B[16], P_B[20], G_B[20], P_B[16], G_C[20], P_C[20]);
  black_cell level_21C(G_B[17], P_B[21], G_B[21], P_B[17], G_C[21], P_C[21]);
  black_cell level_22C(G_B[18], P_B[22], G_B[22], P_B[18], G_C[22], P_C[22]);
  black_cell level_23C(G_B[19], P_B[23], G_B[23], P_B[19], G_C[23], P_C[23]);

  // Level 4
  gray_cell level_7D(cin, P_C[7], G_C[7], G_D[7]);
  gray_cell level_8D(G_A[0], P_C[8], G_C[8], G_D[8]);
  gray_cell level_9D(G_B[1], P_C[9], G_C[9], G_D[9]);
  gray_cell level_10D(G_B[2], P_C[10], G_C[10], G_D[10]);
  gray_cell level_11D(G_C[3], P_C[11], G_C[11], G_D[11]);
  gray_cell level_12D(G_C[4], P_C[12], G_C[12], G_D[12]);
  gray_cell level_13D(G_C[5], P_C[13], G_C[13], G_D[13]);
  gray_cell level_14D(G_C[6], P_C[14], G_C[14], G_D[14]);
  black_cell level_15D(G_C[7], P_C[15], G_C[15], P_C[7], G_D[15], P_D[15]);
  black_cell level_16D(G_C[8], P_C[16], G_C[16], P_C[8], G_D[16], P_D[16]);
  black_cell level_17D(G_C[9], P_C[17], G_C[17], P_C[9], G_D[17], P_D[17]);
  black_cell level_18D(G_C[10], P_C[18], G_C[18], P_C[10], G_D[18], P_D[18]);
  black_cell level_19D(G_C[11], P_C[19], G_C[19], P_C[11], G_D[19], P_D[19]);
  black_cell level_20D(G_C[12], P_C[20], G_C[20], P_C[12], G_D[20], P_D[20]);
  black_cell level_21D(G_C[13], P_C[21], G_C[21], P_C[13], G_D[21], P_D[21]);
  black_cell level_22D(G_C[14], P_C[22], G_C[22], P_C[14], G_D[22], P_D[22]);
  black_cell level_23D(G_C[15], P_C[23], G_C[23], P_C[15], G_D[23], P_D[23]);
  
  // Level 5
  gray_cell level_15E(cin, P_D[15], G_D[15], G_E[15]);
  gray_cell level_16E(G_A[0], P_D[16], G_D[16], G_E[16]);
  gray_cell level_17E(G_B[1], P_D[17], G_D[17], G_E[17]);
  gray_cell level_18E(G_B[2], P_D[18], G_D[18], G_E[18]);
  gray_cell level_19E(G_C[3], P_D[19], G_D[19], G_E[19]);
  gray_cell level_20E(G_C[4], P_D[20], G_D[20], G_E[20]);
  gray_cell level_21E(G_C[5], P_D[21], G_D[21], G_E[21]);
  gray_cell level_22E(G_C[6], P_D[22], G_D[22], G_E[22]);
  gray_cell level_23E(G_D[7], P_D[23], G_D[23], G_E[23]);

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
  and_xor level_Z15(x[15], y[15], P_Z[15], G_Z[15]);
  and_xor level_Z16(x[16], y[16], P_Z[16], G_Z[16]);
  and_xor level_Z17(x[17], y[17], P_Z[17], G_Z[17]);
  and_xor level_Z18(x[18], y[18], P_Z[18], G_Z[18]);
  and_xor level_Z19(x[19], y[19], P_Z[19], G_Z[19]);
  and_xor level_Z20(x[20], y[20], P_Z[20], G_Z[20]);
  and_xor level_Z21(x[21], y[21], P_Z[21], G_Z[21]);
  and_xor level_Z22(x[22], y[22], P_Z[22], G_Z[22]);
  and_xor level_Z23(x[23], y[23], P_Z[23], G_Z[23]);

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
  xor(sum[15], G_D[14], P_Z[15]);
  xor(sum[16], G_E[15], P_Z[16]);
  xor(sum[17], G_E[16], P_Z[17]);
  xor(sum[18], G_E[17], P_Z[18]);
  xor(sum[19], G_E[18], P_Z[19]);
  xor(sum[20], G_E[19], P_Z[20]);
  xor(sum[21], G_E[20], P_Z[21]);
  xor(sum[22], G_E[21], P_Z[22]);
  xor(sum[23], G_E[22], P_Z[23]);
  
  assign cout = G_E[23];
  
endmodule

module gray_cell(Gkj, Pik, Gik, G);
    // Gray cell for Kogge-Stone adder
    input Gkj, Pik, Gik;
    output G;
    wire Y;
    and(Y, Gkj, Pik);
    or(G, Y, Gik);
endmodule

module black_cell(Gkj, Pik, Gik, Pkj, G, P);
    // Black cell for Kogge-Stone adder
    input Gkj, Pik, Gik, Pkj;
    output G, P;
    wire Y;

    and(Y, Gkj, Pik);
    or(G, Gik, Y); 
    and(P, Pkj, Pik);
endmodule

module and_xor(a, b, p, g);
    // First stage of the AND/XOR logic (for sum calculation)
    input a, b;
    output p, g;
    xor(p, a, b);
    and(g, a, b);
endmodule

