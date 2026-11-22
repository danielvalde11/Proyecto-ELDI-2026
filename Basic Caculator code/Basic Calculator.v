//Còdigo generado por Gemini IA
module calculadora_top (
    input  wire        clk,        
    input  wire        rst,       
    input  wire [3:0]  col_num,
    output wire [3:0]  fila_num,
    input  wire [3:0]  col_op,
    output wire [3:0]  fila_op,

    // Salidas hacia los 8 Displays de 7 segmentos de la Nexys
    output wire [7:0]  AN,
    output wire [6:0]  seg,
    output wire        dp,
    output wire        listo_led,   // LED indicador de resultado listo
    output wire [14:0] debug_led
);

    wire [3:0]  tecla_num_out;
    wire        tecla_valida_pulse;
    wire        pulso_signo_pulse;
    wire        clear_op_pulse;
    wire        enable_A;
    wire        enable_B;

    wire [2:0]  opcode_alu;
    wire        modo_grafica;      // Reservado para futura etapa graficadora
    wire        flag_var_x;        // Reservado para futura etapa graficadora
    wire        calcular_trigger;

    wire [31:0] A_float;
    wire [31:0] B_float;

    wire [31:0] alu_result;
    wire        alu_done;

    // Generación de pulso de 1 ciclo (100 MHz) al presionar '=' (calcular_trigger)
    reg calc_trig_d1, calc_trig_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            calc_trig_d1 <= 1'b0;
            calc_trig_d2 <= 1'b0;
        end else begin
            calc_trig_d1 <= calcular_trigger;
            calc_trig_d2 <= calc_trig_d1;
        end
    end
    wire start_alu = calc_trig_d1 & ~calc_trig_d2;

    // Limpieza automática de operandos al iniciar una nueva operación tras '='
    reg esperar_nuevo_ingreso;
    always @(posedge clk or posedge rst) begin
        if (rst)
            esperar_nuevo_ingreso <= 1'b0;
        else if (start_alu)
            esperar_nuevo_ingreso <= 1'b1;
        else if (tecla_valida_pulse || pulso_signo_pulse)
            esperar_nuevo_ingreso <= 1'b0;
    end

    wire auto_clear = esperar_nuevo_ingreso & (tecla_valida_pulse | pulso_signo_pulse);
    wire clear_total = clear_op_pulse | auto_clear;

    // 1. INPUT LOGIC: Escaneo de matrices y FSM de control de entrada
    controlador_entradas u_input_logic (
        .clk                (clk),
        .rst                (rst),
        .col_num            (col_num),
        .fila_num           (fila_num),
        .col_op             (col_op),
        .fila_op            (fila_op),
        .tecla_num_out      (tecla_num_out),
        .tecla_valida_pulse (tecla_valida_pulse),
        .pulso_signo_pulse  (pulso_signo_pulse),
        .clear_op_pulse     (clear_op_pulse),
        .enable_A           (enable_A),
        .enable_B           (enable_B),
        .opcode_alu         (opcode_alu),
        .modo_grafica       (modo_grafica),
        .flag_var_x         (flag_var_x),
        .calcular_trigger   (calcular_trigger)
    );

    // 2. CONVERSORES BCD -> IEEE-754 (Operandos A y B)
    conversor_dual_AB u_bcd_to_float (
        .clk          (clk),
        .reset        (rst),
        .enable_A     (enable_A),
        .enable_B     (enable_B),
        .clear_op     (clear_total),
        .tecla_valida (tecla_valida_pulse),
        .pulso_signo  (pulso_signo_pulse),
        .teclado_in   (tecla_num_out),
        .A_float      (A_float),
        .B_float      (B_float)
    );

    // 3. ALU IEEE-754 CON MUX 4:1
    alu_ieee754 u_alu (
        .clk        (clk),
        .rst        (rst),
        .start      (start_alu),
        .opcode_alu (opcode_alu),
        .A          (A_float),
        .B          (B_float),
        .resultado  (alu_result),
        .done       (alu_done)
    );

    // 4. OUTPUT LOGIC: Captura del resultado ALU y conversión IEEE-754 -> BCD
    reg [31:0] resultado_latched;
    reg [1:0]  rst_out_cnt;
    wire       rst_output_logic = rst || (rst_out_cnt != 2'd0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            resultado_latched <= 32'd0;
            rst_out_cnt       <= 2'd0;
        end else if (alu_done) begin
            resultado_latched <= alu_result;
            rst_out_cnt       <= 2'd2; // Pulso de reset de 2 ciclos para iniciar S0
        end else if (rst_out_cnt != 2'd0) begin
            rst_out_cnt       <= rst_out_cnt - 2'd1;
        end
    end

    assign debug_led[14:11] = tecla_num_out;
    assign debug_led[10]    = (col_num != 4'b1111);
    assign debug_led[9]     = (col_op  != 4'b1111);
    assign debug_led[8]     = enable_A;
    assign debug_led[7]     = enable_B;
    assign debug_led[6:4]   = opcode_alu;
    assign debug_led[3:0]   = A_float[26:23];

    float_to_bcd_nexys u_output_logic (
        .clk  (clk),
        .RST  (rst_output_logic),
        .S    (resultado_latched),
        .AN   (AN),
        .seg  (seg),
        .dp   (dp),
        .done (listo_led)
    );

endmodule

// BLOQUE 1: CONTROLADOR DE ENTRADAS (Teclados Matriciales + FSM)
module controlador_entradas (
    input  wire       clk,
    input  wire       rst,

    // Puertos físicos Matriz 1 (números)
    input  wire [3:0] col_num,
    output wire [3:0] fila_num,

    // Puertos físicos Matriz 2 (Operaciones, Graficar, X, Igual)
    input  wire [3:0] col_op,
    output wire [3:0] fila_op,

    // Salidas hacia el Hardware de Conversión IEEE 754
    output reg  [3:0] tecla_num_out,
    output wire       tecla_valida_pulse,
    output wire       pulso_signo_pulse,
    output wire       clear_op_pulse,
    output reg        enable_A,
    output reg        enable_B,

    // Salidas hacia la ALU
    output reg  [2:0] opcode_alu,
    output reg        modo_grafica,
    output reg        flag_var_x,
    output reg        calcular_trigger
);

    reg [19:0] div_clk;
    wire clk_lento = div_clk[1]; // NOTA: Cambiar a div_clk[19] antes de sintetizar en la Nexys
    always @(posedge clk or posedge rst) begin
        if (rst) div_clk <= 20'd0;
        else     div_clk <= div_clk + 1'b1;
    end

    reg [3:0] anillo;
    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            anillo <= 4'b1110;
        end else begin
            anillo <= {anillo[2:0], anillo[3]};
        end
    end

    assign fila_num = anillo;
    assign fila_op  = anillo;

    // Decodificación Matriz 1 (Números y teclas especiales)
    // 0..9 -> dígitos | A -> Punto decimal ('.') | B -> Signo ('+/-') | C -> Clear
    reg [3:0] tecla;
    reg       ena;

    always @(*) begin
        tecla = 4'h0;
        ena   = 1'b0;
        case ({fila_num, col_num})
            8'b1110_1110: begin tecla = 4'h1; ena = 1'b1; end
            8'b1110_1101: begin tecla = 4'h4; ena = 1'b1; end
            8'b1110_1011: begin tecla = 4'h7; ena = 1'b1; end
            8'b1110_0111: begin tecla = 4'hE; ena = 1'b1; end

            8'b1101_1110: begin tecla = 4'h2; ena = 1'b1; end
            8'b1101_1101: begin tecla = 4'h5; ena = 1'b1; end
            8'b1101_1011: begin tecla = 4'h8; ena = 1'b1; end
            8'b1101_0111: begin tecla = 4'h0; ena = 1'b1; end

            8'b1011_1110: begin tecla = 4'h3; ena = 1'b1; end
            8'b1011_1101: begin tecla = 4'h6; ena = 1'b1; end
            8'b1011_1011: begin tecla = 4'h9; ena = 1'b1; end
            8'b1011_0111: begin tecla = 4'hF; ena = 1'b1; end

            8'b0111_1110: begin tecla = 4'hA; ena = 1'b1; end // Punto decimal '.'
            8'b0111_1101: begin tecla = 4'hB; ena = 1'b1; end // Tecla '+/-'
            8'b0111_1011: begin tecla = 4'hC; ena = 1'b1; end // Tecla Clear
            8'b0111_0111: begin tecla = 4'hD; ena = 1'b1; end
            default:      begin tecla = 4'h0; ena = 1'b0; end
        endcase
    end

    // Detección limpia de una sola pulsación por barrido de las 4 filas
    reg       key_seen_in_scan;
    reg       key_held;
    reg [3:0] latched_tecla;
    reg       new_key_event;

    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            key_seen_in_scan <= 1'b0;
            key_held         <= 1'b0;
            latched_tecla    <= 4'h0;
            new_key_event    <= 1'b0;
        end else begin
            new_key_event <= 1'b0;
            if (ena) begin
                key_seen_in_scan <= 1'b1;
                latched_tecla    <= tecla;
            end
            // Al completar la 4ta fila del anillo (0111), evaluamos si hubo tecla nueva
            if (anillo == 4'b0111) begin
                if (key_seen_in_scan || ena) begin
                    if (!key_held) begin
                        key_held      <= 1'b1;
                        new_key_event <= 1'b1;
                    end
                end else begin
                    key_held <= 1'b0;
                end
                key_seen_in_scan <= 1'b0;
            end
        end
    end

    // Sincronización de evento de tecla a pulso de 1 ciclo en clk (100 MHz)
    reg ev_d1, ev_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ev_d1         <= 1'b0;
            ev_d2         <= 1'b0;
            tecla_num_out <= 4'h0;
        end else begin
            ev_d1 <= new_key_event;
            ev_d2 <= ev_d1;
            if (new_key_event)
                tecla_num_out <= latched_tecla;
        end
    end

    wire single_press_100m = ev_d1 & ~ev_d2;

    // Clasificación del pulso hacia el conversor BCD -> Float
    // Dígitos (0..9) y Punto (4'hA) -> tecla_valida_pulse
    // Tecla 4'hB -> pulso_signo_pulse (+/-)
    // Tecla 4'hC -> clear_op_pulse (Clear)
    assign tecla_valida_pulse = single_press_100m && (latched_tecla <= 4'hA);
    assign pulso_signo_pulse  = single_press_100m && (latched_tecla == 4'hB);
    assign clear_op_pulse     = single_press_100m && (latched_tecla == 4'hC);

    // Decodificación Matriz 2 (Operaciones e Igual)
    reg [3:0] tecla_op_reg;
    reg       valid_op;

    always @(*) begin
        tecla_op_reg = 4'h0;
        valid_op     = 1'b0;
        case ({fila_op, col_op})
            8'b1110_1110: begin tecla_op_reg = 4'h1; valid_op = 1'b1; end // Suma
            8'b1110_1101: begin tecla_op_reg = 4'h2; valid_op = 1'b1; end // Resta
            8'b1110_1011: begin tecla_op_reg = 4'h3; valid_op = 1'b1; end // Multiplicación
            8'b1110_0111: begin tecla_op_reg = 4'h4; valid_op = 1'b1; end // División
            8'b1101_1110: begin tecla_op_reg = 4'h5; valid_op = 1'b1; end // Seno
            8'b1101_1101: begin tecla_op_reg = 4'h6; valid_op = 1'b1; end // Coseno
            8'b1101_1011: begin tecla_op_reg = 4'h7; valid_op = 1'b1; end // Gráfica
            8'b1101_0111: begin tecla_op_reg = 4'h8; valid_op = 1'b1; end // Var X
            8'b0111_0111: begin tecla_op_reg = 4'h9; valid_op = 1'b1; end // Igual (=)
            default:      begin tecla_op_reg = 4'h0; valid_op = 1'b0; end
        endcase
    end

    // --- FSM Máquina de Estados de Control de Entrada ---
    parameter ESTADO_A = 2'b00;
    parameter ESTADO_B = 2'b01;
    parameter CALCULAR = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk_lento or posedge rst) begin
        if (rst) state <= ESTADO_A;
        else     state <= next_state;
    end

    always @(*) begin
        next_state       = state;
        enable_A         = 1'b0;
        enable_B         = 1'b0;
        calcular_trigger = 1'b0;

        case (state)
            ESTADO_A: begin
                enable_A = 1'b1;
                if (valid_op && tecla_op_reg != 4'h9 &&
                    tecla_op_reg != 4'h7 && tecla_op_reg != 4'h8) begin
                    next_state = ESTADO_B;
                end
            end

            ESTADO_B: begin
                enable_B = 1'b1;
                if (valid_op && tecla_op_reg == 4'h9) begin
                    next_state = CALCULAR;
                end
            end

            CALCULAR: begin
                calcular_trigger = 1'b1;
                next_state       = ESTADO_A;
            end

            default: next_state = ESTADO_A;
        endcase
    end

    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            opcode_alu   <= 3'b000;
            modo_grafica <= 1'b0;
            flag_var_x   <= 1'b0;
        end else if (valid_op) begin
            case (tecla_op_reg)
                4'h1: opcode_alu   <= 3'b000; // Suma
                4'h2: opcode_alu   <= 3'b100; // Resta
                4'h3: opcode_alu   <= 3'b001; // Multiplicación
                4'h4: opcode_alu   <= 3'b101; // División
                4'h5: opcode_alu   <= 3'b010; // Seno
                4'h6: opcode_alu   <= 3'b110; // Coseno
                4'h7: modo_grafica <= 1'b1;   // Activar Gráfica
                4'h8: flag_var_x   <= 1'b1;   // Activar X
                default: ;
            endcase
        end
    end

endmodule

// BLOQUE 2: CONVERSOR DUAL BCD A IEEE-754 (Operandos A y B)
module conversor_dual_AB (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable_A,
    input  wire        enable_B,
    input  wire        clear_op,
    input  wire        tecla_valida,
    input  wire        pulso_signo,
    input  wire [3:0]  teclado_in,
    output wire [31:0] A_float,
    output wire [31:0] B_float
);

    captura_y_bcd_a_float bloque_A (
        .clk          (clk),
        .reset        (reset),
        .enable       (enable_A),
        .clear_op     (clear_op),
        .tecla_valida (tecla_valida),
        .pulso_signo  (pulso_signo),
        .teclado_in   (teclado_in),
        .ieee754_out  (A_float)
    );

    captura_y_bcd_a_float bloque_B (
        .clk          (clk),
        .reset        (reset),
        .enable       (enable_B),
        .clear_op     (clear_op),
        .tecla_valida (tecla_valida),
        .pulso_signo  (pulso_signo),
        .teclado_in   (teclado_in),
        .ieee754_out  (B_float)
    );

endmodule

module captura_y_bcd_a_float #(
    parameter N = 32
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        clear_op,
    input  wire        tecla_valida,
    input  wire        pulso_signo,
    input  wire [3:0]  teclado_in,
    output wire [31:0] ieee754_out
);
    reg  [3:0] q_tecla;
    wire       captura_en;

    assign captura_en = tecla_valida & enable;

    always @(posedge clk or posedge reset) begin
        if (reset || clear_op)
            q_tecla <= 4'b0000;
        else if (captura_en)
            q_tecla <= teclado_in;
    end

    wire es_punto;
    wire es_digito;

    assign es_punto  = q_tecla[3] & ~q_tecla[2] & q_tecla[1] & ~q_tecla[0];
    assign es_digito = captura_en & ~(teclado_in == 4'b1010);

    reg [3:0] A0, A1, A2, A3, A4;

    always @(posedge clk or posedge reset) begin
        if (reset || clear_op) begin
            A0 <= 4'd0; A1 <= 4'd0; A2 <= 4'd0; A3 <= 4'd0; A4 <= 4'd0;
        end else if (es_digito) begin
            A0 <= teclado_in;
            A1 <= A0;
            A2 <= A1;
            A3 <= A2;
            A4 <= A3;
        end
    end

    wire [31:0] term_A0, term_A1, term_A2, term_A3, term_A4;
    wire [31:0] binario_entero;

    assign term_A0 = {28'd0, A0};
    assign term_A1 = ({28'd0, A1} << 3) + ({28'd0, A1} << 1);
    assign term_A2 = ({28'd0, A2} << 6) + ({28'd0, A2} << 5) + ({28'd0, A2} << 2);
    assign term_A3 = ({28'd0, A3} << 9) + ({28'd0, A3} << 8) + ({28'd0, A3} << 7) +
                     ({28'd0, A3} << 6) + ({28'd0, A3} << 5) + ({28'd0, A3} << 3);
    assign term_A4 = ({28'd0, A4} << 13) + ({28'd0, A4} << 10) + ({28'd0, A4} << 9) +
                     ({28'd0, A4} << 8) + ({28'd0, A4} << 4);

    assign binario_entero = term_A0 + term_A1 + term_A2 + term_A3 + term_A4;

    reg  flag_punto;
    wire en_counter;

    always @(posedge clk or posedge reset) begin
        if (reset || clear_op)
            flag_punto <= 1'b0;
        else if (enable && (teclado_in == 4'b1010) && tecla_valida)
            flag_punto <= 1'b1;
    end

    assign en_counter = flag_punto & es_digito;
    reg [2:0] k_count;

    always @(posedge clk or posedge reset) begin
        if (reset || clear_op)
            k_count <= 3'd0;
        else if (en_counter && (k_count < 3'd5))
            k_count <= k_count + 1'b1;
    end

    wire [31:0] mux_stage0, mux_stage1, mux_stage2;

    assign mux_stage0 = k_count[0] ? (binario_entero << 1) : binario_entero;
    assign mux_stage1 = k_count[1] ? (mux_stage0 << 2)     : mux_stage0;
    assign mux_stage2 = k_count[2] ? (mux_stage1 << 4)     : mux_stage1;

    reg        sign_reg;
    reg [4:0]  msb_pos;
    reg [7:0]  exponente;
    reg [22:0] mantisa;
    reg [31:0] norm_shift;
    integer    i;

    always @(posedge clk or posedge reset) begin
        if (reset || clear_op)
            sign_reg <= 1'b0;
        else if (enable && pulso_signo)
            sign_reg <= ~sign_reg;
    end

    always @(*) begin
        msb_pos = 5'd0;
        for (i = 0; i < 32; i = i + 1) begin
            if (mux_stage2[i]) msb_pos = i[4:0];
        end
    end

    always @(*) begin
        if (mux_stage2 == 32'd0) begin
            exponente  = 8'd0;
            mantisa    = 23'd0;
            norm_shift = 32'd0;
        end else begin
            exponente  = 8'd127 + {3'd0, msb_pos};
            norm_shift = mux_stage2 << (5'd31 - msb_pos);
            mantisa    = norm_shift[30:8];
        end
    end

    assign ieee754_out = {sign_reg, exponente, mantisa};

endmodule

// BLOQUE 3: ALU IEEE-754 CON MUX 4:1
// opcode_alu[1:0]: 00=Suma/Resta, 01=Mult/Div, 10=Sen/Cos, 11=0
// opcode_alu[2]  : 0=Suma/Mult/Sen, 1=Resta/Div/Cos
module alu_ieee754 (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [2:0]  opcode_alu,
    input  wire [31:0] A,
    input  wire [31:0] B,
    output reg  [31:0] resultado,
    output reg         done
);

    wire [1:0] sel_mux4 = opcode_alu[1:0];
    wire       sub_op   = opcode_alu[2];

    // --- Canal 00: Suma / Resta ---
    wire [31:0] res_suma_resta;
    wire        done_suma;

    suma u_suma_resta (
        .clk       (clk),
        .rst       (rst),
        .start     (start && (sel_mux4 == 2'b00)),
        .A         (A),
        .B         (B),
        .operacion (sub_op),         // 0 = Suma, 1 = Resta
        .C         (res_suma_resta),
        .done      (done_suma)
    );

    // --- Canal 01: Multiplicación / División ---
    wire [31:0] res_mult;
    wire [31:0] res_div;
    wire        done_div;
    reg         done_mult;

    Multipler u_mult (
        .A (A),
        .B (B),
        .S (res_mult)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            done_mult <= 1'b0;
        else
            done_mult <= start && (opcode_alu == 3'b001);
    end

    floating_point_divider u_div (
        .clk   (clk),
        .reset (rst),
        .start (start && (opcode_alu == 3'b101)),
        .A     (A),
        .B     (B),
        .S     (res_div),
        .done  (done_div)
    );

    wire [31:0] canal_01_mult_div = sub_op ? res_div  : res_mult;
    wire        done_01           = sub_op ? done_div : done_mult;

    // --- Canal 10: Seno / Coseno (CORDIC + Conversión Q3.29 -> IEEE-754) ---
    wire signed [31:0] cos_q329;
    wire signed [31:0] sen_q329;
    wire               done_trig;
    wire [31:0]        cos_ieee;
    wire [31:0]        sen_ieee;

    calculadora_trig u_trig (
        .clk          (clk),
        .rst          (rst),
        .inicio       (start && (sel_mux4 == 2'b10)),
        .angulo_float (A),
        .coseno       (cos_q329),
        .seno         (sen_q329),
        .listo        (done_trig)
    );

    q329_to_ieee754 u_conv_sen (.val_q329(sen_q329), .ieee_out(sen_ieee));
    q329_to_ieee754 u_conv_cos (.val_q329(cos_q329), .ieee_out(cos_ieee));

    wire [31:0] canal_10_trig = sub_op ? cos_ieee : sen_ieee;

    // --- MUX 4:1 Principal de la ALU ---
    reg [31:0] mux4_alu_out;
    always @(*) begin
        case (sel_mux4)
            2'b00:   mux4_alu_out = res_suma_resta;    // Suma / Resta
            2'b01:   mux4_alu_out = canal_01_mult_div; // Multiplicación / División
            2'b10:   mux4_alu_out = canal_10_trig;     // Seno / Coseno
            2'b11:   mux4_alu_out = 32'd0;             // Reservado
            default: mux4_alu_out = 32'd0;
        endcase
    end

    // Selección de bandera done según la operación activa
    reg done_mux;
    always @(*) begin
        case (sel_mux4)
            2'b00:   done_mux = done_suma;
            2'b01:   done_mux = done_01;
            2'b10:   done_mux = done_trig;
            2'b11:   done_mux = start;
            default: done_mux = 1'b0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            resultado <= 32'd0;
            done      <= 1'b0;
        end else begin
            done <= done_mux;
            if (done_mux)
                resultado <= mux4_alu_out;
        end
    end

endmodule

// SUBMÓDULO ALU: DIVISIÓN IEEE-754 + SU FSM DE CONTROL
module floating_point_divider (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [31:0] S,
    output wire        done
);

    wire        signo_final = A[31] ^ B[31];
    wire [7:0]  exp_final   = (A[30:23] - B[30:23]) + 8'd127;

    wire        load, shift, sel_A, A_lt_B;

    wire [23:0] mant_A = {1'b1, A[22:0]};
    wire [23:0] mant_B = {1'b1, B[22:0]};

    reg  [24:0] R_parcial;
    reg  [23:0] Q_parcial;

    wire [24:0] resta = R_parcial - {1'b0, mant_B};
    assign A_lt_B = resta[24];

    fsm_divider_control ctrl_fsm (
        .clk    (clk),
        .reset  (reset),
        .start  (start),
        .A_lt_B (A_lt_B),
        .load   (load),
        .shift  (shift),
        .sel_A  (sel_A),
        .done   (done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            R_parcial <= 25'd0;
            Q_parcial <= 24'd0;
        end else if (load) begin
            R_parcial <= {1'b0, mant_A};
            Q_parcial <= 24'd0;
        end else if (shift) begin
            if (A_lt_B) begin
                R_parcial <= {R_parcial[23:0], 1'b0};
                Q_parcial <= {Q_parcial[22:0], 1'b0};
            end else begin
                R_parcial <= {resta[23:0], 1'b0};
                Q_parcial <= {Q_parcial[22:0], 1'b1};
            end
        end
    end

    wire        norm         = ~Q_parcial[23];
    wire [7:0]  exp_real     = norm ? (exp_final - 8'd1) : exp_final;
    wire [22:0] mantisa_real = norm ? {Q_parcial[21:0], 1'b0} : Q_parcial[22:0];

    assign S = {signo_final, exp_real, mantisa_real};

endmodule

module fsm_divider_control (
    input  wire clk,
    input  wire reset,
    input  wire start,
    input  wire A_lt_B,
    output reg  load,
    output reg  shift,
    output reg  sel_A,
    output reg  done
);
    localparam [1:0] S_IDLE = 2'b00,
                     S_INIT = 2'b01,
                     S_CALC = 2'b10,
                     S_DONE = 2'b11;

    reg [1:0] state, next_state;
    reg [4:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            count <= 5'd0;
        end else begin
            state <= next_state;
            if (state == S_INIT)
                count <= 5'd0;
            else if (state == S_CALC)
                count <= count + 5'd1;
        end
    end

    always @(*) begin
        load       = 1'b0;
        shift      = 1'b0;
        sel_A      = ~A_lt_B;
        done       = 1'b0;
        next_state = state;

        case (state)
            S_IDLE: if (start) next_state = S_INIT;
            S_INIT: begin
                load       = 1'b1;
                next_state = S_CALC;
            end
            S_CALC: begin
                shift = 1'b1;
                if (count == 5'd23)
                    next_state = S_DONE;
            end
            S_DONE: begin
                done       = 1'b1;
                next_state = S_IDLE;
            end
        endcase
    end
endmodule

// SUBMÓDULO ALU: SUMA Y RESTA IEEE-754
module suma (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        operacion,
    output reg  [31:0] C,
    output reg         done
);

    wire [31:0] Bfinal;
    assign Bfinal = operacion ? {~B[31], B[30:0]} : B;

    wire        signoA = A[31];
    wire [7:0]  expoA  = A[30:23];
    wire [23:0] mantA  = {1'b1, A[22:0]};

    wire        signoB = Bfinal[31];
    wire [7:0]  expoB  = Bfinal[30:23];
    wire [23:0] mantB  = {1'b1, Bfinal[22:0]};

    parameter inicio = 3'd0, alinear = 3'd1, sumar = 3'd2, normalizar = 3'd3, fin = 3'd4;
    reg [2:0]  estado;
    reg        signores;
    reg [7:0]  expres;
    reg [24:0] mantres;
    reg [23:0] mantAtemp;
    reg [23:0] mantBtemp;
    reg [7:0]  difexp;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            estado    <= inicio;
            C         <= 32'd0;
            mantAtemp <= 24'd0;
            mantBtemp <= 24'd0;
            difexp    <= 8'd0;
            expres    <= 8'd0;
            mantres   <= 25'd0;
            signores  <= 1'b0;
            done      <= 1'b0;
        end else begin
            done <= 1'b0;
            case (estado)
                inicio: begin
                    if (start) begin
                        mantAtemp <= mantA;
                        mantBtemp <= mantB;
                        if (expoA >= expoB) begin
                            expres <= expoA;
                            difexp <= expoA - expoB;
                        end else begin
                            expres <= expoB;
                            difexp <= expoB - expoA;
                        end
                        estado <= alinear;
                    end
                end

                alinear: begin
                    if (expoA >= expoB) begin
                        mantBtemp <= mantBtemp >> difexp;
                    end else begin
                        mantAtemp <= mantAtemp >> difexp;
                    end
                    estado <= sumar;
                end

                sumar: begin
                    if (signoA == signoB) begin
                        mantres  <= mantAtemp + mantBtemp;
                        signores <= signoA;
                    end else begin
                        if (mantAtemp >= mantBtemp) begin
                            mantres  <= mantAtemp - mantBtemp;
                            signores <= signoA;
                        end else begin
                            mantres  <= mantBtemp - mantAtemp;
                            signores <= signoB;
                        end
                    end
                    estado <= normalizar;
                end

                normalizar: begin
                    if (mantres == 25'd0) begin
                        expres <= 8'd0;
                        estado <= fin;
                    end else if (mantres[24]) begin
                        mantres <= mantres >> 1;
                        expres  <= expres + 8'd1;
                        estado  <= fin;
                    end else if (mantres[23] == 1'b0) begin
                        mantres <= mantres << 1;
                        expres  <= expres - 8'd1;
                        estado  <= normalizar;
                    end else begin
                        estado <= fin;
                    end
                end

                fin: begin
                    C      <= {signores, expres, mantres[22:0]};
                    done   <= 1'b1;
                    estado <= inicio;
                end

                default: estado <= inicio;
            endcase
        end
    end

endmodule

// SUBMÓDULO ALU: MULTIPLICACIÓN IEEE-754
module Multipler (
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [31:0] S
);
    wire [47:0] J;
    wire [23:0] concatenacionA;
    wire [23:0] concatenacionB;
    wire [7:0]  H;
    wire        signo;
    wire [7:0]  exp;
    wire [22:0] mantiza;

    assign H              = 8'd127;
    assign signo          = (A[31] && ~B[31] || ~A[31] && B[31]);
    assign exp            = (A[30:23] + B[30:23] + J[47]) - H;
    assign concatenacionA = {1'b1, A[22:0]};
    assign concatenacionB = {1'b1, B[22:0]};
    assign J              = concatenacionB * concatenacionA;

    mux_2a1 mux_multiplier (
        .A (J[45:23]),
        .B (J[46:24]),
        .C (J[47]),
        .Y (mantiza)
    );

    assign S = {signo, exp, mantiza};
endmodule

module mux_2a1 (
    input  wire [22:0] A,
    input  wire [22:0] B,
    input  wire        C,
    output wire [22:0] Y
);
    assign Y = C ? B : A;
endmodule

// SUBMÓDULO ALU: SENO / COSENO CORDIC + CONVERSIÓN Q3.29 -> IEEE-754
module cordic (
    input  wire               clk,
    input  wire               rst,
    input  wire               inicio,
    input  wire signed [31:0] angulo,
    output reg  signed [31:0] cos,
    output reg  signed [31:0] sen,
    output reg                A,
    output reg                B
);
    reg  signed [31:0] x, y, z;
    reg  signed [31:0] xn, yn, zn;
    reg  [4:0]         i;
    wire signed [31:0] angulo_rom;

    arctan ROM (
        .direccion (i),
        .dato      (angulo_rom)
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
            x   <= 32'sd326016437;
            y   <= 32'sd0;
            z   <= 32'sd0;
            i   <= 0;
            cos <= 0;
            sen <= 0;
            A   <= 0;
            B   <= 0;
        end else begin
            B <= 0;
            if (inicio && !A) begin
                x <= 32'sd326016437;
                y <= 32'sd0;
                z <= angulo;
                i <= 0;
                A <= 1;
            end else if (A) begin
                x <= xn;
                y <= yn;
                z <= zn;
                if (i == 15) begin
                    cos <= xn;
                    sen <= yn;
                    A   <= 0;
                    B   <= 1;
                end else begin
                    i <= i + 1;
                end
            end
        end
    end
endmodule

module arctan (
    input  wire [4:0]         direccion,
    output reg  signed [31:0] dato
);
    always @(*) begin
        case (direccion)
            0:  dato = 32'sd421657428;
            1:  dato = 32'sd248918915;
            2:  dato = 32'sd131521918;
            3:  dato = 32'sd66762579;
            4:  dato = 32'sd33510843;
            5:  dato = 32'sd16771758;
            6:  dato = 32'sd8387925;
            7:  dato = 32'sd4194219;
            8:  dato = 32'sd2097145;
            9:  dato = 32'sd1048575;
            10: dato = 32'sd524288;
            11: dato = 32'sd262144;
            12: dato = 32'sd131072;
            13: dato = 32'sd65536;
            14: dato = 32'sd32768;
            15: dato = 32'sd16384;
            default: dato = 0;
        endcase
    end
endmodule

module reduccion (
    input  wire signed [31:0] angulo,
    output reg  signed [31:0] angulo_reducido,
    output reg                signo_cos,
    output reg                signo_sen
);
    reg signed [31:0] normalizado;

    always @(*) begin
        normalizado = angulo % 32'sd23592960;

        if (normalizado < 0)
            normalizado = normalizado + 32'sd23592960;

        if (normalizado <= 32'sd5898240) begin
            angulo_reducido = normalizado;
            signo_cos       = 0;
            signo_sen       = 0;
        end else if (normalizado <= 32'sd11796480) begin
            angulo_reducido = 32'sd11796480 - normalizado;
            signo_cos       = 1;
            signo_sen       = 0;
        end else if (normalizado <= 32'sd17694720) begin
            angulo_reducido = normalizado - 32'sd11796480;
            signo_cos       = 1;
            signo_sen       = 1;
        end else begin
            angulo_reducido = 32'sd23592960 - normalizado;
            signo_cos       = 0;
            signo_sen       = 1;
        end
    end
endmodule

module conversor (
    input  wire [31:0]        flotante,
    output reg  signed [31:0] q1616
);
    reg        signo;
    reg [7:0]  exponente;
    reg [22:0] mantisa;
    reg [23:0] significand;
    reg [63:0] magnitud;
    integer    shift_amount;

    always @(*) begin
        signo        = flotante[31];
        exponente    = flotante[30:23];
        mantisa      = flotante[22:0];
        significand  = 0;
        magnitud     = 0;
        shift_amount = 0;
        q1616        = 0;

        if (exponente == 8'hFF) begin
            if (mantisa == 0) begin
                if (signo) q1616 = 32'h80000000;
                else       q1616 = 32'h7FFFFFFF;
            end else
                q1616 = 0;
        end else if (exponente != 0) begin
            significand = {1'b1, mantisa};
            if (exponente >= 134) begin
                shift_amount = exponente - 134;
                if (shift_amount >= 64) magnitud = 64'hFFFFFFFFFFFFFFFF;
                else                    magnitud = {40'b0, significand} << shift_amount;
            end else begin
                shift_amount = 134 - exponente;
                if (shift_amount >= 64) magnitud = 0;
                else                    magnitud = {40'b0, significand} >> shift_amount;
            end

            if (signo) begin
                if (magnitud >= 64'd2147483648) q1616 = 32'h80000000;
                else                            q1616 = -$signed(magnitud[31:0]);
            end else begin
                if (magnitud > 64'd2147483647)  q1616 = 32'h7FFFFFFF;
                else                            q1616 = magnitud[31:0];
            end
        end
    end
endmodule

module grados_a_radianes (
    input  wire signed [31:0] grados,
    output reg  signed [31:0] radianes
);
    reg signed [63:0] producto;
    always @(*) begin
        producto = grados * 64'sd149922641;
        radianes = producto >>> 20;
    end
endmodule

module calculadora_trig (
    input  wire               clk,
    input  wire               rst,
    input  wire               inicio,
    input  wire [31:0]        angulo_float,
    output reg  signed [31:0] coseno,
    output reg  signed [31:0] seno,
    output reg                listo
);
    reg  signed [31:0] grados_reg;
    reg  [1:0]         estado;

    wire signed [31:0] q1616;
    wire signed [31:0] angulo_reducido;
    wire               signo_cos;
    wire               signo_sen;
    wire signed [31:0] angulo_radianes;

    wire signed [31:0] cos_cordic;
    wire signed [31:0] sen_cordic;
    wire               cordic_busy;
    wire               cordic_done;
    wire               cordic_inicio;

    localparam ESPERA     = 2'b00;
    localparam INICIAR    = 2'b01;
    localparam CALCULANDO = 2'b10;

    conversor U1 (
        .flotante (angulo_float),
        .q1616    (q1616)
    );

    reduccion U2 (
        .angulo          (grados_reg),
        .angulo_reducido (angulo_reducido),
        .signo_cos       (signo_cos),
        .signo_sen       (signo_sen)
    );

    grados_a_radianes U3 (
        .grados   (angulo_reducido),
        .radianes (angulo_radianes)
    );

    assign cordic_inicio = (estado == INICIAR);

    cordic U4 (
        .clk    (clk),
        .rst    (rst),
        .inicio (cordic_inicio),
        .angulo (angulo_radianes),
        .cos    (cos_cordic),
        .sen    (sen_cordic),
        .A      (cordic_busy),
        .B      (cordic_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            estado     <= ESPERA;
            grados_reg <= 0;
            coseno     <= 0;
            seno       <= 0;
            listo      <= 0;
        end else begin
            listo <= 0;
            case (estado)
                ESPERA: begin
                    if (inicio) begin
                        grados_reg <= q1616;
                        estado     <= INICIAR;
                    end
                end
                INICIAR: begin
                    estado <= CALCULANDO;
                end
                CALCULANDO: begin
                    if (cordic_done) begin
                        coseno <= signo_cos ? -cos_cordic : cos_cordic;
                        seno   <= signo_sen ? -sen_cordic : sen_cordic;
                        listo  <= 1;
                        estado <= ESPERA;
                    end
                end
                default: estado <= ESPERA;
            endcase
        end
    end
endmodule

// Conversor Q3.29 (salida CORDIC) -> IEEE-754 (32 bits)
module q329_to_ieee754 (
    input  wire signed [31:0] val_q329,
    output reg         [31:0] ieee_out
);
    wire        sign = val_q329[31];
    wire [31:0] mag  = sign ? (~val_q329 + 32'd1) : val_q329;
    reg  [4:0]  msb_pos;
    reg  [31:0] shifted;
    integer     k;

    always @(*) begin
        msb_pos = 5'd0;
        for (k = 0; k < 32; k = k + 1) begin
            if (mag[k]) msb_pos = k[4:0];
        end

        if (mag == 32'd0) begin
            ieee_out = 32'd0;
        end else begin
            shifted  = mag << (5'd31 - msb_pos);
            ieee_out = {sign, (8'd98 + {3'd0, msb_pos}), shifted[30:8]};
        end
    end
endmodule

// BLOQUE 4: LÓGICA DE SALIDA (IEEE-754 -> BCD Y 8 DISPLAYS NEXYS)
module float_to_bcd_nexys (
    input  wire        clk,
    input  wire        RST,
    input  wire [31:0] S,
    output wire [7:0]  AN,
    output wire [6:0]  seg,
    output wire        dp,
    output wire        done
);

    wire       En1, Load, En2, En3, rstc, Enbcd, Up;
    wire [1:0] Sel;
    wire       Q2_eq_0, a, Q3_ge_10;

    reg        Q1;
    reg  [7:0] Q2;
    wire [7:0] exp_unbiased = S[30:23] - 8'd127;

    always @(posedge clk or posedge RST) begin
        if (RST)
            Q1 <= 1'b0;
        else if (En1)
            Q1 <= S[31];
    end

    always @(posedge clk or posedge RST) begin
        if (RST)
            Q2 <= 8'd0;
        else if (Load)
            Q2 <= exp_unbiased;
        else if (En2) begin
            if (Up) Q2 <= Q2 + 8'd1;
            else    Q2 <= Q2 - 8'd1;
        end
    end

    reg  [47:0] Q3;
    wire [47:0] q3_init  = {24'b0, 1'b1, S[22:0]};
    wire [47:0] q3_shr1  = Q3 >> 1;
    wire [47:0] q3_shl1  = Q3 << 1;
    wire [47:0] q3_mul10 = (Q3 << 3) + (Q3 << 1);
    wire [47:0] q3_div10 = (Q3 >> 4) + (Q3 >> 5) + (Q3 >> 8) +
                           (Q3 >> 9) + (Q3 >> 12) + (Q3 >> 13);
    wire [47:0] N        = a ? q3_div10 : q3_mul10;

    reg [47:0] mux4_q3;
    always @(*) begin
        case (Sel)
            2'b00:   mux4_q3 = q3_init;
            2'b01:   mux4_q3 = N;
            2'b10:   mux4_q3 = q3_shr1;
            2'b11:   mux4_q3 = q3_shl1;
            default: mux4_q3 = q3_init;
        endcase
    end

    always @(posedge clk or posedge RST) begin
        if (RST)
            Q3 <= 48'd0;
        else if (En3)
            Q3 <= mux4_q3;
    end

    assign Q2_eq_0  = (Q2 == 8'd0);
    assign a        = (Q3 >= (48'd1  << 23));
    assign Q3_ge_10 = (Q3 >= (48'd10 << 23));

    fsm_control u_fsm (
        .clk      (clk),
        .RST      (RST),
        .Q2_7     (Q2[7]),
        .Q2_eq_0  (Q2_eq_0),
        .a        (a),
        .Q3_ge_10 (Q3_ge_10),
        .Q3_zero  (Q3 == 48'd0),
        .En1      (En1),
        .Load     (Load),
        .En2      (En2),
        .En3      (En3),
        .Sel      (Sel),
        .rstc     (rstc),
        .Enbcd    (Enbcd),
        .Up       (Up),
        .done     (done)
    );

    reg [7:0] Exp10;
    reg       signe;

    always @(posedge clk or posedge RST) begin
        if (RST)
            Exp10 <= 8'd0;
        else if (rstc)
            Exp10 <= 8'd0;
        else if (Enbcd) begin
            if (Up) Exp10 <= Exp10 + 8'd1;
            else    Exp10 <= Exp10 - 8'd1;
        end
    end

    always @(posedge clk or posedge RST) begin
        if (RST)
            signe <= 1'b0;
        else
            signe <= Exp10[7];
    end

    wire [6:0] exp_neg = (~Exp10[6:0]) + 7'd1;
    wire [6:0] m       = Exp10[7] ? exp_neg : Exp10[6:0];

    wire [3:0] q1, q2_bcd, q3_bcd, q4_bcd;
    add3_stage u_q1 (.in({1'b0,         m[6:4]}), .out(q1));
    add3_stage u_q2 (.in({q1[2:0],     m[3]}),   .out(q2_bcd));
    add3_stage u_q3 (.in({q2_bcd[2:0], m[2]}),   .out(q3_bcd));
    add3_stage u_q4 (.in({q3_bcd[2:0], m[1]}),   .out(q4_bcd));

    wire [3:0] exp_decenas  = {q1[3], q2_bcd[3], q3_bcd[3], q4_bcd[3]};
    wire [3:0] exp_unidades = {q4_bcd[2:0], m[0]};

    wire [47:0] m2_sum = (Q3 >> 6) + (Q3 >> 3) + (Q3 >> 2);
    wire [9:0]  M2     = m2_sum[24:15];

    wire [3:0] u1, u2, u3, u4, u5, u6, u7;
    add3_stage u_u1 (.in({1'b0,    M2[9:7]}), .out(u1));
    add3_stage u_u2 (.in({u1[2:0], M2[6]}),   .out(u2));
    add3_stage u_u3 (.in({u2[2:0], M2[5]}),   .out(u3));
    add3_stage u_u4 (.in({u3[2:0], M2[4]}),   .out(u4));
    add3_stage u_u5 (.in({u4[2:0], M2[3]}),   .out(u5));
    add3_stage u_u6 (.in({u5[2:0], M2[2]}),   .out(u6));
    add3_stage u_u7 (.in({u6[2:0], M2[1]}),   .out(u7));

    wire [3:0] d1, d2, d3, d4;
    add3_stage u_d1 (.in({1'b0,    u1[3], u2[3], u3[3]}), .out(d1));
    add3_stage u_d2 (.in({d1[2:0], u4[3]}),               .out(d2));
    add3_stage u_d3 (.in({d2[2:0], u5[3]}),               .out(d3));
    add3_stage u_d4 (.in({d3[2:0], u6[3]}),               .out(d4));

    wire [3:0] mant_unidades   = {d1[3], d2[3], d3[3], d4[3]};
    wire [3:0] mant_decimas    = {d4[2:0], u7[3]};
    wire [3:0] mant_centesimas = {u7[2:0], M2[0]};

    reg [3:0] reg_exp_dec, reg_exp_uni;
    reg [3:0] reg_mant_uni, reg_mant_dec, reg_mant_cen;

    always @(posedge clk or posedge RST) begin
        if (RST) begin
            reg_exp_dec  <= 4'd0;
            reg_exp_uni  <= 4'd0;
            reg_mant_uni <= 4'd0;
            reg_mant_dec <= 4'd0;
            reg_mant_cen <= 4'd0;
        end else if (done) begin
            reg_exp_dec  <= exp_decenas;
            reg_exp_uni  <= exp_unidades;
            reg_mant_uni <= mant_unidades;
            reg_mant_dec <= mant_decimas;
            reg_mant_cen <= mant_centesimas;
        end
    end

    reg [16:0] div_cnt;
    wire       en_1khz = (div_cnt == 17'd99_999);

    always @(posedge clk or posedge RST) begin
        if (RST)
            div_cnt <= 17'd0;
        else if (en_1khz)
            div_cnt <= 17'd0;
        else
            div_cnt <= div_cnt + 17'd1;
    end

    reg [2:0] sel_disp;
    always @(posedge clk or posedge RST) begin
        if (RST)
            sel_disp <= 3'd0;
        else if (en_1khz)
            sel_disp <= sel_disp + 3'd1;
    end

    assign AN = ~(8'b0000_0001 << sel_disp);
    assign dp = ~(sel_disp == 3'b111);

    reg [3:0] mux8_out;
    always @(*) begin
        case (sel_disp)
            3'b000:  mux8_out = reg_exp_dec;
            3'b001:  mux8_out = reg_exp_uni;
            3'b010:  mux8_out = signe ? 4'b1101 : 4'b1111;
            3'b011:  mux8_out = 4'b1110;
            3'b100:  mux8_out = reg_mant_cen;
            3'b101:  mux8_out = reg_mant_dec;
            3'b110:  mux8_out = Q1 ? 4'b1101 : 4'b1111;
            3'b111:  mux8_out = reg_mant_uni;
            default: mux8_out = 4'b1111;
        endcase
    end

    bcd_7seg_decoder u_7seg (
        .code (mux8_out),
        .seg  (seg)
    );

endmodule

module fsm_control (
    input  wire       clk,
    input  wire       RST,
    input  wire       Q2_7,
    input  wire       Q2_eq_0,
    input  wire       a,
    input  wire       Q3_ge_10,
    input  wire       Q3_zero,
    output reg        En1,
    output reg        Load,
    output reg        En2,
    output reg        En3,
    output reg  [1:0] Sel,
    output reg        rstc,
    output reg        Enbcd,
    output reg        Up,
    output reg        done
);
    localparam [1:0] S0 = 2'b00,
                     S1 = 2'b01,
                     S2 = 2'b10,
                     S3 = 2'b11;

    reg [1:0] state, next_state;

    always @(posedge clk or posedge RST) begin
        if (RST) state <= S0;
        else     state <= next_state;
    end

    always @(*) begin
        En1        = 1'b0;
        Load       = 1'b0;
        En2        = 1'b0;
        En3        = 1'b0;
        Sel        = 2'b00;
        rstc       = 1'b0;
        Enbcd      = 1'b0;
        Up         = 1'b0;
        done       = 1'b0;
        next_state = state;

        case (state)
            S0: begin
                En1        = 1'b1;
                Load       = 1'b1;
                En3        = 1'b1;
                Sel        = 2'b00;
                rstc       = 1'b1;
                next_state = S1;
            end

            S1: begin
                if (!Q2_eq_0) begin
                    En2 = 1'b1;
                    En3 = 1'b1;
                    if (Q2_7) begin
                        Sel = 2'b10;
                        Up  = 1'b1;
                    end else begin
                        Sel = 2'b11;
                        Up  = 1'b0;
                    end
                    next_state = S1;
                end else begin
                    En2        = 1'b0;
                    En3        = 1'b0;
                    next_state = S2;
                end
            end

            S2: begin
                if (Q3_zero) begin
                    En3        = 1'b0;
                    Enbcd      = 1'b0;
                    next_state = S3;
                end else if (Q3_ge_10) begin
                    En3        = 1'b1;
                    Sel        = 2'b01;
                    Enbcd      = 1'b1;
                    Up         = 1'b1;
                    next_state = S2;
                end else if (!a) begin
                    En3        = 1'b1;
                    Sel        = 2'b01;
                    Enbcd      = 1'b1;
                    Up         = 1'b0;
                    next_state = S2;
                end else begin
                    En3        = 1'b0;
                    Enbcd      = 1'b0;
                    next_state = S3;
                end
            end

            S3: begin
                done       = 1'b1;
                next_state = S3;
            end

            default: next_state = S0;
        endcase
    end
endmodule

module add3_stage (
    input  wire [3:0] in,
    output wire [3:0] out
);
    assign out = (in > 4'b0100) ? (in + 4'b0011) : in;
endmodule

module bcd_7seg_decoder (
    input  wire [3:0] code,
    output reg  [6:0] seg
);
    always @(*) begin
        case (code)
            4'b0000: seg = 7'b0000001; // 0
            4'b0001: seg = 7'b1001111; // 1
            4'b0010: seg = 7'b0010010; // 2
            4'b0011: seg = 7'b0000110; // 3
            4'b0100: seg = 7'b1001100; // 4
            4'b0101: seg = 7'b0100100; // 5
            4'b0110: seg = 7'b0100000; // 6
            4'b0111: seg = 7'b0001111; // 7
            4'b1000: seg = 7'b0000000; // 8
            4'b1001: seg = 7'b0000100; // 9
            4'b1101: seg = 7'b1111110; // '-'
            4'b1110: seg = 7'b0110000; // 'E'
            default: seg = 7'b1111111; // Apagado
        endcase
    end
endmodule
