`timescale 1ns/1ps
// NOTE: Timer macros (`TIMER_BITS, `AUTO_LOCK_CYCLES, `LOCKOUT_CYCLES)
// are defined in design.sv - do NOT redefine them here.

module tb_secure_lock;

    reg        clk, rst, ena;
    reg  [3:0] in;
    reg        enter;
    wire       unlock_led, error_led, lockout_led;

    secure_lock dut (
        .clk(clk), .rst(rst), .ena(ena),
        .in(in), .enter(enter),
        .unlock_led(unlock_led),
        .error_led(error_led),
        .lockout_led(lockout_led)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg error_seen, lockout_seen, unlock_seen;
    always @(posedge clk) begin
        if (error_led)   error_seen   <= 1;
        if (lockout_led) lockout_seen <= 1;
        if (unlock_led)  unlock_seen  <= 1;
    end
    task clear_seen;
        begin error_seen=0; lockout_seen=0; unlock_seen=0; end
    endtask

    task enter_digit;
        input [3:0] d;
        begin
            @(negedge clk); in=d; enter=1;
            @(negedge clk); enter=0;
            @(negedge clk);
        end
    endtask

    task enter_password;
        input [3:0] a, b, c, d;
        begin
            enter_digit(a); enter_digit(b);
            enter_digit(c); enter_digit(d);
        end
    endtask

    task wait_n;
        input integer n;
        integer k;
        begin for(k=0; k<n; k=k+1) @(posedge clk); #1; end
    endtask

    integer pass_count=0, fail_count=0;
    task check;
        input        cond;
        input [127:0] msg;
        begin
            if (cond) begin $display("  PASS: %s",msg); pass_count=pass_count+1; end
            else      begin $display("  FAIL: %s",msg); fail_count=fail_count+1; end
        end
    endtask

    initial begin
        $dumpfile("tb_secure_lock.vcd");
        $dumpvars(0, tb_secure_lock);

        rst=1; ena=1; in=0; enter=0; clear_seen;
        repeat(5) @(posedge clk);
        rst=0;
        repeat(2) @(posedge clk);

        $display("\n===== SECURE LOCK TB =====\n");

        // TEST 1: Correct password -> unlock -> auto-lock
        $display("TEST 1: Correct password 1-2-3-4");
        clear_seen;
        enter_password(4'd1, 4'd2, 4'd3, 4'd4);
        wait_n(2);
        check(unlock_seen==1,  "Unlock detected");
        check(error_seen==0,   "No error on correct pw");
        check(lockout_seen==0, "No lockout on correct pw");
        wait_n(19);
        check(unlock_led==0,   "Auto-lock after timer");
        $display("");

        // TEST 2: Wrong x1
        $display("TEST 2: Wrong password (attempt 1/3)");
        wait_n(2);
        clear_seen;
        enter_password(4'd9, 4'd9, 4'd9, 4'd9);
        wait_n(2);
        check(error_seen==1,   "Error seen attempt 1");
        check(lockout_seen==0, "No lockout at attempt 1");
        $display("");

        // TEST 3: Wrong x2
        $display("TEST 3: Wrong password (attempt 2/3)");
        wait_n(2);
        clear_seen;
        enter_password(4'd0, 4'd0, 4'd0, 4'd0);
        wait_n(2);
        check(error_seen==1,   "Error seen attempt 2");
        check(lockout_seen==0, "No lockout at attempt 2");
        $display("");

        // TEST 4: Wrong x3 -> LOCKOUT
        $display("TEST 4: Third wrong -> LOCKOUT");
        wait_n(2);
        clear_seen;
        enter_password(4'd5, 4'd5, 4'd5, 4'd5);
        wait_n(3);
        check(lockout_seen==1, "Lockout seen after 3 attempts");
        check(lockout_led==1,  "Lockout LED HIGH");
        check(unlock_seen==0,  "No unlock during lockout");
        wait_n(36);
        check(lockout_led==0,  "Lockout expired");
        $display("");

        // TEST 5: Correct after lockout
        $display("TEST 5: Correct after lockout");
        wait_n(2);
        clear_seen;
        enter_password(4'd1, 4'd2, 4'd3, 4'd4);
        wait_n(2);
        check(unlock_seen==1,  "Unlock works after lockout");
        wait_n(21);
        $display("");

        // TEST 6: Reset
        $display("TEST 6: Reset");
        enter_digit(4'd9);
        rst=1; @(posedge clk); #1; rst=0;
        check(unlock_led==0,  "unlock cleared");
        check(error_led==0,   "error cleared");
        check(lockout_led==0, "lockout cleared");
        $display("");

        $display("===========================");
        $display("RESULT: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("===========================");
        if (fail_count==0) $display("ALL TESTS PASSED");
        else               $display("Some tests failed");
        $finish;
    end

    initial begin #600000; $display("TIMEOUT"); $finish; end
endmodule