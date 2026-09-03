module program_counter (
    input clk,
    input reset,
    input PCWrite,
    input  [31:0] PCNext,

    output reg [31:0] PC
);

    always @(posedge clk) begin
        if (reset)
            PC <= 32'b0;
        else if (PCWrite)
            PC <= PCNext;
    end

endmodule


module instruction_register (
    input clk,
    input reset,
    input IRWrite,
    input [31:0] Instruction,

    output reg [31:0] IR
);

    always @(posedge clk) begin
        if (reset)
            IR <= 32'b0;
        else if (IRWrite)
            IR <= Instruction;
    end

endmodule

module register_file (
    input clk,
    input reset,
    input RegWrite,

    input [4:0] ReadReg1,
    input [4:0] ReadReg2,
    input [4:0] WriteReg,
    input [31:0] WriteData,

    output [31:0] ReadData1,
    output [31:0] ReadData2
);
    reg [31:0] registers [0:31];

    integer i;

    
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (RegWrite && (WriteReg != 5'b00000)) begin
            registers[WriteReg] <= WriteData;
        end
    end

    assign ReadData1 = (ReadReg1 == 5'b00000) ? 32'b0 : registers[ReadReg1];

    assign ReadData2 = (ReadReg2 == 5'b00000) ? 32'b0 : registers[ReadReg2];

endmodule

module mips_alu(
    input [31:0] A,
    input [31:0] B,
    input [2:0] ALUControl,
    output reg [31:0] Result,
    output zero,
    output carry,
    output overflow

);

wire [31:0] and_result;
wire [31:0] or_result;
wire [31:0] sum_result;
wire [31:0] B_modified;
wire [32:0] Carry;
wire binvert;

assign binvert = (ALUControl == 3'b110) || (ALUControl == 3'b111);
assign B_modified = B ^ {32{binvert}};
assign Carry[0] = binvert;

genvar i;
generate
        for (i = 0; i < 32; i = i + 1) begin : ADDER

            assign sum_result[i] =A[i] ^ B_modified[i] ^ Carry[i];

            assign Carry[i+1] = (A[i] & B_modified[i]) | (A[i] & Carry[i]) |(B_modified[i] & Carry[i]);

        end
endgenerate

assign and_result = A & B;
assign or_result  = A | B;

assign overflow =(A[31] & B_modified[31] & ~sum_result[31]) | (~A[31] & ~B_modified[31] & sum_result[31]);
wire less;
assign less = sum_result[31] ^ overflow;

always @(*) begin
    case (ALUControl)
        3'b000: Result = and_result;       // AND
        3'b001: Result = or_result;        // OR
        3'b010: Result = sum_result;       // ADD
        3'b110: Result = sum_result;       // SUB
        3'b111: Result = {31'b0, less};    // SLT
        default: Result = 32'b0;
    endcase
end

assign carry = Carry[32];
assign zero = (Result == 32'b0);

endmodule

module a_register (
    input clk,
    input reset,
    input  [31:0] DataIn,
    output reg [31:0] A
);

    always @(posedge clk) begin
        if (reset)
            A <= 32'b0;
        else
            A <= DataIn;
    end

endmodule 

module b_register (
    input        clk,
    input        reset,
    input  [31:0] DataIn,

    output reg [31:0] B
);

    always @(posedge clk) begin
        if (reset)
            B <= 32'b0;
        else
            B <= DataIn;
    end

endmodule

module alu_out_register (
    input        clk,
    input        reset,
    input  [31:0] DataIn,

    output reg [31:0] ALUOut
);

    always @(posedge clk) begin
        if (reset)
            ALUOut <= 32'b0;
        else
            ALUOut <= DataIn;
    end

endmodule

module sign_extend (
    input  [15:0] In,
    output [31:0] Out
);

    assign Out = {{16{In[15]}}, In};

endmodule

module memory_data_register (
    input         clk,
    input         reset,
    input  [31:0] MemData,

    output reg [31:0] MDR
);

    always @(posedge clk) begin

        if (reset)
            MDR <= 32'b0;

        else
            MDR <= MemData;

    end

endmodule

module mips_datapath (

    input         clk,
    input         reset,
     // 16 CONTROL SIGNALS

    input RegDst,
    input RegWrite,
    input ALUSrcA,
    input MemRead,
    input MemWrite,
    input MemtoReg,
    input IorD,
    input IRWrite,
    input PCWrite,
    input PCWriteCond,

    input  [1:0]  ALUOp,
    input  [1:0]  ALUSrcB,
    input  [1:0]  PCSource,

    output [5:0]  Opcode,


    output        Zero


);

    wire [31:0] PC;
    wire [31:0] IR;
    wire [31:0] MDR;
    wire [5:0] Funct;

    wire [31:0] A;
    wire [31:0] B;
    wire [31:0] ALUOut;
    wire [31:0] ReadData1;
    wire [31:0] ReadData2;
    wire [31:0] MemoryReadData;
    wire [31:0] SignExtImm;
    wire [31:0] SignExtImmShift2;
    wire [31:0] ALUInputA;
    reg [31:0] ALUInputB;
    wire [31:0] ALUResult;
    wire ALUZero;
    wire ALUCarry;
    wire ALUOverflow;

    reg [2:0] ALUControl;
    wire [31:0] MemoryAddress;
    wire [31:0] PCNext;
    wire [31:0] RegisterWriteData;
    wire [4:0] WriteRegister;
    wire PCEnable;
    wire [31:0] JumpAddress;


    assign Opcode = IR[31:26];

    assign Funct  = IR[5:0];


    sign_extend SE (.In  (IR[15:0]), .Out (SignExtImm) );

    assign SignExtImmShift2 = SignExtImm << 2;

    // ALUOp:
localparam ALU_AND = 3'b000;
localparam ALU_OR  = 3'b001;
localparam ALU_ADD = 3'b010;
localparam ALU_SUB = 3'b110;
localparam ALU_SLT = 3'b111;

always @(*) begin

    case (ALUOp)

        2'b00: begin
            ALUControl = ALU_ADD;
        end

        2'b01: begin
            ALUControl = ALU_SUB;
        end

        2'b10: begin

            case (Funct)

                6'b100000: ALUControl = ALU_ADD; // ADD
                6'b100010: ALUControl = ALU_SUB; // SUB
                6'b100100: ALUControl = ALU_AND; // AND
                6'b100101: ALUControl = ALU_OR;  // OR
                6'b101010: ALUControl = ALU_SLT; // SLT

                default:   ALUControl = ALU_ADD;

            endcase
        end

        default: begin
            ALUControl = ALU_ADD;
        end

    endcase

end


    assign WriteRegister =RegDst ? IR[15:11] : IR[20:16];

    assign RegisterWriteData = MemtoReg ? MDR : ALUOut;


    register_file RF (

        .clk       (clk),
        .reset     (reset),
        .RegWrite  (RegWrite),
        .ReadReg1  (IR[25:21]),
        .ReadReg2  (IR[20:16]),
        .WriteReg  (WriteRegister),
        .WriteData (RegisterWriteData),
        .ReadData1 (ReadData1),
        .ReadData2 (ReadData2)

    );


    a_register A_REG (

        .clk (clk),
        .reset  (reset),
        .DataIn (ReadData1),
        .A (A)

    );


    b_register B_REG (

        .clk (clk),
        .reset  (reset),
        .DataIn (ReadData2),
        .B(B)

    );



    assign ALUInputA = ALUSrcA ? A :  PC;

always @(*) begin

    case (ALUSrcB)

        2'b00: begin
            ALUInputB = B;                 // Register B
        end

        2'b01: begin
            ALUInputB = 32'd4;             // Constant 4
        end

        2'b10: begin
            ALUInputB = SignExtImm;        // Sign-extended immediate
        end

        2'b11: begin
            ALUInputB = SignExtImmShift2;  // Immediate << 2
        end

        default: begin
            ALUInputB = 32'b0;
        end
    
    endcase
    end

    mips_alu ALU (

        .A (ALUInputA),
        .B (ALUInputB),
        .ALUControl (ALUControl),
        .Result (ALUResult),
        .zero (ALUZero),
        .carry (ALUCarry),
        .overflow (ALUOverflow)

    );

    alu_out_register ALU_OUT_REG (

        .clk (clk),
        .reset (reset),
        .DataIn (ALUResult),
        .ALUOut (ALUOut)

    );

    assign MemoryAddress = IorD ? ALUOut : PC;

    memory MEM (

        .clk (clk),
        .MemRead (MemRead),
        .MemWrite (MemWrite),
        .Address (MemoryAddress),
        .WriteData (B),
        .ReadData (MemoryReadData)

    );


    instruction_register IR_REG (

        .clk (clk),
        .reset (reset),
        .IRWrite (IRWrite),
        .Instruction (MemoryReadData),
        .IR (IR)

    );


    memory_data_register MDR_REG (

        .clk (clk),
        .reset (reset),
        .MemData  (MemoryReadData),
        .MDR (MDR)

    );

    assign JumpAddress = { PC[31:28], IR[25:0], 2'b00 };


    assign PCNext = (PCSource == 2'b00) ? ALUResult : (PCSource == 2'b01) ? ALUOut : (PCSource == 2'b10) ? JumpAddress :32'b0;

    // PC WRITE CONTROL
    assign PCEnable =  PCWrite | (PCWriteCond & ALUZero);

    // PROGRAM COUNTER

    program_counter PC_REG (

        .clk (clk),
        .reset (reset),
        .PCWrite (PCEnable),
        .PCNext  (PCNext),
        .PC (PC)

    );

    assign Zero = ALUZero;

endmodule
