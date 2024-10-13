/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a top module that contains all functional units in the design.
// -----------------------------------------------------------------------

module top
#(
    parameter REG_ADDR_W  = 5,
              BLOCK_WIDTH = 512
) 
(
    // Input interface.
    input  logic                       i_clk,
    input  logic                       i_arst,
    input  logic                       i_axi_read_done,
    input  logic [ BLOCK_WIDTH - 1:0 ] i_data_block,

    // Output interface.
    output logic                       o_axi_read_start
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

    // Cache FSM signals.
    logic s_instr_we;
    logic s_icache_hit;
    logic s_stall_cache;

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
        .i_instr_we        ( s_instr_we        ),
        .i_instr_block     ( i_data_block      ),
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
        .o_icache_hit      ( s_icache_hit      ),
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
        .i_stall_cache     ( s_stall_cache     ),
        .o_stall_fetch     ( s_stall_fetch     ),
        .o_stall_dec       ( s_stall_dec       ),
        .o_flush_dec       ( s_flush_dec       ),
        .o_flush_exec      ( s_flush_exec      ),
        .o_forward_rs1     ( s_forward_rs1     ), 
        .o_forward_rs2     ( s_forward_rs2     ) 
    );


    //-------------------------------------
    // Cache fsm unit.
    //-------------------------------------
    cache_fsm C_FSM (
        .i_clk            ( i_clk            ),
        .i_arst           ( i_arst           ),
        .i_icache_hit     ( s_icache_hit     ),
        .i_axi_read_done  ( i_axi_read_done  ),
        .o_stall          ( s_stall_cache    ),
        .o_instr_we       ( s_instr_we       ),
        .o_axi_read_start ( o_axi_read_start )
    );

endmodule