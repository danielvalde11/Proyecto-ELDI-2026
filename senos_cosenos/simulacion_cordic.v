`timescale 1ns / 1ps

module tb_calculadora_trig;

    reg clk;
    reg rst;
    reg inicio;
    reg [31:0] angulo_float;

    wire signed [31:0] coseno;
    wire signed [31:0] seno;
    wire listo;

    real angulo_grados;
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

    // Reloj de 10 ns (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Solo para visualizar los resultados Q3.29 en decimal.
    // Estas variables real pertenecen al testbench, no al hardware.
    always @(*) begin
        coseno_decimal = $itor($signed(coseno)) / 536870912.0;
        seno_decimal   = $itor($signed(seno))   / 536870912.0;
    end

    task probar_angulo;
        input [31:0] valor_ieee754;
        input real valor_grados;
        begin
            @(negedge clk);
            angulo_float = valor_ieee754;
            angulo_grados = valor_grados;
            inicio = 1'b1;

            @(negedge clk);
            inicio = 1'b0;

            @(posedge listo);
            #1;
            $display("Tiempo=%0t ns | Angulo=%0.1f grados | Cos=%0.6f | Sen=%0.6f",
                     $time, angulo_grados, coseno_decimal, seno_decimal);

            repeat (4) @(negedge clk);
        end
    endtask

    initial begin
        rst = 1'b1;
        inicio = 1'b0;
        angulo_float = 32'h00000000;
        angulo_grados = 0.0;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        probar_angulo(32'h00000000,    0.0);
        probar_angulo(32'h41F00000,   30.0);
        probar_angulo(32'h42340000,   45.0);
        probar_angulo(32'h42B40000,   90.0);
        probar_angulo(32'h43070000,  135.0);
        probar_angulo(32'h43610000,  225.0);
        probar_angulo(32'h439D8000,  315.0);
        probar_angulo(32'hC1F00000,  -30.0);

        $display("Simulacion CORDIC terminada.");
        #20;
        $finish;
    end

    // Evita una simulacion infinita si listo no llega a activarse.
    initial begin
        #10000;
        $display("ERROR: tiempo limite sin completar todas las pruebas.");
        $finish;
    end

endmodule
