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
    print(hex(dut.registers[3].value))
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
        # RISCVInstruction.I_type(19, 0, 4, 0, 1),
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
    dut.registers[1].value = 4  

    # dut.dmem[4].value = 10
    
    dut.ending_pc.value = 0x4
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done) 
    assert hex(dut.registers[3].value) == hex(0xdeadbeef)

    # Write to memory file
async def test_store(dut):
    instructions = [
        # addi x1, x0, 8    # opcode=0010011 (ADDI), rd=1, rs1=0, imm=4
        RISCVInstruction.I_type(19, 0, 0x8, 0, 1),
        0,
        0,
        0,
        0,
        # sw x1, 0(x0)    # opcode=0100011 (SW), rs1=1, rs2=0, imm=0
        RISCVInstruction.S_type(35, 2, 0, 0, 1),
        0,
        0,  # nop
        0,  # nop
        0,  # nop
        0,  # nop
        #load x3, 0(x0)    # opcode=0000011 (LW), rd=3, rs1=0, imm=0
        RISCVInstruction.I_type(3, 2, 0, 0, 3),
        0,
        0
    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    dut.ending_pc.value = 60
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done)
    # print(hex(dut.registers[1].value))

    assert hex(dut.registers[3].value) == hex(0x8)
    #works 
async def test_RAW_hazard(dut):
    instructions = [
        # addi x1, x0, 4    # opcode=0010011 (ADDI), rd=1, rs1=0, imm=4
        RISCVInstruction.I_type(19, 0, 4, 0, 1),
        # addi x2, x0, 10   # opcode=0010011 (ADDI), rd=2, rs1=0, imm=10
        RISCVInstruction.I_type(19, 0, 10, 0, 2),
        # add x3, x1, x2    # opcode=0110011 (ADD), rd=3, rs1=1, rs2=2 should be 14
        RISCVInstruction.R_type(51, 0, 0, 1, 2, 3),
        # sub x4, x3, x1    # opcode=0110011 (SUB), rd=4, rs1=3, rs2=1  should be 10
        RISCVInstruction.R_type(51, 0, 32, 3, 1, 4),
        0xDEADBEEF,

    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    # dut.ending_pc.value = 16
    # await ClockCycles(dut.clk, 20)
    # await RisingEdge(dut.instruction_done)
    await ClockCycles(dut.clk, 100)
    assert hex(dut.registers[4].value) == hex(10)
    assert(hex(dut.registers[3].value) == hex(14))
    #works
async def test_load_use_hazard(dut):
    instructions = [
        RISCVInstruction.I_type(3, 2, 4, 0, 1),     # lw x1, 4(x0)
        RISCVInstruction.R_type(51, 0, 0, 1, 2, 3)  # add x3, x1, x2  # Use after load
    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    dut.ending_pc.value = 0x4
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done)
    print(hex(dut.registers[3].value))


async def test_memory_hazard(dut):
    instructions = [
        RISCVInstruction.I_type(19, 0, 100, 0, 1),
        RISCVInstruction.S_type(35, 2, 0, 0, 1),    # sw x1, 0(x0)
        RISCVInstruction.I_type(3, 2, 0, 0, 2)      # lw x2, 0(x0)    # Load after store
    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    dut.registers[1].value = 0xbeefeeef
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    dut.ending_pc.value = 0x8
    # await ClockCycles(dut.clk, 14)
    await RisingEdge(dut.instruction_done)
    assert hex(dut.registers[2].value) == hex(100)
async def test_negative_alu(dut):
    instructions = [
        RISCVInstruction.I_type(19, 0, 100, 0, 1),  # addi x1, x0, 100
        RISCVInstruction.I_type(19, 0, 200, 0, 2),  # addi x2, x0, 200
        RISCVInstruction.R_type(51, 0, 0, 1, 2, 3),  # add x3, x1, x2
        #addi -1 x3 
        RISCVInstruction.I_type(19, 0, -1, 3, 4)
    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    dut.ending_pc.value = 0x10
    await RisingEdge(dut.instruction_done)
    print(int(dut.registers[4].value))

async def test_mixed_hazards(dut):
    instructions = [
        RISCVInstruction.I_type(19, 0, 100, 0, 1),  # addi x1, x0, 100
        RISCVInstruction.I_type(19, 0, 200, 0, 2),  # addi x2, x0, 200
        RISCVInstruction.S_type(35, 2, 0, 0, 1),    # sw x1, 0(x0) #RAW 
        RISCVInstruction.I_type(3, 2, 0, 0, 3),      # lw x3, 0(x0)    # Load after store
        RISCVInstruction.R_type(51, 0, 0, 1, 2, 4),  # add x4, x1, x2  # Use after load
        0,0,0,0,0,0,0

    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    dut.registers[1].value = 0xbeefeeef
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    # dut.ending_pc.value = 0x10
    await ClockCycles(dut.clk, 1)
    # await RisingEdge(dut.instruction_done)
    await ClockCycles(dut.clk, 1000)
    assert hex(dut.registers[3].value) == hex(100)
    assert hex(dut.registers[4].value) == hex(300)
async def bubble_sort_sim(dut):
    instructions = [
        #addi x10, x0, 0
        #pc:0
        RISCVInstruction.I_type(19, 0, 0, 0, 10),
        #pc:4
        #addi x11, x0,10
        RISCVInstruction.I_type(19, 0, 10, 0, 11),
        #pc:8
        #addi x14, x0, 5
        RISCVInstruction.I_type(19, 0, 5, 0, 14),
        #pc:12
        #sw x14, 0(x10)
        RISCVInstruction.S_type(35, 2, 0, 10, 14),
        #pc:16
        #addi x14, x0, 1
        RISCVInstruction.I_type(19, 0, 1, 0, 14),
        #pc:20
        #addi x17, x10, 4
        RISCVInstruction.I_type(19, 0, 4, 10, 17),
        #pc:24
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:28
        #addi x14, x0, 4
        RISCVInstruction.I_type(19, 0, 4, 0, 14),
        #pc:32
        #addi x17, x10, 8
        RISCVInstruction.I_type(19, 0, 8, 10, 17),
        #pc:36
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:40
        #addi x14, x0, 2
        RISCVInstruction.I_type(19, 0, 2, 0, 14),
        #pc:44
        #addi x17, x10, 12
        RISCVInstruction.I_type(19, 0, 12, 10, 17),
        #pc:48
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:52
        #addi x14, x0, 8
        RISCVInstruction.I_type(19, 0, 8, 0, 14),
        #pc:56
        #addi x17, x10, 16
        RISCVInstruction.I_type(19, 0, 16, 10, 17),
        #pc:60
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:64
        #addi x14, x0, 0
        RISCVInstruction.I_type(19, 0, 0, 0, 14),
        #pc:68
        #addi x17, x10, 20
        RISCVInstruction.I_type(19, 0, 20, 10, 17),
        #pc:72
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:76
        #addi x14, x0, 2
        RISCVInstruction.I_type(19, 0, 2, 0, 14),
        #pc:80
        #addi x17, x10, 24
        RISCVInstruction.I_type(19, 0, 24, 10, 17),
        #pc:84
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:88
        #addi x14, x0, 3
        RISCVInstruction.I_type(19, 0, 3, 0, 14),
        #pc:92
        #addi x17, x10, 28
        RISCVInstruction.I_type(19, 0, 28, 10, 17),
        #pc:96
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:100
        #addi x14, x0, 7
        RISCVInstruction.I_type(19, 0, 7, 0, 14),
        #pc:104
        #addi x17, x10, 32
        RISCVInstruction.I_type(19, 0, 32, 10, 17),
        #pc:108
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:112
        #addi x14, x0, 6
        RISCVInstruction.I_type(19, 0, 6, 0, 14),
        #pc:116
        #addi x17, x10, 36
        RISCVInstruction.I_type(19, 0, 36, 10, 17),
        #pc:120
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:124
        #addi x12, x0, 0
        RISCVInstruction.I_type(19, 0, 0, 0, 12),
        #pc:128
        #addi x31, x11, -1
        RISCVInstruction.I_type(19, 0, -1, 11, 31),
        #pc:132
        #bge x12, x31, 92
        RISCVInstruction.B_type(99, 5, 92, 12, 31),
        #pc:136
        #addi x13, x0, 0
        RISCVInstruction.I_type(19, 0, 0, 0, 13),
        #pc:140
        #sub x31, x11, x12
        RISCVInstruction.R_type(51, 0, 0x20, 11, 12, 31),
        #pc:144
        #addi x31, x31, -1
        RISCVInstruction.I_type(19, 0, -1, 31, 31),
        #pc:148
        #bge x13, x31, 68
        RISCVInstruction.B_type(99, 5, 68, 13, 31),
        #pc:152
        #slli x16, x13, 2
        RISCVInstruction.I_type(19, 1, 2, 13, 16),
        #pc:156
        #add x17, x10, x16
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        #pc:160
        #lw x14, 0(x17)
        RISCVInstruction.I_type(3, 2, 0, 17, 14),
        #pc:164
        #addi x18,x13,1
        RISCVInstruction.I_type(19, 0, 1, 13, 18),
        #pc:168
        #slli x16, x18, 2
        RISCVInstruction.I_type(19, 1, 2, 18, 16),
        #pc:172
        #add x17, x10, x16
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        #pc:176
        #lw x15, 0(x17)
        RISCVInstruction.I_type(3, 2, 0, 17, 15),
        #pc:180
        #blt x14, x15, 28
        RISCVInstruction.B_type(99, 4, 28, 14, 15),
        #pc:184
        #slli x16, x13, 2
        RISCVInstruction.I_type(19, 1, 2, 13, 16),
        #pc:188
        #add x17, x10, x16
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        #pc:192
        #sw x15, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 15),
        #pc:196
        #slli x16, x18, 2
        RISCVInstruction.I_type(19, 1, 2, 18, 16),
        #pc:200
        #add x17, x10, x16
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        #pc:204
        #sw x14, 0(x17)
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        #pc:208
        #addi x13, x13, 1
        RISCVInstruction.I_type(19, 0, 1, 13, 13),
        #pc:212
        #jal x0,-72
        RISCVInstruction.J_type(111, -72, 0),
        #pc:216
        #addi x12, x12, 1
        RISCVInstruction.I_type(19, 0, 1, 12, 12),
        #pc:220
        #jal x0,-92
        RISCVInstruction.J_type(111, -92, 0),
        #pc:224
        0,


    # # ProgramEnd equivalent
    # # PC: 224
    # # Sorting is complete
    # # The sorted array is stored in memory st7arting at base_addr


    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    # dut.ending_pc.value = 224
    dut.ending_pc.value =224
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done)
    await ClockCycles(dut.clk, 200000)
    
    
async def mini_bubsort(dut):
    instructions = [

        # # PC: 0
        # addi x10, x0, 0        # x10 = base_addr = 0
        RISCVInstruction.I_type(19, 0, 0, 0, 10),


        # # PC: 4
        # addi x11, x0, 3        # x11 = n = 3 (array size)
        RISCVInstruction.I_type(19, 0, 3, 0, 11),

        # # Initialize the array with values

        # # Element 0
        # # PC: 8
        # addi x14, x0, 5        # x14 = 5
        RISCVInstruction.I_type(19, 0, 5, 0, 14),

        # # PC: 12
        # sw   x14, 0(x10)       # Store 5 at M[base_addr + 0]
        RISCVInstruction.S_type(35, 2, 0, 10, 14),
        # # Element 1
        # # PC: 16
        # addi x14, x0, 2        # x14 = 2
        RISCVInstruction.I_type(19, 0, 2, 0, 14),
        # # PC: 20
        # addi x17, x10, 4       # x17 = base_addr + 4
        RISCVInstruction.I_type(19, 0, 4, 10, 17),
        # # PC: 24
        # sw   x14, 0(x17)       # Store 2 at M[base_addr + 4]
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        # # Element 2
        # # PC: 28
        # addi x14, x0, 8        # x14 = 8
        RISCVInstruction.I_type(19, 0, 8, 0, 14),
        # # PC: 32
        # addi x17, x10, 8       # x17 = base_addr + 8
        RISCVInstruction.I_type(19, 0, 8, 10, 17),
        # # PC: 36
        # sw   x14, 0(x17)       # Store 8 at M[base_addr + 8]
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        # # Bubble Sort Algorithm

        # # PC: 40
        # addi x12, x0, 0        # x12 = i = 0 (outer loop index)
        RISCVInstruction.I_type(19, 0, 0, 0, 12),
        # # Outer Loop Start
        # # PC: 44
        # addi x31, x11, -1      # x31 = n - 1 = 2
        RISCVInstruction.I_type(19, 0, -1, 11, 31),
        # # PC: 48
        # bge  x12, x31, 72      # if i >= 2, branch ahead 72 bytes to PC 120 (Program End)
        RISCVInstruction.B_type(99, 5, 72, 12, 31),
        # # Inner Loop Initialization
        # # PC: 52
        # addi x13, x0, 0        # x13 = j = 0 (inner loop index)
        RISCVInstruction.I_type(19, 0, 0, 0, 13),
        # # Inner Loop Start
        # # PC: 56
        # sub  x31, x11, x12     # x31 = n - i = 3 - i
        RISCVInstruction.R_type(51, 0, 0, 11, 12, 31),
        # # PC: 60
        # addi x31, x31, -1      # x31 = n - i - 1
        RISCVInstruction.I_type(19, 0, -1, 31, 31),
        # # PC: 64
        # bge  x13, x31, 48      # if j >= (n - i - 1), branch ahead 48 bytes to PC 112 (Increment i)
        RISCVInstruction.B_type(99, 5, 48, 13, 31),
        # # Load A[j] into x14
        # # PC: 68
        # slli x16, x13, 2       # x16 = j * 4
        RISCVInstruction.I_type(14, 1, 2, 13, 16),
        # # PC: 72
        # add  x17, x10, x16     # x17 = base_addr + j * 4
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        # # PC: 76
        # lw   x14, 0(x17)       # x14 = A[j]
        RISCVInstruction.I_type(3, 2, 0, 17, 14),
        # # Load A[j+1] into x15
        # # PC: 80
        # addi x16, x16, 4       # x16 = (j + 1) * 4
        RISCVInstruction.I_type(19, 0, 4, 16, 16),
        # # PC: 84
        # add  x17, x10, x16     # x17 = base_addr + (j + 1) * 4
        RISCVInstruction.R_type(51, 0, 0, 10, 16, 17),
        # # PC: 88
        # lw   x15, 0(x17)       # x15 = A[j+1]
        RISCVInstruction.I_type(3, 2, 0, 17, 15),
        # # Compare A[j] > A[j+1]
        # # PC: 92
        # blt  x14, x15, 12      # if A[j] < A[j+1], branch ahead 12 bytes to PC 104 (Increment j)
        RISCVInstruction.B_type(99, 4, 12, 14, 15),
        # # Swap A[j] and A[j+1]
        # # PC: 96
        # sw   x15, -4(x17)      # Store A[j+1] at M[base_addr + j * 4]
        #                         # (A[j] = A[j+1])
        RISCVInstruction.S_type(35, 2, -4, 17, 15),
        # # PC: 100
        # sw   x14, 0(x17)       # Store A[j] at M[base_addr + (j + 1) * 4]
        #                         # (A[j+1] = A[j])
        RISCVInstruction.S_type(35, 2, 0, 17, 14),
        # # Increment j
        # # PC: 104
        # addi x13, x13, 1       # j = j + 1
        RISCVInstruction.I_type(19, 0, 1, 13, 13),
        # # PC: 108
        # jal  x0, -52           # Jump back 52 bytes to PC 56 (Inner Loop Start)
        RISCVInstruction.J_type(111, -52, 0),
        # # Increment i
        # # PC: 112
        # addi x12, x12, 1       # i = i + 1
        RISCVInstruction.I_type(19, 0, 1, 12, 12),
        # # PC: 116
        # jal  x0, -72           # Jump back 72 bytes to PC 44 (Outer Loop Start)
        RISCVInstruction.J_type(111, -72, 0),
        0
    ]
    hex_instructions = [format_hex32(instr) for instr in instructions]
    with open("../data/instructionMem.mem", "w") as f:
        for instr in hex_instructions:
            f.write(f"{instr}\n")
    dut.rst.value = 1
    dut.ending_pc.value = 120
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 1)
    await RisingEdge(dut.instruction_done)
    



@cocotb.test()
async def test_ALU_operations(dut):
    """Test ALU operations"""
    dut._log.info("Starting ALU tests...")
    



    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # await test_sub_sequence(dut)
    # await test_load(dut)
    # await test_store(dut)
    # await test_RAW_hazard (dut)
    # await test_load_use_hazard(dut)
    # await test_memory_hazard(dut)
    # await test_mixed_hazards(dut)
    await bubble_sort_sim(dut)
    # await test_negative_alu(dut)
    # await mini_bubsort(dut)

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
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
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