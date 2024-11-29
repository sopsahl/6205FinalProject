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

@cocotb.test()
async def test_RegisterFile_operations(dut):
    """Test RegisterFile operations"""
    dut._log.info("Starting RegisterFile tests...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await RisingEdge(dut.clk)

    # Reset the register file
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # Write to register 1
    dut.we.value = 1
    dut.rd.value = 1
    dut.wd.value = 42
    await RisingEdge(dut.clk)
    dut.we.value = 0

    # Read from register 1
    dut.rs1.value = 1
    await RisingEdge(dut.clk)
    assert dut.rd1.value == 42, f"Read data from register 1 is incorrect: {dut.rd1.value} != 42"

    # Write to register 2
    dut.we.value = 1
    dut.rd.value = 2
    dut.wd.value = 84
    await RisingEdge(dut.clk)
    dut.we.value = 0

    # Read from register 2
    dut.rs2.value = 2
    await RisingEdge(dut.clk)
    assert dut.rd2.value == 84, f"Read data from register 2 is incorrect: {dut.rd2.value} != 84"

    # Test write enable
    dut.we.value = 0
    dut.rd.value = 3
    dut.wd.value = 128
    await RisingEdge(dut.clk)
    dut.rs1.value = 3
    await RisingEdge(dut.clk)
    assert dut.rd1.value == 0, f"Write enable test failed: {dut.rd1.value} != 0"

def RegisterFile_runner():
    """Simulate the RegisterFile using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "RegisterFile.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="RegisterFile",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="RegisterFile",
        test_module="test_RegisterFile",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    RegisterFile_runner()