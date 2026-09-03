`timescale 1ns/1ps

module testbench;

    // CLOCK AND RESET
    reg clk;
    reg reset;

    // TOP-LEVEL MIPS PROCESSOR

    top_mips DUT ( .clk   (clk), .reset (reset)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // INITIALIZE MEMORY AND REGISTERS
    integer i;
    initial begin
        // Clear memory
        for (i = 0; i < 4096; i = i + 1)
            DUT.DATAPATH.MEM.memory[i] = 8'b0;
        // Clear registers
        for (i = 0; i < 32; i = i + 1)
            DUT.DATAPATH.RF.registers[i] = 32'b0;
        // INITIAL REGISTER VALUES
        // $t0 = register 8
        // $t1 = register 9
        // $t2 = register 10
        // $t3 = register 11
        // $t4 = register 12
        // $t5 = register 13
        // $t6 = register 14
        // $t7 = register 15
        // $s0 = register 16
        // $s1 = register 17

        DUT.DATAPATH.RF.registers[8]  = 32'd10;
        DUT.DATAPATH.RF.registers[9]  = 32'd20;
        DUT.DATAPATH.RF.registers[10] = 32'd5;

        // LOAD PROGRAM INTO MEMORY

        // 0x0000
        // addi $t0, $zero, 10
        // $t0 = 10
        // 0x2008000A


        write_word(12'h000, 32'h2008000A);

        // 0x0004
        // add $t2, $t0, $t1
        // $t2 = 10 + 20 = 30
        // 0x01095020

        write_word(12'h004, 32'h01095020);

        // 0x0008
        // sw $t2, 0($zero)
        //
        // Memory[0] = 30
        //
        // 0xAC0A0000

        write_word(12'h008, 32'hAC0A0000);

        // 0x000C
        // lw $t3, 0($zero)
        // $t3 = Memory[0] = 30
        // 0x8C0B0000

        write_word(12'h00C, 32'h8C0B0000);

        // 0x0010
        // beq $t2, $t3, +1
        // $t2 == $t3
        // Therefore branch is taken.
        // Skips instruction at 0x0014
        // 0x114B0001

        write_word(12'h010, 32'h114B0001);

        // 0x0014
        // addi $t4, $zero, 9 
        // This instruction should be SKIPPED.
        // 0x200C03E7

        write_word(12'h014, 32'h200C03E7);

        // 0x0018
        // j 0x0000001C
        // Jump target = 0x001C
        //
        // 0x08000007
        write_word(12'h018, 32'h08000007);

        // 0x001C
        // addi $t5, $zero, 123
        // $t5 = 123
        // 0x200D007B

        write_word(12'h01C, 32'h200D007B);

        // R-TYPE INSTRUCTIONS
        // 0x0020
        // sub $t6, $t1, $t0
        // $t6 = 20 - 10 = 10
        // opcode = 000000
        // funct = 100010
        // 0x01287022

        write_word(12'h020, 32'h01287022);

        // 0x0024
        // and $t7, $t0, $t1
        // $t7 = 10 & 20 = 0
        // funct = 100100
        // 0x01097824

        write_word(12'h024, 32'h01097824);

        // 0x0028
        // or $s0, $t0, $t1
        // $s0 = 10 | 20 = 30
        // funct = 100101
        // 0x01098025

        write_word(12'h028, 32'h01098025);


        // 0x002C
        // slt $s1, $t0, $t1
        // $s1 = 1 because 10 < 20
        // 0x0109882A

        write_word(12'h02C, 32'h0109882A);

    end


    task write_word;

        input [11:0] address;
        input [31:0] data;

        begin

            DUT.DATAPATH.MEM.memory[address] =
                data[7:0];

            DUT.DATAPATH.MEM.memory[address + 12'd1] =
                data[15:8];

            DUT.DATAPATH.MEM.memory[address + 12'd2] =
                data[23:16];

            DUT.DATAPATH.MEM.memory[address + 12'd3] =
                data[31:24];

        end

    endtask

    initial begin

    reset = 1'b1;

    #20;

    reset = 1'b0;

    #1;

    // Restore $t1 after reset
    DUT.DATAPATH.RF.registers[9] = 32'd20;

end

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | STATE=%0d | PC=%h | IR=%h | A=%d | B=%d | ALUOut=%d | MDR=%d",
            $time,
            DUT.CONTROL_UNIT.state,
            DUT.DATAPATH.PC,
            DUT.DATAPATH.IR,
            DUT.DATAPATH.A,
            DUT.DATAPATH.B,
            DUT.DATAPATH.ALUOut,
            DUT.DATAPATH.MDR
        );

    end

    // FINAL RESULTS
    initial begin

        #600;

        $display("");
        $display("==========================================");
        $display("          FINAL REGISTER VALUES");
        $display("==========================================");

        $display("$t0 (R8)  = %d", DUT.DATAPATH.RF.registers[8]);

        $display("$t1 (R9)  = %d", DUT.DATAPATH.RF.registers[9]);

        $display("$t2 (R10) = %d", DUT.DATAPATH.RF.registers[10]);

        $display("$t3 (R11) = %d", DUT.DATAPATH.RF.registers[11]);

        $display("$t4 (R12) = %d", DUT.DATAPATH.RF.registers[12]);

        $display("$t5 (R13) = %d", DUT.DATAPATH.RF.registers[13]);

        $display("$t6 (R14) = %d", DUT.DATAPATH.RF.registers[14]);

        $display("$t7 (R15) = %d", DUT.DATAPATH.RF.registers[15]);

        $display("$s0 (R16) = %d", DUT.DATAPATH.RF.registers[16]);

        $display("$s1 (R17) = %d", DUT.DATAPATH.RF.registers[17]);

        $display("");

        $display("Memory[0] = %h",
                 {
                    DUT.DATAPATH.MEM.memory[3],
                    DUT.DATAPATH.MEM.memory[2],
                    DUT.DATAPATH.MEM.memory[1],
                    DUT.DATAPATH.MEM.memory[0]
                 });

        $display("==========================================");

        $finish;

    end

    initial begin

        $dumpfile("mips.vcd");

        $dumpvars(0, testbench);

    end

endmodule
