//=====================================================================
// File        : tb_regfile.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_regfile
// Description :
//   Fully self-checking testbench for regfile.v (32x32 register file)
//
// Verified Features:
//   1) Reset clears all registers to 0 (rst_n active-low)
//   2) Writes happen on posedge clk when we=1
//   3) Reads are combinational (async)
//   4) Writes to x0 are ignored
//   5) x0 always reads as 0
//   6) Multiple registers store independent values
//
// Verification Features:
//   - Fully self-checking
//   - Input print per test
//   - Expected output print
//   - Actual output print
//   - PASS/FAIL per test
//   - Global counters
//   - Final verification summary report
//
// Run Commands:
//   iverilog -o ./Verification_Results/result_tb_regfile ./src/regfile.v ./RTL_Verification/tb_regfile.v
//   vvp ./Verification_Results/result_tb_regfile
//=====================================================================

`timescale 1ns/1ps

module tb_regfile;

    //=============================================================
    // Testbench Parameters
    //=============================================================
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg         clk;
    reg         rst_n;
    reg         we;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;
    reg  [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    regfile dut (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (we),
        .rs1   (rs1),
        .rs2   (rs2),
        .rd    (rd),
        .wd    (wd),
        .rd1   (rd1),
        .rd2   (rd2)
    );

    //=============================================================
    // Global Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //=============================================================
    // VCD Dump (for GTKWave)
    //=============================================================
    initial begin
        $dumpfile("Verification_Results/vcd/tb_regfile.vcd");
        $dumpvars(0, tb_regfile);
    end

    //=============================================================
    // Clock Generation (10ns period)
    //=============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //=============================================================
    // Task: Divider
    //=============================================================
    task print_divider;
        begin
            $display("----------------------------------------------------------------");
        end
    endtask

    //=============================================================
    // Task: Print inputs (common format)
    //=============================================================
    task print_inputs;
        input [4:0]  rs1_in;
        input [4:0]  rs2_in;
        input        we_in;
        input [4:0]  rd_in;
        input [31:0] wd_in;
        input        rst_n_in;
        begin
            $display("Inputs:");
            $display("   rst_n = %0d", rst_n_in);
            $display("   we    = %0d", we_in);
            $display("   rs1   = x%0d", rs1_in);
            $display("   rs2   = x%0d", rs2_in);
            $display("   rd    = x%0d", rd_in);
            $display("   wd    = %08h", wd_in);
        end
    endtask

    //=============================================================
    // Task: Run one read check
    //=============================================================
    task check_read;
        input [8*70:1] test_name;
        input [4:0]    rs1_in;
        input [4:0]    rs2_in;
        input [31:0]   exp_rd1;
        input [31:0]   exp_rd2;

        reg [31:0] got1;
        reg [31:0] got2;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply read addresses
            rs1 = rs1_in;
            rs2 = rs2_in;
            #2; // combinational settle

            got1 = rd1;
            got2 = rd2;

            print_inputs(rs1_in, rs2_in, we, rd, wd, rst_n);

            $display("");
            $display("Expected:");
            $display("   rd1   = %08h", exp_rd1);
            $display("   rd2   = %08h", exp_rd2);

            $display("");
            $display("Got:");
            $display("   rd1   = %08h", got1);
            $display("   rd2   = %08h", got2);

            if ((got1 === exp_rd1) && (got2 === exp_rd2)) begin
                passed_tests = passed_tests + 1;
                $display("STATUS: PASS");
            end
            else begin
                failed_tests = failed_tests + 1;
                $display("STATUS: FAIL");
            end

            print_divider();
            $display("");

            #(TEST_DELAY);
        end
   endtask

    //=============================================================
    // Task: Perform one write
    //=============================================================
    task do_write;
        input [8*70:1] step_name;
        input [4:0]    rd_in;
        input [31:0]   wd_in;
        input          we_in;

        begin
            print_divider();
            $display("STEP : %s", step_name);

            we = we_in;
            rd = rd_in;
            wd = wd_in;

            $display("Write Inputs:");
            $display("   we = %0d | rd = x%0d | wd = %08h", we_in, rd_in, wd_in);

            // Write happens on posedge
            @(posedge clk);
            #1;

            print_divider();
            $display("");

            #(TEST_DELAY);
        end
    endtask

    //=============================================================
    // Main Test Sequence
    //=============================================================
    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init signals
        rst_n = 1'b0;
        we    = 1'b0;
        rs1   = 5'd0;
        rs2   = 5'd0;
        rd    = 5'd0;
        wd    = 32'h0000_0000;

        $display("====================================================");
        $display(" REGFILE VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // TEST 1: Reset clears registers
        //=========================================================
        // Hold reset for 2 cycles
        @(posedge clk);
        @(posedge clk);
        #1;

        // Release reset
        rst_n = 1'b1;
        #2;

        // After reset release, check some registers are 0
        check_read("After reset: x0=0, x1=0",
                   5'd0, 5'd1,
                   32'h0000_0000, 32'h0000_0000);

        check_read("After reset: x10=0, x31=0",
                   5'd10, 5'd31,
                   32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // TEST 2: Write to x1 and read back
        //=========================================================
        do_write("Write 0x11111111 into x1",
                 5'd1, 32'h1111_1111, 1'b1);

        check_read("Read back x1 should be 0x11111111",
                   5'd1, 5'd0,
                   32'h1111_1111, 32'h0000_0000);

        //=========================================================
        // TEST 3: Write to x2 and x3, verify independent
        //=========================================================
        do_write("Write 0x22222222 into x2",
                 5'd2, 32'h2222_2222, 1'b1);

        do_write("Write 0x33333333 into x3",
                 5'd3, 32'h3333_3333, 1'b1);

        check_read("Read x2 and x3 should match",
                   5'd2, 5'd3,
                   32'h2222_2222, 32'h3333_3333);

        //=========================================================
        // TEST 4: Write enable = 0 must not write
        //=========================================================
        do_write("Attempt write into x4 with we=0 (should NOT update)",
                 5'd4, 32'h4444_4444, 1'b0);

        check_read("x4 should still be 0",
                   5'd4, 5'd0,
                   32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // TEST 5: Writes to x0 must be ignored
        //=========================================================
        do_write("Attempt write into x0 (must be ignored)",
                 5'd0, 32'hDEAD_BEEF, 1'b1);

        check_read("x0 must remain 0 always",
                   5'd0, 5'd1,
                   32'h0000_0000, 32'h1111_1111);

        //=========================================================
        // TEST 6: Reset again clears everything
        //=========================================================
        print_divider();
        $display("STEP : Apply reset again (rst_n=0)");
        rst_n = 1'b0;
        @(posedge clk);
        @(posedge clk);
        #1;
        rst_n = 1'b1;
        #2;
        print_divider();
        $display("");

        check_read("After 2nd reset: x1=0, x2=0",
                   5'd1, 5'd2,
                   32'h0000_0000, 32'h0000_0000);

        check_read("After 2nd reset: x3=0, x0=0",
                   5'd3, 5'd0,
                   32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" REGFILE VERIFICATION REPORT");
        $display("====================================================");
        $display("   Total Tests   : %0d", total_tests);
        $display("   Passed        : %0d", passed_tests);
        $display("   Failed        : %0d", failed_tests);
        $display("====================================================");

        if (failed_tests == 0) begin
            $display("STATUS: ALL TESTS PASSED");
        end
        else begin
            $display("STATUS: SOME TESTS FAILED");
        end

        $display("====================================================");
        $display("");

        $finish;
    end

endmodule
