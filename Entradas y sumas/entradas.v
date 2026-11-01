module controlador_entradas (
    input wire clk,
    input wire rst, // Reset síncrono activo en alto
    
    // Puertos físicos Matriz 1 (numeros)
    input wire [3:0] col_num,
    output wire [3:0] fila_num,
    
    // Puertos físicos Matriz 2 (Operaciones, Graficar, X, Igual)
    input wire [3:0] col_op,
    output wire [3:0] fila_op,
    
    // Salidas hacia el Hardware de Conversión IEEE 754
    output wire [3:0] tecla_num_out,
    output reg enable_A,
    output reg enable_B,
    
    // Salidas hacia la ALU y Sistema de Video
    output reg [2:0] opcode_alu,
    output reg modo_grafica,
    output reg flag_var_x,
    output reg calcular_trigger
);
    wire [3:0] tecla_num;
    wire valid_num;
    teclado_matricial matriz_numeros (
        .clk(clk),
        .rst(rst),
        .x(col_num),
        .y(fila_num),
        .registro(tecla_num),
        .validar(valid_num)
    );

    wire [3:0] tecla_op;
    wire valid_op;
    teclado_matricial matriz_operaciones (
        .clk(clk),
        .rst(rst),
        .x(col_op),
        .y(fila_op),
        .registro(tecla_op),
        .validar(valid_op)
    );
    assign tecla_num_out = tecla_num;

    //FSM - Modelo de Moore---
    localparam ESTADO_A  = 2'b00;
    localparam ESTADO_B  = 2'b01;
    localparam CALCULAR  = 2'b10;
    
    reg [1:0] state, next_state;
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ESTADO_A;
            opcode_alu <= 3'b000;
            modo_grafica <= 1'b0;
            flag_var_x <= 1'b0;
        end else begin
            state <= next_state;
            
            if (valid_op) begin
                case (tecla_op)
                    4'h1: opcode_alu <= 3'b000; // Suma
                    4'h2: opcode_alu <= 3'b100; // Resta
                    4'h3: opcode_alu <= 3'b001; // Multiplicación
                    4'h4: opcode_alu <= 3'b101; // División
                    4'h5: opcode_alu <= 3'b010; // Seno
                    4'h6: opcode_alu <= 3'b110; // Coseno
                    4'h7: modo_grafica <= 1'b1; // Activar Modo Gráfica
                    4'h8: flag_var_x   <= 1'b1; // Activar Variable X
                    default: ; 
                endcase
            end
        end
    end

    always_comb begin
        next_state = state;

        case (state)
            ESTADO_A: begin
                if (valid_op && (tecla_op >= 4'h1 && tecla_op <= 4'h6)) 
                    next_state = ESTADO_B;
            end
            
            ESTADO_B: begin
                if (valid_op && (tecla_op == 4'hF)) 
                    next_state = CALCULAR;
            end
            
            CALCULAR: begin
                next_state = ESTADO_A;
            end
            
            default: next_state = ESTADO_A;
        endcase
    end
    always_comb begin
        enable_A         = 1'b0;
        enable_B         = 1'b0;
        calcular_trigger = 1'b0;

        case (state)
            ESTADO_A: begin
                enable_A = 1'b1; 
            end
            
            ESTADO_B: begin
                enable_B = 1'b1; 
            end
            
            CALCULAR: begin
                calcular_trigger = 1'b1; 
            end
            
            default: ;
        endcase
    end

endmodule
