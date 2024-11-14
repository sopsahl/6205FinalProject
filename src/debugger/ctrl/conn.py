"""
Main SerialConn class in charge of managing serial port connection and sending/receiving data from the FPGA
    port: Serial Port to connect to
    baud: baud rate to initialize
    bitwidth: 
"""

import serial
import time
from .data import Data

class Conn:
    def __init__(self, port, baud):

        self.conn = serial.Serial() # Initialize the Serial port without opening it
        self.conn.baudrate = baud
        self.conn.port = port # OPen the specific port

    def connect(self, fx):

        try:
            self.conn.open() # Establish the port connection
            print(f"Successfully connected to {self.conn.port}!!")
        except serial.SerialException: 
            print(f"Could not successfully connect to {self.conn.port}!!")
            return

        try: fx() # Perform the operation (sending/receiving data)
        except Exception as e:
            print(f'Transaction Terminated. Reason:\n{e}')
        finally:
            self.conn.close()  # Closing the connection
            print('Closing Serial port...')
        
    
    def send_data(self, data:Data):

        def helper():
            self.conn.write(data.write_control()) # Sending control signal
            assert self.conn.read() == b'\x00', "Handshake Not Received" # Handshake --> Ready to Receive Data

            for point in data:
                for byte in point:
                    self.conn.write(bytes([byte]))
            
        self.connect(helper)

        print(f'Successfully Transmitted {data.depth} elements at a width of {data.width} bytes')

    def receive_data(self, data:Data):

        def helper():
            self.conn.write(data.read_control())  # Sending control signal
            assert self.conn.read() == b'\x00', "Handshake Not Received"  # Handshake --> Ready to Send Data
            
            for _ in range(data.depth):
                value = int.from_bytes(self.conn.read(data.width), 'little')
                data.add_value(value)
                
        self.connect(helper)

        print(f'Successfully Received {data.depth} elements at a width of {data.width} bytes')




def test_ports():
    baud = 57600
    print("Ports found: ")
    ports = serial.tools.list_ports.comports()
    
    for port in ports:
        print("{port.device}: {port.description} [manufacturer: {port.manufacturer}]".format(port=port))
    if (len(ports) == 0):
        print("No ports found. Make sure your board is plugged in and turned on?")
    print()

    for port in ports:
        
        test_port = input("test port '{port.device}'? (y/n/exit) ".format(port=port))
        
        while (test_port == "y"):
            
            try:
                ser = serial.Serial(port.device, baud, write_timeout=4)
                print("\twatch for a flashing green `TX` light")
                
                for i in range(10):
                    ser.write( bytes("Hello, World!", 'utf-8') )
                    time.sleep(0.5)
                
                print("Test completed\n")
            except Exception as e:
                print("Test failed with: {}\n".format(e))
            
            test_port = input("REPEAT test for '{port.device}'? (y/n/exit) ".format(port=port))
            
        if (test_port == "exit"):
            exit()