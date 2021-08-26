#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr 23 11:56:27 2021

@author: lawson
"""

import serial
import time
import datetime
from datetime import date as dd
import csv
import sys
import string

OUTPUT_FILENAME = "lcs_data_"+str(dd.today().year)+"-"+str(dd.today().month)+str(dd.today().day)+".csv"

arduino_connected = False

if sys.platform == "linux":
    while not arduino_connected:
        for num in range(0,10):
            print("Trying port ", num)
            dev_str = '/dev/ttyACM'+str(num)
            print(dev_str)
            try:
                arduino = serial.Serial(dev_str, 115200)
                print("Connected to arduino on port ", num)
                arduino_connected = True
                break
            except serial.SerialException:
                print("Nothing at", dev_str)
            
        time.sleep(2)
        


elif sys.platform == "Windows":
    arduino = serial.Serial("COM?", 115200)
    arduino_connected = True
    
time.sleep(1.5)

def record_data(arduino):
    
    data_str = str(arduino.readline())
    
    # print(data_str)
    data_time = datetime.datetime.now()
    
    if len(data_str) > 26:

        data_chuncks = data_str.split(',')
    
        adc_1 = int(data_chuncks[0].strip(string.ascii_letters)[1:len(data_chuncks[0])]) + 2**23
        adc_2 = int(data_chuncks[1]) + 2**23
        temp_bme = float(data_chuncks[2])
        pressure_bme = float(data_chuncks[3])
        humidity_bme = float(data_chuncks[4].split("\\r")[0])
    
        data_lst = [data_time,adc_1,adc_2,temp_bme,pressure_bme,humidity_bme]
        print(data_lst)
    
    
        with open(OUTPUT_FILENAME,"a") as f:
            writer = csv.writer(f,delimiter=",")
            writer.writerow(data_lst)

    # for chunck in data_chuncks:
    #     print(chunck)
    # print(data_str)
    time.sleep(0.001)


def reinit(arduino_connected):
    # global arduino_connected1
    arduino_connected1 = False
 
    if sys.platform == "linux":
        # arduino_connected1  = False
        while not arduino_connected1:
            print("arduino1= ",arduino_connected1)
            for num in range(0,10):
                # print("Trying port ", num)
                dev_str = '/dev/ttyACM'+str(num)
                print("Trying port ", dev_str)
                try:
                    arduino = serial.Serial(dev_str, 115200)
                    arduino.close()
                    print("Connected to arduino on port ", num)
                    arduino_connected1 = True
                    return dev_str
                except serial.SerialException:
                    print("Nothing at", dev_str)
                    # arduino_connected1 = False
                    continue
          
            print("arduino1= ",arduino_connected1)
        time.sleep(5)
            
    
    elif sys.platform == "Windows":
        arduino = serial.Serial("COM?", 115200)
    
  
    

while True:                                 
    try:
        record_data(arduino)
    

    except serial.SerialException:
        arduino.close()
        print("Bing")
        arduino_connected = False
        print("Bang")
        arduino_str = reinit(arduino_connected)
        print(arduino_str)
        arduino = serial.Serial(dev_str, 115200)
        # print("/n/n/n/n/n THE GREAT ESCAPE!!!!!!!")
        continue
        # break

