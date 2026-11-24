`timescale 1ns / 1ps

module tb_calculadora_trig;

    reg clk;
    reg rst;
    reg inicio;
    reg [31:0] angulo_float;

    wire signed [31:0] coseno;
    wire signed [31:0] seno;
    wire listo;

    real coseno_decimal;
    real seno_decimal;

    calculadora_trig uut (
        .clk(clk),
        .rst(rst),
        .inicio(inicio),
        .angulo_float(angulo_float),
        .coseno(coseno),
        .seno(seno),
        .listo(listo)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task probar_angulo;
        input [31:0] angulo;
        input real grados;

        begin
            @(negedge clk);
            angulo_float = angulo;
            inicio = 1;

            @(negedge clk);
            inicio = 0;

            wait(listo == 1'b1);
            #10;

            coseno_decimal = $itor(coseno) / 536870912.0;
            seno_decimal = $itor(seno) / 536870912.0;

            $display("---------------------------------------");
            $display("Angulo: %f grados", grados);
            $display("Entrada IEEE-754: %h", angulo_float);
            $display("Coseno Q3.29: %d", coseno);
            $display("Seno Q3.29: %d", seno);
            $display("Coseno decimal: %f", coseno_decimal);
            $display("Seno decimal: %f", seno_decimal);

            #100;
        end
    endtask

    initial begin

        $dumpfile("cordic.vcd");
        $dumpvars(0, tb_calculadora_trig);

        rst = 1;
        inicio = 0;
        angulo_float = 0;

        #20;
        rst = 0;
        #20;

        probar_angulo(32'h00000000,   0.0);
        probar_angulo(32'h41F00000,  30.0);
        probar_angulo(32'h42340000,  45.0);
        probar_angulo(32'h42700000,  60.0);
        probar_angulo(32'h42B40000,  90.0);
        probar_angulo(32'h43070000, 135.0);
        probar_angulo(32'h43340000, 180.0);
        probar_angulo(32'h43610000, 225.0);
        probar_angulo(32'h43870000, 270.0);
        probar_angulo(32'h439D8000, 315.0);
        probar_angulo(32'h43B40000, 360.0);
        probar_angulo(32'h42360000,  45.5);
        probar_angulo(32'hC1F00000, -30.0);
        probar_angulo(32'hC1F20000, -30.25);

        $display("SIMULACION FINALIZADA");

        #100;
        $finish;
    end

    initial begin
        #100000;
        $display("ERROR: Tiempo limite de simulacion");
        $finish;
    end

endmodule