import random


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


BUBBLE_SORT = '''
_start:
    la      t0, array           # Load address of the array into t0
    lw      t1, length          # Load the length of the array into t1
    addi    t1, t1, -1          # Decrement length by 1 for zero-based index

outer_loop:
    addi    t2, zero, 0         # Initialize outer loop index to 0

inner_loop:
    beq     t2, t1, outer_done  # If outer loop index equals length, outer loop is done

    lw      t3, 0(t0)           # Load array[t2] into t3
    lw      t4, 4(t0)           # Load array[t2+1] into t4

    ble     t3, t4, skip_swap   # If array[t2] <= array[t2+1], skip swap

    # Swap array[t2] and array[t2+1]
    sw      t4, 0(t0)           # Store array[t2+1] into array[t2]
    sw      t3, 4(t0)           # Store array[t2] into array[t2+1]

skip_swap:
    addi    t0, t0, 4                # Move to the next pair
    addi    t2, t2, 1           # Increment inner loop index
    j       inner_loop         # Jump to the start of the inner loop

outer_done:
    addi    t1, t1, -1          # Decrement length for the next pass
    beqz    t1, end             # If length is zero, sorting is complete

    la      t0, array           # Reset t0 to the start of the array
    j       outer_loop          # Jump to the start of the outer loop

end:
    # Exit program (assuming an environment that supports ecall for exit)

'''

# class send_val