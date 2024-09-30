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
    output logic [ 2:0 ] o_result_src,
    output logic [ 2:0 ] o_alu_op,
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
        I_Type_ALUW = 4'b0011,
        S_Type      = 4'b0100,
        R_Type      = 4'b0101,
        R_Type_W    = 4'b0110,
        B_Type      = 4'b0111,
        J_Type      = 4'b1000,
        U_Type_ALU  = 4'b1001,
        U_Type_LOAD = 4'b1010
    } t_instruction;

    // Instruction decoder signal. 
    t_instruction s_instr_type;

    //----------------------------
    // Instruction decoder logic.
    //---------------------- -----
    always_comb begin
        case ( i_op )
            7'b0000011: s_instr_type = I_Type;
            7'b0010011: s_instr_type = I_Type_ALU;
            7'b1100111: s_instr_type = I_Type_JALR;
            7'b0011011: s_instr_type = I_Type_ALUW;
            7'b0100011: s_instr_type = S_Type;
            7'b0110011: s_instr_type = R_Type;
            7'b0111011: s_instr_type = R_Type_W;
            7'b1100011: s_instr_type = B_Type;
            7'b1101111: s_instr_type = J_Type;
            7'b0010111: s_instr_type = U_Type_ALU;
            7'b0110111: s_instr_type = U_Type_LOAD;
            default   : s_instr_type = I_Type; // For now default to I type later for Illegal instruction. 
        endcase
    end

    instr_decoder INSTR_DEC (
        .i_instr   ( s_instr_type ),
        .o_imm_src ( o_imm_src    )
    );


    //----------------------------------------------
    // Decoder for output control signals.
    //----------------------------------------------
    always_comb begin
        // Default values.
        o_result_src = 3'b0; // 000 - ALUResult, 001 - ReadDataMem, 010 - PCPlus4, 011 - PCPlusImm, 100 - ImmExtended.
        o_alu_op     = 3'b0; // 000 - Add, 001 - Sub, 010 - I & R, I & R W.
        o_mem_we     = 1'b0;
        o_reg_we     = 1'b0;
        o_alu_src    = 1'b0; // 0 - Reg, 1 - Immediate.
        o_branch     = 1'b0;
        o_jump       = 1'b0;

        case ( s_instr_type )
            I_Type: begin
                o_reg_we     = 1'b1;
                o_alu_src    = 1'b1;
                o_result_src = 3'b1;
            end
            I_Type_ALU: begin
                o_reg_we     = 1'b1;
                o_alu_src    = 1'b1;
                o_alu_op     = 3'b10;
            end
            I_Type_JALR: begin
                o_reg_we     = 1'b1;
                o_alu_src    = 1'b1; 
                o_jump       = 1'b1;
                o_result_src = 3'b10;
            end
            I_Type_ALUW: begin
                o_reg_we     = 1'b1;
                o_alu_src    = 1'b1;
                o_alu_op     = 3'b11; 
            end
            S_Type: begin
                o_mem_we     = 1'b1;
                o_alu_src    = 1'b1;
            end
            R_Type: begin
                o_reg_we     = 1'b1;
                o_alu_op     = 3'b10;
            end
            R_Type_W: begin
                o_reg_we     = 1'b1;
                o_alu_op     = 3'b11;
            end
            B_Type: begin
                o_branch     = 1'b1;
                o_alu_op     = 3'b1;
            end
            J_Type: begin
                o_reg_we     = 1'b1;
                o_jump       = 1'b1;
                o_result_src = 3'b10;
            end
            U_Type_ALU: begin
                o_reg_we     = 1'b1;
                o_result_src = 3'b11;
            end
            U_Type_LOAD: begin
                o_reg_we     = 1'b1; 
                o_result_src = 3'b100; 
            end
            default: begin
                o_result_src = 3'b0;
                o_alu_op     = 3'b0;
                o_mem_we     = 1'b0;
                o_reg_we     = 1'b0;
                o_alu_src    = 1'b0;
                o_branch     = 1'b0;
                o_jump       = 1'b0; 
            end
        endcase
    end




endmodule