// Log size: log base two size of instruction memory and data
// memory, and address space for all devices
module address_res #(parameter LOG_SIZE = 12, WORD_SIZE = 32) (
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
    // Read signals
    logic instr_read_one, data_read_one, instr_read_two, data_read_two;

    // Read data signals
    logic [WORD_SIZE - 1:0] instr_read_data_one, data_read_data_one,
                            instr_read_data_two, data_read_data_two;

    // Read valid signals
    logic instr_read_one_valid, data_read_one_valid, 
          instr_read_two_valid, data_read_two_valid;

    // Write signals
    logic instr_wren, data_wren, instr_write_valid, data_write_valid

    // Instantiate instruction memory
    mem_32_big #(.WORD_SIZE(WORD_SIZE), .LOG_SIZE(LOG_SIZE)) instruction_memory (
        .clk(clk),
        .read_one(instr_read_one),
        .read_sign_one(read_sign_one),
        .read_addr_one(read_addr_one),
        .read_size_one(read_size_one),
        .read_data_one(instr_read_data_one),
        .read_valid_one(instr_read_one_valid),
        .read_two(instr_read_two),
        .read_sign_two(read_sign_two),
        .read_addr_two(read_addr_two),
        .read_size_two(read_size_two),
        .read_data_two(instr_read_data_two),
        .read_valid_two(instr_read_two_valid),
        .wren(instr_wren),
        .write_size(write_size),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_valid(instr_write_valid)
    );

    // Instantiate data memory
    mem_32_big #(.WORD_SIZE(WORD_SIZE), .LOG_SIZE(LOG_SIZE)) data_memory (
        .clk(clk),
        .read_one(data_read_one),
        .read_sign_one(read_sign_one),
        .read_addr_one(read_addr_one),
        .read_size_one(read_size_one),
        .read_data_one(data_read_data_one),
        .read_valid_one(data_read_one_valid),
        .read_two(data_read_two),
        .read_sign_two(read_sign_two),
        .read_addr_two(read_addr_two),
        .read_size_two(read_size_two),
        .read_data_two(data_read_data_two),
        .read_valid_two(data_read_two_valid),
        .wren(data_wren),
        .write_size(write_size),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_valid(data_write_valid)
    );

    logic [19:0] read_one_offset, read_two_offset, write_offset;
    
    assign read_one_offset = (read_addr_one >> LOG_SIZE);
    assign read_two_offset = (read_addr_two >> LOG_SIZE);
    assign write_offset = (write_addr >> LOG_SIZE);


    always_comb begin : set_memory_signals
        // Default read one signals
        instr_read_one = 1'b0;
        data_read_one = 1'b0;
        read_valid_one = 1'b0;
        read_data_one = 32'b0;
        
        // Rout read one signals
        if (read_one_offset == 20'd0) begin
            instr_read_one = read_one;
            read_valid_one = instr_read_one_valid;
            read_data_one = instr_read_data_one;
        end else if (read_one_offset == 20'd1) begin
            data_read_one = read_one;
            read_valid_one = data_read_one_valid;
            read_data_one = data_read_data_one;
        end

        // Default read two signals
        instr_read_two = 1'b0;
        data_read_two = 1'b0;
        read_valid_two = 1'b0;
        read_data_two = 32'b0;

        // Route read two signals
        if (read_one_offset == 20'd0) begin
            instr_read_two = read_two;
            read_valid_two = instr_read_two_valid;
            read_data_two = instr_read_data_two;
        end else if (read_one_offset == 20'd1) begin
            data_read_two = read_two;
            read_valid_one = data_read_two_valid;
            read_data_two = data_read_data_two;
        end

        // Default write signals
        instr_wren = 1'b0;
        data_wren = 1'b0;

        // Route write signals
        if (write_offset == 20'd0) begin
            data_wren = wren;
        end else if (write_offset == 20'd1) begin
            instr_wren = wren;
        end
    end // set_memory_signals
endmodule