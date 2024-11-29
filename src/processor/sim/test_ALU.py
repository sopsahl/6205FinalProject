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
async def test_ALU_operations(dut):
    """Test ALU operations"""
    dut._log.info("Starting ALU tests...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    await ClockCycles(dut.clk_in,3)
    await RisingEdge(dut.clk_in)

    # Test addition
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 0 
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == 15, f"Addition result is incorrect: {dut.result.value} != 15"

    # Test subtraction
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 1 
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == 5, f"Subtraction result is incorrect: {dut.result.value} != 5"

    # Test AND
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 2  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (10 & 5), f"AND result is incorrect: {dut.result.value} != {10 & 5}"

    # Test OR
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 3      
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (10 | 5), f"OR result is incorrect: {dut.result.value} != {10 | 5}"

    # Test XOR
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 4  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (10 ^ 5), f"XOR result is incorrect: {dut.result.value} != {10 ^ 5}"

    # Test SLL
    dut.a.value = 10
    dut.b.value = 1
    dut.alu_ctrl.value = 5  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (10 << 1), f"SLL result is incorrect: {dut.result.value} != {10 << 1}"

    # Test SRL
    dut.a.value = 10
    dut.b.value = 1
    dut.alu_ctrl.value = 6  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (10 >> 1), f"SRL result is incorrect: {dut.result.value} != {10 >> 1}"

    # Test SRA
    dut.a.value = -1
    dut.b.value = 1
    dut.alu_ctrl.value = 7  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    # ffffff>1 arithmetic is still fffffff
    print(hex(dut.result.value))
    print(hex(dut.result.value),"results")
    assert bin(dut.result.value) == bin(0xffffffff), f"SRA result is incorrect: {dut.result.value} != {bin(0xffffffff)}"

    # Test SLT
    dut.a.value = 10
    dut.b.value = 5
    dut.alu_ctrl.value = 8  
    await RisingEdge(dut.clk_in)
    await ClockCycles(dut.clk_in,1)
    assert dut.result.value == (1 if 10 < 5 else 0), f"SLT result is incorrect: {dut.result.value} != {1 if 10 < 5 else 0}"

def ALU_runner():
    """Simulate the ALU using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "ALU.sv"]
    sources +=[proj_path/"hdl"/"alu_constants.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="ALU",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="ALU",
        test_module="test_ALU",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    ALU_runner()