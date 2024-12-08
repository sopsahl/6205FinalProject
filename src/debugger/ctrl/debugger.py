import serial

from .data import Data, DataStructure
from .conn import Conn


class Debugger:
    def __init__(self, port, baud=115200):
        self.conn = Conn(port, baud)
