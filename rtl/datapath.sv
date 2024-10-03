/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------------------------------------
// This module contains instantiation of all functional units in all stages of the pipeline
// ------------------------------------------------------------------------------------------

module datapath
#(
    parameter ADDR_WIDTH  = 64,
              DATA_WIDTH  = 64,
              REG_ADDR_W  = 5,
              INSTR_WIDTH = 32
) 
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic                      i_stall_fetch,
    input  logic                      i_stall_dec,
    input  logic                      i_flush_dec,
    input  logic                      i_flush_exec,
    input  logic [              1:0 ] i_forward_rs1, 
    input  logic [              1:0 ] i_forward_rs2, 

    // Output interface.
    output logic [ REG_ADDR_W - 1:0 ] o_rs1_addr_dec,
    output logic [ REG_ADDR_W - 1:0 ] o_rs1_addr_exec,
    output logic [ REG_ADDR_W - 1:0 ] o_rs2_addr_dec,
    output logic [ REG_ADDR_W - 1:0 ] o_rs2_addr_exec,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr_exec,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr_mem,
    output logic [ REG_ADDR_W - 1:0 ] o_rd_addr_wb,
    output logic                      o_reg_we_mem,
    output logic                      o_reg_we_wb
);

    //-------------------------------------------------------------
    // Internal nets.
    //-------------------------------------------------------------
    
    // Fetch stage signals.
    logic [ ADDR_WIDTH - 1:0 ] s_pc_target_fetch;
    logic                      s_pc_src_fetch;


    // Decode stage signals.
    logic [ INSTR_WIDTH - 1:0 ] s_instruction_dec;
    logic [ ADDR_WIDTH  - 1:0 ] s_pc_plus4_dec;
    logic [ ADDR_WIDTH  - 1:0 ] s_pc_dec;
    logic [ REG_ADDR_W  - 1:0 ] s_rd_addr_dec;
    logic                       s_reg_we_dec;


    // Execute stage signals.
    logic [              2:0 ] s_func3_exec;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_exec;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_plus4_exec;
    logic [ DATA_WIDTH - 1:0 ] s_rs1_data_exec;
    logic [ DATA_WIDTH - 1:0 ] s_rs2_data_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rs1_addr_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rs2_addr_exec;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_exec;
    logic [ DATA_WIDTH - 1:0 ] s_imm_ext_exec;
    logic [              2:0 ] s_result_src_exec;
    logic [              4:0 ] s_alu_control_exec;
    logic                      s_mem_we_exec;
    logic                      s_reg_we_exec;
    logic                      s_alu_src_exec;
    logic                      s_branch_exec;
    logic                      s_jump_exec;
    logic [ DATA_WIDTH - 1:0 ] s_alu_result_exec;


    // Memory stage signals.
    logic [ ADDR_WIDTH - 1:0 ] s_pc_plus4_mem;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_target_mem;
    logic [ DATA_WIDTH - 1:0 ] s_alu_result_mem;
    logic [ DATA_WIDTH - 1:0 ] s_write_data_mem;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_mem;
    logic [ DATA_WIDTH - 1:0 ] s_imm_ext_mem;
    logic [              2:0 ] s_result_src_mem;
    logic                      s_mem_we_mem;
    logic                      s_reg_we_mem;


    // Write-back stage signals.
    logic [ DATA_WIDTH - 1:0 ] s_result_wb;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_plus4_wb;
    logic [ ADDR_WIDTH - 1:0 ] s_pc_target_wb;
    logic [ DATA_WIDTH - 1:0 ] s_alu_result_wb;
    logic [ DATA_WIDTH - 1:0 ] s_read_data_wb;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr_wb;
    logic [ DATA_WIDTH - 1:0 ] s_imm_ext_wb;
    logic [              2:0 ] s_result_src_wb;
    logic                      s_reg_we_wb;


    //-------------------------------------------------------------
    // Lower level modules.
    //-------------------------------------------------------------

    //-------------------------------------
    // Fetch stage module.
    //-------------------------------------
    fetch_stage F_STAGE1 (
        .i_clk         ( i_clk             ),
        .i_arst        ( i_arst            ),
        .i_pc_target   ( s_pc_target_fetch ),
        .i_pc_src      ( s_pc_src_fetch    ),
        .i_stall_fetch ( i_stall_fetch     ),
        .i_stall_dec   ( i_stall_dec       ),
        .i_flush_dec   ( i_flush_dec       ),
        .o_instruction ( s_instruction_dec ),
        .o_pc_plus4    ( s_pc_plus4_dec    ),
        .o_pc          ( s_pc_dec          )
    );


    //-------------------------------------
    // Decode stage module.
    //-------------------------------------
    decode_stage DEC_STAGE2 (
        .i_clk           ( i_clk              ),
        .i_arst          ( i_arst             ),
        .i_instruction   ( s_instruction_dec  ),
        .i_pc_plus4      ( s_pc_plus4_dec     ),
        .i_pc            ( s_pc_dec           ),
        .i_rd_write_data ( s_result_wb        ),
        .i_rd_addr       ( s_rd_addr_dec      ),
        .i_reg_we        ( s_reg_we_dec       ),
        .i_flush_exec    ( i_flush_exec       ),
        .o_func3         ( s_func3_exec       ),
        .o_pc            ( s_pc_exec          ),
        .o_pc_plus4      ( s_pc_plus4_exec    ),
        .o_rs1_data      ( s_rs1_data_exec    ),
        .o_rs2_data      ( s_rs2_data_exec    ),
        .o_rs1_addr      ( o_rs1_addr_dec     ),
        .o_rs2_addr      ( o_rs2_addr_dec     ),
        .o_rs1_addr_preg ( s_rs1_addr_exec    ),
        .o_rs2_addr_preg ( s_rs2_addr_exec    ),
        .o_rd_addr       ( s_rd_addr_exec     ),
        .o_imm_ext       ( s_imm_ext_exec     ),
        .o_result_src    ( s_result_src_exec  ),
        .o_alu_control   ( s_alu_control_exec ),
        .o_mem_we        ( s_mem_we_exec      ),
        .o_reg_we        ( s_reg_we_exec      ),
        .o_alu_src       ( s_alu_src_exec     ),
        .o_branch        ( s_branch_exec      ),
        .o_jump          ( s_jump_exec        )
    );

    //-------------------------------------
    // Execute stage module.
    //-------------------------------------
    execute_stage EXEC_STAGE3 (
        .i_clk              ( i_clk              ),
        .i_arst             ( i_arst             ),
        .i_pc               ( s_pc_exec          ),
        .i_pc_plus4         ( s_pc_plus4_exec    ),
        .i_rs1_data         ( s_rs1_data_exec    ),
        .i_rs2_data         ( s_rs2_data_exec    ),
        .i_rs1_addr         ( s_rs1_addr_exec    ),
        .i_rs2_addr         ( s_rs2_addr_exec    ),
        .i_rd_addr          ( s_rd_addr_exec     ),
        .i_imm_ext          ( s_imm_ext_exec     ),
        .i_func3            ( s_func3_exec       ),
        .i_result_src       ( s_result_src_exec  ),
        .i_alu_control      ( s_alu_control_exec ),
        .i_mem_we           ( s_mem_we_exec      ),
        .i_reg_we           ( s_reg_we_exec      ),
        .i_alu_src          ( s_alu_src_exec     ),
        .i_branch           ( s_branch_exec      ),
        .i_jump             ( s_jump_exec        ),
        .i_result           ( s_result_wb        ),
        .i_alu_result       ( s_alu_result_exec  ),
        .i_forward_rs1_exec ( i_forward_rs1      ),
        .i_forward_rs2_exec ( i_forward_rs2      ),
        .o_pc_plus4         ( s_pc_plus4_mem     ),
        .o_pc_target        ( s_pc_target_fetch  ),
        .o_pc_target_preg   ( s_pc_target_mem    ),
        .o_alu_result       ( s_alu_result_mem   ),
        .o_write_data       ( s_write_data_mem   ),
        .o_rs1_addr         ( o_rs1_addr_exec    ),
        .o_rs2_addr         ( o_rs2_addr_exec    ),
        .o_rd_addr          ( o_rd_addr_exec     ),
        .o_rd_addr_preg     ( s_rd_addr_mem      ),
        .o_imm_ext          ( s_imm_ext_mem      ),
        .o_result_src       ( s_result_src_mem   ),
        .o_mem_we           ( s_mem_we_mem       ),
        .o_reg_we           ( s_reg_we_mem       ),
        .o_pc_src           ( s_pc_src_fetch     )
    );


    //-------------------------------------
    // Memory stage module.
    //-------------------------------------
    memory_stage MEM_STAGE4 (
        .i_clk             ( i_clk             ),
        .i_arst            ( i_arst            ),
        .i_pc_plus4        ( s_pc_plus4_mem    ),
        .i_pc_target       ( s_pc_target_mem   ),
        .i_alu_result      ( s_alu_result_mem  ),
        .i_write_data      ( s_write_data_mem  ),
        .i_rd_addr         ( s_rd_addr_mem     ),
        .i_imm_ext         ( s_imm_ext_mem     ),
        .i_result_src      ( s_result_src_mem  ),
        .i_mem_we          ( s_mem_we_mem      ),
        .i_reg_we          ( s_reg_we_mem      ),
        .o_pc_plus4        ( s_pc_plus4_wb     ),
        .o_pc_target       ( s_pc_target_wb    ),
        .o_alu_result      ( s_alu_result_exec ),
        .o_alu_result_preg ( s_alu_result_wb   ),
        .o_read_data       ( s_read_data_wb    ),
        .o_rd_addr         ( o_rd_addr_mem     ),
        .o_rd_addr_preg    ( s_rd_addr_wb      ),
        .o_imm_ext         ( s_imm_ext_wb      ),
        .o_result_src      ( s_result_src_wb   ),
        .o_reg_we          ( s_reg_we_wb       )
    );


    //-------------------------------------
    // Write-back stage module.
    //-------------------------------------
    write_back_stage WB_STAGE5 (
        .i_pc_plus4   ( s_pc_plus4_wb   ),
        .i_pc_target  ( s_pc_target_wb  ),
        .i_alu_result ( s_alu_result_wb ),
        .i_read_data  ( s_read_data_wb  ),
        .i_rd_addr    ( s_rd_addr_wb    ),
        .i_imm_ext    ( s_imm_ext_wb    ),
        .i_result_src ( s_result_src_wb ),
        .i_reg_we     ( s_reg_we_wb     ),
        .o_result     ( s_result_wb     ),
        .o_rd_addr    ( s_rd_addr_dec   ),
        .o_reg_we     ( s_reg_we_dec    )
    );


    //-------------------------------------------------------------
    // Continious assignment of outputs.
    //-------------------------------------------------------------
    assign o_rd_addr_wb = s_rd_addr_dec;
    assign o_reg_we_mem = s_reg_we_mem;
    assign o_reg_we_wb  = s_reg_we_wb;

endmodule