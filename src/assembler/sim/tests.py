CHAR_PER_LINE = 32
NUM_LINES = 64

class Test:
    def __init__(self, name, code="", instructions=[], error=None):
        self.name = name
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
                buffer[line_index][char_index] = char

        return buffer
    
    def add_inst(self, inst):
        self.returned_instructions.append(inst)
    
    def check_insts(self):
        assert self.expected_instructions == self.returned_instructions, f'Set of Instructions differ\nExpected:\n{self.expected_instructions}\nActual:\n{self.returned_instructions}'

    def check_error(self, line):
        assert self.error_line == line, f'Desired Error not on line {line}!'


TESTS = [
    Test("EMPTY"), 
    Test("INST",
        '''
        add r00, r01, r02
        ''',
        [0x00208033]
        ),

    Test("LABEL",
        '''
        'loop'
        beq r01, r11, 'loop'
        '''
         )
]