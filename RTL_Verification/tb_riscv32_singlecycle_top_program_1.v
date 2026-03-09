//=====================================================================
// File        : tb_riscv32_singlecycle_top_program_1.v
// Author      : Prabhat Pandey
// Created On  : 25-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_riscv32_singlecycle_top_program_1
// Description :
//   Fully self-checking top-level testbench for riscv32_singlecycle_top
//   using program_1.hex.
//
// Program Used (program_1.hex):
//   00000013   nop
//   00100093   addi x1,  x0, 1
//   00200113   addi x2,  x0, 2
//   00308193   addi x3,  x1, 3
//   00410213   addi x4,  x2, 4
//   00518293   addi x5,  x3, 5
//   00620313   addi x6,  x4, 6
//   00728393   addi x7,  x5, 7
//   00830413   addi x8,  x6, 8
//   00938493   addi x9,  x7, 9
//   00a40513   addi x10, x8, 10
//   00b48593   addi x11, x9, 11
//   00c50613   addi x12, x10,12
//   00d58693   addi x13, x11,13
//   00e60713   addi x14, x12,14
//   00f68793   addi x15, x13,15
//
// Expected Final Register Values:
//   x1  = 1
//   x2  = 2
//   x3  = 4
//   x4  = 6
//   x5  = 9
//   x6  = 12
//   x7  = 16
//   x8  = 20
//   x9  = 25
//   x10 = 30
//   x11 = 36
//   x12 = 42
//   x13 = 49
//   x14 = 56
//   x15 = 64
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
//   iverilog -o ./Verification_Results/result_tb_top_program_1 \
//       ./src/*.v ./RTL_Verification/tb_riscv32_singlecycle_top_program_1.v
//
//   vvp ./Verification_Results/result_tb_top_program_1
//=====================================================================

`timescale 1ns/1ps

module tb_riscv32_singlecycle_top_program_1;

    //=============================================================
    // Parameters
    //=============================================================
    localparam IMEM_DEPTH_WORDS = 4096;
    localparam DMEM_DEPTH_WORDS = 256;
    // NOTE: Keep this below the 10ns clock period to avoid skipping cycles.
    localparam integer TEST_DELAY = 1; // ns between checks for waveform visibility

    //=============================================================
    // Clock / Reset
    //=============================================================
    reg clk;
    reg rst_n;
    reg clk_en;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    riscv32_singlecycle_top #(
        .IMEM_DEPTH_WORDS(IMEM_DEPTH_WORDS),
        .DMEM_DEPTH_WORDS(DMEM_DEPTH_WORDS)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    //=============================================================
    // Global Counters
    //=============================================================
    integer total_tests;
    integer passed_tests;
    integer failed_tests;
    integer i;

    //=============================================================
    // VCD Dump (for GTKWave)
    //=============================================================
    initial begin
        $dumpfile("Verification_Results/vcd/tb_riscv32_singlecycle_top_program_1.vcd");
        $dumpvars(0, tb_riscv32_singlecycle_top_program_1);
    end

    //=============================================================
    // Clock Generation (10ns period)
    //=============================================================
    initial begin
        clk = 1'b0;
        forever begin
            #5;
            if (clk_en) begin
                clk = ~clk;
            end
        end
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
    // Task: Check Register Value
    //=============================================================
    task check_reg;
        input [8*60:1] test_name;
        input [4:0]    reg_num;
        input [31:0]   expected;

        reg [31:0] got;
        begin
            total_tests = total_tests + 1;

            got = dut.u_regfile.regs[reg_num];

            print_divider();
            $display("TEST : %s", test_name);

            $display("Inputs:");
            $display("   Register = x%0d", reg_num);

            $display("");
            $display("Expected:");
            $display("   Value    = %08h (%0d)", expected, expected);

            $display("");
            $display("Got:");
            $display("   Value    = %08h (%0d)", got, got);

            if (got === expected) begin
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
    // Main Test
    //=============================================================
    integer cycle;

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        $display("====================================================");
        $display(" RV32 TOP (PROGRAM 1) VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // Load program into IMEM (simulation-only)
        $readmemh("program_1.hex", dut.u_imem.mem);

        // Clear DMEM (simulation-only)
        for (i = 0; i < DMEM_DEPTH_WORDS; i = i + 1)
            dut.u_dmem.mem[i] = 32'h0000_0000;

        // Reset sequence
        clk_en = 1'b1;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        // Run CPU for fixed number of cycles
        // Program has 16 instructions. We'll run 20 cycles.
        for (cycle = 0; cycle < 20; cycle = cycle + 1) begin
            @(posedge clk);
            #1;

            // Trace prints (debug friendly)
            $display("[Cycle %0d] PC = %08h | instr = %08h",
                     cycle,
                     dut.u_pc_reg.pc_current,
                     dut.u_imem.instr);
        end

        $display("");
        $display("====================================================");
        $display(" CHECKING FINAL REGISTER STATE");
        $display("====================================================");
        $display("");

        // Pause clock so PC/reg state doesn't change while checking
        clk_en = 1'b0;

        //=========================================================
        // Check x0 always zero
        //=========================================================
        check_reg("x0 must always be 0", 5'd0, 32'd0);

        //=========================================================
        // Check final expected register values
        //=========================================================
        check_reg("x1 must be 1",   5'd1,  32'd1);
        check_reg("x2 must be 2",   5'd2,  32'd2);
        check_reg("x3 must be 4",   5'd3,  32'd4);
        check_reg("x4 must be 6",   5'd4,  32'd6);
        check_reg("x5 must be 9",   5'd5,  32'd9);
        check_reg("x6 must be 12",  5'd6,  32'd12);
        check_reg("x7 must be 16",  5'd7,  32'd16);
        check_reg("x8 must be 20",  5'd8,  32'd20);
        check_reg("x9 must be 25",  5'd9,  32'd25);

        check_reg("x10 must be 30", 5'd10, 32'd30);
        check_reg("x11 must be 36", 5'd11, 32'd36);
        check_reg("x12 must be 42", 5'd12, 32'd42);
        check_reg("x13 must be 49", 5'd13, 32'd49);
        check_reg("x14 must be 56", 5'd14, 32'd56);
        check_reg("x15 must be 64", 5'd15, 32'd64);

        // Resume clock if needed for future extensions
        clk_en = 1'b1;

        //=========================================================
        // Final Summary
        //=========================================================
        $display("====================================================");
        $display(" RV32 TOP (PROGRAM 1) VERIFICATION REPORT");
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
