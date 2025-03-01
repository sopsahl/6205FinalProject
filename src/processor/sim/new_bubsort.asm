_start:
    # Initialize base address and array size
    addi x10, x0, 0          # x10 = base_addr = 0
    addi x11, x0, 10         # x11 = n = 10 (array size)

    # Initialize outer loop index i
    addi x12, x0, 0          # x12 = i = 0

outer_loop:
    addi x31, x11, -1        # x31 = n - 1
    bge  x12, x31, program_end # if i >= n - 1, exit

    # Initialize inner loop index j
    addi x13, x0, 0          # x13 = j = 0

inner_loop:
    sub   x31, x11, x12      # x31 = n - i
    addi  x31, x31, -1       # x31 = n - i - 1
    bge   x13, x31, increment_i # if j >= n - i - 1, increment i

    # Calculate address of A[j]
    slli  x16, x13, 2        # x16 = j * 4
    add   x17, x10, x16      # x17 = base_addr + (j * 4)
    lw    x14, 0(x17)        # x14 = A[j]

    # Calculate address of A[j+1]
    addi  x18, x13, 1        # x18 = j + 1
    slli  x16, x18, 2        # x16 = (j + 1) * 4
    add   x17, x10, x16      # x17 = base_addr + ((j + 1) * 4)
    lw    x15, 0(x17)        # x15 = A[j+1]

    # Compare A[j] and A[j+1]
    blt   x14, x15, increment_j # if A[j] < A[j+1], skip swapping

    # Swap A[j] and A[j+1]
    # Store A[j+1] into A[j]
    slli  x16, x13, 2        # x16 = j * 4
    add   x17, x10, x16      # x17 = base_addr + (j * 4)
    sw    x15, 0(x17)        # A[j] = A[j+1]

    # Store A[j] into A[j+1]
    slli  x16, x18, 2        # x16 = (j + 1) * 4
    add   x17, x10, x16      # x17 = base_addr + ((j + 1) * 4)
    sw    x14, 0(x17)        # A[j+1] = A[j]

increment_j:
    addi  x13, x13, 1        # j = j + 1
    jal   x0, inner_loop     # Jump to inner_loop

increment_i:
    addi  x12, x12, 1        # i = i + 1
    jal   x0, outer_loop     # Jump to outer_loop

program_end:
    nop                      # End of program