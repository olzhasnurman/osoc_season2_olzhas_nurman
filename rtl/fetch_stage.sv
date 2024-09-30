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

    // Output interface.
    output logic [ INSTR_WIDTH - 1:0 ] o_instruction,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc_plus4,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc
);

    //-----------------------------
    // Internal nets.
    //-----------------------------

    // MUX signals.
    logic [ ADDR_WIDTH - 1:0 ] s_pc_plus4;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_next;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_reg;

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
    register PC_REG (
        .i_clk        ( i_clk     ),
        .i_arst       ( i_arst    ),
        .i_write_data ( s_pc_next ),
        .o_read_data  ( s_pc_reg  )
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
        .o_read_data ( o_instruction     )
    );


    //-----------------------------
    // Continious assignments.
    //-----------------------------
    assign o_pc_plus4 = s_pc_plus4;
    assign o_pc       = s_pc_reg;

endmodule