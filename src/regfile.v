//=====================================================================
// File        : regfile.v
// Author      : Prabhat Pandey
// Created On  : 13-Feb-2026
// Project     : RV32I Single-Cycle 32-bit RISC-V Processor
// Module Name : regfile
// Description :
//   This module implements a 32x32 Register File for RV32I.
//
// Features:
//   - 32 registers (x0 to x31), each 32-bit wide
//   - 2 read ports (combinational)
//   - 1 write port (synchronous on posedge clk)
//   - Active-low reset (rst_n)
//   - x0 is hardwired to 0 (writes to x0 are ignored)
//
// Inputs:
//   - clk   : clock
//   - rst_n : active-low reset
//   - we    : write enable
//   - rs1   : source register 1 index
//   - rs2   : source register 2 index
//   - rd    : destination register index
//   - wd    : write data
//
// Outputs:
//   - rd1   : data from rs1
//   - rd2   : data from rs2
//
// Notes:
//   - Reads are asynchronous (combinational).
//   - Writes happen only on rising edge of clk.
//   - On reset, all registers become 0.
//
// Revision History:
//   - 16-Feb-2026 : Added rst_n support + reset clearing.
//   - 13-Feb-2026 : Initial version
//=====================================================================

module regfile (
    input  wire        clk,      // Clock input (positive-edge triggered)
    input  wire        rst_n,    // Active-low reset
    input  wire        we,       // Write enable
    input  wire [4:0]  rs1,      // Source register 1 index
    input  wire [4:0]  rs2,      // Source register 2 index
    input  wire [4:0]  rd,       // Destination register index
    input  wire [31:0] wd,       // Write data
    output wire [31:0] rd1,      // Read data from rs1
    output wire [31:0] rd2       // Read data from rs2
);

`ifdef USE_SRAM_MACROS
`ifdef SYNTHESIS
    //=============================================================
    // SRAM Macro Mapping (Synthesis/OpenLane path)
    //=============================================================
    // A true 2R1W regfile is mapped using two identical 1RW1R macros:
    //   - Macro A read port1 -> rd1
    //   - Macro B read port1 -> rd2
    //   - Write port0 mirrored into both macros
    //
    // Logical register index [4:0] is stored in lower 32 entries:
    //   macro_addr = {3'b000, reg_index}
    //=============================================================
`ifdef USE_POWER_PINS
    supply1 macro_vccd1;
    supply0 macro_vssd1;
`endif
    wire        wr_en;
    wire [7:0]  wr_addr;
    wire [7:0]  rs1_addr;
    wire [7:0]  rs2_addr;
    wire [31:0] rd1_sram;
    wire [31:0] rd2_sram;

    assign wr_en   = we && rst_n && (rd != 5'd0);
    assign wr_addr = {3'b000, rd};
    assign rs1_addr = {3'b000, rs1};
    assign rs2_addr = {3'b000, rs2};

    sky130_sram_1kbyte_1rw1r_32x256_8 u_sram_rs1 (
`ifdef USE_POWER_PINS
        .vccd1  (macro_vccd1),
        .vssd1  (macro_vssd1),
`endif
        .clk0   (clk),
        .csb0   (~wr_en),
        .web0   (~wr_en),
        .wmask0 (4'b1111),
        .addr0  (wr_addr),
        .din0   (wd),
        .dout0  (),
        .clk1   (clk),
        .csb1   (1'b0),
        .addr1  (rs1_addr),
        .dout1  (rd1_sram)
    );

    sky130_sram_1kbyte_1rw1r_32x256_8 u_sram_rs2 (
`ifdef USE_POWER_PINS
        .vccd1  (macro_vccd1),
        .vssd1  (macro_vssd1),
`endif
        .clk0   (clk),
        .csb0   (~wr_en),
        .web0   (~wr_en),
        .wmask0 (4'b1111),
        .addr0  (wr_addr),
        .din0   (wd),
        .dout0  (),
        .clk1   (clk),
        .csb1   (1'b0),
        .addr1  (rs2_addr),
        .dout1  (rd2_sram)
    );

    assign rd1 = (rs1 == 5'd0) ? 32'h0000_0000 : rd1_sram;
    assign rd2 = (rs2 == 5'd0) ? 32'h0000_0000 : rd2_sram;
`else
    //=============================================================
    // Behavioral Register File (Simulation/RTL verification path)
    //=============================================================
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0000_0000;
        end
        else begin
            if (we && (rd != 5'd0))
                regs[rd] <= wd;
            regs[0] <= 32'h0000_0000;
        end
    end

    assign rd1 = (rs1 == 5'd0) ? 32'h0000_0000 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'h0000_0000 : regs[rs2];
`endif
`else
    //=============================================================
    // Behavioral Register File (Simulation/RTL verification path)
    //=============================================================
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0000_0000;
        end
        else begin
            if (we && (rd != 5'd0))
                regs[rd] <= wd;
            regs[0] <= 32'h0000_0000;
        end
    end

    assign rd1 = (rs1 == 5'd0) ? 32'h0000_0000 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'h0000_0000 : regs[rs2];
`endif

endmodule
