'timescale 1ns / 1ps
module suma(
    input clk,
    input rst,
    input wire [31:0] A,
    input wire [31:0] B,
    input wire operacion,
    output reg [31:0] C
);
// definir resta
wire [31:0] Ba;

 