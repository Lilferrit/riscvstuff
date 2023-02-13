import pyverilator

# Initialize the inputs
def read_write_byte(dut):
    dut.io.clk = 0
    dut.io.read_one = 0
    dut.io.read_sign_one = 0
    dut.io.read_addr_one = 0
    dut.io.read_size_one = 1

    dut.io.read_two = 0
    dut.io.read_sign_two = 0
    dut.io.read_addr_two = 0
    dut.io.read_size_two = 1

    dut.io.wren = 0
    dut.io.write_size = 1
    dut.io.write_addr = 0
    dut.io.write_data = 0

    for i in range(2 ** LOG_SIZE):
        # Write byte
        dut.io.wren = 1
        dut.io.write_addr = i
        dut.io.write_data = i

        dut.clk.tick()

        dut.io.wren = 0

        dut.io.read_one = 1
        dut.io.read_two = 1
        dut.io.read_addr_one = i
        dut.io.read_addr_two = i
        dut.io.read_data_one = i

        print("Write addr: {}".format(write_addr))
        print("Write Valid: {}".format(write_valid))

        dut.clk.tick()

        dut.io.read_one = 0
        dut.io.read_two = 0

        print("Write valid one: {} two: {}".format(read_valid_one, read_valid_two))
        print("Write address one: {} two: {}".format(read_addr_one, read_addr_two))
        print("Read data one: {} two: {}".format(read_data_one, read_data_two))

def main():
    # Build DUT
    dut = pyverilator.PyVerilator.build("../mem_32_big.sv")

    # run tests
    read_write_byte(dut)

if __name__ == "__main__":
    main()