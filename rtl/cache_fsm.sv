/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------
// This is cache fsm module that implements mechanism for caching data from main memory that
// reads and writes data to main memory by communication with them through AXI4-Lite interace. 
// --------------------------------------------------------------------------------------------

module cache_fsm
(
    // Input interface.
    input  logic i_clk,
    input  logic i_arst,
    input  logic i_icache_hit,
    input  logic i_dcache_hit,
    input  logic i_dcache_dirty,
    input  logic i_axi_done,
    input  logic i_mem_access,

    // Output interface.
    output logic o_stall,
    output logic o_instr_we,
    output logic o_dcache_we,
    output logic o_axi_write_start,
    output logic o_axi_read_start_i,
    output logic o_axi_read_start_d
);

    //------------------------------------
    // FSM.
    //------------------------------------

    // FSM states.
    typedef enum logic [ 1:0 ]
    {
        IDLE       = 2'b00,
        ALLOCATE_I = 2'b01,
        ALLOCATE_D = 2'b10,
        WRITE_BACK = 2'b11
    } t_state;

    t_state PS;
    t_state NS;

    // FSM: PS syncronization.
    always_ff @( posedge i_clk, posedge i_arst ) begin
        if ( i_arst ) PS <= IDLE;
        else          PS <= NS;
    end

    
    // FSM: NS logic.
    always_comb begin
        // Default value.
        NS = PS;

        case ( PS )
            IDLE    : if ( ~ i_icache_hit                ) NS = ALLOCATE_I;
                 else if ( i_dcache_hit                  ) NS = PS;
                 else if ( i_dcache_dirty & i_mem_access ) NS = WRITE_BACK;
                 else if ( ~ i_dcache_hit & i_mem_access ) NS = ALLOCATE_D;
                 else                                      NS = PS; 
            ALLOCATE_I: if ( i_axi_done                  ) NS = IDLE;
            ALLOCATE_D: if ( i_axi_done                  ) NS = IDLE;
            WRITE_BACK: if ( i_axi_done                  ) NS = IDLE;
            default : NS = PS; 
        endcase
    end


    // FSM: Output logic.
    always_comb begin
        // Default values.
        o_stall            = 1'b0;
        o_instr_we         = 1'b0;
        o_dcache_we        = 1'b0;
        o_axi_write_start  = 1'b0;
        o_axi_read_start_i = 1'b0;
        o_axi_read_start_d = 1'b0;

        case ( PS )
            IDLE: begin
                o_stall            = ( ~ i_icache_hit ) | ( ~ i_dcache_hit & i_mem_access );
                o_axi_write_start  = ~ i_dcache_hit & i_dcache_dirty & i_mem_access;
                o_axi_read_start_i = ( ~ i_icache_hit ); 
                o_axi_read_start_d = ( ( ~ i_dcache_hit ) & ( ~ i_dcache_dirty ) & i_mem_access );
            end

            ALLOCATE_I: begin
                o_stall            = 1'b1;
                o_instr_we         = i_axi_done;
                o_axi_read_start_i = ~ i_axi_done;              
            end 

            ALLOCATE_D: begin
                o_stall            = 1'b1;
                o_dcache_we        = i_axi_done;
                o_axi_read_start_d = ~ i_axi_done;              
            end 

            WRITE_BACK: begin
                o_stall           = 1'b1;
                o_axi_write_start = ~ i_axi_done;
            end

            default: begin
                o_stall            = 1'b0;
                o_instr_we         = 1'b0;
                o_dcache_we        = 1'b0;
                o_axi_write_start  = 1'b0;
                o_axi_read_start_i = 1'b0;
                o_axi_read_start_d = 1'b0; 
            end
        endcase
    end
    
endmodule