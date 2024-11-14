import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_a(dut):
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut._log.info("Holding reset...")
    dut.rst_in.value = 1
    dut.trigger_in.value = 0
    dut.data_byte_in.value = 0x3E #set in 8 bit input value
    await ClockCycles(dut.clk_in, 3) #wait three clock cycles
    await  FallingEdge(dut.clk_in)
    dut.rst_in.value = 0 #un reset device
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk_in)
    dut._log.info("Setting Trigger")
    dut.trigger_in.value = 1
    await ClockCycles(dut.clk_in, 1,rising=False)
    dut.data_byte_in.value = 0xAA # once trigger in is off, don't expect data_in to stay the same!!
    dut.trigger_in.value = 0
    await ClockCycles(dut.clk_in, 300)


def uart_transmit_runner():
    """Simulate the uart_transmit using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_transmit.sv", proj_path / "hdl" / "evt_counter.sv", proj_path / "hdl" / "cycle_counter.sv",]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 9600} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_transmit",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_transmit",
        test_module="test_uart_transmit",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_transmit_runner()