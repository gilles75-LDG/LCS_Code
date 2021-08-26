
#include <Wire.h>         //For the lols? It's probably included in most of these packages
#include <NAU7802.h>      //Include the NAU7802 sensor on I2C communication


#include <QuickMedianLib.h>


#include <Adafruit_Sensor.h>  //To read the pressure sensor
#include <Adafruit_BME280.h>  //See above

#define SEALEVELPRESSURE_HPA (1013.25)    //Don't love this. We should develop our own pressure calibrations




Adafruit_BME280 bme; // I2C  -->Initialize this sensor on I2C communication


NAU7802 adc = NAU7802(); //Get adc set up




float temp_bme280 = 0.0;   //variable to hold BME280 Temp
float pres_bme280 = 0.0;   //variable to hold BME280 Pressure
float hum_bme280 = 0.0;    //variable to hold BME280 Relative Humidity %


//int sensorPin = A0; // Arduino ADC input pin
//int sensorValue = 0;  // variable to hold Arduino ADC sensor value
// float AR_EXTERNAL = 5.0;

void setup() {
  // put your setup code here, to run once:
  
  //Initialize serial communication through USB
  Serial.begin(115200);
  while(!Serial);    // time to get serial running
  

 //Begin I2C communication
//  Wire.begin();

  //Initialize BME280 sensor
  Serial.print(F("BME280 test"));
  
  unsigned status;
    
  // default settings
  status = bme.begin();  
//   You can also pass in a Wire library object like &Wire2
//   status = bme.begin(0x76, &Wire2)
  if (!status) {
    while (1) delay(1);
  }
  Serial.println("Passed");

  //Initialize I2C communication with NAU7802 (24bit-ADC)
  adc.begin();
  //Set NAU7802 REFP
  adc.extAvcc(5.00);


}

void loop() {
  // Serial.println("Made it into loop");
  // put your main code here, to run repeatedly:




 
  int num_loops = 9;
  
  //read NAU7802
  long valADC_ary[num_loops];
  int i = 0;
  for (i; i < num_loops; i++) {
    valADC_ary[i] = adc.readADC();
  }
 int valADC_ary_len = sizeof(valADC_ary)/sizeof(long);
  
 long valADC =  QuickMedian<long>::GetMedian(valADC_ary, valADC_ary_len);

 
//  Serial.print(valADC + ",");

  adc.selectCh2();
 
  //read NAU7802_ch2
  
  long valADC_ary2[num_loops];
  i = 0;
  for (int i = 0; i < num_loops; i++) {
    valADC_ary2[i] = adc.readADC();
  }
  int valADC_ary_len2 = sizeof(valADC_ary2)/sizeof(long);
  
  long valADC2 =  QuickMedian<long>::GetMedian(valADC_ary2, valADC_ary_len2);
  adc.selectCh1();
  
 
  
  //read BME280 sensor
  temp_bme280 = bme.readTemperature();

//  
  pres_bme280 = bme.readPressure();

  
  hum_bme280 = bme.readHumidity();


  //Read arduino ADC
//  
//  sensorValue = analogRead(sensorPin);
//  


  
//  char dataline[50];
//  
//  sprintf(dataline, "%ld,%ld",valADC,valADC2);
//  datafile.println(dataline);

  //Print it all off
//  Serial.print(print_time(dt) + ",");
//  Serial.print(dataline);
  Serial.print(valADC);
  Serial.print(",");
  Serial.print(valADC2);
  Serial.print(",");
  Serial.print(temp_bme280);
  Serial.print(",");
  Serial.print(pres_bme280);
  Serial.print(",");
  Serial.println(hum_bme280);
//  Serial.println(sensorValue);

 
  delay(100);
}
