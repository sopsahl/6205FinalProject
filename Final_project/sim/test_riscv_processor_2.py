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




async def test_add_operation(dut):
        REG_OP_CODE=51
        FUNC_3=0
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=10
        dut.registers[2].value=5
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(15)  
async def test_sub_operation(dut):
        REG_OP_CODE=51
        FUNC_3=0
        FUNC_7=32
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=7
        dut.registers[2].value=5
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(2)
async def test_xor_operation(dut):
        REG_OP_CODE=51
        FUNC_3=4
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=10
        dut.registers[2].value=5
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(15)
async def test_or_operation(dut):
        REG_OP_CODE=51
        FUNC_3=6
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        dut.registers[1].value=1
        dut.registers[2].value=9
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(9)
async def test_and_operation(dut):
        REG_OP_CODE=51
        FUNC_3=7
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        dut.registers[1].value=1
        dut.registers[2].value=9
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(1)
async def test_sll_operation(dut):
        REG_OP_CODE=51
        FUNC_3=1
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        dut.registers[1].value=1
        dut.registers[2].value=3
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(8)
async def test_srl_operation(dut):
        REG_OP_CODE=51
        FUNC_3=5
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        dut.registers[1].value=8
        dut.registers[2].value=2
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(2)
async def test_sra_operation(dut):
        REG_OP_CODE=51
        FUNC_3=5
        FUNC_7=0x20
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=0xFFFFFFFF
        dut.registers[2].value=4
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value)== hex(0xFFFFFFFF)
async def test_slt_operation(dut):
        REG_OP_CODE=51
        FUNC_3=2
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value= -8
        dut.registers[2].value=2
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(1)
async def test_sltu_operation(dut):
        REG_OP_CODE=51
        FUNC_3=3
        FUNC_7=0
        REG_1=1
        REG_2=2
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=-8
        dut.registers[2].value=2
        dut.imem[0].value=RISCVInstruction.R_type(REG_OP_CODE,FUNC_3,FUNC_7,REG_1,REG_2,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(0)
async def test_addi_operation(dut):
        REG_OP_CODE=19
        FUNC_3=0
        IMM=10
        REG_1=1
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=10
        dut.imem[0].value=RISCVInstruction.I_type(REG_OP_CODE,FUNC_3,IMM,REG_1,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(20)
async def test_xori_operation(dut):
        REG_OP_CODE=19
        FUNC_3=4
        IMM=10
        REG_1=1
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=5
        dut.imem[0].value=RISCVInstruction.I_type(REG_OP_CODE,FUNC_3,IMM,REG_1,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(15)
async def test_andi_operation(dut):
        REG_OP_CODE=19
        FUNC_3=7
        IMM=1
        REG_1=1
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=0
        dut.imem[0].value=RISCVInstruction.I_type(REG_OP_CODE,FUNC_3,IMM,REG_1,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(0)
async def test_ori_operation(dut):
        REG_OP_CODE=19
        FUNC_3=6
        IMM=8
        REG_1=1
        DEST_REG=3
        dut.rst.value = 1
        await ClockCycles(dut.clk,1)
        dut.rst.value = 0
        await ClockCycles(dut.clk,1)
        await FallingEdge(dut.clk)
        #inverted
        dut.registers[1].value=1
        dut.imem[0].value=RISCVInstruction.I_type(REG_OP_CODE,FUNC_3,IMM,REG_1,DEST_REG)
        await ClockCycles(dut.clk,1)
        await RisingEdge(dut.clk)
        assert hex(dut.registers[3].value) == hex(9)
async def test_slli_operation(dut):
    REG_OP_CODE = 19
    FUNC_3 = 1
    IMM = 2
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 1

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    # Wait for a clock cycle
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert hex(dut.registers[DEST_REG].value)== hex(4)

async def test_srli_operation(dut):
    REG_OP_CODE = 19
    FUNC_3 = 5
    IMM = 1
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 8

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert hex(dut.registers[DEST_REG].value) == hex(4)

async def test_srai_operation(dut):
    REG_OP_CODE = 19
    FUNC_3 = 5
    FUNC_7 = 0x20
    IMM = 38 #needs to be imm[5:11] = 0x20 , soo 32 + 6  so shift 6 spots, 38 in hex is 0x26 which is in binary 
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 0xFFFFFFFF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert hex(dut.registers[DEST_REG].value)== hex(0xFFFFFFFF)

async def test_slti_operation(dut):
    REG_OP_CODE = 19
    FUNC_3 = 2
    IMM = 2
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = -3

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

 
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert hex(dut.registers[DEST_REG].value) == hex(1)

async def test_sltiu_operation(dut):
    REG_OP_CODE = 19
    FUNC_3 = 3
    IMM = 2
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = -3

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert hex(dut.registers[DEST_REG].value) == hex(0)
async def test_load_byte(dut):
    REG_OP_CODE = 3
    FUNC_3 = 0
    IMM = 2
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.dmem[40].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    print((dut.registers[DEST_REG].value))
    print(dut.registers[REG_1].value)
    await ClockCycles(dut.clk, 1)
    assert (hex(dut.registers[DEST_REG].value))== hex(0xffffffad)#expecting 0xfffffad
async def test_load_half(dut):
    REG_OP_CODE = 3
    FUNC_3 = 1
    IMM = 1
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.dmem[40].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    print(hex(dut.registers[DEST_REG].value))#expecting 0xFFFFDEAD
async def test_load_word(dut):
    REG_OP_CODE = 3
    FUNC_3 = 2
    IMM = 1
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.dmem[40].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    print(hex(dut.registers[DEST_REG].value))#expecting 0xDEADBEEF
      
async def test_load_byte_unsigned(dut):
    REG_OP_CODE = 3
    FUNC_3 = 4
    IMM = 1
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.dmem[40].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert (hex(dut.registers[DEST_REG].value)) == hex(0x000000BE)#expecting 
async def test_load_half_unsigned(dut):
    REG_OP_CODE = 3
    FUNC_3 = 5
    IMM = 1
    REG_1 = 1
    DEST_REG = 3

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)

    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.dmem[40].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, FUNC_3, IMM, REG_1, DEST_REG)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert (hex(dut.registers[DEST_REG].value)) == hex(0xbeef)
async def test_store_byte(dut):
    REG_OP_CODE = 35
    FUNC_3 = 0
    IMM =0
    REG_1 = 1
    REG_2 = 2

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.dmem[40].value = 0x00000000
    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.registers[REG_2].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.S_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert (hex(dut.dmem[40].value)) == hex(0xef)#expecting 0xef
async def test_store_half(dut):
    REG_OP_CODE = 35
    FUNC_3 = 1
    IMM =0
    REG_1 = 1
    REG_2 = 2

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.dmem[40].value = 0x00000000
    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.registers[REG_2].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.S_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    await ClockCycles(dut.clk, 8)
    assert (hex(dut.dmem[40].value)) == hex(0xBEEF)#expecting 0xBEEF
async def test_store_word(dut):
    REG_OP_CODE = 35
    FUNC_3 = 2
    IMM =0
    REG_1 = 1
    REG_2 = 2

    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.dmem[40].value = 0x00000000
    dut.registers[REG_1].value = 40#memory location 40 base 
    dut.registers[REG_2].value = 0xDEADBEEF

    dut.imem[0].value = RISCVInstruction.S_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)

    assert (hex(dut.dmem[40].value)) == hex(0xDEADBEEF)#expecting 0xDEADBEEF
      
async def test_ALU(dut):
    await test_add_operation(dut)
    await test_sub_operation(dut)
    await test_xor_operation(dut)
    await test_or_operation(dut)
    await test_and_operation(dut)
    await test_sll_operation(dut)
    await test_srl_operation(dut)
    await test_sra_operation(dut)
    await test_slt_operation(dut)
    await test_sltu_operation(dut)
    await test_addi_operation(dut)
    await test_xori_operation(dut)
    await test_andi_operation(dut)
    await test_ori_operation(dut)
    await test_slli_operation(dut)
    await test_srli_operation(dut)
    await test_srai_operation(dut)
    await test_slti_operation(dut)
    await test_sltiu_operation(dut)
async def test_load(dut):
    await test_load_byte(dut)
    await test_load_half(dut)
    await test_load_word(dut)
    await test_load_byte_unsigned(dut)
    await test_load_half_unsigned(dut)
async def test_store(dut):
    await test_store_byte(dut)
    await test_store_half(dut)
    await test_store_word(dut)
async def test_branch_equal(dut):
    REG_OP_CODE = 99
    FUNC_3 = 0
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x1
    dut.registers[REG_2].value = 0x1
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value) == hex(4)
async def test_branch_not_equal(dut):
    REG_OP_CODE = 99
    FUNC_3 = 1
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x1
    dut.registers[REG_2].value = 0x2
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value) == hex(4)
async def test_branch_less_than(dut):
    REG_OP_CODE = 99
    FUNC_3 = 4
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x1
    dut.registers[REG_2].value = 0x2
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value)== hex(4)
async def test_branch_greater_than_equalTo(dut):
    REG_OP_CODE = 99
    FUNC_3 = 5
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x2
    dut.registers[REG_2].value = 0x1
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value)== hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value) == hex(4)
async def test_branch_less_than_unsigned(dut):
    REG_OP_CODE = 99
    FUNC_3 = 6
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 1
    dut.registers[REG_2].value = 22
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value) == hex(4)
async def test_branch_greater_than_equalTo_unsigned(dut):
    REG_OP_CODE = 99
    FUNC_3 = 7
    IMM = 0x14
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 22
    dut.registers[REG_2].value = 1
    dut.imem[0].value = RISCVInstruction.B_type(REG_OP_CODE, FUNC_3, IMM, REG_1, REG_2)
    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[3].value) == hex(4)
async def test_branch(dut):
    await test_branch_equal(dut)
    await test_branch_not_equal(dut)
    await test_branch_less_than(dut)
    await test_branch_greater_than_equalTo(dut)
    await test_branch_less_than_unsigned(dut)
    await test_branch_greater_than_equalTo_unsigned(dut)  
async def test_jump_and_link(dut):
    REG_OP_CODE = 111
    IMM = 0x14
    REG_1 = 1
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 0x1
    # print(hex(RISCVInstruction.J_type(REG_OP_CODE, IMM, REG_1)))
    # print(hex(RISCVInstruction.I_type(19, 0, 4, 0, 3)))
    dut.imem[0].value = RISCVInstruction.J_type(REG_OP_CODE, IMM, REG_1)
    #    def J_type(opcode, imm, rd):

    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4

    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value) == hex(0x14)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[1].value) == hex(4)
async def test_jump_and_link_register(dut):
    REG_OP_CODE = 103
    IMM = 10
    REG_1 = 1
    REG_2 = 2
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.registers[REG_1].value = 10
    dut.imem[0].value = RISCVInstruction.I_type(REG_OP_CODE, 0, IMM, REG_1, REG_2)
    #    def I_type(opcode, funct3, imm, rs1, rd):

    dut.imem[20].value = RISCVInstruction.I_type(19, 0, 4, 0, 3)#addi x3,x0,4
    #    def I_type(opcode, funct3, imm, rs1, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.pc.value)== hex(0x14)

    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(dut.registers[2].value) == hex(4)
async def test_lui(dut):
    REG_OP_CODE = 55
    IMM = 1
    DST_REG = 1
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.imem[0].value = RISCVInstruction.U_type(REG_OP_CODE, IMM, DST_REG)
    #    def U_type(opcode, imm, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(int(dut.registers[1].value)) == hex(0x1000)#should be 1<<12 = 0x1000
async def test_auipc(dut):
    REG_OP_CODE = 23
    IMM = 1
    DST_REG = 1
    # Apply reset
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await FallingEdge(dut.clk)
    dut.imem[0].value = RISCVInstruction.U_type(REG_OP_CODE, IMM, DST_REG)
    #    def U_type(opcode, imm, rd):
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.clk)
    assert hex(int(dut.registers[1].value)) == hex(0x1000)#should be 1<<12 = 0x1000
async def test_u_type(dut):
    await test_lui(dut)
    await test_auipc(dut)
@cocotb.test()
async def test_ALU_operations(dut):
    """Test ALU operations"""
    dut._log.info("Starting ALU tests...")
    



    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    #timing issues

    # await test_jump_and_link(dut)
    # await test_jump_and_link_register(dut)
    # await test_u_type(dut)
    # await test_ALU(dut)
    dut.rst.value = 1
    await ClockCycles(dut.clk,1)
    dut.rst.value = 0

    await test_load_byte(dut)
    # await test_jump_and_link(dut)
    # await test_store_half(dut)
    # await ClockCycles(dut.clk,20)
    # await test_load(dut)
    # await test_store(dut)
    # await test_branch(dut)
    # write me a command that adds 10 to register 0 and stores it in register 2
    # write me a command that adds 15 to register 0 and stores it in register 3
    #write me a command that addes register 2 and 3 and stores it in 4 
     
                 
         



  



    

   



   
def ALU_runner():
    """Simulate the ALU using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "working_riscv_processor.sv"]
    sources += [proj_path / "hdl" / "project_helpers.sv"]
    sources+= [proj_path / "hdl" / "control_unit.sv"]
    sources += [proj_path / "hdl" / "ALU.sv"]
    sources += [proj_path / "hdl" / "xilinx_single_port_ram_read_first.v"]
    # sources += [proj_path / "data" / "instructionMem.mem"]
    build_test_args = ["-Wall"]
    # build_test_args.append(f"+readmemh={str(proj_path / 'data' / 'instructionMem.mem')}")
    # build_test_args.append(f"+readmemh={str(proj_path / 'data' / 'instructionMem.mem')}")

    parameters = {}
    sys.path.append(str(proj_path / "sim"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="working_riscv_processor",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="working_riscv_processor",
        test_module="test_riscv_processor_2",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    ALU_runner()