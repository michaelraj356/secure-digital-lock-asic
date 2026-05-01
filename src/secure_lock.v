`timescale 1ns/1ps

// Timer macros - SIM values used for EDA Playground testbench.
// For real hardware synthesis, change to 24-bit values below.
`define TIMER_BITS       8
`define AUTO_LOCK_CYCLES 8'd16
`define LOCKOUT_CYCLES   8'd32

// To use hardware timing instead, comment above and uncomment:
// `define TIMER_BITS       24
// `define AUTO_LOCK_CYCLES 24'd5_000_000
// `define LOCKOUT_CYCLES   24'd10_000_000

module secure_lock (
    input  wire       clk,
    input  wire       rst,
    input  wire       ena,
    input  wire [3:0] in,
    input  wire       enter,
    output reg        unlock_led,
    output reg        error_led,
    output reg        lockout_led
);
    localparam [3:0] PASS0=4'd1, PASS1=4'd2, PASS2=4'd3, PASS3=4'd4;
    localparam [2:0]
        S_IDLE=3'd0, S_INPUT=3'd1, S_VERIFY=3'd2,
        S_SUCCESS=3'd3, S_ERROR=3'd4, S_LOCKOUT=3'd5;

    reg [2:0]             state;
    reg [3:0]             digit [0:3];
    reg [1:0]             digit_idx;
    reg [1:0]             attempts;
    reg [`TIMER_BITS-1:0] timer;
    reg                   enter_prev;

    wire enter_rise  = enter & ~enter_prev;
    wire password_ok = (digit[0]==PASS0) && (digit[1]==PASS1) &&
                       (digit[2]==PASS2) && (digit[3]==PASS3);
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state<=S_IDLE; digit_idx<=0; attempts<=0; timer<=0;
            enter_prev<=0; unlock_led<=0; error_led<=0; lockout_led<=0;
            for(i=0; i<4; i=i+1) digit[i]<=0;
        end else if (!ena) begin
            enter_prev <= enter;
        end else begin
            enter_prev <= enter;
            case (state)
                S_IDLE: begin
                    timer<=0; digit_idx<=0;
                    for(i=0; i<4; i=i+1) digit[i]<=0;
                    if (enter_rise) begin
                        digit[0]<=in; digit_idx<=1; state<=S_INPUT;
                    end
                end
                S_INPUT: begin
                    if (enter_rise) begin
                        digit[digit_idx]<=in;
                        if (digit_idx==3) state<=S_VERIFY;
                        else digit_idx<=digit_idx+1;
                    end
                end
                S_VERIFY: begin
                    if (password_ok) begin
                        state<=S_SUCCESS; timer<=`AUTO_LOCK_CYCLES;
                    end else begin
                        state<=S_ERROR;
                        if (attempts<3) attempts<=attempts+1;
                    end
                end
                S_SUCCESS: begin
                    if (timer>0) timer<=timer-1;
                    else         state<=S_IDLE;
                end
                S_ERROR: begin
                    if (attempts>=3) begin
                        state<=S_LOCKOUT; timer<=`LOCKOUT_CYCLES;
                    end else begin
                        state<=S_IDLE;
                    end
                end
                S_LOCKOUT: begin
                    if (timer>0) timer<=timer-1;
                    else begin attempts<=0; state<=S_IDLE; end
                end
                default: state<=S_IDLE;
            endcase
            unlock_led  <= (state==S_SUCCESS);
            error_led   <= (state==S_ERROR);
            lockout_led <= (state==S_LOCKOUT);
        end
    end
endmodule

module tt_um_secure_lock (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire unlock_led, error_led, lockout_led;
    secure_lock lock_inst (
        .clk(clk), .rst(~rst_n), .ena(ena),
        .in(ui_in[3:0]), .enter(ui_in[4]),
        .unlock_led(unlock_led),
        .error_led(error_led),
        .lockout_led(lockout_led)
    );
    assign uo_out  = {5'b00000, lockout_led, error_led, unlock_led};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
endmodule