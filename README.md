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

# 🏗️ Processor Architecture

The processor follows the fundamental organization of the multi-cycle MIPS datapath.

### Major datapath components

```text
                    ┌──────────────────────┐
                    │ ROM-Based Control    │
                    │    Microprogram      │
                    └──────────┬───────────┘
                               │
                         Control Signals
                               │
                               ▼
┌──────┐       ┌─────────┐   ┌─────┐   ┌──────────┐
│  PC  │──────►│ Memory  │──►│ IR  │──►│ Register │
└──┬───┘       └─────────┘   └─────┘   │   File   │
   │                                    └────┬─────┘
   │                                         │
   │                                    ┌────▼────┐
   │                                    │ A / B   │
   │                                    │Registers│
   │                                    └────┬────┘
   │                                         │
   │                                         ▼
   │                                    ┌─────────┐
   └───────────────────────────────────►│   ALU   │
                                        └────┬────┘
                                             │
                                          ALUOut
                                             │
                       ┌─────────────────────┼──────────────────┐
                       │                     │                  │
                       ▼                     ▼                  ▼
                    Memory                Register             PC
                    Access                 Write             Update
