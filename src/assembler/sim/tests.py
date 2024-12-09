import os

CHAR_PER_LINE = 32
NUM_LINES = 64

class Test:
    def __init__(self, name, code="", instructions=[], from_directory = "", error=None):
        self.name = name

        if from_directory != "":
            instructions = []
            try:
                with open(f'../examples/{from_directory}/assembler.txt') as f:
                    code = f.read()
                with open(f'../examples/{from_directory}/instructions.txt') as f:
                      for line in f:
                            if line.strip():
                                instructions.append(int(line.strip(), 16))

            except: 
                  
                with open(f'./examples/{from_directory}/assembler.txt') as f:
                    code = f.read()
                with open(f'./examples/{from_directory}/instructions.txt') as f:
                      for line in f:
                            if line.strip():
                                  instructions.append(int(line.strip(), 16))

        self.code = self.clean_code(code)
        self.expected_instructions = [hex(inst) for inst in instructions]
        
        self.error_line = error
        self.returned_instructions = []

    def clean_code(self, code):
        buffer = [
            [" " for _ in range(CHAR_PER_LINE)] for _ in range(NUM_LINES)
        ]
        for line_index, line in enumerate(code.split('\n')):
            for char_index, char in enumerate(line):
                if char_index < CHAR_PER_LINE:
                    if char in ["/", " ", "'"] or char.isalpha() or char.isalnum():
                        buffer[line_index][char_index] = char

        return buffer
    
    def add_inst(self, inst):
        self.returned_instructions.append(inst)
    
    def check_insts(self):
        assert self.expected_instructions == self.returned_instructions, f'Set of Instructions differ\nExpected:\n{self.expected_instructions}\nActual:\n{self.returned_instructions}'

    def check_error(self, line):
        assert self.error_line == line, f'Desired Error not on line {line}!'


TESTS = [
    # Test("EMPTY"), # WORKS
    # Test("EVERY_INST",  from_directory="every_inst"), # DOES NOT WORK
    Test('R-Type', from_directory="Rtype"), # WORKS
    Test('I-Type', from_directory="Itype"), # WORKS
    # Test('Branch', from_directory='branch'), # DOES NOT WORK
    # Test('Jumps', from_directory='jumps'), # JAL DOESN"T WORK
    Test('LUI and AUIPC', from_directory='lui_auipc'), # WORKS
    Test('Loads and Stores', from_directory='memory') # WORKS
]

