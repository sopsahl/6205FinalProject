###TEST FOR NEW MEMORY TYPE OPERATIONS with IMEM being a bram insteaf of reg######
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
 
 
@cocotb.test()
async def first_test(dut):
    """ First cocotb test?"""
    # write your test here!
	  # throughout your test, use "assert" statements to test for correct behavior
	  # replace the assertion below with useful statements
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value =1
    await ClockCycles(dut.clk,10)
    dut.rst.value =0
    await ClockCycles(dut.clk,100)


 
"""the code below should largely remain unchanged in structure, though the specific files and things
specified should get updated for different simulations.
"""
def counter_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [] #grow/modify this as needed.
    # sources += [proj_path / "hdl" / "character_sprites.sv"]
    # sources += [proj_path / "hdl" / "debouncer.sv"]
    # sources += [proj_path / "hdl" / "block_sprite.sv"]    
    # sources += [proj_path / "hdl" / "hdmi_clk_wiz_720p.v"]
    # sources += [proj_path / "hdl" / "terminal_controller.sv"]
    # sources += [proj_path / "hdl" / "tm_choice.sv"]
    # sources += [proj_path / "hdl" / "tmds_encoder.sv"]
    # sources += [proj_path / "hdl" / "tmds_serializer.sv"]
    # sources += [proj_path / "hdl" / "video_sig_gen.sv"]
    sources += [proj_path / "hdl" / "xilinx_single_port_ram_read_first.v"]
    # sources += [proj_path / "hdl" / "top_level.sv"]
    sources += [proj_path/"hdl"/ "assembler_emulator.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]


    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="assembler_emulator",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="assembler_emulator",
        test_module="test_counter",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    counter_runner()