/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------
// This module contains instantiation of all functional units residing in the fetch stage.
// ----------------------------------------------------------------------------------------

module fetch_stage 
#(
    parameter ADDR_WIDTH  = 64,
              INSTR_WIDTH = 32
) 
(
    // Input interface.
    input  logic                       i_clk,
    input  logic                       i_arst,
    input  logic [ ADDR_WIDTH  - 1:0 ] i_pc_target,
    input  logic                       i_pc_src,
    input  logic                       i_stall_fetch,
    input  logic                       i_stall_dec,
    input  logic                       i_flush_dec,

    // Output interface.
    output logic [ INSTR_WIDTH - 1:0 ] o_instruction,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc_plus4,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc
);

    //-----------------------------
    // Internal nets.
    //-----------------------------
    logic [ ADDR_WIDTH - 1:0 ] s_pc_plus4;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_next;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_reg;

    logic [ INSTR_WIDTH - 1:0 ] s_instruction;


    //-----------------------------
    // Lower level modules.
    //-----------------------------

    // 2-to-1 MUX module.
    mux2to1 MUX0 (
        .i_control_signal ( i_pc_src    ),
        .i_mux_0          ( s_pc_plus4  ),
        .i_mux_1          ( i_pc_target ),
        .o_mux            ( s_pc_next   )
    );

    // PC register.
    register_en PC_REG (
        .i_clk        ( i_clk            ),
        .i_write_en   ( ~ i_stall_fetch  ),
        .i_arst       ( i_arst           ),
        .i_write_data ( s_pc_next        ),
        .o_read_data  ( s_pc_reg         )
    );

    // Adder to calculate next PC value.
    adder ADD4 (
        .i_input1 ( s_pc_reg   ),
        .i_input2 ( 64'd4      ),
        .o_sum    ( s_pc_plus4 )
    );

    // Instruction memory. Later to be replaced with cache.
    i_mem I_MEM (
        .i_clk       ( i_clk             ),
        .i_arst      ( i_arst            ),
        .i_addr      ( s_pc_reg [ 9:0 ]  ),
        .o_read_data ( s_instruction     )
    );


    //---------------------------------------------------------------------------------
    // Pipeline Register. With enable & clear for stalling and flushing, respectively.
    //---------------------------------------------------------------------------------
    preg_fetch PREG_F0 (
        .i_clk       ( i_clk         ),
        .i_arst      ( i_arst        ),
        .i_flush_dec ( i_flush_dec   ),
        .i_stall_dec ( i_stall_dec   ),
        .i_instr     ( s_instruction ),
        .i_pc        ( s_pc_reg      ),
        .i_pc_plus4  ( s_pc_plus4    ),
        .o_instr     ( o_instruction ),
        .o_pc        ( o_pc          ),
        .o_pc_plus4  ( o_pc_plus4    )
    );

endmodule