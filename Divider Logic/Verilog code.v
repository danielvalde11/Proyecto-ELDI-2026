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

    
    wire        signo_final;
    wire [7:0]  exp_final;

    assign signo_final = A[31] ^ B[31];
    
    assign exp_final   = (A[30:23] - B[30:23]) + 8'd127;

   
    wire        load;
    wire        shift;
    wire        sel_A;
    wire        A_lt_B;
    
  
    wire [23:0] mant_A = {1'b1, A[22:0]};
    wire [23:0] mant_B = {1'b1, B[22:0]};

    reg  [24:0] R_parcial; 
    wire [24:0] resta_D;
    wire [23:0] cociente;

  
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

  
    
    assign resta_D = R_parcial - {1'b0, mant_B};
    assign A_lt_B  = resta_D[24]; 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            R_parcial <= 25'd0;
        end else if (load) begin
           
            R_parcial <= 25'd0;
        end else if (shift) begin
           
            if (sel_A)
                R_parcial <= {resta_D[23:0], mant_A[23]}; 
            else
                R_parcial <= {R_parcial[23:0], mant_A[23]}; 
        end
    end


wire [22:0] mantisa_final;

assign mantisa_final = R_parcial[22:0];


assign S = {signo_final, exp_final, mantisa_final};

endmodule



module fsm_divider_control (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire       A_lt_B,
    output reg        load,
    output reg        shift,
    output reg        sel_A,
    output reg        done
);

    parameter [1:0] S_IDLE  = 2'b00,
                    S_INIT  = 2'b01,
                    S_CALC  = 2'b10,
                    S_DONE  = 2'b11;

    reg [1:0] state, nextstate;
    reg [4:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            count <= 5'd0;
        end else begin
            state <= nextstate;
            if (state == S_INIT)
                count <= 5'd0;
            else if (state == S_CALC)
                count <= count + 1'b1;
        end
    end

    always @(*) begin
        nextstate = state;
        load      = 1'b0;
        shift     = 1'b0;
        sel_A     = 1'b0;
        done      = 1'b0;

        case (state)
            S_IDLE: begin
                if (start) nextstate = S_INIT;
            end

            S_INIT: begin
                load      = 1'b1;
                nextstate = S_CALC;
            end

            S_CALC: begin
                shift = 1'b1;
                sel_A = ~A_lt_B; 
                if (count == 5'd23) 
                    nextstate = S_DONE;
            end

            S_DONE: begin
                done      = 1'b1;
                nextstate = S_IDLE;
            end

            default: nextstate = S_IDLE;
        endcase
    end

endmodule


