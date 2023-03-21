import serial
from datetime import datetime
ser=serial.Serial('/dev/ttyUSB0',9600,timeout=1)

while True:
  log=ser.readline().decode('utf-8')

  if log:
    now=datetime.now()
    entry=str(now) + '->' + str(log)
    print(entry)
      #f.write(entry + '\n')
      #f.flush()
