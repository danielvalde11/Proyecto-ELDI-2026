module captura_y_escalado_A #(
    parameter N = 32, // Salida para la ALU o bloque final
    parameter M = 4   
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             enable_a,      // Control desde la FSM (Turno de A)
    input  logic             tecla_valida,  // Viene del antirrebote del teclado
    input  logic             pulso_punto,   // Detector de la tecla "."
    input  logic [3:0]       teclado_in,    // Datos puros de la matriz
    input  logic [N-1:0]     dat_acumulado, 
    output logic [N-1:0]     A              // Salida escalada hacia la ALU o IEEE 754
);

 
    logic         captura_permitida;
    logic [3:0]   q_tecla;
    logic         flag_punto;
    logic         en_contador;
    logic         limite_1010;
    logic [M-1:0] k_count;

    
    assign captura_permitida = tecla_valida & enable_a;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            q_tecla <= 4'b0;
        else if (captura_permitida)
            q_tecla <= teclado_in;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            flag_punto <= 1'b0;
        else if (pulso_punto & enable_a) 
            flag_punto <= 1'b1;
    end

    assign en_contador = flag_punto & captura_permitida;
    assign limite_1010 = (k_count[3] & ~k_count[2] & k_count[1] & ~k_count[0]);

    always_ff @(posedge clk or posedge reset) begin
        if (reset || limite_1010)
            k_count <= '0;
        else if (en_contador)
            k_count <= k_count + 1'b1;
    end
    assign A = dat_acumulado << k_count;

endmodule

module captura_y_escalado_B #(
    parameter N = 32, 
    parameter M = 4   
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             enable_b,      // Control desde la FSM (Turno de B)
    input  logic             tecla_valida,  // Viene del antirrebote del teclado
    input  logic             pulso_punto,   // Detector de la tecla "."
    input  logic [3:0]       teclado_in,    // Datos puros de la matriz
    input  logic [N-1:0]     dat_acumulado, 
    output logic [N-1:0]     B             
);


    logic         captura_permitida;
    logic [3:0]   q_tecla;
    logic         flag_punto;
    logic         en_contador;
    logic         limite_1010;
    logic [M-1:0] k_count;

   
    assign captura_permitida = tecla_valida & enable_b;


    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            q_tecla <= 4'b0;
        else if (captura_permitida)
            q_tecla <= teclado_in;
    end

 
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            flag_punto <= 1'b0;
        else if (pulso_punto & enable_b) 
            flag_punto <= 1'b1;
    end

 
    assign en_contador = flag_punto & captura_permitida;
    assign limite_1010 = (k_count[3] & ~k_count[2] & k_count[1] & ~k_count[0]);

    always_ff @(posedge clk or posedge reset) begin
        if (reset || limite_1010)
            k_count <= '0;
        else if (en_contador)
            k_count <= k_count + 1'b1;
    end

    assign B = enable_b ? (dat_acumulado << k_count) : '0;

endmodule
