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
    dut.rx_wire_in.value = 1
    data_byte_in = 0x3E #set in 8 bit input value
    await ClockCycles(dut.clk_in, 3) #wait three clock cycles
    await  FallingEdge(dut.clk_in)
    dut.rst_in.value = 0 #un reset device
    await ClockCycles(dut.clk_in, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk_in)
    dut._log.info("Setting Trigger")
    dut.rx_wire_in.value = 0
    await ClockCycles(dut.clk_in, 3, rising=False)
    for bit in [0, 1, 1, 1, 0, 1, 1, 0]:
        dut.rx_wire_in.value = bit
        await ClockCycles(dut.clk_in, 3, rising=False)
    dut.rx_wire_in.value = 1
    await FallingEdge(dut.clk_in)
    



def uart_receive_runner():
    """Simulate the uart_receive using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv", proj_path / "hdl" / "evt_counter.sv", proj_path / "hdl" / "cycle_counter.sv",]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ' : 100, 'BAUD_RATE': 10} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_receive",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_receive",
        test_module="test_uart_receive",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    uart_receive_runner()