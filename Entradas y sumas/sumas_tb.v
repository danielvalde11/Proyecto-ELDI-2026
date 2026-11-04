`timescale 1ns / 1ps

module tb_suma;

reg clk;
reg rst;
reg [31:0] A;
reg [31:0] B;
reg operacion;
wire [31:0] C;

suma uut (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .operacion(operacion),
    .C(C)
);

// Reloj de 10 ns
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Inicializacion
    rst = 1;
    A = 32'h00000000;
    B = 32'h00000000;
    operacion = 0;

    #20;
    rst = 0;

    // PRUEBA 1: 2.0 + 3.0 = 5.0
    A = 32'h40000000;
    B = 32'h40400000;
    operacion = 0;

    #100;

    // PRUEBA 2: 2.0 - 1.0 = 1.0
    A = 32'h40000000;
    B = 32'h3F800000;
    operacion = 1;

    #100;

    // PRUEBA 3: 2.0 + 1.0 = 3.0
    A = 32'h40000000;
    B = 32'h3F800000;
    operacion = 0;

    #100;

    // PRUEBA 4: 4.0 + 2.0 = 6.0
    A = 32'h40800000;
    B = 32'h40000000;
    operacion = 0;

    #100;

    // PRUEBA 5: 8.0 + 0.5 = 8.5
    A = 32'h41000000;
    B = 32'h3F000000;
    operacion = 0;

    #100;

    // PRUEBA 6: -2.0 + 3.0 = 1.0
    A = 32'hC0000000;
    B = 32'h40400000;
    operacion = 0;

    #100;

    $finish;
end

initial begin
    $monitor("Tiempo=%0t | A=%h | B=%h | Operacion=%b | C=%h",
             $time, A, B, operacion, C);
end

