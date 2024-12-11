
CHAR_PER_LINE = 64
NUM_LINES = 64

def clean_code(code):
        buffer = [
            [" " for _ in range(CHAR_PER_LINE)] for _ in range(NUM_LINES)
        ]
        for line_index, line in enumerate(code.split('\n')):
            for char_index, char in enumerate(line):
                if char_index < CHAR_PER_LINE:
                    if char in ["/", " ", "."] or char.isalnum():
                        buffer[line_index][char_index] = char

        return buffer


def char_to_ascii_hex(char):
    # Get the ASCII value of the character
    ascii_value = ord(char)
    # Format the ASCII value as a 2-digit hexadecimal string
    hex_value = format(ascii_value, '02x')
    return hex_value


def test_add_instructions(buffer):
    

    with open("sim/bubbleSort.mem", "w") as f:
        for line in buffer:
            for character in line:
                f.write(f"{char_to_ascii_hex(character)}\n")

if __name__ == '__main__':
    with open(f'sim/bubble_sort.txt') as f:
        code = f.read()

    code = clean_code(code)

    test_add_instructions(code)
