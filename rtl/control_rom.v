module mips_control_rom (
    input  wire clk,
    input  wire  reset,
    input  wire [5:0] opcode,
    input  wire  zero,

    output reg PCWrite,
    output reg PCWriteCond,
    output reg IorD,
    output reg MemRead,
    output reg MemWrite,
    output reg IRWrite,
    output reg MemtoReg,
    output reg RegWrite,
    output reg RegDst,
    output reg ALUSrcA,
    output reg [1:0]  ALUSrcB,
    output reg [1:0]  PCSource,
    output reg [1:0]  ALUOp
);

    // STATE ENCODING
    localparam FETCH = 4'd0;
    localparam DECODE = 4'd1;
    localparam MEM_ADDR = 4'd2;
    localparam MEM_READ = 4'd3;
    localparam MEM_WB = 4'd4;
    localparam MEM_WRITE = 4'd5;
    localparam R_EXEC = 4'd6;
    localparam R_WB = 4'd7;
    localparam BRANCH = 4'd8;
    localparam JUMP = 4'd9;
    localparam ADDI_EXEC= 4'd10;
    localparam ADDI_WB = 4'd11;

    reg [3:0] state;
    reg [3:0] next_state;

    // 16-BIT CONTROL ROM
    reg [15:0] control_rom [0:11];

    initial begin
        // FETCH
        control_rom[FETCH] = 16'b1001010000010000;
        // DECODE
        control_rom[DECODE] = 16'b0000000000110000;
        // MEM ADDRESS
        control_rom[MEM_ADDR] = 16'b0000000001100000;
        // MEM READ
        control_rom[MEM_READ] = 16'b0011000000000000;
        // MEM WB
        control_rom[MEM_WB] = 16'b0000001100000000;
        // MEM WRITE
        control_rom[MEM_WRITE] = 16'b0010100000000000;
        // R EXEC
        control_rom[R_EXEC] = 16'b0000000001000010;
        // R WB
        control_rom[R_WB] =16'b0000000110000000;
        // BRANCH
        control_rom[BRANCH] = 16'b0100000001000101;
        // JUMP
        control_rom[JUMP] = 16'b1000000000001000;
        // ADDI EXEC
        control_rom[ADDI_EXEC] = 16'b0000000001100000;
        // ADDI WB
        control_rom[ADDI_WB] = 16'b0000000100000000;

    end

    // STATE REGISTER
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    // NEXT STATE LOGIC
    always @(*) begin

        case (state)

            FETCH: next_state = DECODE;

            DECODE: begin
                case (opcode)

                    6'b000000: next_state = R_EXEC;
                    6'b100011: next_state = MEM_ADDR;   // LW
                    6'b101011: next_state = MEM_ADDR;   // SW
                    6'b000100: next_state = BRANCH;     // BEQ
                    6'b000010: next_state = JUMP;       // J
                    6'b001000: next_state = ADDI_EXEC;  // ADDI
                    default:   next_state = FETCH;

                endcase
            end

            MEM_ADDR: begin
                if (opcode == 6'b100011)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE;
            end

            MEM_READ:
                next_state = MEM_WB;

            MEM_WB:
                next_state = FETCH;

            MEM_WRITE:
                next_state = FETCH;

            R_EXEC:
                next_state = R_WB;

            R_WB:
                next_state = FETCH;

            BRANCH:
                next_state = FETCH;

            JUMP:
                next_state = FETCH;

            ADDI_EXEC:
                next_state = ADDI_WB;

            ADDI_WB:
                next_state = FETCH;

            default:
                next_state = FETCH;

        endcase

    end

    // ROM OUTPUT
    always @(*) begin
        {   PCWrite,
            PCWriteCond,
            IorD,
            MemRead,
            MemWrite,
            IRWrite,
            MemtoReg,
            RegWrite,
            RegDst,
            ALUSrcA,
            ALUSrcB,
            PCSource,
            ALUOp
        } = control_rom[state];
    end
endmodule
