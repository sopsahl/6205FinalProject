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


from tests import TESTS, AssemblyController

class state:
    IDLE=0
    PC_MAPPING=1
    INSTRUCTION_MAPPING=2
    ERROR=3
    
class AssemblerController:
    def __init__(self, dut, test:AssemblyController):
        self.assembler = dut
        self.test = test

        self.line_count = 0
        self.char_count = 0

    async def __call__(self):
        print(f'Testing {self.test.name}')
        await self.setup()
        try:
            await self.pc_mapping()
            await self.assembly()
            await self.aftermath()
        except Exception as e: 
            print(f'Assembly aborted for {e}')
            self.test.check_error(self.line_count)

        self.test.check_insts()


    async def setup(self):
        self.assembler._log.info("Starting...")
        cocotb.start_soon(Clock(self.assembler.clk_in, 10, units="ns").start())
        self.assembler._log.info("Holding reset...")
        self.assembler.rst_in.value = 1
        self.assembler.new_line.value = 0
        self.assembler.new_character.value = 0
        self.assembler.line_count.value = self.line_count
        self.assembler.char_count.value = self.char_count
        self.assembler.incoming_character.value = ord(" ")
        self.assembler.assembler_state.value = state.IDLE
        await ClockCycles(self.assembler.clk_in, 3) #wait three clock cycles
        await  FallingEdge(self.assembler.clk_in)
        self.assembler.rst_in.value = 0 #un reset device
        await ClockCycles(self.assembler.clk_in, 3) #wait a few clock cycles
        await  FallingEdge(self.assembler.clk_in)

    async def pc_mapping(self):
        pass

    async def assembly(self):
        pass

    async def aftermath(self):
        pass

    async def send_char(self, char, line_count, char_count):
        self.assembler.new_character = 1
        self.assembler.incoming_character = char
        # self.assembler.



@cocotb.test()
async def test(dut):
    for test in TESTS:
        assembler = AssemblerController(dut, test)
        await assembler()

def assembler_runner():
    """Simulate the ALU using the Python runner."""
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
    parameters = {}
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