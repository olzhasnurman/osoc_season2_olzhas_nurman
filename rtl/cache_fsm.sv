/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------
// This is cache fsm module that implements mechanism for caching data from main memory that
// reads and writes data to main memory by communication with them through AXI4-Lite interace. 
// --------------------------------------------------------------------------------------------

module cache_fsm
(
    // Input ports.
    input  logic i_clk,
    input  logic i_arst,
    input  logic i_icache_hit,
    input  logic i_axi_read_done,

    output logic o_stall,
    output logic o_instr_we,
    output logic o_axi_read_start
);

    //------------------------------------
    // FSM.
    //------------------------------------

    // FSM states.
    typedef enum logic 
    {
        IDLE     = 1'b0,
        ALLOCATE = 1'b1
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
            IDLE    : if ( ~ i_icache_hit  ) NS = ALLOCATE;
            ALLOCATE: if ( i_axi_read_done ) NS = IDLE;
            default : NS = PS; 
        endcase
    end


    // FSM: Output logic.
    always_comb begin
        // Default values.
        o_stall          = 1'b0;
        o_instr_we       = 1'b0;
        o_axi_read_start = 1'b0;

        case ( PS )
            IDLE: begin
                o_stall          = ~ i_icache_hit;
                o_axi_read_start = ~ i_icache_hit;
            end

            ALLOCATE: begin
                o_stall          = 1'b1;
                o_instr_we       = i_axi_read_done;
                o_axi_read_start = ~ i_axi_read_done;              
            end 

            default: begin
                o_stall          = 1'b0;
                o_instr_we       = 1'b0;
                o_axi_read_start = 1'b0;   
            end
        endcase
    end
    
endmodule