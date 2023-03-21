
#include <Wire.h>         //For the lols? It's probably included in most of these packages
#include <NAU7802.h>      //Include the NAU7802 sensor on I2C communication
#include <SD.h>           //For writing to the SD card
#include"FS.h"
#include "SPI.h"          //For communicating to the SD card?
#include "RTClib.h"
#include <QuickMedianLib.h> //For calculating the ADC median outputs
#include <esp_task_wdt.h> //Watchdog timer

//+++++++++++Useful Functions!!!++++++++++++++++++++++++++++++++++++++++=

typedef union
{
  float f;
  uint8_t b[4];
} floatConverter;

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

static void uint32_tToBytes(uint8_t *const buff, uint32_t l)
{
  uint8_t shifter = (4 - 1) * 8;
  for (uint8_t i = 0; i < 4; i++)
  {
    buff[i] = (uint8_t)(l >> shifter) & 0xFF;
    shifter -= 8;
  }
}


//+++++++++++++++++++++Averaging Functions++++++++++++++++++++++++++++++++++++=

long l_average (long * array, int len)  // assuming array is int.
{
  long sum = 0 ;  // sum will be larger than an item, long for safety.
  for (int i = 0 ; i < len ; i++)
    sum += array [i] ;
  return  sum / len ;
}

float f_average (float * array, int len)  // assuming array is int.
{
  float sum = 0 ;  // sum will be larger than an item, long for safety.
  for (int i = 0 ; i < len ; i++)
    sum += array [i] ;
  return   sum / len ;  // average will be fractional, so float may be appropriate.
}

//+++++++++Filesystem functions+++++++++++

void writeFile(fs::FS &fs, const char * path, const char * message){
    Serial.printf("Writing file: %s\n", path);

    File file = fs.open(path, FILE_WRITE);
    if(!file){
        Serial.println("Failed to open file for writing");
        return;
    }
    if(file.print(message)){
        Serial.println("File written");
    } else {
        Serial.println("Write failed");
    }
    file.close();
}

void appendFile(fs::FS &fs, const char * path, const char * message){
    Serial.printf("Appending to file: %s\n", path);

    File file = fs.open(path, FILE_APPEND);
    if(!file){
        Serial.println("Failed to open file for appending");
        return;
    }
    if(file.print(message)){
        Serial.println("Message appended");
    } else {
        Serial.println("Append failed");
    }
    file.close();
}

uint8_t check_card(fs::FS &fs){
  uint8_t cardType = SD.cardType();

    if(cardType == CARD_NONE){
        Serial.println("No SD card attached");
        Serial.println(CARD_NONE);
    }
    Serial.println(cardType);
    return cardType;
}



//+++++++LORA variables and constructors++++++++++++++++++++
uint8_t len = 27;
const uint8_t buffer_len = 28;   //len + 1
uint8_t buffer[buffer_len]; //Buffer len
uint8_t board_id = 0x01;  //Board ID
int LORA_REQUEST =  27;  // Data request pin goes low when data is requested.

//++++++++++SD card parameters+++++++++++++++++++++++++++++++
RTC_PCF8523 rtc;

//#define SDmissing 7       //Pin connected to SD card detect
int CScard = 33;      //Card CS pin  10 for arduino, 33 for esp32 feather
//#define RedLED    6       //red LED on Adafruit datalogger shield
//#define GreenLED  5       // likewise

DateTime now;  //initialize datetime

//+++++++++++++BME280 Sensors+++++++++++++++++++++++++++++++++++

#include <Adafruit_Sensor.h>  //To read the pressure sensor
#include <Adafruit_BME280.h>  //See above

#define SEALEVELPRESSURE_HPA (1013.25)    //Don't love this. We should develop our own pressure calibrations
Adafruit_BME280 bme; // I2C  -->Initialize this sensor on I2C communication


//+++++++++++++Global variables++++++++++++++++++++++++++++++++++
//String datafile;  //initialize variable for datafile name

long valADC;      //initialize long for adc reading
long valADC2;     //initialize long for adc reading
//File datalog;
uint16_t counter = 0;
DateTime dt;
//File datafile;
float temp_bme280 = 0.0;   //variable to hold BME280 Temp
float pres_bme280 = 0.0;   //variable to hold BME280 Pressure
float hum_bme280 = 0.0;    //variable to hold BME280 Relative Humidity %
int BATTERY_SENSE = 4;    //Battery Sense I/O pin (3.3V ADC)
int battery_adc = 0;  // variable to hold ESP32 ADC read from battery divider

#define WDT_TIMEOUT 15    //7 seconds timeout on watchdog
//+++++++ 2D Array/multiple 1D arrays to hold last 'n' readings++++++++++++++++++++
const int NUM_AVGS = 50;
long ADC1_vals[NUM_AVGS];
long ADC2_vals[NUM_AVGS];
float temp_vals[NUM_AVGS];
float pres_vals[NUM_AVGS];
float hum_vals[NUM_AVGS];
uint32_t unixtimes[NUM_AVGS];


//+++++++++++++++++++Initialize ADC++++++++++++++++++++++++++++++++++++++++++++++++++++++
NAU7802 adc = NAU7802(); //Get adc set up


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//     Sensor board data
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float Rs1 = 508.8;//509.9;
float Rs2 = 512.2;//510.5;
String Sens1 = "TGS2611-E00" ;//"TGS2610-C00";
String Sens2 =  "TGS2611-C00"; //"TGS2611";


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      SETUP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void setup() {
  // put your setup code here, to run once:
  Serial.print("Check CARD_NONE");
  Serial.println(CARD_NONE);
  //  pinMode(SDmissing, INPUT_PULLUP);     //Needed for detecting if SD card is inserted
  //  pinMode(CScard, OUTPUT);                //SD card CS pin
  pinMode(LORA_REQUEST, INPUT_PULLUP);
  buffer[1] = board_id;
  buffer[0] = len;


  //Initialize serial communication through USB
  Serial.begin(115200);
  Serial2.begin(38400, SERIAL_8N1, 16, 17);
  //  while (!Serial);   // time to get serial running



  //call SDinit function to see if SD card is present
  //  initSDCard_now();

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

  Serial.println("Trying to find RTC");

  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    //    Serial.flush();
    while (1) delay(10);
  }
  Serial.println("Found RTC");

  Serial.println("Configuring WDT...");
  esp_task_wdt_init(WDT_TIMEOUT, true); //enable panic so ESP32 restarts
  esp_task_wdt_add(NULL); //add current thread to WDT watch

}


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      LOOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


void loop() {

  Serial.print("In the loop now! Watchdog reset. Counter = ");
  esp_task_wdt_reset();  //Pet the dog
  Serial.println(counter);

  //  digitalWrite(RedLED, LOW);
  //  digitalWrite(GreenLED, LOW);

  dt = rtc.now();
//    char* datafile[30] ;
  //
    String datafile =  print_filename(dt);
  //  String datafile = "test2.csv";
    Serial.println(datafile);
  //

   bool  sd_panic = initSDCard_now();
  //
  //  if (!digitalRead(SDmissing)) {

  //    // put your main code here, to run repeatedly:
  //
  //
  //
  //
  //
  //    digitalWrite(GreenLED, HIGH);
  int num_loops = 10;
  //
  //    //read NAU7802
  long valADC_ary[num_loops];
  int i = 0;
  for (i; i < num_loops; i++) {
    valADC_ary[i] = adc.readADC();
  }
  int valADC_ary_len = sizeof(valADC_ary) / sizeof(long);

  valADC =  QuickMedian<long>::GetMedian(valADC_ary, valADC_ary_len);

  //    valADC = getMin(valADC_ary, valADC_ary_len);

  //  Serial.print(valADC + ",");

  adc.selectCh2();

  //read NAU7802_ch2

  long valADC_ary2[num_loops];
  i = 0;
  for (int i = 0; i < num_loops; i++) {
    valADC_ary2[i] = adc.readADC();
  }
  int valADC_ary_len2 = sizeof(valADC_ary2) / sizeof(long);

  valADC2 = QuickMedian<long>::GetMedian(valADC_ary2, valADC_ary_len);
  //    valADC2 = getMin(valADC_ary2, valADC_ary_len2);

  adc.selectCh1();


  //read BME280 sensor
  temp_bme280 = bme.readTemperature();

  //
  pres_bme280 = bme.readPressure();


  hum_bme280 = bme.readHumidity();
  //   digitalWrite(GreenLED, LOW);
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
  
  if (sd_panic) {
    Serial.println("SD card does not seem to be working!!!"); 
  }  else{
    Serial.println("SD card working okay");
    }
  //    //  Serial.println(sensorValue);


  //    digitalWrite(RedLED, HIGH);
      if (!SD.exists(datafile)) {
        File datalog = SD.open(datafile, FILE_WRITE);
 // //
  ////      digitalWrite(RedLED, HIGH);
  //
      if (datalog) {
        datalog.println("dt,ADC1,ADC2,temp_BME,pres_BME,hum_BME,Resistor1,Sensor1,Resistor2,Sensor2");
        Serial.println("Wrote data header");
        datalog.close();
        }
      else {
         sd_panic = initSDCard_now();
      }
      
      }
  
  else {
  File datalog = SD.open(datafile, FILE_WRITE);
  if (datalog) {
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
     }
  else {
  SD.end();
  initSDCard_now();
  }
  SD.end();
  }
  

  uint32_t utime = dt.unixtime();

  int j = counter % NUM_AVGS;
  //Add values to average arrays
  ADC1_vals[j] = valADC;
  ADC2_vals[j] = valADC2;
  temp_vals[j] = temp_bme280;
  pres_vals[j] = pres_bme280;
  hum_vals[j] = hum_bme280;
  unixtimes[j] = utime;

  long valADC1_avg = 0;
  long valADC2_avg = 0;
  float temp_avg = 0.0;
  float pres_avg = 0.0;
  float hum_avg = 0.0;

  if (counter < NUM_AVGS) {
    valADC1_avg = l_average(ADC1_vals, counter + 1);
    valADC2_avg = l_average(ADC2_vals, counter + 1);
    temp_avg = f_average(temp_vals, counter + 1);
    pres_avg = f_average(pres_vals, counter + 1);
    hum_avg = f_average(hum_vals, counter + 1);
  }
  else {
    valADC1_avg = l_average(ADC1_vals, 50);
    valADC2_avg = l_average(ADC2_vals, 50);
    temp_avg = f_average(temp_vals, 50);
    pres_avg = f_average(pres_vals, 50);
    hum_avg = f_average(hum_vals, 50);
  }

  uint32_tToBytes(buffer + 2, utime); //write unixtime to buffer
  ulongToBytes(buffer + 6, valADC1_avg);   //write ADC1 reading to buffer
  ulongToBytes(buffer + 10, valADC2_avg); //write ADC2 reading to buffer

  floatConverter converter;
  converter.f = temp_avg;
  memcpy(buffer + 14, converter.b, 4); //write temp to buffer

  converter.f = pres_avg;
  memcpy(buffer + 18, converter.b, 4); //write pressure to buffer

  converter.f = hum_avg;
  memcpy(buffer + 22, converter.b, 4); //write humidity to buffer

  //TODO --Add battery voltage, whether on feather battery or not
 //counter
 buffer[27] = (uint8_t)(counter >> 8) & 0xff;

 buffer[28] = (uint8_t)(counter & 0xff);
  //sd_panic 
  if (sd_panic){
    buffer[29] = 1;
  }
  else {
    buffer[29] = 0;
  }
  
  if (digitalRead(LORA_REQUEST) == LOW) {
    //    byte data[4] = {0x01, 0x02, 0x03, 0x04};
    Serial.println("LORA Pin is high");
    //    Serial2.write(26);
    Serial2.write(buffer, 29);
  }
  else {
    Serial.println("LORA pin is low. :(");
    }

  counter = counter + 1;
  SD.end();
}





//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      OTHER FUNCTIONS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//
bool initSDCard_now() {
//  // SD card init routine, from Ralph S. Bacon
//  // https://www.youtube.com/watch?v=GQjtG1MeVs4
//
int i = 0;
while ((!SD.begin()) && (i < 5) ) {
    Serial.println("----SD Card not found / responding----");
    Serial.println("------Insert a formatted SD Card-------");
    Serial.println(i);
    SD.end();
////    digitalWrite(GreenLED, HIGH);
////    digitalWrite(RedLED, HIGH);
    i++ ;
    delay(100);
    
  }
//  digitalWrite(GreenLED, LOW);
//  digitalWrite(RedLED, LOW);
  if (i >= 5) {
    return 1;
  }
  else if (check_card == 0){
    return 1;
  }
  else {
    return 0;
  }
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

  sprintf(message, "%04d-%02d-%02d %02d:%02d:%02d", Year, Month, Day, Hour, Minute, Second);

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
