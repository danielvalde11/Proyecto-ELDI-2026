`timescale 1ns / 1ps

module divider(
    input [31:0] A,
    input [31:0] B,
    output [31:0] S 
);
assign H = 8'd127;
assign S[31] = (A[31]&&~B[31] || ~A[31]&&B[31]);
assign S[30:23] = (A[31:23] - B[31:23])+ H;

endmodule
