`timescale 1ns / 1ps

module pcpi_cnn_tb;
    localparam integer MEM_BYTES = 65536;
    localparam [31:0] MEM_BASE   = 32'h00004000;
    localparam [31:0] RESET_ADDR = 32'h00004000;
    parameter MEMH_FILE = "C:/Users/Revanth/Downloads/CNN_hardware_accelerator_project/firmware.memh";

    reg clk = 1'b0;
    reg resetn = 1'b0;

    wire trap;
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    reg  [31:0] mem_rdata;

    wire pcpi_valid;
    wire pcpi_wr;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    wire [31:0] pcpi_rd;
    wire pcpi_wait;
    wire pcpi_ready;

    wire [31:0] irq;
    wire [31:0] eoi;
    wire trace_valid;
    wire [35:0] trace_data;

    reg [7:0] mem [0:MEM_BYTES-1];

    integer i;

    assign irq = 32'b0;
    assign mem_ready = 1'b1;

    function [31:0] read_word;
        input [31:0] addr;
        reg [31:0] base;
        begin
            if (addr < MEM_BASE) begin
                read_word = 32'h00000000;
            end else begin
                base = {addr[31:2], 2'b00} - MEM_BASE;
                if (base + 3 < MEM_BYTES)
                    read_word = {mem[base + 3], mem[base + 2], mem[base + 1], mem[base + 0]};
                else
                    read_word = 32'h00000000;
            end
        end
    endfunction

    always @* begin
        mem_rdata = read_word(mem_addr);
    end

    always @(posedge clk) begin
        if (mem_valid && |mem_wstrb) begin
            if (mem_addr >= MEM_BASE) begin
                if (mem_addr + 0 - MEM_BASE < MEM_BYTES && mem_wstrb[0]) mem[mem_addr + 0 - MEM_BASE] <= mem_wdata[7:0];
                if (mem_addr + 1 - MEM_BASE < MEM_BYTES && mem_wstrb[1]) mem[mem_addr + 1 - MEM_BASE] <= mem_wdata[15:8];
                if (mem_addr + 2 - MEM_BASE < MEM_BYTES && mem_wstrb[2]) mem[mem_addr + 2 - MEM_BASE] <= mem_wdata[23:16];
                if (mem_addr + 3 - MEM_BASE < MEM_BYTES && mem_wstrb[3]) mem[mem_addr + 3 - MEM_BASE] <= mem_wdata[31:24];
            end
        end
    end

    always #5 clk = ~clk;

    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .ENABLE_PCPI(1),
        .ENABLE_MUL(0),
        .ENABLE_FAST_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(1),
        .ENABLE_IRQ_TIMER(1),
        .ENABLE_TRACE(0),
        .REGS_INIT_ZERO(1),
        .PROGADDR_RESET(RESET_ADDR),
        .PROGADDR_IRQ(32'h00000010)
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_read(),
        .mem_la_write(),
        .mem_la_addr(),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready),
        .irq(irq),
        .eoi(eoi),
        .trace_valid(trace_valid),
        .trace_data(trace_data)
    );

    picorv32_pcpi_cnn cnn (
        .clk(clk),
        .resetn(resetn),
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready)
    );

    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'h00;

        $readmemh(MEMH_FILE, mem);

        $display("Firmware word at reset: %08x", read_word(RESET_ADDR));

        $dumpfile("pcpi_cnn_tb.vcd");
        $dumpvars(0, pcpi_cnn_tb);

        repeat (5) @(posedge clk);
        resetn = 1'b1;

        repeat (200000) begin
            @(posedge clk);
            if (pcpi_valid && pcpi_ready) begin
                $display("%0t PCPI hit insn=%08x rs1=%08x rs2=%08x rd=%08x", $time, pcpi_insn, pcpi_rs1, pcpi_rs2, pcpi_rd);
            end
            if (pcpi_valid) begin
                $display("%0t PCPI valid insn=%08x rs1=%08x rs2=%08x ready=%b wr=%b rd=%08x", $time, pcpi_insn, pcpi_rs1, pcpi_rs2, pcpi_ready, pcpi_wr, pcpi_rd);
            end
            if (trap) begin
                $display("%0t TRAP asserted", $time);
            end
        end

        $display("Timeout without trap");
        $finish;
    end
endmodule