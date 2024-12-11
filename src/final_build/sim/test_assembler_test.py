import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.binary import BinaryValue

CHAR_PER_LINE = 64
NUM_LINES = 64


def char_to_ascii_hex(char):
    # Get the ASCII value of the character
    ascii_value = ord(char)
    # Format the ASCII value as a 2-digit hexadecimal string
    hex_value = format(ascii_value, '02x')
    return hex_value

def clean_code(code):
        buffer = [
            [" " for _ in range(CHAR_PER_LINE)] for _ in range(NUM_LINES)
        ]
        for line_index, line in enumerate(code.split('\n')):
            for char_index, char in enumerate(line):
                if char_index < CHAR_PER_LINE:
                    if char in [",", " ", "."] or char.isalnum():
                        buffer[line_index][char_index] = char

        return buffer


def test_add_instruction(lines):
    
    datamem = [
        [" " for _ in range(64)] for _ in range(64)
    ]

    for line_index, line in enumerate(lines):
        for char_index, char in enumerate(line):
            datamem[line_index][char_index] = char

    with open("sim/defaultTextEditor.mem", "w") as f:
        for line in datamem:
            for character in line:
                f.write(f"{char_to_ascii_hex(character)}\n")

def test_add_instruction_file():

    with open(f'sim/bubble_sort.txt') as f:
        code = f.read()

    code = clean_code(code)

    with open("sim/bubbleSort.mem", "w") as f:
        for line in code:
            for character in line:
                f.write(f"{char_to_ascii_hex(character)}\n")


@cocotb.test()
async def test(dut):
    """Test the Assembler."""
    cocotb.start_soon(Clock(dut.clk_pixel, 10, units="ns").start())
    dut.sw.value=0
    dut.sys_rst.value=1 
    await ClockCycles(dut.clk_pixel, 10)
    dut.sys_rst.value=0
    
    await ClockCycles(dut.clk_pixel,10)

    dut.sw.value = 2
    await ClockCycles(dut.clk_pixel,10)

    dut.sw.value = 0
    await ClockCycles(dut.clk_pixel,100000)

    

    

def assembler_test_runner():
    """Simulate the Assembler using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "constants.sv",
        proj_path / "sim" / "assembler_test.sv",
        proj_path /'hdl'/"xilinx_true_dual_port_read_first_1_clock_ram.v",
        proj_path / "hdl" / "assembler.sv",
        proj_path / "hdl" / "counters.sv",
        proj_path / "hdl" / "immediate_interpreter.sv",
        proj_path / "hdl" / "register_interpreter.sv",
        proj_path / "hdl" / "instruction_interpreter.sv",
        proj_path / "hdl" / "label_controller.sv",
               ]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="assembler_test",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="assembler_test",
        test_module="test_assembler_test",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    # lines=[
    #     "addi r01, r00, x10",
    #     "sw r01, r00, x00"
    # ]
    # test_add_instruction_file()
    assembler_test_runner()