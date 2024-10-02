/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------------------
// This module contains instantiation of all functional units residing in the execute stage.
// -------------------------------------------------------------------------------------------

module decode_stage
#(
    parameter ADDR_WIDTH  = 64,
              DATA_WIDTH  = 64,
              REG_ADDR_W  = 5
) 
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic [ ADDR_WIDTH - 1:0 ] i_pc,
    input  logic [ ADDR_WIDTH - 1:0 ] i_pc_plus4,
    input  logic [ DATA_WIDTH - 1:0 ] i_rs1_data,
    input  logic [ DATA_WIDTH - 1:0 ] i_rs2_data,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs1_addr,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs2_addr,
    input  logic [ REG_ADDR_W - 1:0 ] i_rd_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_imm_ext,
    input  logic [              2:0 ] i_func3,
    input  logic [              2:0 ] i_result_src,
    input  logic [              4:0 ] i_alu_control,
    input  logic                      i_mem_we,
    input  logic                      i_reg_we,
    input  logic                      i_alu_src,
    input  logic                      i_branch,
    input  logic                      i_jump,
    input  logic [ DATA_WIDTH - 1:0 ] i_result,
    input  logic [ DATA_WIDTH - 1:0 ] i_alu_result,
    input  logic [              1:0 ] i_forward_rs1_exec,
    input  logic [              1:0 ] i_forward_rs2_exec,

    // Output interface.
    output logic [ ADDR_WIDTH - 1:0 ] o_pc_plus4,
    output logic [ ADDR_WIDTH - 1:0 ] o_pc_target,
    output logic [ ADDR_WIDTH - 1:0 ] o_pc_target_preg,
    output logic [ DATA_WIDTH - 1:0 ] o_alu_result,
    output logic [ DATA_WIDTH - 1:0 ] o_write_data,
    output logic [ REG_ADDR_W - 1:0 ] o_rs1_addr,
    output logic [ REG_ADDR_W - 1:0 ] o_rs2_addr,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr_preg,
    output logic [ DATA_WIDTH - 1:0 ] o_imm_ext,
    output logic [              2:0 ] o_result_src,
    output logic                      o_mem_we,
    output logic                      o_reg_we,
    output logic                      o_pc_src
);

    //-------------------------------------
    // Internal nets.
    //-------------------------------------
    logic [ DATA_WIDTH - 1:0 ] s_alu_srcA;
    logic [ DATA_WIDTH - 1:0 ] s_alu_srcB;
    logic [ DATA_WIDTH - 1:0 ] s_write_data;

    logic [ DATA_WIDTH - 1:0 ] s_alu_result;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_target;

    logic s_zero_flag;
    logic s_lt_flag;
    logic s_ltu_flag;

    logic s_branch;


    //-------------------------------------
    // Lower level modules.
    //-------------------------------------

    // ALU.
    alu ALU0 ( 
        .i_alu_control ( i_alu_control ),
        .i_src_1       ( s_alu_srcA    ),
        .i_src_2       ( s_alu_srcB    ),
        .o_alu_result  ( s_alu_result  ),
        .o_zero_flag   ( s_zero_flag   ),
        .o_lt_flag     ( s_lt_flag     ),
        .o_ltu_flag    ( s_ltu_flag    )
    );

    // Adder for target pc value calculation.
    adder ADD_IMM0 (
        .i_input1 ( i_pc        ),
        .i_input2 ( i_imm_ext   ),
        .o_sum    ( s_pc_target )
    );

    // 3-to-1 ALU SrcA MUX.
    mux3to1 MUX0 (
        .i_control_signal ( i_forward_rs1_exec ),
        .i_mux_0          ( i_rs1_data         ),
        .i_mux_1          ( i_result           ),
        .i_mux_2          ( i_alu_result       ),
        .o_mux            ( s_alu_srcA         )
    );

    // 3-to-1 write data MUX.
    mux3to1 MUX1 (
        .i_control_signal ( i_forward_rs2_exec ),
        .i_mux_0          ( i_rs2_data         ),
        .i_mux_1          ( i_result           ),
        .i_mux_2          ( i_alu_result       ),
        .o_mux            ( s_write_data       )
    );

    // 2-to-1 ALU SrcB MUX.
    mux2to1 MUX2 (
        .i_control_signal ( i_alu_src     ),
        .i_mux_0          ( s_write_data  ),
        .i_mux_1          ( i_imm_ext     ),
        .o_mux            ( s_alu_srcB    )
    );


    // Branch decision logic.
    always_comb begin
        case ( i_func3 )
            3'd0:    s_branch = i_branch & s_zero_flag;       // beq. 
            3'd1:    s_branch = i_branch & ( ~ s_zero_flag ); // bne.
            3'd4:    s_branch = i_branch & s_lt_flag;         // blt.
            3'd5:    s_branch = i_branch & ( ~ s_lt_flag );   // bge.
            3'd6:    s_branch = i_branch & s_ltu_flag;        // bltu.
            3'd7:    s_branch = i_branch & ( ~ s_ltu_flag );  // breu.
            default: s_branch = 1'b0;
        endcase
    end

    assign o_pc_src = i_jump | s_branch;

    //-------------------------------------
    // Pipeline Register.
    //-------------------------------------
    preg_execute PREG_E (
        .i_clk        ( i_clk            ),
        .i_arst       ( i_arst           ),
        .i_result_src ( i_result_src     ),
        .i_mem_we     ( i_mem_we         ),
        .i_reg_we     ( i_reg_we         ),
        .i_pc_plus4   ( i_pc_plus4       ),
        .i_pc_target  ( s_pc_target      ),
        .i_imm_ext    ( i_imm_ext        ),
        .i_alu_result ( s_alu_result     ),
        .i_write_data ( s_write_data     ),
        .i_rd_addr    ( i_rd_addr        ),
        .o_result_src ( o_result_src     ),
        .o_mem_we     ( o_mem_we         ),
        .o_reg_we     ( o_reg_we         ),
        .o_pc_plus4   ( o_pc_plus4       ),
        .o_pc_target  ( o_pc_target_preg ),
        .o_imm_ext    ( o_imm_ext        ),
        .o_alu_result ( o_alu_result     ),
        .o_write_data ( o_write_data     ),
        .o_rd_addr    ( o_rd_addr_preg   )
    );


    //--------------------------------------
    // Continious assignment of outputs.
    //--------------------------------------
    assign o_pc_target = s_pc_target;
    assign o_rs1_addr  = i_rs1_addr;
    assign o_rs2_addr  = i_rs2_addr;
    assign o_rd_addr   = i_rd_addr;

endmodule