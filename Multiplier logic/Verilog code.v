`timescale 1ns / 1ps

module Multipler(
    input [31:0] A,
    input [31:0] B,
    output [31:0] S
    );
    wire [47:0] J;
    wire [23:0] concatenacionA;
    wire [23:0] concatenacionB;
    wire [7:0]  H;
    wire        signo;
    wire [7:0]  exp;
    wire [22:0] mantiza;
    assign H = 8'd127;
    assign signo = (A[31] && ~B[31] || ~A[31] && B[31]); //Calculo del signo con una XOR
    assign exp = (A[30:23] + B[30:23] + J[47]) - H; //multiplicacion de exponentes teniendo en cuenta el sesgo
    //concatenacion de A y B para multiplicacion de mantiza
    assign concatenacionA = {1'b1, A[22:0]}; 
    assign concatenacionB = {1'b1, B[22:0]};
    assign J = concatenacionB * concatenacionA;
    mux_2a1 mux_multiplier (
        .A(J[45:23]),
        .B(J[46:24]),
        .C(J[47]),
        .Y(mantiza)
    );
    assign S = {signo, exp, mantiza}; //resultado de la multiplicacion entre dos flotante

endmodule
module mux_2a1 (
    input  wire [22:0] A,
    input  wire [22:0] B,
    input  wire        C,
    output wire [22:0] Y
);
    assign Y = C ? B : A;
endmodule
