/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------
// This module contains instantiation of all functional units residing in the memory stage.
// ----------------------------------------------------------------------------------------

module memory_stage
#(
    parameter ADDR_WIDTH  = 64,
              DATA_WIDTH  = 64,
              REG_ADDR_W  = 5
) 
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic [ ADDR_WIDTH - 1:0 ] i_pc_plus4,
    input  logic [ ADDR_WIDTH - 1:0 ] i_pc_target,
    input  logic [ DATA_WIDTH - 1:0 ] i_alu_result,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    input  logic [ REG_ADDR_W - 1:0 ] i_rd_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_imm_ext,
    input  logic [              2:0 ] i_result_src,
    input  logic                      i_mem_we,
    input  logic                      i_reg_we,
    input  logic [              1:0 ] i_forward_src,

    // Output interface.
    output logic [ ADDR_WIDTH - 1:0 ] o_pc_plus4,
    output logic [ ADDR_WIDTH - 1:0 ] o_pc_target,
    output logic [ DATA_WIDTH - 1:0 ] o_forward_value,
    output logic [ DATA_WIDTH - 1:0 ] o_alu_result,
    output logic [ DATA_WIDTH - 1:0 ] o_read_data,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr_preg,
    output logic [ DATA_WIDTH - 1:0 ] o_imm_ext,
    output logic [              2:0 ] o_result_src,
    output logic                      o_reg_we
);

    //-------------------------------------
    // Internal nets.
    //-------------------------------------
    logic [ DATA_WIDTH - 1:0 ] s_read_data;

    //-------------------------------------
    // Lower level modules.
    //-------------------------------------

    // Data memory.
    d_mem DATA_MEM (
        .i_clk        ( i_clk                ),
        .i_write_en   ( i_mem_we             ),
        .i_arst       ( i_arst               ),
        .i_addr       ( i_alu_result [ 9:0 ] ),
        .i_write_data ( i_write_data         ),
        .o_read_data  ( s_read_data          )
    );


    // Forwarding value MUX.
    mux3to1 MUX0 (
        .i_control_signal ( i_forward_src   ),
        .i_mux_0          ( i_alu_result    ),
        .i_mux_1          ( i_pc_target     ),
        .i_mux_2          ( i_imm_ext       ),
        .o_mux            ( o_forward_value )
    );


    //-------------------------------------------
    // Pipeline register for memory stage.
    //-------------------------------------------
    preg_memory PREG_M0 (
        .i_clk        ( i_clk          ),
        .i_arst       ( i_arst         ),
        .i_result_src ( i_result_src   ),
        .i_reg_we     ( i_reg_we       ),
        .i_pc_plus4   ( i_pc_plus4     ),
        .i_pc_target  ( i_pc_target    ),
        .i_imm_ext    ( i_imm_ext      ),
        .i_alu_result ( i_alu_result   ),
        .i_read_data  ( s_read_data    ),
        .i_rd_addr    ( i_rd_addr      ),
        .o_result_src ( o_result_src   ),
        .o_reg_we     ( o_reg_we       ),
        .o_pc_plus4   ( o_pc_plus4     ),
        .o_pc_target  ( o_pc_target    ),
        .o_imm_ext    ( o_imm_ext      ),
        .o_alu_result ( o_alu_result   ),
        .o_read_data  ( o_read_data    ),
        .o_rd_addr    ( o_rd_addr_preg )
    );

    //--------------------------------------------
    // Continious assignment of outputs.
    //--------------------------------------------
    assign o_rd_addr    = i_rd_addr;

endmodule