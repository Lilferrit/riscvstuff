module program_counter #(parameter ADDR_SIZE = 32, FIRST_ADDR = 4) (
    // clk: clock signal
    // rst: reset program counter
    // enable: enable program counter
    input  logic clk, rst, enable

    // Opcode directly from risc-v instruction, used to
    // calculate next address for branching
    input  logic [6:0] opcode,

    // Funct3 directly from risc-v instruction, used to
    // calculate next address for branching
    input  logic [2:0] funct3,

    // Immediates, provided by decoder
    input  logic [19:0] j_immediate,
    input  logic [11:0] b_immediate,

    // ALU output for conditional branches
    // On jalr alu_out should be set to the
    // value rs1 + I_immediate
    input  logic [31:0] alu_out,

    // Current program counter location
    output logic [ADDR_SIZE - 1:0] curr_pc
);
    // Opcode parameters
    parameter JAL = 7'b1101111;
    parameter JALR = 7'b1100111;
    parameter BEQ = 7'b1100011;

    // Funct3 parameters
    parameter BEQ = 3'b000;
    parameter BNE = 3'b001;
    parameter BLT = 3'b100;
    parameter BGE = 3'b101;
    parameter BLTU = 3'b110;
    parameter BGEU = 3'b111;

    // Get 32 bit signed value of j immedaite when used in jal instruction
    function [31:0] process_j (
        input logic [19:0] internal_j_imm
    );
        process_j[31:12] = internal_j_imm;
        process_j = process_j >>> 10;
    endfunction

    // Get 32 bit signed value of b immedaite when used in branches
    function [31:0] process_b (
        input logic [11:0] internal_b_imm
    );
        process_b[31:20] = internal_b_imm[11:0];
        process_b = process_b >>> 19;
    endfunction

    logic [31:0] next_pc;

    always_comb begin : calculate_next_pc
        // Default next PC is current PC incremented by 4
        next_pc = curr_pc + 4;

        if (opcode == JAL) begin
            next_pc = curr_pc + process_j(j_immediate);
        end else if (opcode == JALR && funct3 == BEQ) begin
            next_pc = alu_out;
            next_pc[0] = 1'b0;
        end else if (opcode == BEQ) begin
            if ((funct3 == BEQ && alu_out == 0) ||
                (funct3 == BNE && alu_out != 0) ||
                (funct3 == BLT && alu_out < 0)  ||
                (funct3 == BGE && alu_out >= 0) ||
                (funct3 == BLTU && alu_out == 0) ||
                (funct3 == BGEU && alu_out != 0)) begin

                next_pc = curr_pc + process_b(b_immediate);
            end
        end
    end  // Calculate next pc

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_pc <= FIRST_ADDR;
        end if (enable) begin
            curr_pc <= next_pc
        end
    end
endmodule // program_counter