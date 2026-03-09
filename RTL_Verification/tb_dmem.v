//=====================================================================
// File        : tb_dmem.v
// Author      : Prabhat Pandey
// Created On  : 16-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Testbench   : tb_dmem
// Description :
//   Fully self-checking testbench for dmem.v
//
// DMEM Behavior Verified:
//   1) Combinational read when mem_read=1
//   2) Synchronous write on posedge clk when mem_write=1
//   3) mem_read=0 forces read_data = 0
//   4) mem_write=0 prevents memory update
//   5) Word addressing uses addr[31:2]
//   6) No out-of-range checks in RTL (addressing is truncated by width)
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
//   iverilog -o ./Verification_Results/result_tb_dmem ./src/dmem.v ./RTL_Verification/tb_dmem.v
//   vvp ./Verification_Results/result_tb_dmem
//=====================================================================

`timescale 1ns/1ps

module tb_dmem;

    //=============================================================
    // Parameters (must match DUT config)
    //=============================================================
    localparam DEPTH = 16; // keep small for test visibility
    localparam integer TEST_DELAY = 10; // ns between tests for waveform visibility

    //=============================================================
    // DUT Signals
    //=============================================================
    reg         clk;
    reg         mem_read;
    reg         mem_write;
    reg  [31:0] addr;
    reg  [31:0] write_data;
    wire [31:0] read_data;

    //=============================================================
    // Instantiate DUT
    //=============================================================
    dmem #(
        .DEPTH(DEPTH)
    ) dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .read_data  (read_data)
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
        $dumpfile("Verification_Results/vcd/tb_dmem.vcd");
        $dumpvars(0, tb_dmem);
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
    // Task: Run One Read Test
    //=============================================================
    task run_read_test;
        input [8*70:1] test_name;
        input          mem_read_in;
        input [31:0]   addr_in;
        input [31:0]   expected_read;

        reg [31:0] got_read;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Apply inputs
            mem_read   = mem_read_in;
            mem_write  = 1'b0;
            addr       = addr_in;
            write_data = 32'h0000_0000;

            #2; // settle combinational read
            got_read = read_data;

            // Print Inputs
            $display("Inputs:");
            $display("   mem_read   = %0d", mem_read_in);
            $display("   mem_write  = %0d", 1'b0);
            $display("   addr       = %08h", addr_in);
            $display("   word_index = %0d", (addr_in >> 2));

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   read_data  = %08h", expected_read);

            // Print Got
            $display("");
            $display("Got:");
            $display("   read_data  = %08h", got_read);

            // Compare
            if (got_read === expected_read) begin
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
    // Task: Run One Write + Readback Test
    //=============================================================
    task run_write_readback_test;
        input [8*70:1] test_name;
        input          mem_write_in;
        input [31:0]   addr_in;
        input [31:0]   wd_in;
        input [31:0]   expected_after;

        reg [31:0] got_read;
        begin
            total_tests = total_tests + 1;

            print_divider();
            $display("TEST : %s", test_name);

            // Step 1: Apply write signals
            mem_read   = 1'b0;
            mem_write  = mem_write_in;
            addr       = addr_in;
            write_data = wd_in;

            // Commit on posedge
            @(posedge clk);
            #1;

            // Step 2: Read back
            mem_write = 1'b0;
            mem_read  = 1'b1;
            #2;

            got_read = read_data;

            // Print Inputs
            $display("Inputs:");
            $display("   mem_write  = %0d", mem_write_in);
            $display("   mem_read   = %0d", 1'b1);
            $display("   addr       = %08h", addr_in);
            $display("   word_index = %0d", (addr_in >> 2));
            $display("   write_data = %08h", wd_in);

            // Print Expected
            $display("");
            $display("Expected:");
            $display("   read_data  = %08h", expected_after);

            // Print Got
            $display("");
            $display("Got:");
            $display("   read_data  = %08h", got_read);

            // Compare
            if (got_read === expected_after) begin
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
    // Main Test Sequence
    //=============================================================
    initial begin

        // Init counters
        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        // Init inputs
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        addr       = 32'h0000_0000;
        write_data = 32'h0000_0000;

        // Clear memory (simulation-only)
        for (i = 0; i < DEPTH; i = i + 1)
            dut.mem[i] = 32'h0000_0000;

        $display("====================================================");
        $display(" DMEM VERIFICATION STARTED — Author: Prabhat Pandey");
        $display("====================================================");
        $display("");

        //=========================================================
        // TEST 1: Read from address 0 (initial memory = 0)
        //=========================================================
        run_read_test("Initial read @ addr=0 should be 0",
                      1'b1, 32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // TEST 2: Write then read back @ addr=0
        //=========================================================
        run_write_readback_test("Write 0xDEADBEEF @ addr=0, read back",
                                1'b1, 32'h0000_0000, 32'hDEAD_BEEF,
                                32'hDEAD_BEEF);

        //=========================================================
        // TEST 3: Write then read back @ addr=4 (word index 1)
        //=========================================================
        run_write_readback_test("Write 0x12345678 @ addr=4, read back",
                                1'b1, 32'h0000_0004, 32'h1234_5678,
                                32'h1234_5678);

        //=========================================================
        // TEST 4: Verify addr=0 still has old data
        //=========================================================
        run_read_test("Read @ addr=0 must still be 0xDEADBEEF",
                      1'b1, 32'h0000_0000, 32'hDEAD_BEEF);

        //=========================================================
        // TEST 5: mem_write=0 should not update memory
        //=========================================================
        run_write_readback_test("Write disabled (mem_write=0), addr=8 must remain 0",
                                1'b0, 32'h0000_0008, 32'hAAAA_AAAA,
                                32'h0000_0000);

        //=========================================================
        // TEST 6: mem_read=0 forces read_data=0 even if memory has data
        //=========================================================
        run_read_test("mem_read=0 must force read_data=0 (even if mem contains data)",
                      1'b0, 32'h0000_0000, 32'h0000_0000);

        //=========================================================
        // Final Summary Report
        //=========================================================
        $display("====================================================");
        $display(" DMEM VERIFICATION REPORT");
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
