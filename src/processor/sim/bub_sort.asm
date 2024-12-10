# Bubble Sort in RISC-V Assembly
# - No pseudoinstructions
# - No alias registers
# - No stack pointers
# - Uses the first 720 spots in memory
# - Jumps based on PC, no labels used

# Registers used:
# x0: zero       - hardwired zero
# x10: base_addr - base address of the array
# x11: n         - size of the array
# x12: i         - outer loop index
# x13: j         - inner loop index
# x14: A_j       - array element A[j]
# x15: A_j1      - array element A[j+1]
# x16: offset    - memory offset calculation
# x17: addr      - memory address calculation
# x18: temp      - temporary register for (j + 1)
# x31: limit     - loop limit (n - i - 1)

# Initialize base address and array size

# PC: 0
addi x10, x0, 0       # x10 = base_addr = 0
# translates to 0x00000513

# PC: 4
addi x11, x0, 10     # x11 = n = 10 (array size)
# translates to 00a00593

# Initialize the array with values
# M[base_addr + i*4] = array[i]

# Element 0
# PC: 8
addi x14, x0, 5       # x14 = 5
# 00500713

# PC: 12
sw   x14, 0(x10)      # Store 5 at M[0]
# 00e52023

# Element 1
# PC: 16
addi x14, x0, 1       # x14 = 1
# 00100713


# PC: 20
addi x17, x10, 4      # x17 = base_addr + 4
# 00450893

# PC: 24
sw   x14, 0(x17)      # Store 1 at M[4]
# 00e8a023

# Element 2
# PC: 28
addi x14, x0, 4       # x14 = 4
# 00400713

# PC: 32
addi x17, x10, 8      # x17 = base_addr + 8
# 00850893

# PC: 36
sw   x14, 0(x17)      # Store 4 at M[8]
# 00e8a023

# Element 3
# PC: 40
addi x14, x0, 2       # x14 = 2
# 00200713


# PC: 44
addi x17, x10, 12     # x17 = base_addr + 12
# 00c50893

# PC: 48
sw   x14, 0(x17)      # Store 2 at M[12]
# 00e8a023

# Element 4
# PC: 52
addi x14, x0, 8       # x14 = 8


# PC: 56
addi x17, x10, 16     # x17 = base_addr + 16

# PC: 60
sw   x14, 0(x17)      # Store 8 at M[16]

# Element 5
# PC: 64
addi x14, x0, 0       # x14 = 0

# PC: 68
addi x17, x10, 20     # x17 = base_addr + 20

# PC: 72
sw   x14, 0(x17)      # Store 0 at M[20]

# Element 6
# PC: 76
addi x14, x0, 2       # x14 = 2

# PC: 80
addi x17, x10, 24     # x17 = base_addr + 24

# PC: 84
sw   x14, 0(x17)      # Store 2 at M[24]

# Element 7
# PC: 88
addi x14, x0, 3       # x14 = 3

# PC: 92
addi x17, x10, 28     # x17 = base_addr + 28

# PC: 96
sw   x14, 0(x17)      # Store 3 at M[28]

# Element 8
# PC: 100
addi x14, x0, 7       # x14 = 7

# PC: 104
addi x17, x10, 32     # x17 = base_addr + 32

# PC: 108
sw   x14, 0(x17)      # Store 7 at M[32]

# Element 9
# PC: 112
addi x14, x0, 6       # x14 = 6

# PC: 116
addi x17, x10, 36     # x17 = base_addr + 36

# PC: 120
sw   x14, 0(x17)      # Store 6 at M[36]
# HERE STARTSS#




# Bubble Sort Algorithm

# PC: 124
addi x12, x0, 0       # x12 = i = 0 (outer loop index)

# OuterLoopStart equivalent
# PC: 128
addi x31, x11, -1     # x31 = n - 1

# PC: 132
bge  x12, x31, 92     # if i >= n - 1, branch ahead 92 bytes to PC 224 (ProgramEnd)

# Inner loop initialization
# PC: 136
addi x13, x0, 0       # x13 = j = 0 (inner loop index)

# InnerLoopStart equivalent
# PC: 140
sub  x31, x11, x12    # x31 = n - i

# PC: 144
addi x31, x31, -1     # x31 = n - i - 1

# PC: 148
bge  x13, x31, 68     # if j >= n - i - 1, branch ahead 68 bytes to PC 216

# Load A[j] into x14
# PC: 152
slli x16, x13, 2      # x16 = j * 4

# PC: 156
add  x17, x10, x16    # x17 = base_addr + j * 4

# PC: 160
lw   x14, 0(x17)      # x14 = A[j]

# Load A[j+1] into x15
# PC: 164
addi x18, x13, 1      # x18 = j + 1

# PC: 168
slli x16, x18, 2      # x16 = (j + 1) * 4

# PC: 172
add  x17, x10, x16    # x17 = base_addr + (j + 1) * 4

# PC: 176
lw   x15, 0(x17)      # x15 = A[j+1]

# Compare A[j] > A[j+1]
# PC: 180
blt  x14, x15, 28     # if A[j] < A[j+1], branch ahead 28 bytes to PC 208

# Swap A[j] and A[j+1]
# Store A[j+1] into A[j]
# PC: 184
slli x16, x13, 2      # x16 = j * 4

# PC: 188
add  x17, x10, x16    # x17 = base_addr + j * 4

# PC: 192
sw   x15, 0(x17)      # M[base_addr + j * 4] = A[j+1]

# Store A[j] into A[j+1]
# PC: 196
slli x16, x18, 2      # x16 = (j + 1) * 4

# PC: 200
add  x17, x10, x16    # x17 = base_addr + (j + 1) * 4

# PC: 204
sw   x14, 0(x17)      # M[base_addr + (j + 1) * 4] = A[j]

# NoSwap equivalent
# PC: 208
addi x13, x13, 1      # j = j + 1

# PC: 212
jal  x0, -72          # Jump back 72 bytes to PC 140 (Inner loop start)

# IncrementI equivalent
# PC: 216
addi x12, x12, 1      # i = i + 1

# PC: 220
jal  x0, -92          # Jump back 92 bytes to PC 128 (Outer loop start)

# ProgramEnd equivalent
# PC: 224
# Sorting is complete
# The sorted array is stored in memory starting at base_addr