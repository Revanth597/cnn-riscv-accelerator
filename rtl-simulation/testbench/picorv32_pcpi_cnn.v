//////////////////////////////////////////////////////////////////////////////////
// Company: CIE
// Engineer: Revanth A H
// 
// Create Date: 06/28/2026 10:20:38 PM
// Design Name: 
// Module Name: picorv32_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/*
 * Simple PCPI handler for two CNN custom instructions.
 * - opcode 7'b0001011 (0x0B)
 * - funct3 3'b000 : CNN_LD_WT  -> return rs1
 * - funct3 3'b001 : CNN_LD_IMG_EXE -> return rs1 + rs2
 */
`timescale 1 ns / 1 ps

module picorv32_pcpi_cnn (
    input clk, resetn,

    input             pcpi_valid,
    input      [31:0] pcpi_insn,
    input      [31:0] pcpi_rs1,
    input      [31:0] pcpi_rs2,
    output reg        pcpi_wr,
    output reg [31:0] pcpi_rd,
    output reg        pcpi_wait,
    output reg        pcpi_ready
);
always @* begin
    pcpi_wr    = 0;
    pcpi_rd    = 32'b0;
    pcpi_wait  = 0;
    pcpi_ready = 0;

    if (pcpi_valid && pcpi_insn[6:0] == 7'b0001011) begin
        case (pcpi_insn[14:12])

            3'b000: begin
                pcpi_rd    = pcpi_rs1;
                pcpi_wr    = 1;
                pcpi_ready = 1;
            end

            3'b001: begin
                pcpi_rd    = pcpi_rs1 + pcpi_rs2;
                pcpi_wr    = 1;
                pcpi_ready = 1;
            end

            default: begin
                pcpi_ready = 0;
                pcpi_wr    = 0;
            end
        endcase
    end
end
endmodule
