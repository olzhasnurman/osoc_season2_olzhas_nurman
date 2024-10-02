/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------
// This module contains instantiation of all functional units residing in the decode stage.
// ----------------------------------------------------------------------------------------

module decode_stage
#(
    parameter ADDR_WIDTH  = 64,
              DATA_WIDTH  = 64,
              REG_ADDR_W  = 5,
              INSTR_WIDTH = 32
) 
(
    // Input interface.
    input  logic                       i_clk,
    input  logic                       i_arst,
    input  logic [ INSTR_WIDTH - 1:0 ] i_instruction,
    input  logic [ ADDR_WIDTH  - 1:0 ] i_pc_plus4,
    input  logic [ ADDR_WIDTH  - 1:0 ] i_pc,
    input  logic [ DATA_WIDTH  - 1:0 ] i_rd_write_data,
    input  logic [ REG_ADDR_W  - 1:0 ] i_rd_addr,
    input  logic                       i_reg_we,
    input  logic                       i_flushE,

    // Output interface.
    output logic [               2:0 ] o_func3,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc,
    output logic [ ADDR_WIDTH  - 1:0 ] o_pc_plus4,
    output logic [ DATA_WIDTH  - 1:0 ] o_rs1_data,
    output logic [ DATA_WIDTH  - 1:0 ] o_rs2_data,
    output logic [ REG_ADDR_W  - 1:0 ] o_rs1_addr,
    output logic [ REG_ADDR_W  - 1:0 ] o_rs2_addr,
    output logic [ REG_ADDR_W  - 1:0 ] o_rd_addr,
    output logic [ DATA_WIDTH  - 1:0 ] o_imm_ext,
    output logic [               2:0 ] o_result_src,
    output logic [               4:0 ] o_alu_control,
    output logic                       o_mem_we,
    output logic                       o_reg_we,
    output logic                       o_alu_src,
    output logic                       o_branch,
    output logic                       o_jump
);

    //-------------------------------------
    // Internal nets.
    //-------------------------------------
    
    // Control signals.
    logic [ 6 :0 ] s_op;
    logic [ 2 :0 ] s_func3;
    logic          s_func7_5;

    // 
    logic [ 2:0 ] s_result_src;
    logic [ 4:0 ] s_alu_control;
    logic         s_mem_we;
    logic         s_reg_we;
    logic         s_alu_src;
    logic         s_branch;
    logic         s_jump;
    
    // Extend imm signal.
    logic [             24:0 ] s_imm_data;
    logic [              2:0 ] s_imm_src;
    logic [ DATA_WIDTH - 1:0 ] s_imm_ext;

    // Register file.
    logic [ DATA_WIDTH - 1:0 ] s_rs1_data;
    logic [ DATA_WIDTH - 1:0 ] s_rs2_data;
    logic [ REG_ADDR_W - 1:0 ] s_rs1_addr;
    logic [ REG_ADDR_W - 1:0 ] s_rs2_addr;
    logic [ REG_ADDR_W - 1:0 ] s_rd_addr;


    //-------------------------------------------
    // Continious assignments for internal nets.
    //-------------------------------------------
    assign s_op       = i_instruction [ 6 :0  ];
    assign s_func3    = i_instruction [ 14:12 ];
    assign s_func7_5  = i_instruction [ 30    ];
    assign s_imm_data = i_instruction [ 31:7  ];

    assign s_rs1_addr = i_instruction [ 19:15 ];
    assign s_rs2_addr = i_instruction [ 24:20 ]; 
    assign s_rd_addr  = i_instruction [ 11:7  ];


    //-------------------------------------
    // Lower level modules.
    //-------------------------------------

    // Control unit.
    control_unit CU0 (
        .i_op          ( s_op          ),
        .i_func3       ( s_func3       ),
        .i_func7_5     ( s_func7_5     ),
        .o_imm_src     ( s_imm_src     ),
        .o_result_src  ( s_result_src  ),
        .o_alu_control ( s_alu_control ),
        .o_mem_we      ( s_mem_we      ),
        .o_reg_we      ( s_reg_we      ),
        .o_alu_src     ( s_alu_src     ),
        .o_branch      ( s_branch      ),
        .o_jump        ( s_jump        ) 
    );

    // Extend immediate module.
    extend_imm EI0 (
        .i_control_signal ( s_imm_src  ),
        .i_imm            ( s_imm_data ),
        .o_imm_ext        ( s_imm_ext  )
    );

    // Register file.
    register_file REG_FILE0 (
        .i_clk          ( i_clk           ),
        .i_write_en_3   ( i_reg_we        ),
        .i_arst         ( i_arst          ),
        .i_addr_1       ( s_rs1_addr      ),
        .i_addr_2       ( s_rs2_addr      ),
        .i_addr_3       ( i_rd_addr       ),
        .i_write_data_3 ( i_rd_write_data ),
        .o_read_data_1  ( s_rs1_data      ),
        .o_read_data_2  ( s_rs2_data      )
    );



    //-------------------------------------------------------------------------
    // Pipeline Register. With additional clear signal for flushing
    //-------------------------------------------------------------------------

    preg_decode PREG_D (
        .i_clk         ( i_clk         ),
        .i_arst        ( i_arst        ),
        .i_flushE      ( i_flushE      ),
        .i_result_src  ( s_result_src  ),
        .i_alu_control ( s_alu_control ),
        .i_mem_we      ( s_mem_we      ),
        .i_reg_we      ( s_reg_we      ),
        .i_alu_src     ( s_alu_src     ),
        .i_branch      ( s_branch      ),
        .i_jump        ( s_jump        ),
        .i_pc_plus4    ( i_pc_plus4    ),
        .i_pc          ( i_pc          ),
        .i_imm_ext     ( s_imm_ext     ),
        .i_rs1_data    ( s_rs1_data    ),
        .i_rs2_data    ( s_rs2_data    ),
        .i_rs1_addr    ( s_rs1_addr    ),
        .i_rs2_addr    ( s_rs2_addr    ),
        .i_rd_addr     ( s_rd_addr     ),
        .i_func3       ( s_func3       ),
        .o_result_src  ( o_result_src  ),
        .o_alu_control ( o_alu_control ),
        .o_mem_we      ( o_mem_we      ),
        .o_reg_we      ( o_reg_we      ),
        .o_alu_src     ( o_alu_src     ),
        .o_branch      ( o_branch      ),
        .o_jump        ( o_jump        ),
        .o_pc_plus4    ( o_pc_plus4    ),
        .o_pc          ( o_pc          ),
        .o_imm_ext     ( o_imm_ext     ),
        .o_rs1_data    ( o_rs1_data    ),
        .o_rs2_data    ( o_rs2_data    ),
        .o_rs1_addr    ( o_rs1_addr    ),
        .o_rs2_addr    ( o_rs2_addr    ),
        .o_rd_addr     ( o_rd_addr     ),
        .o_func3       ( o_func3       )
    );
    
endmodule