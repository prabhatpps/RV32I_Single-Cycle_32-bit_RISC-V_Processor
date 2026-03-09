# RV32I Single-Cycle 32-bit RISC-V Processor

**Author:** Prabhat Pandey  
**Created:** February 2026  
**Architecture:** Single-Cycle RISC-V RV32I  

---

## Overview

A complete RV32I single-cycle processor implemented in Verilog. This is a straightforward, educational implementation where all five pipeline stages (fetch, decode, execute, memory, writeback) happen in one clock cycle.

**What's Implemented:**
- Full RV32I base instruction set (37 instructions)
- 32-bit datapath with 32 general-purpose registers (x0-x31)
- Separate instruction and data memories
- Self-checking testbenches for all modules
- Single-cycle execution (CPI = 1.0)

**What This Is:**
- A working, verified RISC-V processor core
- Clean, modular RTL suitable for FPGA synthesis
- Educational reference implementation
- Foundation for pipelined or extended designs

**What This Isn't:**
- High-performance (clock limited by longest path)
- Optimized for area or power
- Feature-complete beyond base RV32I

---

## Architecture


![Architecture](./RV32I_Single-Cycle_Processor—Datapath_and_Control_Architecture.svg)


### Single-Cycle Execution

Every instruction completes in one clock cycle:

1. **Fetch:** PC → IMEM → Instruction
2. **Decode:** Instruction → Control Signals + Register Read
3. **Execute:** ALU operation / Branch evaluation
4. **Memory:** Load/Store to DMEM
5. **Writeback:** Result → Register File

---

## Instruction Set Support

### Complete RV32I Base Integer Instruction Set

#### Arithmetic & Logic (R-Type)
- **ADD**, **SUB**: Addition and subtraction
- **AND**, **OR**, **XOR**: Bitwise logical operations
- **SLL**, **SRL**, **SRA**: Shift left logical, shift right logical/arithmetic
- **SLT**, **SLTU**: Set less than (signed/unsigned)

#### Immediate Operations (I-Type)
- **ADDI**, **ANDI**, **ORI**, **XORI**: Immediate arithmetic/logic
- **SLLI**, **SRLI**, **SRAI**: Immediate shifts
- **SLTI**, **SLTIU**: Set less than immediate (signed/unsigned)

#### Memory Operations
- **LW** (Load Word): Load 32-bit value from memory
- **SW** (Store Word): Store 32-bit value to memory

#### Branch Instructions (B-Type)
- **BEQ**, **BNE**: Branch if equal/not equal
- **BLT**, **BGE**: Branch if less than/greater or equal (signed)
- **BLTU**, **BGEU**: Branch if less than/greater or equal (unsigned)

#### Jump Instructions
- **JAL** (Jump and Link): Unconditional jump, save PC+4
- **JALR** (Jump and Link Register): Indirect jump via register

#### Upper Immediate Instructions
- **LUI** (Load Upper Immediate): Load 20-bit immediate to upper bits
- **AUIPC** (Add Upper Immediate to PC): PC-relative addressing

---

## Module Descriptions

### 1. **riscv32_singlecycle_top.v**
**Top-level integration module.**

Instantiates and connects all datapath and control components. This is the processor's main entry point.

**Interface:**
- `clk` (input): System clock
- `rst_n` (input): Active-low asynchronous reset

**Functionality:**
- Connects 12 internal modules in correct datapath sequence
- Routes control signals from decoder to datapath elements
- Handles PC update, instruction fetch, decode, execute, memory, and writeback

---

### 2. **pc_reg.v**
**Program Counter register.**

Holds the current program counter value. Updates on every rising clock edge.

**Interface:**
- `clk` (input): Clock
- `rst_n` (input): Active-low reset
- `pc_next` (input, 32-bit): Next PC value
- `pc_current` (output, 32-bit): Current PC value

**Behavior:**
- On reset: PC ← 0x00000000
- On rising edge: PC ← pc_next

---

### 3. **imem.v**
**Instruction Memory (ROM).**

Stores program instructions. Initialized from HEX file using `$readmemh`.

**Interface:**
- `addr` (input, 32-bit): Byte address from PC
- `instr` (output, 32-bit): Instruction word

**Parameters:**
- `MEM_DEPTH_WORDS` (default: 1024): Number of 32-bit instruction words
- `MEM_INIT_FILE` (default: "program.hex"): HEX initialization file

**Behavior:**
- Combinational read: `instr = mem[addr[31:2]]`
- Uses word addressing (ignores lower 2 bits)

**HEX File Format:**
```
00000013    // NOP (addi x0, x0, 0)
00100093    // addi x1, x0, 1
00200113    // addi x2, x0, 2
```

---

### 4. **decoder_controller.v**
**Main instruction decoder and control unit.**

Generates all high-level control signals by decoding the instruction opcode, funct3, and funct7 fields.

**Interface:**
- **Inputs:**
  - `opcode` (7-bit): instr[6:0]
  - `funct3` (3-bit): instr[14:12]
  - `funct7` (7-bit): instr[31:25]
  
- **Outputs:**
  - `reg_write` (1-bit): Register file write enable
  - `wb_sel` (3-bit): Writeback mux select
  - `alu_src` (1-bit): ALU B operand select (0=rs2, 1=imm)
  - `alu_op` (2-bit): High-level ALU operation selector
  - `use_pc_as_alu_a` (1-bit): ALU A operand select (0=rs1, 1=PC)
  - `mem_read` (1-bit): Data memory read enable
  - `mem_write` (1-bit): Data memory write enable
  - `branch` (1-bit): Branch instruction flag
  - `jump` (1-bit): JAL instruction flag
  - `jalr` (1-bit): JALR instruction flag

**Opcode Decoding:**

| Opcode    | Instruction Type | Description                    |
|-----------|------------------|--------------------------------|
| 0110011   | R-type (OP)      | Register-register operations   |
| 0010011   | I-type (OP-IMM)  | Register-immediate operations  |
| 0000011   | LOAD             | Load word                      |
| 0100011   | STORE            | Store word                     |
| 1100011   | BRANCH           | Conditional branches           |
| 1101111   | JAL              | Jump and link                  |
| 1100111   | JALR             | Jump and link register         |
| 0110111   | LUI              | Load upper immediate           |
| 0010111   | AUIPC            | Add upper immediate to PC      |

**Writeback Select Encoding (wb_sel):**

| wb_sel | Source         | Used By           |
|--------|----------------|-------------------|
| 000    | ALU result     | R-type, I-type    |
| 001    | Memory data    | LW                |
| 010    | PC+4           | JAL, JALR         |
| 011    | U-immediate    | LUI               |
| 100    | PC+imm_u       | AUIPC             |

**ALUOp Encoding:**

| alu_op | Meaning                      | Usage                           |
|--------|------------------------------|---------------------------------|
| 00     | Default ADD                  | LW/SW, address calculation      |
| 01     | Branch (SUB for comparison)  | Branch instructions             |
| 10     | R-type decode                | Uses funct3/funct7 for exact op |
| 11     | I-type decode                | Uses funct3/funct7[5] for op    |

---

### 5. **regfile.v**
**32x32 Register File.**

Implements the 32 general-purpose registers (x0-x31) required by RV32I.

**Interface:**
- `clk` (input): Clock
- `rst_n` (input): Active-low reset
- `we` (input): Write enable
- `rs1` (input, 5-bit): Source register 1 address
- `rs2` (input, 5-bit): Source register 2 address
- `rd` (input, 5-bit): Destination register address
- `wd` (input, 32-bit): Write data
- `rd1` (output, 32-bit): Read data from rs1
- `rd2` (output, 32-bit): Read data from rs2

**Behavior:**
- **Reset**: All registers cleared to 0x00000000
- **Read**: Combinational (asynchronous)
- **Write**: Synchronous on rising clock edge
- **x0 Hardwiring**: Register x0 is always 0 (writes to x0 are ignored)

**Critical Design Note:**
- Two independent read ports allow simultaneous access to rs1 and rs2
- Write occurs on clock edge with `we` asserted
- x0 is architecturally hardwired to zero (RISC-V specification)

---

### 6. **imm_gen.v**
**Immediate Generator.**

Extracts and sign-extends immediate values from the 32-bit instruction word for all five RISC-V immediate formats.

**Interface:**
- `instr` (input, 32-bit): Full instruction word
- **Outputs (all 32-bit, sign-extended):**
  - `imm_i`: I-type immediate
  - `imm_s`: S-type immediate
  - `imm_b`: B-type immediate (branch offset)
  - `imm_u`: U-type immediate (upper 20 bits)
  - `imm_j`: J-type immediate (jump offset)

**Immediate Formats:**

#### I-Type (12-bit signed)
```
imm[11:0] = instr[31:20]
```
Used by: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, LW, JALR, SLLI, SRLI, SRAI

#### S-Type (12-bit signed)
```
imm[11:5] = instr[31:25]
imm[4:0]  = instr[11:7]
```
Used by: SW

#### B-Type (13-bit signed, already shifted left by 1)
```
imm[12]   = instr[31]
imm[11]   = instr[7]
imm[10:5] = instr[30:25]
imm[4:1]  = instr[11:8]
imm[0]    = 0  (always zero per RISC-V spec)
```
Used by: BEQ, BNE, BLT, BGE, BLTU, BGEU

#### U-Type (20-bit upper immediate)
```
imm[31:12] = instr[31:12]
imm[11:0]  = 0
```
Used by: LUI, AUIPC

#### J-Type (21-bit signed, already shifted left by 1)
```
imm[20]    = instr[31]
imm[19:12] = instr[19:12]
imm[11]    = instr[20]
imm[10:1]  = instr[30:21]
imm[0]     = 0  (always zero per RISC-V spec)
```
Used by: JAL

**Critical Implementation Details:**
- B-type and J-type immediates are **already left-shifted by 1** (bit 0 forced to 0)
- This matches RISC-V specification that branch/jump targets are always 2-byte aligned
- Sign extension is performed for all signed immediate types

---

### 7. **alu_control.v**
**ALU Control Decoder.**

Generates the precise 4-bit ALU control signal from high-level ALUOp and instruction funct fields.

**Interface:**
- `alu_op` (input, 2-bit): High-level operation from main decoder
- `funct3` (input, 3-bit): Instruction funct3 field
- `funct7` (input, 7-bit): Instruction funct7 field
- `alu_ctrl` (output, 4-bit): Exact ALU operation selector

**ALU Control Encoding:**

| alu_ctrl | Operation | Description                |
|----------|-----------|----------------------------|
| 0000     | ADD       | Addition                   |
| 0001     | SUB       | Subtraction                |
| 0010     | AND       | Bitwise AND                |
| 0011     | OR        | Bitwise OR                 |
| 0100     | XOR       | Bitwise XOR                |
| 0101     | SLT       | Set less than (signed)     |
| 0110     | SLTU      | Set less than (unsigned)   |
| 0111     | SLL       | Shift left logical         |
| 1000     | SRL       | Shift right logical        |
| 1001     | SRA       | Shift right arithmetic     |

**Decoding Logic:**

For **R-type** (alu_op = 10):
- funct3 + funct7[5] determines operation
- Example: funct3=000, funct7[5]=0 → ADD
- Example: funct3=000, funct7[5]=1 → SUB

For **I-type** (alu_op = 11):
- funct3 determines operation (similar to R-type)
- funct7[5] distinguishes SRLI (0) from SRAI (1)

---

### 8. **alu.v**
**Arithmetic Logic Unit.**

Executes all arithmetic and logical operations for the processor.

**Interface:**
- **Inputs:**
  - `A` (32-bit): Operand A
  - `B` (32-bit): Operand B
  - `ALUControl` (4-bit): Operation selector

- **Outputs:**
  - `Result` (32-bit): Operation result
  - `Carry` (1-bit): Carry-out (valid for ADD/SUB)
  - `OverFlow` (1-bit): Signed overflow flag
  - `Zero` (1-bit): Result is zero
  - `Negative` (1-bit): Result[31] (sign bit)

**Supported Operations:**
- **ADD/SUB**: 33-bit extended arithmetic for proper carry/overflow detection
- **AND/OR/XOR**: Bitwise logical operations
- **SLT/SLTU**: Signed/unsigned comparison (returns 1 if A < B, else 0)
- **SLL/SRL/SRA**: Shift operations using B[4:0] as shift amount

**Flag Generation:**

1. **Carry Flag:**
   - For ADD: Carry = sum[32]
   - For SUB: Carry = 1 means "no borrow", Carry = 0 means "borrow occurred"

2. **Overflow Flag (Signed):**
   - ADD: Overflow if A and B have same sign, but Result has different sign
   - SUB: Overflow if A and B have different signs, and Result sign differs from A
   - Formula: `OverFlow = (~(A[31] ^ B[31])) & (A[31] ^ Result[31])` for ADD
   - Formula: `OverFlow = (A[31] ^ B[31]) & (A[31] ^ Result[31])` for SUB

3. **Zero Flag:**
   - Zero = 1 if Result == 32'h00000000

4. **Negative Flag:**
   - Negative = Result[31] (MSB of result)

**Critical Implementation Details:**
- Uses 33-bit extended arithmetic: `sum_ext = {1'b0, A} + {1'b0, B}`
- Subtraction implemented as: `A + (~B + 1)` (two's complement)
- Shift operations use only lower 5 bits of B (RV32I specification)
- SRA uses Verilog arithmetic shift operator `>>>` for sign extension

---

### 9. **branch_unit.v**
**Branch Condition Evaluator.**

Determines whether a conditional branch should be taken by comparing rs1 and rs2 values.

**Interface:**
- `funct3` (input, 3-bit): Branch type selector
- `rs1_val` (input, 32-bit): Value from rs1
- `rs2_val` (input, 32-bit): Value from rs2
- `take_branch` (output, 1-bit): Branch decision (1=take, 0=don't take)

**Branch Types (funct3 encoding):**

| funct3 | Instruction | Condition                     | take_branch           |
|--------|-------------|-------------------------------|-----------------------|
| 000    | BEQ         | Branch if rs1 == rs2          | rs1_val == rs2_val    |
| 001    | BNE         | Branch if rs1 != rs2          | rs1_val != rs2_val    |
| 100    | BLT         | Branch if rs1 < rs2 (signed)  | $signed(rs1) < $signed(rs2) |
| 101    | BGE         | Branch if rs1 >= rs2 (signed) | $signed(rs1) >= $signed(rs2) |
| 110    | BLTU        | Branch if rs1 < rs2 (unsigned)| rs1_val < rs2_val     |
| 111    | BGEU        | Branch if rs1 >= rs2 (unsigned)| rs1_val >= rs2_val   |

**Design Philosophy:**
- **Purely combinational** logic
- Performs direct comparison (does not rely on ALU)
- PC target calculation handled separately in pc_next_logic

---

### 10. **dmem.v**
**Data Memory.**

Implements read/write memory for load/store instructions.

**Interface:**
- `clk` (input): Clock
- `mem_read` (input): Read enable
- `mem_write` (input): Write enable
- `addr` (input, 32-bit): Byte address (from ALU result)
- `write_data` (input, 32-bit): Data to store
- `read_data` (output, 32-bit): Data loaded

**Parameters:**
- `DEPTH` (default: 256): Number of 32-bit words
- `MEM_INIT_FILE` (default: ""): Optional HEX file for initialization

**Behavior:**
- **Read**: Combinational (synchronous latching for timing)
  - If mem_read=1: read_data = mem[addr[31:2]]
  - If mem_read=0: read_data = 0
  
- **Write**: Synchronous on rising clock edge
  - If mem_write=1: mem[addr[31:2]] ← write_data

**Address Translation:**
- Uses word addressing internally: `word_addr = addr[31:2]`
- Ignores addr[1:0] (assumes word-aligned accesses)

---

### 11. **pc_next_logic.v**
**PC Next Value Selector.**

Determines the next program counter value based on instruction type and branch conditions.

**Interface:**
- **Inputs:**
  - `pc_current` (32-bit): Current PC
  - `rs1_val` (32-bit): Register rs1 value (for JALR)
  - `imm_i`, `imm_b`, `imm_j` (32-bit each): Immediate values
  - `branch`, `take_branch`, `jump`, `jalr` (1-bit each): Control signals

- **Outputs:**
  - `pc_next` (32-bit): Next PC value
  - `pc_plus4` (32-bit): PC + 4 (for writeback)

**PC Update Priority (highest to lowest):**

1. **JALR** (jalr=1):
   ```
   pc_next = (rs1_val + imm_i) & 32'hFFFF_FFFE
   ```
   Note: Bit 0 is forced to 0 per RISC-V specification

2. **JAL** (jump=1):
   ```
   pc_next = pc_current + imm_j
   ```

3. **Branch Taken** (branch=1 && take_branch=1):
   ```
   pc_next = pc_current + imm_b
   ```

4. **Default** (sequential execution):
   ```
   pc_next = pc_current + 4
   ```

---

### 12. **wb_mux.v**
**Writeback Multiplexer.**

Selects the correct data to write back to the register file.

**Interface:**
- **Inputs:**
  - `wb_sel` (3-bit): Writeback source selector
  - `alu_result` (32-bit): Result from ALU
  - `mem_data` (32-bit): Data from memory
  - `pc_plus4` (32-bit): PC + 4
  - `u_imm` (32-bit): U-type immediate
  - `pc_plus_imm` (32-bit): PC + U-immediate (for AUIPC)

- **Output:**
  - `wb_data` (32-bit): Selected writeback data

**Writeback Source Selection:**

| wb_sel | Source         | Instruction(s)  |
|--------|----------------|-----------------|
| 000    | alu_result     | R-type, I-type  |
| 001    | mem_data       | LW              |
| 010    | pc_plus4       | JAL, JALR       |
| 011    | u_imm          | LUI             |
| 100    | pc_plus_imm    | AUIPC           |

---

## Control Signals

### ALUOp Encoding
```
00: ADD (for load/store/JALR/AUIPC)
01: SUB (for branches)
10: R-type (decode using funct3/funct7)
11: I-type (decode using funct3/funct7)
```

### ALU Control (alu_ctrl)
```
0000: ADD
0001: SUB
0010: AND
0011: OR
0100: XOR
0101: SLT  (signed)
0110: SLTU (unsigned)
0111: SLL
1000: SRL
1001: SRA
```

### Writeback Select (wb_sel)
```
000: ALU result     (R-type, I-type)
001: Memory data    (LW)
010: PC+4           (JAL, JALR)
011: U-immediate    (LUI)
100: PC+imm_u       (AUIPC)
```

---

## Verification

### Module-Level Testbenches

Each module has a dedicated self-checking testbench with:
- Automated input generation
- Expected vs. actual output comparison
- Pass/fail reporting per test
- Final summary statistics

**Test Coverage:**

| Module          | Testbench                  | Test Cases | Status |
|-----------------|----------------------------|------------|--------|
| ALU             | tb_alu.v                   | 24         | ✓      |
| ALU Control     | tb_alu_control.v           | 23         | ✓      |
| Branch Unit     | tb_branch_unit.v           | 21         | ✓      |
| Decoder         | tb_decoder_controller.v    | 11         | ✓      |
| Data Memory     | tb_dmem.v                  | Manual     | ✓      |
| Instruction Mem | tb_imem.v                  | 9          | ✓      |
| Immediate Gen   | tb_imm_gen.v               | 16         | ✓      |
| PC Next Logic   | tb_pc_next_logic.v         | 9          | ✓      |
| PC Register     | tb_pc_reg.v                | 8          | ✓      |
| Register File   | tb_regfile.v               | Manual     | ✓      |
| Writeback Mux   | tb_wb_mux.v                | 7          | ✓      |
| Top-Level       | tb_riscv32_singlecycle_top.v | 16 regs  | ✓      |

**Total: ~130+ individual test cases across all modules**

### Top-Level Verification

The top-level testbench runs a simple ADDI program:
```assembly
nop
addi x1,  x0, 1
addi x2,  x0, 2
addi x3,  x1, 3
addi x4,  x2, 4
addi x5,  x3, 5
addi x6,  x4, 6
addi x7,  x5, 7
addi x8,  x6, 8
addi x9,  x7, 9
addi x10, x8, 10
addi x11, x9, 11
addi x12, x10, 12
addi x13, x11, 13
addi x14, x12, 14
addi x15, x13, 15
```

Verifies final register values:
```
x1=1, x2=2, x3=4, x4=6, x5=9, x6=12, x7=16, x8=20,
x9=25, x10=30, x11=36, x12=42, x13=49, x14=56, x15=64
```

---

## Directory Structure

```
RV32I_Single-Cycle_32-bit_RISC-V_Processor/
│
├── LICENSE                            # License file
├── README.md                          # This file
├── program.hex                        # Sample program
│
├── src/                               # RTL source files
│   ├── riscv32_singlecycle_top.v      # Top-level processor
│   ├── pc_reg.v                       # Program counter
│   ├── imem.v                         # Instruction memory
│   ├── decoder_controller.v           # Main decoder
│   ├── regfile.v                      # Register file
│   ├── imm_gen.v                      # Immediate generator
│   ├── alu_control.v                  # ALU control
│   ├── alu.v                          # ALU
│   ├── branch_unit.v                  # Branch evaluator
│   ├── dmem.v                         # Data memory
│   ├── pc_next_logic.v                # PC next logic
│   └── wb_mux.v                       # Writeback mux
│
├── RTL_Verification/                  # Testbenches
│   ├── tb_riscv32_singlecycle_top.v
│   ├── tb_alu.v
│   ├── tb_alu_control.v
│   ├── tb_branch_unit.v
│   ├── tb_decoder_controller.v
│   ├── tb_dmem.v
│   ├── tb_imem.v
│   ├── tb_imm_gen.v
│   ├── tb_pc_next_logic.v
│   ├── tb_pc_reg.v
│   ├── tb_regfile.v
│   └── tb_wb_mux.v
│
├── Verification_Results/              # Compiled simulation binaries
│   ├── result_tb_top
│   ├── result_tb_alu
│   ├── result_tb_alu_control
│   └── ... (one for each testbench)
│
└── riscv-unprivileged.pdf
```

---

## Simulation

### Prerequisites

```bash
# Install Icarus Verilog (Ubuntu/Debian)
sudo apt-get install iverilog gtkwave
```

### Running Individual Module Tests

**Example: Test ALU**
```bash
iverilog -o ./Verification_Results/result_tb_alu \
    ./src/alu.v \
    ./RTL_Verification/tb_alu.v

vvp ./Verification_Results/result_tb_alu
```

**Example: Test Top-Level Processor**
```bash
iverilog -o ./Verification_Results/result_tb_top \
    ./src/*.v \
    ./RTL_Verification/tb_riscv32_singlecycle_top.v

vvp ./Verification_Results/result_tb_top
```

### Expected Output Format

```
====================================================
 ALU VERIFICATION STARTED — Author: Prabhat Pandey
====================================================

----------------------------------------------------------------
TEST : ADD basic
Inputs:
   A          = 0x00000005
   B          = 0x00000007
   ALUControl = 0000
Expected:
   Result     = 0x0000000C
   Carry      = 0
   OverFlow   = 0
   Zero       = 0
   Negative   = 0
Got:
   Result     = 0x0000000C
   Carry      = 0
   OverFlow   = 0
   Zero       = 0
   Negative   = 0
STATUS: PASS
----------------------------------------------------------------

... (more tests) ...

====================================================
 ALU VERIFICATION REPORT
====================================================
   Total Tests   : 24
   Passed        : 24
   Failed        : 0
====================================================
STATUS: ALL TESTS PASSED
====================================================
```

---

## Creating Custom Programs

### Step 1: Write RISC-V Assembly

```assembly
# test.s
.text
.globl _start

_start:
    addi x1, x0, 5      # x1 = 5
    addi x2, x0, 10     # x2 = 10
    add  x3, x1, x2     # x3 = 15
    sw   x3, 0(x0)      # Store to address 0
    lw   x4, 0(x0)      # Load from address 0
```

### Step 2: Assemble to HEX

```bash
# Using RISC-V GNU toolchain
riscv32-unknown-elf-as -o test.o test.s
riscv32-unknown-elf-objcopy -O binary test.o test.bin
od -An -tx4 -w4 -v test.bin > program.hex
```

### Step 3: Update Testbench

Point IMEM parameter to your new `program.hex` file and run simulation.

---

## Limitations

### Not Implemented

**RV32I Instructions:**
- Byte/halfword loads/stores (LB, LBU, LH, LHU, SB, SH)
- FENCE (memory ordering)
- ECALL, EBREAK (system calls)
- CSR instructions

**Extensions:**
- M extension (multiply/divide)
- A extension (atomics)
- F/D extensions (floating-point)
- C extension (compressed)
- Privileged architecture

### Architecture Limitations

- Fixed memory sizes (1KB IMEM, 256B DMEM by default)
- No memory protection
- No cache hierarchy
- Word-aligned accesses only
- Single-cycle inefficiency (wastes time on short instructions)

---

## Future Work

### Short-Term
- Add remaining RV32I instructions (LB, LH, SB, SH)
- Implement FENCE, ECALL, EBREAK
- Add misaligned access detection
- Parameterize memory sizes

### Medium-Term
- Convert to 5-stage pipeline
- Add hazard detection and forwarding
- Implement RV32M (multiply/divide)
- Add interrupt support

### Long-Term
- Privileged architecture (M/S/U modes)
- Virtual memory with page tables
- Cache hierarchy
- Multi-core support

---

## References

### RISC-V Documentation
- RISC-V Instruction Set Manual (Unprivileged): Included in repo
- RISC-V Official Website: https://riscv.org/

### Textbooks
- "Computer Organization and Design RISC-V Edition" - Patterson & Hennessy
- "Digital Design and Computer Architecture, RISC-V Edition" - Harris & Harris

### Tools
- Icarus Verilog: http://iverilog.icarus.com/
- GTKWave: http://gtkwave.sourceforge.net/
- RISC-V GNU Toolchain: https://github.com/riscv/riscv-gnu-toolchain

---

## License

MIT License - See file header comments for details.

---

## Contact

**Author:** Prabhat Pandey  
**Date:** 16 February 2026  
