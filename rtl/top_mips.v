module top_mips (

    input  wire clk,
    input  wire reset

);
    // CONTROL SIGNALS
    wire PCWrite;
    wire PCWriteCond;
    wire IorD;
    wire MemRead;
    wire MemWrite;
    wire IRWrite;
    wire MemtoReg;
    wire RegWrite;
    wire RegDst;
    wire ALUSrcA;
    wire [1:0]  ALUSrcB;
    wire [1:0]  PCSource;
    wire [1:0]  ALUOp;

    // STATUS / INSTRUCTION SIGNALS
    wire [5:0]  Opcode;
    wire        Zero;

    // CONTROL ROM
    mips_control_rom CONTROL_UNIT (

        .clk (clk),
        .reset (reset),
        .opcode (Opcode),
        .zero (Zero),

        // 16 datapath control signals
        .PCWrite (PCWrite),
        .PCWriteCond (PCWriteCond),
        .IorD  (IorD),
        .MemRead (MemRead),
        .MemWrite (MemWrite),
        .IRWrite (IRWrite),
        .MemtoReg (MemtoReg),
        .RegWrite (RegWrite),
        .RegDst (RegDst),
        .ALUSrcA (ALUSrcA),
        .ALUSrcB (ALUSrcB),
        .PCSource (PCSource),
        .ALUOp (ALUOp)

    );

    // DATAPATH
    mips_datapath DATAPATH (

        .clk (clk),
        .reset (reset),
        // 16 control signals
        .RegDst (RegDst),
        .RegWrite(RegWrite),
        .ALUSrcA (ALUSrcA),
        .MemRead (MemRead),
        .MemWrite (MemWrite),
        .MemtoReg (MemtoReg),
        .IorD (IorD),
        .IRWrite (IRWrite),
        .PCWrite (PCWrite),
        .PCWriteCond (PCWriteCond),
        .ALUOp (ALUOp),
        .ALUSrcB (ALUSrcB),
        .PCSource (PCSource),
        // Outputs from datapath
        .Opcode (Opcode),
        .Zero (Zero)
    );

endmodule
