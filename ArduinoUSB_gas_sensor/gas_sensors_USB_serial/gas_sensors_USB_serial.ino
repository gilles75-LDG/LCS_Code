
#include <Wire.h>         //For the lols? It's probably included in most of these packages
#include <NAU7802.h>      //Include the NAU7802 sensor on I2C communication


#include <QuickMedianLib.h>


#include <Adafruit_Sensor.h>  //To read the pressure sensor
#include <Adafruit_BME280.h>  //See above

#define SEALEVELPRESSURE_HPA (1013.25)    //Don't love this. We should develop our own pressure calibrations




Adafruit_BME280 bme; // I2C  -->Initialize this sensor on I2C communication


NAU7802 adc = NAU7802(); //Get adc set up

typedef union 
{
  float f;
  uint8_t b[4];
}floatConverter;

void longToBytes(uint8_t *const buff, long l)

{

    uint8_t shifter = (4 - 1) * 8;


    for (uint8_t i = 0; i < 4; i++)

    {

        buff[i] = (uint8_t)(l >> shifter) & 0xFF;

        shifter -= 8;

    }

}

static void ulongToBytes(uint8_t *const buff, unsigned long l)
{
    uint8_t shifter = (4 - 1) * 8;
    for (uint8_t i = 0; i < 4; i++)
    {
        buff[i] = (uint8_t)(l >> shifter) & 0xFF;
        shifter -= 8;
    }
}



float temp_bme280 = 0.0;   //variable to hold BME280 Temp
float pres_bme280 = 0.0;   //variable to hold BME280 Pressure
float hum_bme280 = 0.0;    //variable to hold BME280 Relative Humidity %


int DATA_REQUEST   = 33 ; // esp32 data request input pin
//int sensorValue = 0;  // variable to hold Arduino ADC sensor value
// float AR_EXTERNAL = 5.0;

void setup() {
  // put your setup code here, to run once:
  
  //Initialize serial communication through USB
  Serial.begin(115200);
  while(!Serial);    // time to get serial running
  

 //Begin I2C communication
  Wire.begin();

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

  pinMode(data_request,INPUT_PULLDOWN);

  Serial2.begin(9600,SERIAL_8N1, 16, 17);
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

 //1 byte - board ID.
 //1 byte - length
 //4 byte timestamp
 //4 byte adc1
 //4 byte adc2
 //4 byte hum
 //4 byte pres
 //4 byte temp

uint8_t buffer[26];
uint8_t board_id = 0x01;
uint8_t len = 24;

buffer[0] = board_id;
buffer[1] = len;

//longToBytes(buffer + 2, valADC1);

longToBytes(buffer + 2, 1000);
longToBytes(buffer + 6, 1100);

ulongToBytes(buffer + 10, 12222222);

floatConverter converter;
converter.f = 1.02;
memcpy(buffer + 14, converter.b, 4);

converter.f = 1.04;
memcpy(buffer + 18, converter.b, 4);

converter.f = 1.06;
memcpy(buffer + 22, converter.b, 4);

  
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
  Serial.println(hum_bme280);
//  Serial.println(sensorValue);


  //TODO - check pin 33 for input == high
  // if p33 == high
  if (digitalRead(DATA_REQUEST) == HIGH) {
//    byte data[4] = {0x01, 0x02, 0x03, 0x04};
    Serial.println("Pin is high");
    Serial2.write(buffer, 26);
    }
    
    
    // send datastruct over uart
    
 
  delay(100);
}
