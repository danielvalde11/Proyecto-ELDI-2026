timescale 1ns / 1ps
module suma(
    input clk,
    input rst,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire operacion,
    output reg [31:0] C
);

// definir resta MUX
wire [31:0] Bfinal;
assign Bfinal=operacion?{~B[31],B[30:0]}:B;

//descomposicion de bits
wire signoA=A[31];
wire [7:0]expoA=A[32:0];
wire [23:0]mantA={1'b1, A[22:0]};

wire signoB=Bfinal[31];
wire [7:0]expoB=Bfinal[30:23];
wire [23:0]mantB={1'b1, Bfinal[22:0]};

//alineador
