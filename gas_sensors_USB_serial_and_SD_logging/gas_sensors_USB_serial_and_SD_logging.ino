
#include <Wire.h>         //For the lols? It's probably included in most of these packages
#include <NAU7802.h>      //Include the NAU7802 sensor on I2C communication
#include <SD.h>           //For writing to the SD card
#include <SPI.h>          //For communicating to the SD card?
#include "RTClib.h"

RTC_PCF8523 rtc;

#define SDmissing 7       //Pin connected to SD card detect 
#define CScard    10        //Card CS pin
#define RedLED    6       //red LED on Adafruit datalogger shield
#define GreenLED  5       // likewise

//#include <QuickMedianLib.h> //For calculating the ADC median outputs


#include <Adafruit_Sensor.h>  //To read the pressure sensor
#include <Adafruit_BME280.h>  //See above

#define SEALEVELPRESSURE_HPA (1013.25)    //Don't love this. We should develop our own pressure calibrations

DateTime now;
String datafile;
long valADC;
long valADC2;
//File datalog;
Adafruit_BME280 bme; // I2C  -->Initialize this sensor on I2C communication


NAU7802 adc = NAU7802(); //Get adc set up

//
DateTime dt;
//
//File datafile;


float temp_bme280 = 0.0;   //variable to hold BME280 Temp
float pres_bme280 = 0.0;   //variable to hold BME280 Pressure
float hum_bme280 = 0.0;    //variable to hold BME280 Relative Humidity %

//char* datafile[30] ;
//int sensorPin = A0; // Arduino ADC input pin
//int sensorValue = 0;  // variable to hold Arduino ADC sensor value
// float AR_EXTERNAL = 5.0;


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     Sensor board data
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float Rs1 = 509.9;
float Rs2 = 510.5;
String Sens1 = "TGS2610-C00";
String Sens2 = "TGS2611";


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      SETUP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void setup() {
  // put your setup code here, to run once:

  pinMode(SDmissing, INPUT_PULLUP); //Needed for detecting if SD card is inserted
  pinMode(CScard, OUTPUT);          //SD card CS pin

  //Initialize serial communication through USB
  Serial.begin(9600);
//  while (!Serial);   // time to get serial running



  //call SDinit function to see if SD card is present
  initSDCard_now();
  
  Serial.println("SD Card initialized sucessfully");
  //Begin I2C communication
    Wire.begin();

//  Initialize BME280 sensor
  Serial.print(F("BME280 test"));
  
  //Serial.println("Is this working?");
  unsigned status;
  unsigned status2;

  // default settings
  status = bme.begin();
  
  Serial.println("Is this working?");
  //   You can also pass in a Wire library object like &Wire2
  //   status = bme.begin(0x76, &Wire2)
  if (!status) {
    while (1)  delay(1);
  }
  
  Serial.println("Passed");

  //Initialize I2C communication with NAU7802 (24bit-ADC)
  Serial.println("Initializing NAU7802 Coms");
  status2 = adc.begin();
  if (!status2) {
   while (1) delay(1);
  }
  //Set NAU7802 REFP
  adc.extAvcc(5.00);
  Serial.println("Coms successful");

  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
//    Serial.flush();
    while (1) delay(10);
  }
 
}


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      LOOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void loop() {
  
  digitalWrite(RedLED, LOW);
  digitalWrite(GreenLED, LOW);

  dt = rtc.now();
//  char* datafile[30] ;
//
  String datafile =  print_filename(dt);
//  String datafile = "test2.csv";
  Serial.println(datafile);
//
  
  initSDCard_now();
//
  if (!digitalRead(SDmissing)) {
     
//    // put your main code here, to run repeatedly:
//
//
//
//
//
    digitalWrite(GreenLED, HIGH);
    int num_loops = 5;
//
//    //read NAU7802
    long valADC_ary[num_loops];
    int i = 0;
    for (i; i < num_loops; i++) {
      valADC_ary[i] = adc.readADC();
    }
     int valADC_ary_len = sizeof(valADC_ary)/sizeof(long);
  
//     valADC =  QuickMedian<long>::GetMedian(valADC_ary, valADC_ary_len);

    valADC = getMin(valADC_ary, valADC_ary_len);
    
    //  Serial.print(valADC + ",");

    adc.selectCh2();

    //read NAU7802_ch2

    long valADC_ary2[num_loops];
    i = 0;
    for (int i = 0; i < num_loops; i++) {
      valADC_ary2[i] = adc.readADC();
    }
    int valADC_ary_len2 = sizeof(valADC_ary2) / sizeof(long);

    valADC2 = getMin(valADC_ary2, valADC_ary_len2);
    
    adc.selectCh1();


    //read BME280 sensor
    temp_bme280 = bme.readTemperature();

    //
    pres_bme280 = bme.readPressure();


    hum_bme280 = bme.readHumidity();
   digitalWrite(GreenLED, LOW);
//  delay(100);
    //Read arduino ADC
    //
    //  sensorValue = analogRead(sensorPin);
    //



    //  char dataline[50];
    //
    //  sprintf(dataline, "%ld,%ld",valADC,valADC2);
    //  datafile.println(dataline);

    //Print it all off
    Serial.print(print_time(dt));
////    //  Serial.print(dataline);
    Serial.print(",");
    Serial.print(valADC);
    Serial.print(",");
    Serial.print(valADC2);
    Serial.print(",");
    Serial.print(temp_bme280);
    Serial.print(",");
    Serial.print(pres_bme280);
    Serial.print(",");
    Serial.print(hum_bme280);
    Serial.print(",");
    Serial.print(Rs1);
    Serial.print(",");
    Serial.print(Sens1);
    Serial.print(",");
    Serial.print(Rs2);
    Serial.print(",");
    Serial.println(Sens2);
//    //  Serial.println(sensorValue);

   
    digitalWrite(RedLED, HIGH);
    if (!SD.exists(datafile)) {
      File datalog = SD.open(datafile, FILE_WRITE);

      digitalWrite(RedLED, HIGH);

//      if (datalog) {
        datalog.println("dt,ADC1,ADC2,temp_BME,pres_BME,hum_BME,Resistor1,Sensor1,Resistor2,Sensor2");
//        Serial.println("Wrote data header");
        datalog.close();
//      }
//      else {
//        initSDCard_now();
//      }

      digitalWrite(RedLED, LOW);

    }

    else {
      

      File datalog = SD.open(datafile, FILE_WRITE);

//      if (datalog) {
        datalog.print(print_time(dt));
        datalog.print(","); 
        datalog.print(valADC);
        datalog.print(",");
        datalog.print(valADC2);
        datalog.print(",");
        datalog.print(temp_bme280);
        datalog.print(",");
        datalog.print(pres_bme280);
        datalog.print(",");
        datalog.print(hum_bme280);
        datalog.print(",");
        datalog.print(Rs1);
        datalog.print(",");
        datalog.print(Sens1);
        datalog.print(",");
        datalog.print(Rs2);
        datalog.print(",");
        datalog.println(Sens2);
        
        datalog.close();
//      }
//      else {
//        SD.end();
//        initSDCard_now();
//      }
      SD.end();
      digitalWrite(RedLED, LOW);
    }
    //  delay(100);

  }

  else {
    SD.end();
    initSDCard_now();
  }

}





//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      OTHER FUNCTIONS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void initSDCard_now() {
  // SD card init routine, from Ralph S. Bacon
  // https://www.youtube.com/watch?v=GQjtG1MeVs4

  while (!SD.begin(CScard)) {
    Serial.println("----SD Card not found / responding----");
    Serial.println("------Insert a formatted SD Card-------");
    SD.end();
    digitalWrite(GreenLED, HIGH);
    digitalWrite(RedLED, HIGH);
    delay(1000);
  }
  digitalWrite(GreenLED, LOW);
  digitalWrite(RedLED, LOW);
  return;
}


String print_filename(DateTime timestamp) {
  static char ymd[10];
  int y = timestamp.year();
  int m = timestamp.month();
  int d = timestamp.day();
  sprintf(ymd, "%4d%02d%02d.CSV", y, m, d);
  return ymd;
}

String print_time(DateTime timestamp) {
  static char message[19];

  int Year = timestamp.year();
  int Month = timestamp.month();
  int Day = timestamp.day();
  int Hour = timestamp.hour();
  int Minute = timestamp.minute();
  int Second = timestamp.second();

  sprintf(message, "%04d-%02d-02%d %02d:%02d:%02d", Year, Month, Day, Hour, Minute, Second);

  return message;
}

long getMin(long* array, int size)
{
  long minimum = array[0];
  for (int i = 0; i < size; i++)
  {
    if (array[i] < minimum) minimum = array[i];
  }
  return minimum;
}
