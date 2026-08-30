# mips-multicycle-processor
32-bit MIPS Multi-Cycle Processor with ROM-Based Control Unit implemented in Verilog
# 32-bit MIPS Multi-Cycle Processor with ROM-Based Microprogrammed Control

A Verilog HDL implementation of a **32-bit MIPS Multi-Cycle Processor** using a **ROM-based microprogrammed control unit**.

The design is based on the classical multi-cycle MIPS datapath architecture and replaces conventional hardwired control logic with a compact microprogram stored in ROM.

---

## 📌 Project Overview

This project implements a 32-bit MIPS processor in Verilog HDL using a **multi-cycle datapath**.

Unlike a single-cycle processor, where every instruction must complete within one clock cycle, the multi-cycle architecture divides instruction execution into several smaller stages. Datapath resources such as the ALU and memory can therefore be reused across different stages.

The major focus of this project is the implementation of a **ROM-based microprogrammed control unit**.

Instead of generating every control signal through a large combinational FSM, the control unit stores microinstructions in ROM. Each microinstruction contains:

- Datapath control signals
- ALU control information
- PC control information
- Memory control information
- Register-file control information
- A 2-bit sequencing field

The resulting design provides a structured and easily extensible approach to processor control.

---

## ✨ Key Features

- 32-bit MIPS datapath
- Multi-cycle processor architecture
- ROM-based microprogrammed control unit
- 16-bit datapath/control field
- 2-bit microinstruction sequencing field
- 18-bit total ROM word
- Opcode-based microinstruction dispatch
- Separate dispatch mechanisms for instruction classes
- Register file
- ALU
- Program Counter
- Instruction Register
- Memory Data Register
- ALUOut register
- Sign-extension and shift-left logic
- Support for memory, branch, jump and R-type instructions
- RTL simulation using Verilog
- FPGA-oriented RTL implementation

---
## 🧠 ROM-Based Microprogrammed Control Unit

The processor uses a **ROM-based microprogrammed control unit** to generate the control signals required to operate the multi-cycle MIPS datapath. Instead of implementing the control sequence entirely using hardwired combinational logic, the required control signals are stored as microinstructions in ROM. Each microinstruction specifies the datapath operations for a particular processor state, along with a **2-bit sequencing field** that determines how the next microinstruction is selected. The control flow uses sequential execution, return to the Fetch state, and two opcode-based dispatch mechanisms to support the different instruction classes.


 ## 🧠 Control Microprogram

The ROM-based control unit uses a microprogram consisting of **10
microinstructions**. Each microinstruction generates the required
datapath control signals and specifies the sequencing operation.

| Label | ALU Control | SRC1 | SRC2 | Register Control | Memory Control | PCWrite Control | Sequencing |
|---|---|---|---|---|---|---|---|
| **Fetch** | Add | PC | 4 | — | Read PC | ALU | Seq |
| **Decode** | Add | PC | Extshft | Read | — | — | Dispatch 1 |
| **Mem1** | Add | A | Extend | — | — | — | Dispatch 2 |
| **LW2** | — | — | — | — | Read ALU | — | Seq |
| **LW3** | — | — | — | Write MDR | — | — | Fetch |
| **SW2** | — | — | — | — | Write ALU | — | Fetch |
| **Rformat1** | Func code | A | B | — | — | — | Seq |
| **Rformat2** | — | — | — | Write ALU | — | — | Fetch |
| **BEQ1** | Sub | A | B | — | — | ALUOut-cond | Fetch |
| **JUMP1** | — | — | — | — | — | Jump address | Fetch |

## 🚦 Opcode Dispatch

### Dispatch ROM 1

| Opcode | Instruction | Target Microinstruction |
|---|---|---|
| `000000` | R-format | `Rformat1` |
| `000010` | J | `JUMP1` |
| `000100` | BEQ | `BEQ1` |
| `100011` | LW | `Mem1` |
| `101011` | SW | `Mem1` |

### Dispatch ROM 2

| Opcode | Instruction | Target Microinstruction |
|---|---|---|
| `100011` | LW | `LW2` |
| `101011` | SW | `SW2` |
## 🔄 Microinstruction Sequencing

| `Next[1:0]` | Sequencing Operation | Description |
|---|---|---|
| `00` | **SEQ** | Proceed to the next ROM microinstruction |
| `01` | **FETCH** | Return to the Fetch state |
| `10` | **DISPATCH 1** | Use opcode to select an entry from Dispatch ROM 1 |
| `11` | **DISPATCH 2** | Use opcode to select an entry from Dispatch ROM 2 |
## 🧩 Microinstruction Format

Each ROM entry is an **18-bit microinstruction**:

| Field | Width | Purpose |
|---|---:|---|
| Control Field | 16 bits | Generates datapath and control signals |
| Next Field | 2 bits | Determines microinstruction sequencing |
| **Total** | **18 bits** | Complete ROM word |

```text
18-bit ROM Word
┌────────────────────────────────┬──────────────┐
│      16-bit Control Field      │ 2-bit Next   │
│                                │    Field     │
└────────────────────────────────┴──────────────┘
### Instruction-level flow

You can then put this immediately below the tables:

```markdown
### Microinstruction ROM

| Opcode | Label | PCW | PCWC | IorD | MR | MW | IRW | MtoR | RW | RDst | A | B[1:0] | PCSrc[1:0] | ALUOp[1:0] | Next[1:0] | 18-bit ROM Word |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| — | **Fetch** | 1 | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | `01` | `00` | `00` | `00` | `100101000001000000` |
| — | **Decode** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `11` | `00` | `00` | `10` | `000000000011000010` |
| `100011 / 101011` | **Mem1** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | `10` | `00` | `00` | `11` | `000000001110000011` |
| `100011` | **LW2** | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `00` | `00` | `00` | `001100000000000000` |
| `100011` | **LW3** | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | `00` | `00` | `00` | `01` | `000000110000000001` |
| `101011` | **SW2** | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | `00` | `00` | `00` | `01` | `001010000000000001` |
| `000000` | **Rformat1** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | `00` | `00` | `10` | `00` | `000000010010000000` |
| `000000` | **Rformat2** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | `00` | `00` | `00` | `01` | `000000110000000001` |
| `000100` | **BEQ1** | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | `00` | `01` | `01` | `01` | `01000100001010101` |
| `000010` | **JUMP1** | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `10` | `00` | `01` | `100000000000100001` |
## 🔁 Instruction Microprogram Flow

```text
                 FETCH
                   │
                   ▼
                DECODE
                   │
             DISPATCH 1
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
    R-format      LW/SW     BEQ / J
        │          │          │
        ▼          ▼          ▼
    Rformat1      Mem1     BEQ1/JUMP1
        │          │
        ▼          ▼
    Rformat2    DISPATCH 2
        │          │
        │       ┌──┴──┐
        │       ▼     ▼
        │      LW2   SW2
        │       │     │
        │       ▼     │
        │      LW3    │
        │       │     │
        └───────┴─────┴──────► FETCH
