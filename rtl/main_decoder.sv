/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------
// This is a main decoder module.
// --------------------------------

module main_decoder
(
    // Input interface.
    input  logic [ 6:0 ] i_op,

    // Output interface.
    output logic [ 2:0 ] o_imm_src,
    output logic [ 1:0 ] o_result_src,
    output logic [ 1:0 ] o_alu_op,
    output logic         o_mem_we,
    output logic         o_reg_we,
    output logic         o_alu_src,
    output logic         o_branch,
    output logic         o_jump        
);

    // Instruction type.
    typedef enum logic [3:0] {
        I_Type      = 4'b0000,
        I_Type_ALU  = 4'b0001,
        I_Type_JALR = 4'b0010,
        I_Type_IW   = 4'b0011,
        S_Type      = 4'b0100,
        R_Type      = 4'b0101,
        R_Type_W    = 4'b0110,
        B_Type      = 4'b0111,
        J_Type      = 4'b1000,
        U_Type_ALU  = 4'b1001,
        U_Type_LOAD = 4'b1010
    } t_instruction;

    // Instruction decoder signal. 
    t_instruction s_instr;
    logic [ 2:0 ] s_instr_type;

    //----------------------------
    // Instruction decoder logic.
    //---------------------- -----
    always_comb begin
        case ( i_op )
            7'b0000011: s_instr = I_Type;
            7'b0010011: s_instr = I_Type_ALU;
            7'b1100111: s_instr = I_Type_JALR;
            7'b0011011: s_instr = I_Type_IW;
            7'b0100011: s_instr = S_Type;
            7'b0110011: s_instr = R_Type;
            7'b0111011: s_instr = R_Type_W;
            7'b1100011: s_instr = B_Type;
            7'b1101111: s_instr = J_Type;
            7'b0010111: s_instr = U_Type_ALU;
            7'b0110111: s_instr = U_Type_LOAD;
            default   : s_instr = I_Type; // For now default to I type later for Illegal instruction. 
        endcase
    end

    instr_decoder INSTR_DEC (
        .i_instr   ( s_instr      ),
        .o_imm_src ( s_instr_type )
    );

    assign o_imm_src = s_instr_type;

    //Decoder logic.
    /*
    ____________________________________
    | control signal | instuction type |
    |________________|_________________|
    | 000            | I type          |
    | 001            | S type          |
    | 010            | B type          |
    | 011            | J type          |
    | 100            | U type          |
    | 101            | R type          |
    |__________________________________|
    */


    //----------------------------------------------
    // Result MUX control signal logic.
    //----------------------------------------------
    always_comb begin
        o_result_src = 3'b0;
        o_alu_op     = 2'b0;
        o_mem_we     = 1'b0;
        o_reg_we     = 1'b0;
        o_alu_src    = 1'b0;
        o_branch     = 1'b0;
        o_jump       = 1'b0; 

        case ( s_instr )
            I_Type,     : 
            default: 
        endcase

        case ( s_instr_type ) 
            3'b000: begin
                o_reg_we = 1'b1;
            end
            3'b001: begin
                o_mem_we = 1'b1; // S-type
            end
            3'b010: begin
                
            end
            3'b011: begin
                o_reg_we = 1'b1;
            end
            3'b100: begin
                o_reg_we = 1'b1;
            end
            3'b101: begin
                o_reg_we = 1'b1;
            end
            default: begin
                o_result_src = 3'b0;
                o_alu_op     = 2'b0;
                o_mem_we     = 1'b0;
                o_reg_we     = 1'b0;
                o_alu_src    = 1'b0;
                o_branch     = 1'b0;
                o_jump       = 1'b0; 
            end
        endcase
    end




endmodule