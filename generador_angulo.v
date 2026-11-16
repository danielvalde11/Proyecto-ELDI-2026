
module generador_angulo(
    input wire [5:0] indice,
    output reg signed [31:0] angulo_ref,
    output reg signo_cos,
    output reg signo_sen
);

    localparam signed [31:0] PASO = 32'sd52707179;

    reg [1:0] cuadrante;
    reg [3:0] desplazamiento;
    reg [4:0] k;
    reg signed [31:0] k_ext;

    always @(*) begin

        cuadrante = indice[5:4];
        desplazamiento = indice[3:0];

        k = 5'd0;
        signo_cos = 1'b0;
        signo_sen = 1'b0;

        case (cuadrante)

            2'b00: begin
                k = {1'b0, desplazamiento};
                signo_cos = 1'b0;
                signo_sen = 1'b0;
            end

            2'b01: begin
                k = 5'd16 - {1'b0, desplazamiento};
                signo_cos = 1'b1;
                signo_sen = 1'b0;
            end

            2'b10: begin
                k = {1'b0, desplazamiento};
                signo_cos = 1'b1;
                signo_sen = 1'b1;
            end

            2'b11: begin
                k = 5'd16 - {1'b0, desplazamiento};
                signo_cos = 1'b0;
                signo_sen = 1'b1;
            end

            default: begin
                k = 5'd0;
                signo_cos = 1'b0;
                signo_sen = 1'b0;
            end

        endcase

        k_ext = $signed({27'd0, k});
        angulo_ref = k_ext * PASO;

    end

endmodule


module contador_indice(
    input wire clk,
    input wire rst,
    input wire limpiar,
    input wire avanzar,
    output reg [5:0] indice,
    output wire fin
);
    always @(posedge clk) begin
        if (rst)
            indice <= 6'd0;
        else if (limpiar)
            indice <= 6'd0;
        else if (avanzar)
            indice <= indice + 1'b1;
    end
    assign fin = (indice == 6'd63);
endmodule


module fsm(
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire hecho,
    input wire fin,

    output reg limpiar,
    output reg avanzar,
    output reg inicio_cordic,
    output reg guardar,
    output reg terminado
);

    localparam espera     = 3'd0;
    localparam limpiar_m  = 3'd1;
    localparam generar    = 3'd2;
    localparam calcular   = 3'd3;
    localparam almacenar  = 3'd4;
    localparam verificar  = 3'd5;
    localparam finalizar  = 3'd6;

    reg [2:0] estado_actual;
    reg [2:0] estado_siguiente;

    // REGISTRO DE ESTADO

    always @(posedge clk) begin
        if (rst)
            estado_actual <= espera;
        else
            estado_actual <= estado_siguiente;
    end

    // LOGICA DE TRANSICION

    always @(*) begin

        estado_siguiente = estado_actual;

        case (estado_actual)

            espera: begin
                if (inicio)
                    estado_siguiente = limpiar_m;
            end

            limpiar_m: begin
                estado_siguiente = generar;
            end

            generar: begin
                estado_siguiente = calcular;
            end

            calcular: begin
                if (hecho)
                    estado_siguiente = almacenar;
            end

            almacenar: begin
                estado_siguiente = verificar;
            end

            verificar: begin
                if (fin)
                    estado_siguiente = finalizar;
                else
                    estado_siguiente = generar;
            end

            finalizar: begin
                estado_siguiente = espera;
            end

            default: begin
                estado_siguiente = espera;
            end

        endcase

    end

    // LOGICA DE SALIDAS

    always @(*) begin

        limpiar = 1'b0;
        avanzar = 1'b0;
        inicio_cordic = 1'b0;
        guardar = 1'b0;
        terminado = 1'b0;

        case (estado_actual)

            limpiar_m: begin
                limpiar = 1'b1;
            end

            generar: begin
                inicio_cordic = 1'b1;
            end

            calcular: begin
            end

            almacenar: begin
                guardar = 1'b1;
            end

            verificar: begin
                avanzar = !fin;
            end

            finalizar: begin
                terminado = 1'b1;
            end

            default: begin
            end

        endcase

    end

endmodule


module registro_coordenadas(
    input wire clk,
    input wire rst,
    input wire guardar,
    input wire [5:0] indice,
    input wire [5:0] indice_lectura,
    input wire signo_cos,
    input wire signo_sen,
    input wire signed [31:0] seno,
    input wire signed [31:0] coseno,
    output reg signed [31:0] coordenada_x,
    output reg signed [31:0] coordenada_y
);
    reg signed [31:0] memoria_sen [0:63];
    reg signed [31:0] memoria_cos [0:63];
    reg signed [31:0] seno_final;
    reg signed [31:0] coseno_final;
    always @(*) begin
        seno_final = signo_sen ? -seno : seno;
        coseno_final = signo_cos ? -coseno : coseno;
    end
    always @(posedge clk) begin
        if (!rst && guardar) begin
            memoria_sen[indice] <= seno_final;
            memoria_cos[indice] <= coseno_final;
        end
    end
    always @(*) begin
        coordenada_x = memoria_cos[indice_lectura];
        coordenada_y = memoria_sen[indice_lectura];
    end
endmodule


module conversor_coordenadas(
    input wire [5:0] indice,
    input wire signed [31:0] seno_q329,
    input wire signed [31:0] coseno_q329,
    input wire [1:0] amplitud,

    output reg [5:0] columna,
    output reg [2:0] fila_sen,
    output reg [2:0] fila_cos
);

    localparam signed [31:0] UNO = 32'sd536870912;

    reg signed [31:0] seno_limitado;
    reg signed [31:0] coseno_limitado;

    reg signed [63:0] producto_sen;
    reg signed [63:0] producto_cos;

    reg signed [63:0] desplazamiento_sen;
    reg signed [63:0] desplazamiento_cos;

    reg signed [63:0] resultado_sen;
    reg signed [63:0] resultado_cos;

    reg signed [31:0] escala;

    always @(*) begin

        columna = indice;

        case (amplitud)
            2'b00: escala = 32'sd1;
            2'b01: escala = 32'sd2;
            2'b10: escala = 32'sd3;
            2'b11: escala = 32'sd3;
            default: escala = 32'sd3;
        endcase

        if (seno_q329 > UNO)
            seno_limitado = UNO;
        else if (seno_q329 < -UNO)
            seno_limitado = -UNO;
        else
            seno_limitado = seno_q329;

        if (coseno_q329 > UNO)
            coseno_limitado = UNO;
        else if (coseno_q329 < -UNO)
            coseno_limitado = -UNO;
        else
            coseno_limitado = coseno_q329;

        producto_sen = seno_limitado * escala;
        producto_cos = coseno_limitado * escala;

        desplazamiento_sen = producto_sen >>> 29;
        desplazamiento_cos = producto_cos >>> 29;

        resultado_sen = 64'sd3 - desplazamiento_sen;
        resultado_cos = 64'sd3 - desplazamiento_cos;

        if (resultado_sen < 0)
            fila_sen = 3'd0;
        else if (resultado_sen > 7)
            fila_sen = 3'd7;
        else
            fila_sen = resultado_sen[2:0];

        if (resultado_cos < 0)
            fila_cos = 3'd0;
        else if (resultado_cos > 7)
            fila_cos = 3'd7;
        else
            fila_cos = resultado_cos[2:0];

    end

endmodule


module memoria_matriz(
    input wire clk,
    input wire rst,
    input wire limpiar,
    input wire guardar,

    input wire [1:0] modo,

    input wire [5:0] columna,
    input wire [2:0] fila_sen,
    input wire [2:0] fila_cos,
    input wire [2:0] indice_fila,

    output reg [63:0] datos_fila
);

    reg [63:0] memoria [0:7];

    integer i;

    always @(posedge clk) begin

        if (rst || limpiar) begin

            for (i = 0; i < 8; i = i + 1)
                memoria[i] <= 64'd0;

        end

        else if (guardar) begin

            case (modo)

                2'b00: begin
                    memoria[fila_sen][columna] <= 1'b1;
                end

                2'b01: begin
                    memoria[fila_cos][columna] <= 1'b1;
                end

                2'b10: begin
                    memoria[fila_sen][columna] <= 1'b1;
                    memoria[fila_cos][columna] <= 1'b1;
                end

                2'b11: begin
                    memoria[fila_sen][columna] <= 1'b1;
                    memoria[fila_cos][columna] <= 1'b1;
                end

                default: begin
                end

            endcase

        end

    end

    always @(*) begin
        datos_fila = memoria[indice_fila];
    end

endmodule

module fsm_max7219(
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire transmision_lista,
    input wire fin_filas,

    output reg leer_fila,
    output reg cargar,
    output reg transmitir,
    output reg latch,
    output reg avanzar_fila,
    output reg terminado
);

    localparam ESPERA     = 3'd0;
    localparam PREPARAR   = 3'd1;
    localparam CARGAR     = 3'd2;
    localparam INICIAR_TX = 3'd3;
    localparam ESPERAR_TX = 3'd4;
    localparam FINALIZAR  = 3'd5;
    localparam SIGUIENTE  = 3'd6;
    localparam TERMINADO  = 3'd7;

    reg [2:0] estado_actual;
    reg [2:0] estado_siguiente;

    // REGISTRO DE ESTADOS

    always @(posedge clk) begin
        if (rst)
            estado_actual <= ESPERA;
        else
            estado_actual <= estado_siguiente;
    end

    // LOGICA DE TRANSICION

    always @(*) begin

        estado_siguiente = estado_actual;

        case (estado_actual)

            ESPERA: begin
                if (inicio)
                    estado_siguiente = PREPARAR;
            end

            PREPARAR: begin
                estado_siguiente = CARGAR;
            end

            CARGAR: begin
                estado_siguiente = INICIAR_TX;
            end

            INICIAR_TX: begin
                estado_siguiente = ESPERAR_TX;
            end

            ESPERAR_TX: begin
                if (transmision_lista)
                    estado_siguiente = FINALIZAR;
            end

            FINALIZAR: begin
                estado_siguiente = SIGUIENTE;
            end

            SIGUIENTE: begin
                if (fin_filas)
                    estado_siguiente = TERMINADO;
                else
                    estado_siguiente = PREPARAR;
            end

            TERMINADO: begin
                estado_siguiente = ESPERA;
            end

            default: begin
                estado_siguiente = ESPERA;
            end

        endcase

    end

    // LOGICA DE SALIDAS

    always @(*) begin

        leer_fila = 1'b0;
        cargar = 1'b0;
        transmitir = 1'b0;
        latch = 1'b0;
        avanzar_fila = 1'b0;
        terminado = 1'b0;

        case (estado_actual)

            PREPARAR: begin
                leer_fila = 1'b1;
            end

            CARGAR: begin
                cargar = 1'b1;
            end

            INICIAR_TX: begin
                transmitir = 1'b1;
            end

            ESPERAR_TX: begin
            end

            FINALIZAR: begin
                latch = 1'b1;
            end

            SIGUIENTE: begin
                avanzar_fila = !fin_filas;
            end

            TERMINADO: begin
                terminado = 1'b1;
            end

            default: begin
            end

        endcase

    end

endmodule

module registro_desplazamiento(
    input wire clk,
    input wire rst,
    input wire cargar,
    input wire desplazar,
    input wire [127:0] datos_entrada,
    output wire dato_serial
);
    // Registro interno de 128 bits
    reg [127:0] registro;
    // Bit que se envia al MAX7219
    assign dato_serial = registro[127];
    always @(posedge clk) begin
        if (rst) begin
            registro <= 128'd0;
        end
        // Carga paralela de los 128 bits
        else if (cargar) begin
            registro <= datos_entrada;
        end
        // Desplazamiento de un bit
        else if (desplazar) begin
            registro <= {registro[126:0], 1'b0};
        end
    end
endmodule

module empaquetador_max7219(
    input wire [63:0] datos_fila,
    input wire [2:0] indice_fila,
    output reg [127:0] datos_empaquetados
);
    reg [7:0] direccion;
    integer i;
    always @(*) begin
        // Direccion del registro de fila del MAX7219
        direccion = {5'b00000, indice_fila} + 8'd1;
        // Inicializar salida
        datos_empaquetados = 128'd0;
        // Crear las ocho instrucciones de 16 bits
        for (i = 0; i < 8; i = i + 1) begin
            datos_empaquetados[i*16 +: 16] =
                {direccion, datos_fila[i*8 +: 8]};
        end
    end
endmodule

module contador_bits(
    input wire clk,
    input wire rst,
    input wire limpiar,
    input wire contar,
    output reg [7:0] contador,
    output wire fin
);
    // Contar los 128 bits transmitidos
    always @(posedge clk) begin
        if (rst)
            contador <= 8'd0;
        else if (limpiar)
            contador <= 8'd0;
        else if (contar && !fin)
            contador <= contador + 1'b1;
    end
    // Indica que se transmitieron los 128 bits
    assign fin = (contador == 8'd128);
endmodule

module divisor_frecuencia #(
    parameter DIVISOR = 500
)(
    input wire clk,
    input wire rst,
    output reg tick
);
    localparam ANCHO = $clog2(DIVISOR);
    reg [ANCHO-1:0] contador;
    always @(posedge clk) begin
        if (rst) begin
            contador <= 0;
            tick <= 0;
        end
        else begin
            if (contador == DIVISOR - 1) begin
                contador <= 0;
                tick <= 1'b1;
            end
            else begin
                contador <= contador + 1'b1;
                tick <= 1'b0;
            end
        end
    end
endmodule


module controlador_serial #(
    parameter DIVISOR = 50
)(
    input wire clk,
    input wire rst,
    input wire cargar,
    input wire transmitir,
    input wire [127:0] datos_serial,
    output reg DIN,
    output reg CLK,
    output reg CS,
    output reg transmision_lista,
    output wire ocupado
);
    localparam ESPERA = 3'd0;
    localparam PREPARAR = 3'd1;
    localparam BAJO = 3'd2;
    localparam SUBIR = 3'd3;
    localparam ALTO = 3'd4;
    localparam BAJAR = 3'd5;
    localparam FIN = 3'd6;

    reg [2:0] estado;
    reg [127:0] desplazamiento;
    reg [6:0] contador_bits;
    reg [31:0] contador_reloj;

    assign ocupado = (estado != ESPERA);

    always @(posedge clk) begin
        if (rst) begin
            estado <= ESPERA;
            desplazamiento <= 128'd0;
            contador_bits <= 7'd0;
            contador_reloj <= 32'd0;
            DIN <= 1'b0;
            CLK <= 1'b0;
            CS <= 1'b1;
            transmision_lista <= 1'b0;
        end else begin
            transmision_lista <= 1'b0;
            case (estado)
                ESPERA: begin
                    CLK <= 1'b0;
                    CS <= 1'b1;
                    contador_reloj <= 32'd0;
                    if (cargar)
                        desplazamiento <= datos_serial;
                    if (transmitir && !cargar) begin
                        contador_bits <= 7'd0;
                        estado <= PREPARAR;
                    end
                end
                PREPARAR: begin
                    CS <= 1'b0;
                    CLK <= 1'b0;
                    DIN <= desplazamiento[127];
                    contador_reloj <= 32'd0;
                    estado <= BAJO;
                end
                BAJO: begin
                    if (contador_reloj == DIVISOR - 1) begin
                        contador_reloj <= 32'd0;
                        estado <= SUBIR;
                    end else
                        contador_reloj <= contador_reloj + 1'b1;
                end
                SUBIR: begin
                    CLK <= 1'b1;
                    estado <= ALTO;
                end
                ALTO: begin
                    if (contador_reloj == DIVISOR - 1) begin
                        contador_reloj <= 32'd0;
                        estado <= BAJAR;
                    end else
                        contador_reloj <= contador_reloj + 1'b1;
                end
                BAJAR: begin
                    CLK <= 1'b0;
                    if (contador_bits == 7'd127)
                        estado <= FIN;
                    else begin
                        desplazamiento <= {desplazamiento[126:0], 1'b0};
                        contador_bits <= contador_bits + 1'b1;
                        estado <= PREPARAR;
                    end
                end
                FIN: begin
                    CS <= 1'b1;
                    transmision_lista <= 1'b1;
                    estado <= ESPERA;
                end
                default: begin
                    estado <= ESPERA;
                    CLK <= 1'b0;
                    CS <= 1'b1;
                end
            endcase
        end
    end
endmodule


module graficadora_top (
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire [1:0] modo,
    input wire [1:0] amplitud,
    output wire DIN,
    output wire CLK_MAX,
    output wire CS_MAX,
    output wire terminado
);
    // CONTROL PRINCIPAL
    localparam INICIALIZAR = 3'd0;
    localparam ESPERAR_INICIO = 3'd1;
    localparam CALCULANDO = 3'd2;
    localparam INICIAR_VIS = 3'd3;
    localparam ESPERAR_VIS = 3'd4;
    reg [2:0] estado_principal;
    reg inicio_anterior;
    reg solicitud;
    reg imagen_lista;
    reg [1:0] modo_reg;
    reg [1:0] amplitud_reg;
    wire pulso_inicio;
    wire arrancar_calculo;
    wire arrancar_visual;
    assign pulso_inicio = inicio && !inicio_anterior;
    assign arrancar_calculo =
        (estado_principal == ESPERAR_INICIO &&
         solicitud) ||
        (estado_principal == ESPERAR_VIS &&
         visualizacion_terminada &&
         solicitud);
    assign arrancar_visual =
        (estado_principal == INICIAR_VIS);
    // FSM DE CALCULO
    wire limpiar;
    wire avanzar;
    wire inicio_cordic;
    wire guardar;
    wire calculo_terminado;
    // GENERADOR DE ANGULOS
    wire [5:0] indice;
    wire fin_indice;
    wire signed [31:0] angulo_ref;
    wire signo_cos;
    wire signo_sen;
    // CORDIC
    wire signed [31:0] seno;
    wire signed [31:0] coseno;
    wire cordic_ocupado;
    wire cordic_listo;
    wire signed [31:0] seno_final;
    wire signed [31:0] coseno_final;
    // COORDENADAS
    wire [5:0] columna;
    wire [2:0] fila_sen;
    wire [2:0] fila_cos;
    // MEMORIA
    reg [2:0] indice_fila;
    wire [63:0] datos_fila;
    // EMPAQUETADOR
    wire [127:0] datos_empaquetados;
    // FSM MAX7219
    wire leer_fila;
    wire cargar_visual;
    wire transmitir_visual;
    wire latch;
    wire avanzar_fila;
    wire visualizacion_terminada;
    wire fin_filas;
    // INICIALIZADOR
    wire cargar_init;
    wire transmitir_init;
    wire [127:0] datos_init;
    wire inicializacion_lista;
    // CONTROL SERIAL COMPARTIDO
    wire cargar_serial;
    wire transmitir_serial;
    wire [127:0] datos_serial;
    wire transmision_lista;
    wire serial_ocupado;
    // FSM PRINCIPAL
    always @(posedge clk) begin
        if (rst) begin
            estado_principal <= INICIALIZAR;
            inicio_anterior <= 1'b0;
            solicitud <= 1'b0;
            modo_reg <= 2'b10;
            amplitud_reg <= 2'b10;
            imagen_lista <= 1'b0;
        end else begin
            inicio_anterior <= inicio;
            // Registrar peticiones nuevas
            if (arrancar_calculo)
                solicitud <= 1'b0;
            else if (pulso_inicio)
                solicitud <= 1'b1;
            case (estado_principal)
                INICIALIZAR: begin
                    if (inicializacion_lista)
                        estado_principal <= ESPERAR_INICIO;
                end
                ESPERAR_INICIO: begin
                    if (arrancar_calculo) begin
                        modo_reg <= modo;
                        amplitud_reg <= amplitud;
                        imagen_lista <= 1'b0;
                        estado_principal <= CALCULANDO;
                    end
                end
                CALCULANDO: begin
                    if (calculo_terminado) begin
                        imagen_lista <= 1'b1;
                        estado_principal <= INICIAR_VIS;
                    end
                end
                INICIAR_VIS: begin
                    estado_principal <= ESPERAR_VIS;
                end
                ESPERAR_VIS: begin
                    if (visualizacion_terminada) begin
                        if (solicitud) begin
                            modo_reg <= modo;
                            amplitud_reg <= amplitud;
                            imagen_lista <= 1'b0;
                            estado_principal <= CALCULANDO;
                        end else begin
                            estado_principal <= INICIAR_VIS;
                        end
                    end
                end
                default: begin
                    estado_principal <= INICIALIZAR;
                end
            endcase
        end
    end
    // CONTADOR DE INDICE
    contador_indice contador (
        .clk(clk),
        .rst(rst),
        .limpiar(limpiar),
        .avanzar(avanzar),
        .indice(indice),
        .fin(fin_indice)
    );
    // GENERADOR DE ANGULO
    generador_angulo generador (
        .indice(indice),
        .angulo_ref(angulo_ref),
        .signo_cos(signo_cos),
        .signo_sen(signo_sen)
    );
    // CORDIC
    cordic calculadora (
        .clk(clk),
        .rst(rst),
        .inicio(inicio_cordic),
        .angulo(angulo_ref),
        .cos(coseno),
        .sen(seno),
        .A(cordic_ocupado),
        .B(cordic_listo)
    );
    assign seno_final =
        signo_sen ? -seno : seno;
    assign coseno_final =
        signo_cos ? -coseno : coseno;
    // CONVERSOR DE COORDENADAS
    conversor_coordenadas conversor (
        .indice(indice),
        .seno_q329(seno_final),
        .coseno_q329(coseno_final),
        .amplitud(amplitud_reg),
        .columna(columna),
        .fila_sen(fila_sen),
        .fila_cos(fila_cos)
    );
    // FSM GRAFICADORA
    fsm control_calculo (
        .clk(clk),
        .rst(rst),
        .inicio(arrancar_calculo),
        .hecho(cordic_listo),
        .fin(fin_indice),
        .limpiar(limpiar),
        .avanzar(avanzar),
        .inicio_cordic(inicio_cordic),
        .guardar(guardar),
        .terminado(calculo_terminado)
    );
    // MEMORIA DE MATRIZ
    memoria_matriz memoria (
        .clk(clk),
        .rst(rst),
        .limpiar(limpiar),
        .guardar(guardar),
        .modo(modo_reg),
        .columna(columna),
        .fila_sen(fila_sen),
        .fila_cos(fila_cos),
        .indice_fila(indice_fila),
        .datos_fila(datos_fila)
    );
    // CONTADOR DE FILAS
    always @(posedge clk) begin
        if (rst)
            indice_fila <= 3'd0;
        else if (arrancar_visual)
            indice_fila <= 3'd0;
        else if (avanzar_fila)
            indice_fila <= indice_fila + 1'b1;
    end
    assign fin_filas = (indice_fila == 3'd7);
    // EMPAQUETADOR MAX7219
    empaquetador_max7219 empaquetador (
        .datos_fila(datos_fila),
        .indice_fila(indice_fila),
        .datos_empaquetados(datos_empaquetados)
    );
    // FSM DE VISUALIZACION
    fsm_max7219 control_visual (
        .clk(clk),
        .rst(rst),
        .inicio(arrancar_visual),
        .transmision_lista(transmision_lista),
        .fin_filas(fin_filas),
        .leer_fila(leer_fila),
        .cargar(cargar_visual),
        .transmitir(transmitir_visual),
        .latch(latch),
        .avanzar_fila(avanzar_fila),
        .terminado(visualizacion_terminada)
    );
    // INICIALIZADOR MAX7219
    inicializador_max7219 inicializador (
        .clk(clk),
        .rst(rst),
        .transmision_lista(transmision_lista),
        .cargar(cargar_init),
        .transmitir(transmitir_init),
        .datos_serial(datos_init),
        .terminado(inicializacion_lista)
    );
    // MULTIPLEXORES
    assign cargar_serial =
        inicializacion_lista ?
        cargar_visual : cargar_init;
    assign transmitir_serial =
        inicializacion_lista ?
        transmitir_visual : transmitir_init;
    assign datos_serial =
        inicializacion_lista ?
        datos_empaquetados : datos_init;
    // CONTROLADOR SERIAL
    controlador_serial #(
        .DIVISOR(50)
    ) serial (
        .clk(clk),
        .rst(rst),
        .cargar(cargar_serial),
        .transmitir(transmitir_serial),
        .datos_serial(datos_serial),
        .DIN(DIN),
        .CLK(CLK_MAX),
        .CS(CS_MAX),
        .transmision_lista(transmision_lista),
        .ocupado(serial_ocupado)
    );
    // SALIDA DE ESTADO
    assign terminado = imagen_lista;
endmodule
module inicializador_max7219(
    input wire clk,
    input wire rst,
    input wire transmision_lista,
    output reg cargar,
    output reg transmitir,
    output reg [127:0] datos_serial,
    output reg terminado
);
    localparam ESPERA       = 3'd0;
    localparam PREPARAR     = 3'd1;
    localparam CARGAR       = 3'd2;
    localparam INICIAR_TX   = 3'd3;
    localparam ESPERAR_TX   = 3'd4;
    localparam SIGUIENTE    = 3'd5;
    localparam FINALIZAR    = 3'd6;

    reg [2:0] estado_actual;
    reg [2:0] estado_siguiente;
    reg [3:0] indice_config;
    reg [7:0] direccion;
    reg [7:0] dato;
    integer i;

    always @(posedge clk) begin
        if (rst)
            estado_actual <= ESPERA;
        else
            estado_actual <= estado_siguiente;
    end

    always @(posedge clk) begin
        if (rst)
            indice_config <= 4'd0;
        else if (estado_actual == SIGUIENTE && indice_config < 4'd13)
            indice_config <= indice_config + 1'b1;
    end

    always @(*) begin
        direccion = 8'h00;
        dato = 8'h00;
        case (indice_config)
            4'd0: begin direccion = 8'h0C; dato = 8'h00; end
            4'd1: begin direccion = 8'h0F; dato = 8'h00; end
            4'd2: begin direccion = 8'h09; dato = 8'h00; end
            4'd3: begin direccion = 8'h0B; dato = 8'h07; end
            4'd4: begin direccion = 8'h0A; dato = 8'h04; end
            4'd5, 4'd6, 4'd7, 4'd8,
            4'd9, 4'd10, 4'd11, 4'd12: begin
                direccion = {4'b0000, (indice_config - 4'd4)};
                dato = 8'h00;
            end
            4'd13: begin direccion = 8'h0C; dato = 8'h01; end
            default: begin direccion = 8'h00; dato = 8'h00; end
        endcase
    end

    always @(*) begin
        datos_serial = 128'd0;
        for (i = 0; i < 8; i = i + 1)
            datos_serial[i*16 +: 16] = {direccion, dato};
    end

    always @(*) begin
        estado_siguiente = estado_actual;
        case (estado_actual)
            ESPERA: estado_siguiente = PREPARAR;
            PREPARAR: estado_siguiente = CARGAR;
            CARGAR: estado_siguiente = INICIAR_TX;
            INICIAR_TX: estado_siguiente = ESPERAR_TX;
            ESPERAR_TX: begin
                if (transmision_lista)
                    estado_siguiente = SIGUIENTE;
            end
            SIGUIENTE: begin
                if (indice_config == 4'd13)
                    estado_siguiente = FINALIZAR;
                else
                    estado_siguiente = PREPARAR;
            end
            FINALIZAR: estado_siguiente = FINALIZAR;
            default: estado_siguiente = ESPERA;
        endcase
    end

    always @(*) begin
        cargar = 1'b0;
        transmitir = 1'b0;
        terminado = 1'b0;
        case (estado_actual)
            CARGAR: cargar = 1'b1;
            INICIAR_TX: transmitir = 1'b1;
            FINALIZAR: terminado = 1'b1;
            default: begin end
        endcase
    end
endmodule


module arctan(
    input wire [4:0] direccion,
    output reg signed [31:0] dato
);
    always @(*) begin
        case (direccion)
            5'd0: dato = 32'sd421657428;
            5'd1: dato = 32'sd248918915;
            5'd2: dato = 32'sd131521918;
            5'd3: dato = 32'sd66762579;
            5'd4: dato = 32'sd33510843;
            5'd5: dato = 32'sd16771758;
            5'd6: dato = 32'sd8387925;
            5'd7: dato = 32'sd4194219;
            5'd8: dato = 32'sd2097141;
            5'd9: dato = 32'sd1048575;
            5'd10: dato = 32'sd524288;
            5'd11: dato = 32'sd262144;
            5'd12: dato = 32'sd131072;
            5'd13: dato = 32'sd65536;
            5'd14: dato = 32'sd32768;
            5'd15: dato = 32'sd16384;
            5'd16: dato = 32'sd8192;
            5'd17: dato = 32'sd4096;
            5'd18: dato = 32'sd2048;
            5'd19: dato = 32'sd1024;
            5'd20: dato = 32'sd512;
            5'd21: dato = 32'sd256;
            5'd22: dato = 32'sd128;
            5'd23: dato = 32'sd64;
            5'd24: dato = 32'sd32;
            5'd25: dato = 32'sd16;
            5'd26: dato = 32'sd8;
            5'd27: dato = 32'sd4;
            5'd28: dato = 32'sd2;
            5'd29: dato = 32'sd1;
            default: dato = 32'sd0;
        endcase
    end
endmodule

module cordic(
    input wire clk,
    input wire rst,
    input wire inicio,
    input wire signed [31:0] angulo,
    output reg signed [31:0] cos,
    output reg signed [31:0] sen,
    output reg A,
    output reg B
);
    reg signed [31:0] x;
    reg signed [31:0] y;
    reg signed [31:0] z;
    reg signed [31:0] xn;
    reg signed [31:0] yn;
    reg signed [31:0] zn;
    reg [4:0] i;
    wire signed [31:0] angulo_rom;

    arctan ROM (
        .direccion(i),
        .dato(angulo_rom)
    );

    always @(*) begin
        if (z >= 0) begin
            xn = x - (y >>> i);
            yn = y + (x >>> i);
            zn = z - angulo_rom;
        end else begin
            xn = x + (y >>> i);
            yn = y - (x >>> i);
            zn = z + angulo_rom;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            x <= 32'sd326016437;
            y <= 32'sd0;
            z <= 32'sd0;
            i <= 5'd0;
            cos <= 32'sd0;
            sen <= 32'sd0;
            A <= 1'b0;
            B <= 1'b0;
        end else begin
            B <= 1'b0;
            if (inicio && !A) begin
                x <= 32'sd326016437;
                y <= 32'sd0;
                z <= angulo;
                i <= 5'd0;
                A <= 1'b1;
            end else if (A) begin
                x <= xn;
                y <= yn;
                z <= zn;
                if (i == 5'd29) begin
                    cos <= xn;
                    sen <= yn;
                    A <= 1'b0;
                    B <= 1'b1;
                end else
                    i <= i + 1'b1;
            end
        end
    end
endmodule
