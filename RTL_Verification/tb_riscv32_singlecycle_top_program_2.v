//=====================================================================
// File        : tb_riscv32_singlecycle_top_program_2.v
// Author      : Prabhat Pandey
// Created On  : 25-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_riscv32_singlecycle_top_program_2
// Description :
//   Fully self-checking top-level testbench for riscv32_singlecycle_top
//   using program_2.hex. Verifies full program flow including
//   branch/jump behavior and the loop sequence.
//
// Program Used (program_2.hex):
//   00000013
//   00a00093
//   01400113
//   002081b3
//   40208233
//   0ff3f293
//   0f016313
//   0552c393
//   00209413
//   0011d493
//   00f0a513
//   019135b3
//   00302023
//   00002603
//   00c18463
//   06300693
//   008007ef
//   12345737
//   00000817
//   00100893
//   fe0006e3
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
//   iverilog -o ./Verification_Results/result_tb_top_program_2 \
//       ./src/*.v ./RTL_Verification/tb_riscv32_singlecycle_top_program_2.v
//
//   vvp ./Verification_Results/result_tb_top_program_2
//=====================================================================

`timescale 1ns/1ps

module tb_riscv32_singlecycle_top_program_2;

    //=============================================================
    // Parameters
    //=============================================================
    localparam IMEM_DEPTH_WORDS = 4096;
    localparam DMEM_DEPTH_WORDS = 256;
    // NOTE: Keep this below the 10ns clock period to avoid skipping fetch cycles.
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
        $dumpfile("Verification_Results/vcd/tb_riscv32_singlecycle_top_program_2.vcd");
        $dumpvars(0, tb_riscv32_singlecycle_top_program_2);
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
    // Task: Check Fetch (PC + Instruction)
    //=============================================================
    task check_fetch;
        input [8*60:1] test_name;
        input [31:0]   expected_pc;
        input [31:0]   expected_instr;

        reg [31:0] got_pc;
        reg [31:0] got_instr;
        begin
            total_tests = total_tests + 1;

            got_pc    = dut.u_pc_reg.pc_current;
            got_instr = dut.u_imem.instr;

            print_divider();
            $display("TEST : %s", test_name);

            $display("Inputs:");
            $display("   PC          = %08h", got_pc);

            $display("");
            $display("Expected:");
            $display("   PC          = %08h", expected_pc);
            $display("   instr       = %08h", expected_instr);

            $display("");
            $display("Got:");
            $display("   PC          = %08h", got_pc);
            $display("   instr       = %08h", got_instr);

            if ((got_pc === expected_pc) && (got_instr === expected_instr)) begin
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
    reg [31:0] expected_instr [0:18];
    reg [31:0] expected_pc    [0:18];
    reg [8*80:1] step_name    [0:18];

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Load program into IMEM (simulation-only)
        $readmemh("program_2.hex", dut.u_imem.mem);

        // Clear DMEM (simulation-only)
        for (i = 0; i < DMEM_DEPTH_WORDS; i = i + 1)
            dut.u_dmem.mem[i] = 32'h0000_0000;

        // Expected instruction sequence for the first full pass
        // (includes branches/jumps)
        expected_pc[0]     = 32'h0000_0000;
        expected_instr[0]  = 32'h0000_0013; // addi x0, x0, 0
        step_name[0]       = "Fetch: NOP (ADDI x0, x0, 0) @ PC=0x00000000";

        expected_pc[1]     = 32'h0000_0004;
        expected_instr[1]  = 32'h00a0_0093; // addi x1, x0, 10
        step_name[1]       = "Fetch: ADDI x1, x0, 10 @ PC=0x00000004";

        expected_pc[2]     = 32'h0000_0008;
        expected_instr[2]  = 32'h0140_0113; // addi x2, x0, 20
        step_name[2]       = "Fetch: ADDI x2, x0, 20 @ PC=0x00000008";

        expected_pc[3]     = 32'h0000_000C;
        expected_instr[3]  = 32'h0020_81b3; // add x3, x1, x2
        step_name[3]       = "Fetch: ADD x3, x1, x2 @ PC=0x0000000C";

        expected_pc[4]     = 32'h0000_0010;
        expected_instr[4]  = 32'h4020_8233; // sub x4, x1, x2
        step_name[4]       = "Fetch: SUB x4, x1, x2 @ PC=0x00000010";

        expected_pc[5]     = 32'h0000_0014;
        expected_instr[5]  = 32'h0ff3_f293; // andi x5, x7, 255
        step_name[5]       = "Fetch: ANDI x5, x7, 255 @ PC=0x00000014";

        expected_pc[6]     = 32'h0000_0018;
        expected_instr[6]  = 32'h0f01_6313; // ori x6, x2, 240
        step_name[6]       = "Fetch: ORI x6, x2, 240 @ PC=0x00000018";

        expected_pc[7]     = 32'h0000_001C;
        expected_instr[7]  = 32'h0552_c393; // xori x7, x5, 85
        step_name[7]       = "Fetch: XORI x7, x5, 85 @ PC=0x0000001C";

        expected_pc[8]     = 32'h0000_0020;
        expected_instr[8]  = 32'h0020_9413; // slli x8, x1, 2
        step_name[8]       = "Fetch: SLLI x8, x1, 2 @ PC=0x00000020";

        expected_pc[9]     = 32'h0000_0024;
        expected_instr[9]  = 32'h0011_d493; // srli x9, x3, 1
        step_name[9]       = "Fetch: SRLI x9, x3, 1 @ PC=0x00000024";

        expected_pc[10]    = 32'h0000_0028;
        expected_instr[10] = 32'h00f0_a513; // slti x10, x1, 15
        step_name[10]      = "Fetch: SLTI x10, x1, 15 @ PC=0x00000028";

        expected_pc[11]    = 32'h0000_002C;
        expected_instr[11] = 32'h0191_35b3; // sltu x11, x2, x25
        step_name[11]      = "Fetch: SLTU x11, x2, x25 @ PC=0x0000002C";

        expected_pc[12]    = 32'h0000_0030;
        expected_instr[12] = 32'h0030_2023; // sw x3, 0(x0)
        step_name[12]      = "Fetch: SW x3, 0(x0) @ PC=0x00000030";

        expected_pc[13]    = 32'h0000_0034;
        expected_instr[13] = 32'h0000_2603; // lw x12, 0(x0)
        step_name[13]      = "Fetch: LW x12, 0(x0) @ PC=0x00000034";

        expected_pc[14]    = 32'h0000_0038;
        expected_instr[14] = 32'h00c1_8463; // beq x3, x12, 8
        step_name[14]      = "Fetch: BEQ x3, x12, +8 @ PC=0x00000038";

        expected_pc[15]    = 32'h0000_0040;
        expected_instr[15] = 32'h0080_07ef; // jal x15, 8
        step_name[15]      = "Fetch: JAL x15, +8 (skip 0x44) @ PC=0x00000040";

        expected_pc[16]    = 32'h0000_0048;
        expected_instr[16] = 32'h0000_0817; // auipc x16, 0x0
        step_name[16]      = "Fetch: AUIPC x16, 0x0 @ PC=0x00000048";

        expected_pc[17]    = 32'h0000_004C;
        expected_instr[17] = 32'h0010_0893; // addi x17, x0, 1
        step_name[17]      = "Fetch: ADDI x17, x0, 1 @ PC=0x0000004C";

        expected_pc[18]    = 32'h0000_0050;
        expected_instr[18] = 32'hfe00_06e3; // beq x0, x0, -20
        step_name[18]      = "Fetch: BEQ x0, x0, -20 (loop) @ PC=0x00000050";

        $display("====================================================");
        $display(" RV32 TOP (PROGRAM 2) VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        // Reset sequence
        clk_en = 1'b1;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        // Check fetch at reset PC (before first posedge)
        #1;
        check_fetch(step_name[0], expected_pc[0], expected_instr[0]);

        // Check full first pass (includes branch + jump effects)
        for (cycle = 1; cycle <= 18; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            check_fetch(step_name[cycle], expected_pc[cycle], expected_instr[cycle]);
        end

        // Verify state after first pass (before loop executes 0x3C)
        // Pause clock so the PC doesn't advance while we check registers
        clk_en = 1'b0;
        check_reg("Post-pass: x1 = 10",  5'd1,  32'd10);
        check_reg("Post-pass: x2 = 20",  5'd2,  32'd20);
        check_reg("Post-pass: x3 = 30",  5'd3,  32'd30);
        check_reg("Post-pass: x4 = -10", 5'd4,  32'hFFFF_FFF6);
        check_reg("Post-pass: x5 = 0",   5'd5,  32'd0);
        check_reg("Post-pass: x6 = 244", 5'd6,  32'd244);
        check_reg("Post-pass: x7 = 85",  5'd7,  32'd85);
        check_reg("Post-pass: x8 = 40",  5'd8,  32'd40);
        check_reg("Post-pass: x9 = 15",  5'd9,  32'd15);
        check_reg("Post-pass: x10 = 1",  5'd10, 32'd1);
        check_reg("Post-pass: x11 = 0",  5'd11, 32'd0);
        check_reg("Post-pass: x12 = 30", 5'd12, 32'd30);
        check_reg("Post-pass: x13 = 0 (skipped at 0x3C)", 5'd13, 32'd0);
        check_reg("Post-pass: x14 = 0 (skipped at 0x44)", 5'd14, 32'd0);
        check_reg("Post-pass: x15 = 0x44 (JAL link)", 5'd15, 32'h0000_0044);
        check_reg("Post-pass: x16 = 0x48 (AUIPC)", 5'd16, 32'h0000_0048);
        check_reg("Post-pass: x17 = 1",  5'd17, 32'd1);

        // Verify DMEM write + readback (mem[0] = x3)
        check_reg("Post-pass: mem[0] = 30 (via LW x12)", 5'd12, 32'd30);

        // Resume clock for loop execution
        clk_en = 1'b1;

        // Enter loop: BEQ x0, x0, -20 takes us to 0x3C
        @(posedge clk);
        #1;
        check_fetch("Loop entry: ADDI x13, x0, 99 @ PC=0x0000003C", 32'h0000_003C, 32'h0630_0693);

        // After executing 0x3C, x13 must become 99
        @(posedge clk);
        #1;
        check_fetch("Loop: JAL x15, +8 @ PC=0x00000040", 32'h0000_0040, 32'h0080_07ef);
        check_reg("Loop state: x13 = 99", 5'd13, 32'd99);

        // Continue one loop cycle
        @(posedge clk);
        #1;
        check_fetch("Loop: AUIPC x16, 0x0 @ PC=0x00000048", 32'h0000_0048, 32'h0000_0817);

        @(posedge clk);
        #1;
        check_fetch("Loop: ADDI x17, x0, 1 @ PC=0x0000004C", 32'h0000_004C, 32'h0010_0893);

        @(posedge clk);
        #1;
        check_fetch("Loop: BEQ x0, x0, -20 @ PC=0x00000050", 32'h0000_0050, 32'hfe00_06e3);

        // Verify loop back to 0x3C
        @(posedge clk);
        #1;
        check_fetch("Loop repeat: PC returns to 0x0000003C", 32'h0000_003C, 32'h0630_0693);

        // Run a few extra cycles for waveform visibility
        for (cycle = 0; cycle < 5; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            $display("[Cycle +%0d] PC = %08h | instr = %08h",
                     cycle,
                     dut.u_pc_reg.pc_current,
                     dut.u_imem.instr);
        end

        $display("");
        $display("====================================================");
        $display(" CHECKING PROGRAM 2 STATE (POST-PASS + LOOP)");
        $display("====================================================");
        $display("");

        //=========================================================
        // Check x0 always zero
        //=========================================================
        check_reg("x0 must always be 0", 5'd0, 32'd0);

        //=========================================================
        // Final Summary
        //=========================================================
        $display("====================================================");
        $display(" RV32 TOP (PROGRAM 2) VERIFICATION REPORT");
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
