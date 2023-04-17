import serial
from datetime import datetime
import struct
import argparse

parser = argparse.ArgumentParser(prog='DataReceiver', 
                                 description='Receive data from the CottonCandy gateway using RPI GPIO UART')
                                 
parser.add_argument('-f', '--filename', default='DataLog.csv', required=False)

args = parser.parse_args()
filename = args.filename;

#Set up the communication with the gateway device
ser = serial.Serial('/dev/ttyS0',9600,timeout=1)

with open(filename, 'w') as f:
    while True:
      try:  
        if ser.in_waiting > 0:
          src = ser.read(2) # The first 2 bytes indicate the origin of the message
          length = ser.read(1) # The next byte indicate the length of the message
        else:
          continue

        # If receiving fails
        if len(src) < 2 or len(length) < 1:
          continue
        
        data_len = int.from_bytes(length, 'big');
        print(data_len)
        raw_data = ser.read(data_len)
      
        # If receiving fails
        if len(raw_data) < data_len:
          print("Warning: Only partial data received")
          continue
      
        rpi_timestamp = datetime.now().strftime('%Y-%m-%d-%H:%M:%S')
        node_addr = src.hex('-')
        print(rpi_timestamp + '-> Raw Data = ' + raw_data.hex('-') + ' received from ' + node_addr)

      
        if data_len == 30:
          parent_addr, board_id, sensor_timestamp = struct.unpack('>HBL', raw_data[0:7])
          adc1, adc2 = struct.unpack('>LL', raw_data[7:15]) # Big endian
          temp, pressure, humidity = struct.unpack('<fff', raw_data[15:27]) # floats were stored as little endian on ESP32
          counter, is_sd_panic = struct.unpack('>HB', raw_data[27:]) # Big endian
        
          print(board_id, sensor_timestamp, adc1, adc2, temp, pressure, humidity, counter, is_sd_panic)
      
          f.write(str(board_id))
          f.write(',')
          f.write(str(sensor_timestamp)) #This time can be formatted to date-time string
          f.write(',')
          f.write(str(adc1))
          f.write(',')
          f.write(str(adc2))
          f.write(',')
          f.write(str(temp))
          f.write(',')
          f.write(str(pressure))
          f.write(',')
          f.write(str(humidity))
          f.write(',')
          f.write(str(counter))
          f.write(',')
          f.write(str(is_sd_panic))
          f.write('\n')
          f.flush()

        if data_len == 38;
          parent_addr, board_id, sensor_timestamp = struct.unpack('>HBL', raw_data[0:7])
          adc1, adc2 = struct.unpack('>LL', raw_data[7:15]) # Big endian
          temp, pressure, humidity = struct.unpack('<fff', raw_data[15:27]) # floats were stored as little endian on ESP32
          counter, is_sd_panic = struct.unpack('>HB', raw_data[27:30]) # Big endian
          V12_batt, V4_batt = struct.unpack('<ff', raw_data[30:38]) #
          print(board_id, sensor_timestamp, adc1, adc2, temp, pressure, humidity, counter, is_sd_panic)
      
          f.write(str(board_id))
          f.write(',')
          f.write(str(sensor_timestamp)) #This time can be formatted to date-time string
          f.write(',')
          f.write(str(adc1))
          f.write(',')
          f.write(str(adc2))
          f.write(',')
          f.write(str(temp))
          f.write(',')
          f.write(str(pressure))
          f.write(',')
          f.write(str(humidity))
          f.write(',')
          f.write(str(counter))
          f.write(',')
          f.write(str(is_sd_panic))
          f.write(',')
          f.write(str(V12_batt))
          f.write(',')
          f.write(str(V4_batt))
          f.write('\n')
          f.flush()
      except KeyboardInterrupt:
          print("Exiting program");
          exit(0)
           
