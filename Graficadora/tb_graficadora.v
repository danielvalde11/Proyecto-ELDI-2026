`timescale 1ns / 1ps

module tb_graficadora;

    reg clk;
    reg rst;
    reg inicio;
    reg [1:0] modo;
    reg [1:0] amplitud;

    wire DIN;
    wire CLK_MAX;
    wire CS_MAX;
    wire terminado;

    // Senales adicionales para facilitar las ondas en Vivado.
    wire [5:0] indice_decimal;
    wire [5:0] columna_decimal;
    wire [2:0] fila_seno_decimal;
    wire [2:0] fila_coseno_decimal;
    wire guardar_punto;
    wire cordic_listo;
    wire inicializacion_lista;
    wire visualizacion_lista;
    wire [2:0] estado_principal;

    real angulo_grados;
    real seno_decimal;
    real coseno_decimal;

    // Valores sincronizados: se actualizan cuando se guarda cada punto.
    // Son los mas faciles de interpretar en la ventana de ondas.
    real angulo_guardado_grados;
    real seno_guardado_decimal;
    real coseno_guardado_decimal;
    reg [5:0] indice_guardado;
    reg [2:0] fila_seno_guardada;
    reg [2:0] fila_coseno_guardada;

    integer puntos_calculados;

    integer fila;
    integer columna_i;
    integer pixeles;
    integer puntos_columna;
    reg [63:0] fila_actual;

    graficadora_top uut (
        .clk(clk),
        .rst(rst),
        .inicio(inicio),
        .modo(modo),
        .amplitud(amplitud),
        .DIN(DIN),
        .CLK_MAX(CLK_MAX),
        .CS_MAX(CS_MAX),
        .terminado(terminado)
    );

    // Solo en simulacion: acelera el enlace serial de los MAX7219.
    // No modifica el modulo de hardware ni los valores de la matriz.
    defparam uut.serial.DIVISOR = 1;

    assign indice_decimal = uut.indice;
    assign columna_decimal = uut.columna;
    assign fila_seno_decimal = uut.fila_sen;
    assign fila_coseno_decimal = uut.fila_cos;
    assign guardar_punto = uut.guardar;
    assign cordic_listo = uut.cordic_listo;
    assign inicializacion_lista = uut.inicializacion_lista;
    assign visualizacion_lista = uut.visualizacion_terminada;
    assign estado_principal = uut.estado_principal;

    always @(*) begin
        angulo_grados = indice_decimal * 5.625;
        seno_decimal = $itor($signed(uut.seno_final)) / 536870912.0;
        coseno_decimal = $itor($signed(uut.coseno_final)) / 536870912.0;
    end

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Comprobacion: deben guardarse 64 coordenadas por imagen.
    always @(posedge clk) begin
        if (rst || uut.limpiar) begin
            puntos_calculados <= 0;
            indice_guardado <= 0;
            fila_seno_guardada <= 0;
            fila_coseno_guardada <= 0;
            angulo_guardado_grados <= 0.0;
            seno_guardado_decimal <= 0.0;
            coseno_guardado_decimal <= 0.0;
        end
        else if (guardar_punto) begin
            puntos_calculados <= puntos_calculados + 1;
            indice_guardado <= uut.indice;
            fila_seno_guardada <= uut.fila_sen;
            fila_coseno_guardada <= uut.fila_cos;
            angulo_guardado_grados <= uut.indice * 5.625;
            seno_guardado_decimal <= $itor($signed(uut.seno_final)) / 536870912.0;
            coseno_guardado_decimal <= $itor($signed(uut.coseno_final)) / 536870912.0;
        end
    end

    // Se imprime la memoria real de la matriz: '#' = LED encendido.
    task mostrar_matriz;
        begin
            pixeles = 0;
            $display("       0        8       16       24       32       40       48       56");
            for (fila = 0; fila < 8; fila = fila + 1) begin
                fila_actual = uut.memoria.memoria[fila];
                $write("F%0d | ", fila);
                for (columna_i = 0; columna_i < 64; columna_i = columna_i + 1) begin
                    if (fila_actual[columna_i] === 1'b1) begin
                        $write("#");
                        pixeles = pixeles + 1;
                    end
                    else if (fila_actual[columna_i] === 1'b0)
                        $write(".");
                    else
                        $write("?");
                end
                $display(" |");
            end
            $display("Pixeles encendidos: %0d", pixeles);

            // Todas las columnas deben tener uno o dos pixeles,
            // segun el modo (seno, coseno o ambos).
            for (columna_i = 0; columna_i < 64; columna_i = columna_i + 1) begin
                puntos_columna = 0;
                for (fila = 0; fila < 8; fila = fila + 1)
                    if (uut.memoria.memoria[fila][columna_i] === 1'b1)
                        puntos_columna = puntos_columna + 1;

                if (puntos_columna == 0 ||
                    ((modo == 2'b00 || modo == 2'b01) && puntos_columna != 1) ||
                    (puntos_columna > 2)) begin
                    $display("ERROR: columna %0d con %0d LEDs", columna_i, puntos_columna);
                    $fatal(1, "Contenido incorrecto de la matriz");
                end
            end
        end
    endtask

    task probar_modo;
        input [1:0] nuevo_modo;
        input [1:0] nueva_amplitud;
        input integer numero_prueba;
        begin
            @(negedge clk);
            modo = nuevo_modo;
            amplitud = nueva_amplitud;
            inicio = 1'b1;

            @(negedge clk);
            inicio = 1'b0;

            // 'terminado' sube cuando los 64 puntos fueron guardados.
            @(posedge terminado);
            #1;

            $display("\n===============================================");
            $display("PRUEBA %0d | modo=%0d | amplitud=%0d",
                     numero_prueba, nuevo_modo, nueva_amplitud);
            $display("Tiempo: %0t ns | Puntos: %0d", $time, puntos_calculados);

            if (puntos_calculados != 64)
                $fatal(1, "No se almacenaron los 64 puntos");

            mostrar_matriz();
            $display("===============================================\n");
        end
    endtask

    initial begin
        rst = 1'b1;
        inicio = 1'b0;
        modo = 2'b00;
        amplitud = 2'b10;
        puntos_calculados = 0;

        repeat (4) @(negedge clk);
        rst = 1'b0;

        // El controlador debe configurar primero los MAX7219.
        wait (inicializacion_lista === 1'b1);
        $display("Inicializacion MAX7219 completada en %0t ns", $time);

        // modo: 00=seno, 01=coseno, 10=ambos.
        // amplitud: 00=1, 01=2, 10=3, 11=3.
        probar_modo(2'b00, 2'b10, 1); // seno, amplitud 3
        probar_modo(2'b01, 2'b01, 2); // coseno, amplitud 2
        probar_modo(2'b10, 2'b10, 3); // seno y coseno, amplitud 3

        // Esperar tambien la transmision de una imagen completa.
        @(posedge visualizacion_lista);
        #1;
        $display("Transmision completa de las ocho filas al MAX7219.");
        $display("TODAS LAS PRUEBAS FINALIZARON.");
        #20;
        $finish;
    end

    // Evita una simulacion infinita si hay un fallo de la FSM.
    initial begin
        #20000000;
        $fatal(1, "Tiempo limite: la graficadora no termino");
    end

endmodule
