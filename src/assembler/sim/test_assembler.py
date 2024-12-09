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

from tests import *

class state:
    IDLE=0
    PC_MAPPING=1
    INSTRUCTION_MAPPING=2
    ERROR=3

class LineError(Exception):
    def __init__(self, line):
        self.line = line
        self.message = f'Assembly Error found on line {line}'
    def __str__(self):
        return self.message
    
class AssemblerController:
    def __init__(self, dut, test:Test):
        self.assembler = dut
        self.test = test

    async def __call__(self):
        print(f'Testing {self.test.name}')
        await self.setup()
        await self.error()
        await self.idle()
        await self.pc_mapping()
        await self.assembly()
        await self.idle()
        self.test.check_insts()

    async def setup(self):
        self.assembler._log.info("Starting...")
        cocotb.start_soon(Clock(self.assembler.clk_in, 10, units="ns").start())
        self.assembler._log.info("Holding reset...")
        self.assembler.rst_in.value = 1
        self.assembler.new_line.value = 0
        self.assembler.new_character.value = 0
        self.assembler.line_count.value = 0
        self.assembler.char_count.value = 0
        self.assembler.incoming_character.value = ord(" ")
        self.assembler.assembler_state.value = state.IDLE
        await ClockCycles(self.assembler.clk_in, 3) #wait three clock cycles
        await  FallingEdge(self.assembler.clk_in)
        self.assembler.rst_in.value = 0 #un reset device
        await ClockCycles(self.assembler.clk_in, 3) #wait a few clock cycles

    async def pc_mapping(self):
        print('TESTING PC_MAPPING')
        self.assembler.assembler_state.value = state.PC_MAPPING
        await self.send_buffer()


    async def assembly(self):
        print('TESTING INSTRUCTION_MAPPING')
        self.assembler.assembler_state.value = state.INSTRUCTION_MAPPING
        await self.send_buffer()

    async def idle(self):
        print('TESTING IDLE')
        self.assembler.assembler_state.value = state.IDLE
        await self.send_buffer()

    async def error(self):
        print('TESTING ERROR')
        self.assembler.assembler_state.value = state.ERROR
        await self.send_buffer()

    async def send_buffer(self):
        for line_index, line in enumerate(self.test.code):
            self.assembler.line_count.value = line_index
            await self.new_line()
            for char_index, char in enumerate(line):
                self.assembler.char_count.value = char_index
                await self.send_char(char)
                
                if self.assembler.error_flag.value:
                    self.test.check_error(line_index)

                if self.assembler.new_instruction.value:
                    self.test.add_inst(hex(self.assembler.instruction.value))
                
                if self.assembler.done_flag.value:
                    break

    async def send_char(self, char):
        # We send a character every other clock_cycle
        await FallingEdge(self.assembler.clk_in)
        self.assembler.new_character.value = 1
        self.assembler.incoming_character.value = ord(char)
        await ClockCycles(self.assembler.clk_in, 1)
        await FallingEdge(self.assembler.clk_in)
        self.assembler.new_character.value = 0
        if not await self.check_flags():
            self.assembler.new_character.value = 0
            await ClockCycles(self.assembler.clk_in, 1) # Double Period

    async def new_line(self):
        await FallingEdge(self.assembler.clk_in)
        self.assembler.new_line.value = 1
        await ClockCycles(self.assembler.clk_in, 1)
        await FallingEdge(self.assembler.clk_in)
        self.assembler.new_line.value = 0
        await ClockCycles(self.assembler.clk_in, 1) 
    
    async def check_flags(self):
        return self.assembler.done_flag.value or self.assembler.new_instruction.value or self.assembler.error_flag.value


@cocotb.test()
async def test(dut):
    for test in TESTS:
        assembler = AssemblerController(dut, test)
        await assembler()

def assembler_runner():
    """Simulate the Assembler using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "constants.sv",
        proj_path / "hdl" / "assembler.sv",
        proj_path / "hdl" / "counters.sv",
        proj_path / "hdl" / "immediate_interpreter.sv",
        proj_path / "hdl" / "register_interpreter.sv",
        proj_path / "hdl" / "instruction_interpreter.sv",
        proj_path / "hdl" / "label_controller.sv",
               ]
    build_test_args = ["-Wall"]
    parameters = {'CHAR_PER_LINE' : CHAR_PER_LINE, 'NUMBER_LINES' : NUM_LINES}
    sys.path.append(str(proj_path / "sim"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="assembler",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="assembler",
        test_module="test_assembler",
        test_args=run_test_args,
        waves=True
    )


if __name__ == "__main__":
    assembler_runner()