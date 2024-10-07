/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------
// This module contains logic for data and conrol hazard managment unit.
// ----------------------------------------------------------------------

module hazard_unit
#(
    parameter REG_ADDR_W  = 5
) 
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs1_addr_dec,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs1_addr_exec,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs2_addr_dec,
    input  logic [ REG_ADDR_W - 1:0 ] i_rs2_addr_exec,
    input  logic [ REG_ADDR_W - 1:0 ] i_rd_addr_exec,
    input  logic [ REG_ADDR_W - 1:0 ] i_rd_addr_mem,
    input  logic [ REG_ADDR_W - 1:0 ] i_rd_addr_wb,
    input  logic                      i_reg_we_mem,
    input  logic                      i_reg_we_wb,
    input  logic                      i_pc_src_exec,
    input  logic                      i_load_instr_exec

    // Output interface.
    output logic                      o_stall_fetch,
    output logic                      o_stall_dec,
    output logic                      o_flush_dec,
    output logic                      o_flush_exec,
    output logic [              1:0 ] o_forward_rs1, 
    output logic [              1:0 ] o_forward_rs2, 
);

    logic s_load_instr_stall;

    always_comb begin
        if      ( ( i_rs1_addr_exec == i_rd_addr_mem ) & i_reg_we ) o_forward_rs1 = 2'b10;
        else if ( ( i_rs1_addr_exec == i_rd_addr_wb  ) & i_reg_we ) o_forward_rs1 = 2'b01;
        else                                                        o_forward_rs1 = 2'b00;

        if      ( ( i_rs2_addr_exec == i_rd_addr_mem ) & i_reg_we ) o_forward_rs2 = 2'b10;
        else if ( ( i_rs2_addr_exec == i_rd_addr_wb  ) & i_reg_we ) o_forward_rs2 = 2'b01;
        else                                                        o_forward_rs2 = 2'b00;

    end

    assign s_load_instr_stall = i_load_instr_exec & ( ( i_rs1_addr_dec == i_rd_addr_exec ) | ( i_rs2_addr_dec == i_rd_addr_exec ) );

    assign o_stall_fetch = s_load_instr_stall;
    assign o_stall_dec   = s_load_instr_stall;

    assign o_flush_dec  = i_pc_src_exec;
    assign o_flush_exec = s_load_instr_stall | i_pc_src_exec;


endmodule