
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
            if (Up)
                Q2 <= Q2 + 8'd1;
            else
                Q2 <= Q2 - 8'd1;
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

    reg  [47:0] mux4_q3;
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
    assign a        = (Q3 >= (48'd1  << 23)); // Q3 >= 1.0
    assign Q3_ge_10 = (Q3 >= (48'd10 << 23)); // Q3 >= 10.0

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
            if (Up)
                Exp10 <= Exp10 + 8'd1;
            else
                Exp10 <= Exp10 - 8'd1;
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
    add3_stage u_q1 (.in({1'b0,        m[6:4]}), .out(q1));
    add3_stage u_q2 (.in({q1[2:0],    m[3]}),   .out(q2_bcd));
    add3_stage u_q3 (.in({q2_bcd[2:0],m[2]}),   .out(q3_bcd));
    add3_stage u_q4 (.in({q3_bcd[2:0],m[1]}),   .out(q4_bcd));

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
        if (RST)
            state <= S0;
        else
            state <= next_state;
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
            4'b1101: seg = 7'b1111110; // '-' (signo negativo)
            4'b1110: seg = 7'b0110000; // 'E' (exponente)
            default: seg = 7'b1111111; // Apagado (blanco)
        endcase
    end
endmodule
