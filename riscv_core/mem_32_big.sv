// SIZE: Memory size
// WORD: Word size (bytes)
// BIG: whether big endian
// read_size / write size:
//  01: byte
//  10: half word
//  11: full word
//
// On not full word the unused most significant bytes of read_data
// to 0, i.e. the read will be packed into the least significant
// bytes. For write only the necessary least significant bytes
// are used
//
// Read will be sign extended if read_sign is asserted
module mem_32_big #(parameter LOG_SIZE = 12, WORD_SIZE = 32) (
    input logic clk,

    // Read data one
    input  logic read_one,
    input  logic read_sign_one,
    input  logic [WORD_SIZE - 1:0] read_addr_one,
    input  logic [1:0]  read_size_one,
    output logic [WORD_SIZE - 1:0] read_data_one,
    output logic read_valid_one,

    // Read data two (surprise tool that'll help us later)
    input  logic read_two,
    input  logic read_sign_two,
    input  logic [WORD_SIZE - 1:0] read_addr_two,
    input  logic [1:0]  read_size_two,
    output logic [WORD_SIZE - 1:0] read_data_two,
    output logic read_valid_two,

    // Write data
    input  logic wren,
    input  logic [1:0] write_size,
    input  logic [WORD_SIZE - 1:0] write_addr,
    input  logic [WORD_SIZE - 1:0] write_data,
    output logic write_valid
);
    // Constants
    parameter BYTE = 2'b01;
    parameter HALF = 2'b10;
    parameter FULL = 2'b11;

    // Memory array
    logic [7:0] mem [2 ** LOG_SIZE - 1:0];

    // Calculate out
    logic [WORD_SIZE - 1:0] mem_out_one, mem_out_two, write_shift;

    // Set set_read to 32 bit equaivalent of read_data depending
    // on read_sign and read_size
    function [31:0] set_read (
        input read_sign,
        input read_size,
        input [31:0] read_data
    );
        set_read = read_data;

        if (read_sign) begin
            if (read_size == HALF) begin
                set_read = read_data >>> (WORD_SIZE / 2);
            end else if (read_size == BYTE) begin
                set_read = read_data >>> (WORD_SIZE - 7);
            end
        end else begin
            if (read_size == HALF) begin
                set_read = read_data >> (WORD_SIZE / 2);
            end else if (read_size == BYTE) begin
                set_read = read_data >> (WORD_SIZE - 7);
            end
        end
    endfunction

    // Pack write data into right-most bits of set_write depending
    // on internal_write_size
    function [31:0] set_write (
        input internal_write_size,
        input [31:0] unpacked_write
    );
        set_write = unpacked_write;

        if (internal_write_size == HALF) begin
            set_write = unpacked_write << (WORD_SIZE / 2);
        end else if (internal_write_size == BYTE) begin
            set_write = unpacked_write << (WORD_SIZE - 7);
        end
    endfunction

    // Get packed and sign extended read data and write shift signals
    assign read_data_one = set_read(read_sign_one, read_size_one, mem_out_one);
    assign read_data_two = set_read(read_sign_two, read_size_two, mem_out_two);
    assign write_shift = set_write(write_size, write_data);

    // MUX to read_data, set write data
    always_comb begin : set_read_write
        write_shift = write_data;

        if (write_size == FULL) begin
            write_shift = write_data >> (WORD_SIZE / 2);
        end else if (write_size == BYTE) begin
            write_shift = write_data >> (WORD_SIZE - 8);
        end
    end

    always_ff @(posedge clk) begin : set_mem
        // Read one
        if (read_one) begin
            mem_out_one <= {mem[read_addr_one][7:0],
                            (read_size_one != BYTE) ? mem[read_addr_one + 1][7:0] : 8'b0,
                            (read_size_one == FULL) ? mem[read_addr_one + 2][7:0] : 8'b0,
                            (read_size_one == FULL) ? mem[read_addr_one + 3][7:0] : 8'b0};
        end

        // Read two
        if (read_two) begin
            mem_out_two <= {mem[read_addr_two][7:0],
                            (read_size_two != BYTE) ? mem[read_addr_two + 1][7:0] : 8'b0,
                            (read_size_two == FULL) ? mem[read_addr_two + 2][7:0] : 8'b0,
                            (read_size_two == FULL) ? mem[read_addr_two + 3][7:0] : 8'b0};
        end

        // Set read valid flags
        read_valid_one <= (read_one == 1);
        read_valid_two <= (read_two == 1);

        // Write
        if (wren) begin
            mem[write_addr] <= write_shift[WORD_SIZE - 1:WORD_SIZE - 8];

            if (write_size != BYTE) begin
                mem[write_addr + 1] <= write_shift[WORD_SIZE - 9:WORD_SIZE - 16];
            end

            if (write_size == FULL) begin
                mem[write_addr + 2] <= write_shift[WORD_SIZE - 17:WORD_SIZE - 24];
            end

            if (write_size == FULL) begin
                mem[write_addr + 3] <= write_shift[WORD_SIZE - 25: WORD_SIZE - 32];
            end
        end

        // Set write valid
        write_valid <= (wren == 1);
    end // set_mem
endmodule // mem_32_big

module test_mem_32_big();
    logic clk;

    // Read data one
    logic read_one;
    logic read_sign_one;
    logic [WORD_SIZE - 1:0] read_addr_one;
    logic [1:0]  read_size_one;
    logic [WORD_SIZE - 1:0] read_data_one;
    logic read_valid_one;

    // Read data two (surprise tool that'll help us later)
    logic read_two;
    logic read_sign_two;
    logic [WORD_SIZE - 1:0] read_addr_two;
    logic [1:0]  read_size_two;
    logic [WORD_SIZE - 1:0] read_data_two;
    logic read_valid_two;

    // Write data
    logic wren;
    logic [1:0] write_size;
    logic [WORD_SIZE - 1:0] write_addr;
    logic [WORD_SIZE - 1:0] write_data;
    logic write_valid;

    // Instance of the memory module
    mem_32_big mem_32_big_i (
        .clk(clk),
        .read_one(read_one),
        .read_sign_one(read_sign_one),
        .read_addr_one(read_addr_one),
        .read_size_one(read_size_one),
        .read_data_one(read_data_one),
        .read_valid_one(read_valid_one),
        .read_two(read_two),
        .read_sign_two(read_sign_two),
        .read_addr_two(read_addr_two),
        .read_size_two(read_size_two),
        .read_data_two(read_data_two),
        .read_valid_two(read_valid_two),
        .wren(wren),
        .write_size(write_size),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_valid(write_valid)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Initialize the inputs
    initial begin
        clk <= 0;
        read_one <= 0;
        read_sign_one <= 0;
        read_addr_one <= 0;
        read_size_one <= 2'b01;

        read_two <= 0;
        read_sign_two <= 0;
        read_addr_two <= 0;
        read_size_two <= 2'b01;

        wren <= 0;
        write_size <= 2'b01;
        write_addr <= 0;
        write_data <= 0;

        for (int i = 0; i < 2 ** LOG_SIZE; i++) begin
            // Write byte
            wren <= 1;
            write_addr <= i;
            write_data <= i;

            @(posedge clk);

            wren <= 0;

            read_one <= 1;
            read_two <= 1;
            read_addr_one <= i;
            read_addr_one <= i;
            read_data_one <= i;
            read_addr_two <= i;

            $display("Write addr: %d\m", write_addr);
            $display("Write Valid: %d\n", write_valid);

            @(posedge clk);

            read_one <= 0;
            read_two <= 0;

            $display("Write valid one: %d two: %d\n" , read_valid_one, read_valid_two);
            $display("Write address one: %d two: %d\n", read_addr_one, read_addr_two);
            $display("Read data one: %d two: %d\n", read_data_one, read_addr_two);
            $display("\n");
        end
    end
