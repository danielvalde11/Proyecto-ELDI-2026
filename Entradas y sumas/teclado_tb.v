`timescale 1ns / 1ps
module teclado_tb;
    reg clk = 0;
    reg rst = 1;
    reg [3:0] x = 4'b1111; // Filas en pull-up (sin presionar)
    wire [3:0] y, tecla, registro;
    wire ena, validar;
    teclado uut (clk, rst, x, y, tecla, ena, registro, validar);
    always #5 clk = ~clk;
    initial begin
        $monitor("Tiempo: %0t | y (col): %b | x (fila): %b | tecla: %h | ena: %b | registro: %h", $time, y, x, tecla, ena, registro);
        #20 rst = 0;       // Apaga el reset
        #40 x = 4'b1101;   // Simula presionar un botón en la fila 1
        #40 x = 4'b1111;   // Simula soltar el botón
        #20 $finish;       // Termina la simulación
    end
endmodule