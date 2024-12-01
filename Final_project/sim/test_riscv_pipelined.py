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

class RISCVInstruction:
    def R_type(opcode, funct3, funct7, rs1, rs2, rd):
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    def I_type(opcode, funct3, imm, rs1, rd):
       
        imm = imm & 0xFFF
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

    def S_type(opcode, funct3, imm, rs1, rs2):
        imm = imm & 0xFFF
        imm_11_5 = (imm >> 5) & 0x7F
        imm_4_0 = imm & 0x1F
        return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode
    @staticmethod
    def B_type(opcode, funct3, imm, rs1, rs2):
        imm = imm & 0x1FFE  
        imm_12 = (imm >> 12) & 0x1
        imm_11 = (imm >> 11) & 0x1
        imm_10_5 = (imm >> 5) & 0x3F
        imm_4_1 = (imm >> 1) & 0xF
        return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | \
               (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

    @staticmethod
    def U_type(opcode, imm, rd):
        return (imm & 0x000FFFFF)<< 12 | (rd << 7) | opcode

    @staticmethod
    def J_type(opcode, imm, rd):
        imm = imm & 0x1FFFFF  # 21-bit immediate
        imm_20 = (imm >> 20) & 0x1
        imm_10_1 = (imm >> 1) & 0x3FF
        imm_11 = (imm >> 11) & 0x1
        imm_19_12 = (imm >> 12) & 0xFF
        return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | \
               (imm_19_12 << 12) | (rd << 7) | opcode



def format_hex32(value):
    """Format 32-bit value as 8-digit hex string"""
    return f"{value & 0xFFFFFFFF:08x}"
 
async def test_jump_and_link(dut):
    REG_OP_CODE = 111
    IMM = 0x14
    REG_1 = 1

    value = RISCVInstruction.J_type(REG_OP_CODE, IMM, REG_1)
    value = format_hex32(value)
    instructions = [value,format_hex32(10201001),format_hex32(0),
                    format_hex32(0),format_hex32(0),format_hex32(RISCVInstruction.I_type(
                         19, 0, 4, 0, 3)
                    )]
    with open("../data/instructionMem.mem", "w") as f:
        for i in instructions:
            f.write(str(i) + "\n")

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x1
    # print(hex(RISCVInstruction.J_type(REG_OP_CODE, IMM, REG_1)))
    # print(hex(RISCVInstruction.I_type(19, 0, 4, 0, 3)))
    # dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def J_type(opcode, imm, rd):

    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 35)
    await RisingEdge(dut.clk)
    # assert hex(dut.pc.value) == hex(0x14)

    # await ClockCycles(dut.clk, 1)
    # await RisingEdge(dut.clk)
    assert hex(dut.registers[1].value) == hex(4)
async def test_add_sequence(dut):
    instructions = [
        # addi x1, x0, 5    # opcode=0010011 (ADDI), rd=1, rs1=0, imm=5
        RISCVInstruction.I_type(19, 0, 5, 0, 1),  
        
        # addi x2, x0, 10   # opcode=0010011 (ADDI), rd=2, rs1=0, imm=10
        RISCVInstruction.I_type(19, 0, 10, 0, 2),

        format_hex32(0),  # nop
        format_hex32(0),  # nop
        format_hex32(0),  # nop
        format_hex32(0),  # nop
        
        # add x3, x1, x2    # opcode=0110011 (ADD), rd=3, rs1=1, rs2=2
        RISCVInstruction.R_type(51, 0, 0, 1, 2, 3)
    ]

    # Convert to hex format
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 18)
    assert hex(dut.registers[3].value) == hex(15)
async def test_sub_sequence(dut):
    instructions = [
        # addi x1, x0, 5    # opcode=0010011 (ADDI), rd=1, rs1=0, imm=5
        RISCVInstruction.I_type(19, 0, 5, 0, 1),  
        
        # addi x2, x0, 10   # opcode=0010011 (ADDI), rd=2, rs1=0, imm=10
        RISCVInstruction.I_type(19, 0, 10, 0, 2),

        0,  # nop
        0,  # nop
        0,  # nop
        0,  # nop

        # sub x3, x2, x1    # opcode=0110011 (SUB), rd=3, rs1=2, rs2=1
        RISCVInstruction.R_type(51, 0, 32, 2, 1, 3)

    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0

    dut.registers[1].value = 4
    dut.dmem[4].value = 10
    dut.ending_pc.value = 0x1c
    await ClockCycles(dut.clk, 1)
    print(dut.dmem[4].value, dut.registers[1].value)
    await RisingEdge(dut.instruction_done)
    assert hex(dut.registers[3].value) == hex(5)
async def test_load(dut):
    #THIS FUCKING abommination of a framework just doesn't work sometimes 
    instructions = [
        # addi x1, x0, 4    # opcode=0010011 (ADDI), rd=1, rs1=0, imm=4
        # lw x3, 0(x1)    # opcode=0000011 (LW), rd=3, rs1=1, imm=0
        RISCVInstruction.I_type(3, 2, 0, 1, 3),
        0,  # nop


    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0

    dut.dmem[4].value = 10
    dut.registers[1].value = 4
    
    dut.ending_pc.value = 0x60
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done) 
    assert hex(dut.registers[3].value) == hex(10)

    # Write to memory file

   

@cocotb.test()
async def test_ALU_operations(dut):
    """Test ALU operations"""
    dut._log.info("Starting ALU tests...")
    



    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # await test_sub_sequence(dut)
    await test_load(dut)
    #timing issues

   
         



  



    

   



   
def ALU_runner():
    """Simulate the ALU using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "riscv_processor.sv"]
    sources += [proj_path / "hdl" / "project_helpers.sv"]
    sources+= [proj_path / "hdl" / "control_unit.sv"]
    sources += [proj_path / "hdl" / "ALU.sv"]
    sources += [proj_path / "hdl" / "xilinx_single_port_ram_read_first.v"]
    sources += [proj_path / "hdl" / "mem_ctrl_unit.sv"]
    sources += [proj_path / "hdl" / "branch_unit.sv"]
    # sources += [proj_path / "data" / "instructionMem.mem"]
    build_test_args = ["-Wall"]
    # build_test_args.append(f"+readmemh={str(proj_path / 'data' / 'instructionMem.mem')}")
    # build_test_args.append(f"+readmemh={str(proj_path / 'data' / 'instructionMem.mem')}")

    parameters = {}
    sys.path.append(str(proj_path / "sim"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="riscv_processor",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="riscv_processor",
        test_module="test_riscv_pipelined",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    ALU_runner()