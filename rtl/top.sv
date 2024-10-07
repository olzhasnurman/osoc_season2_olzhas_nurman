/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a top module that contains all functional units in the design.
// -----------------------------------------------------------------------

module top
#(
    parameter REG_ADDR_W  = 5
) 
(
    // Input interface.
    input logic i_clk,
    input logic i_arst
);

    //-------------------------------------------------------------
    // Internal nets.
    //-------------------------------------------------------------
    logic                      s_stall_fetch;
    logic                      s_stall_dec;
    logic                      s_flush_dec;
    logic                      s_flush_exec;
    logic [              1:0 ] s_forward_rs1;
    logic [              1:0 ] s_forward_rs2;
    logic [ REG_ADDR_W - 1:0 ] s_rs1_addr_dec;
    logic [ REG_ADDR_W - 1:0 ] s_rs1_addr_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rs2_addr_dec;
    logic [ REG_ADDR_W - 1:0 ] s_rs2_addr_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_mem;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_wb;
    logic                      s_reg_we_mem;
    logic                      s_reg_we_wb;
    logic                      s_pc_src_exec;
    logic                      s_load_instr_exec;


    //-------------------------------------------------------------
    // Lower level modules.
    //-------------------------------------------------------------

    //-------------------------------------
    // Datapath module.
    //-------------------------------------
    datapath D0 (
        .i_clk             ( i_clk             ),
        .i_arst            ( i_arst            ),
        .i_stall_fetch     ( s_stall_fetch     ),
        .i_stall_dec       ( s_stall_dec       ),
        .i_flush_dec       ( s_flush_dec       ),
        .i_flush_exec      ( s_flush_exec      ),
        .i_forward_rs1     ( s_forward_rs1     ), 
        .i_forward_rs2     ( s_forward_rs2     ), 
        .o_rs1_addr_dec    ( s_rs1_addr_dec    ),
        .o_rs1_addr_exec   ( s_rs1_addr_exec   ),
        .o_rs2_addr_dec    ( s_rs2_addr_dec    ),
        .o_rs2_addr_exec   ( s_rs2_addr_exec   ),
        .o_rd_addr_exec    ( s_rd_addr_exec    ),
        .o_rd_addr_mem     ( s_rd_addr_mem     ),
        .o_rd_addr_wb      ( s_rd_addr_wb      ),
        .o_reg_we_mem      ( s_reg_we_mem      ),
        .o_reg_we_wb       ( s_reg_we_wb       ),
        .o_pc_src_exec     ( s_pc_src_exec     ),
        .o_load_instr_exec ( s_load_instr_exec )
    );

    //-------------------------------------
    // Hazard unit.
    //-------------------------------------
    hazard_unit H0 (
        .i_rs1_addr_dec    ( s_rs1_addr_dec    ),
        .i_rs1_addr_exec   ( s_rs1_addr_exec   ),
        .i_rs2_addr_dec    ( s_rs2_addr_dec    ),
        .i_rs2_addr_exec   ( s_rs2_addr_exec   ),
        .i_rd_addr_exec    ( s_rd_addr_exec    ),
        .i_rd_addr_mem     ( s_rd_addr_mem     ),
        .i_rd_addr_wb      ( s_rd_addr_wb      ),
        .i_reg_we_mem      ( s_reg_we_mem      ),
        .i_reg_we_wb       ( s_reg_we_wb       ),
        .i_pc_src_exec     ( s_pc_src_exec     ),
        .i_load_instr_exec ( s_load_instr_exec ),
        .o_stall_fetch     ( s_stall_fetch     ),
        .o_stall_dec       ( s_stall_dec       ),
        .o_flush_dec       ( s_flush_dec       ),
        .o_flush_exec      ( s_flush_exec      ),
        .o_forward_rs1     ( s_forward_rs1     ), 
        .o_forward_rs2     ( s_forward_rs2     ) 
    );

endmodule