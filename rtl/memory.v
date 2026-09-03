module memory (
    input clk,
    input MemRead,
    input MemWrite,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);

    reg [7:0] memory [0:4095];

    assign ReadData = MemRead ? 
             {memory[Address[11:0] + 12'd3],
              memory[Address[11:0] + 12'd2],
              memory[Address[11:0] + 12'd1],
              memory[Address[11:0]]} :
             32'b0;

    always @(posedge clk) begin
        if (MemWrite) begin
            memory[Address[11:0]] <= WriteData[7:0];
            memory[Address[11:0] + 12'd1] <= WriteData[15:8];
            memory[Address[11:0] + 12'd2] <= WriteData[23:16];
            memory[Address[11:0] + 12'd3] <= WriteData[31:24];
        end
    end

endmodule
