import json


class Data:
    
    def __init__(self, loc:str, depth:int):
        with open('locs.json', 'r') as file:
            locs = json.load(file)

        assert loc in locs, f'Specified location not in {locs.keys()}'
        self.loc = locs[loc]

        assert depth in self.loc['depths'], 'Not a supported size'
        self.depth = depth

        self.width = self.loc['width']

        self.control_template = ((self.loc['index'] & 0x7) << 5) | \
                                ((self.loc['depths'].index(depth) & 0x3) << 3) | \
                                ((1 if self.width == 4 else 0) << 2)

        self.data = []
    
    def add_value(self, value):
        self.data.append(DataPoint(value, self.width))

    def __iter__(self):
        for point in self.data:
            yield point
    
    def dump(self, filename='tmp'):
        with open(f'{filename}.mem', 'w') as file:
            for value in self.data:
                file.write(f"{value.value:0{self.width * 8}b}\n")  # Writing the binary value

    def load(self, filename):
        with open(f'{filename}.mem', 'r') as file:
            self.data = [DataPoint(int(line.strip(), 2), self.width) for line in file if line.strip()]

    def read_control(self):
        return bytes([self.control_template | 0x3])

    def write_control(self):
        return bytes([self.control_template | 0x1])
        


class DataPoint:
    def __init__(self, value, num_bytes = 4):
        self.value = value
        self.num_bytes = num_bytes
    
    def __iter__(self):
        for i in range(self.num_bytes):
            yield (self.value >> (i*8)) & 0xff