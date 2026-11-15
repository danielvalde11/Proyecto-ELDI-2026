`timescale 1ns / 1ps
module conversor_dual_AB (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable_A,      // Desde la FSM (Turno del operando A)
    input  wire        enable_B,      // Desde la FSM (Turno del operando B)
    input  wire        clear_op,      // Limpia ambos registros para una nueva operación
    input  wire        tecla_valida,  // Pulso válido del teclado
    input  wire        pulso_signo,   // Pulso tecla "+/-"
    input  wire [3:0]  teclado_in,    // Bus de datos de la tecla presionada
    output wire [31:0] A_float,       // Operando A en IEEE 754 hacia la ALU
    output wire [31:0] B_float        // Operando B en IEEE 754 hacia la ALU
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
            if (mux_stage2[i]) msb_pos = i;
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
