`timescale 1ns / 1ps

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
        .clk(clk),
        .reset(reset),
        .start(start),
        .A_lt_B(A_lt_B), 
        .load(load),
        .shift(shift),
        .sel_A(sel_A),
        .done(done)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            R_parcial <= 25'd0;
            Q_parcial <= 24'd0;
        end else if (load) begin
            // Para división fraccionaria, R inicia con el dividendo completo
            R_parcial <= {1'b0, mant_A}; 
            Q_parcial <= 24'd0;
        end else if (shift) begin
            if (A_lt_B) begin
                // Si R < B: El bit del cociente es 0, y se desplaza R a la izquierda
                R_parcial <= {R_parcial[23:0], 1'b0};
                Q_parcial <= {Q_parcial[22:0], 1'b0};
            end else begin
                // Si R >= B: El bit del cociente es 1, se resta y desplaza la resta a la izquierda
                R_parcial <= {resta[23:0], 1'b0};
                Q_parcial <= {Q_parcial[22:0], 1'b1};
            end
        end
    end

    wire norm = ~Q_parcial[23];
    wire [7:0] exp_real = norm ? (exp_final - 8'd1) : exp_final;
    wire [22:0] mantisa_real = norm ? {Q_parcial[21:0], 1'b0} : Q_parcial[22:0];

    assign S = {signo_final, exp_real, mantisa_real};

endmodule
