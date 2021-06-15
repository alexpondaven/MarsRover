#include <Wire.h>
#include <INA219_WE.h>
#include <SPI.h>
#include <SD.h>

INA219_WE ina219; // this is the instantiation of the library for the current sensor

// set up variables using the SD utility library functions:
Sd2Card card;
SdVolume volume;
SdFile root;

const int chipSelect = 10;
unsigned int rest_timer;
unsigned int loop_trigger;
unsigned int int_count = 0; // a variables to count the interrupts. Used for program debugging.
float u0i, u1i, delta_ui, e0i, e1i, e2i; // Internal values for the current controller
float ui_max = 1, ui_min = 0; //anti-windup limitation
float kpi = 0.02512, kii = 39.4, kdi = 0; // current pid.
float Ts = 0.001; //1 kHz control frequency.
float current_measure, current_ref = 0, error_amps; // Current Control
float pwm_out;
float V_Bat;
boolean input_switch;
int state_num=0,next_state;
String dataString;

//add voltage pid
float kpv=0.05024,kiv=15.78,kdv=0; // voltage pid.
float u0v,u1v,delta_uv,e0v,e1v,e2v; // u->output; e->error; 0->this time; 1->last time; 2->last last time
float uv_max=4, uv_min=0; //anti-windup limitation
float voltage_ref = 0, error_volts, current_volts = 0;

//added
float current_previous;
double soc = 0.85;
float soc_last_value;



void setup() 
{
  //Some General Setup Stuff

  Wire.begin(); // We need this for the i2c comms for the current sensor
  Wire.setClock(700000); // set the comms speed for i2c
  ina219.init(); // this initiates the current sensor
  Serial.begin(9600); // USB Communications


  //Check for the SD Card
  Serial.println("\nInitializing SD card...");
  if (!SD.begin(chipSelect))
  {
    Serial.println("* is a card inserted?");
    while (true) {} //It will stick here FOREVER if no SD is in on boot
  } 
  
  else
  {
    Serial.println("Wiring is correct and a card is present.");
  }

  if (SD.exists("BatCycle.csv"))
  { // Wipe the datalog when starting
    SD.remove("BatCycle.csv");
  }

  
  
  /*
  //////////////////try read
  else if (SD.exists("soc.csv"))
  { // Wipe the datalog when starting
    File soc_last = SD.open("soc.csv",FILE_READ);
    soc_last_value = read_file(soc_last);
    SD.remove("soc.csv");
    Serial.println("soc.csv removed.");
  }
  */
  
  noInterrupts(); //disable all interrupts
  analogReference(EXTERNAL); // We are using an external analogue reference for the ADC

  //SMPS Pins
  pinMode(13, OUTPUT); // Using the LED on Pin D13 to indicate status
  pinMode(2, INPUT_PULLUP); // Pin 2 is the input from the CL/OL switch
  pinMode(6, OUTPUT); // This is the PWM Pin

  //LEDs on pin 7 and 8
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);

  //Analogue input, the battery voltage (also port B voltage)
  pinMode(A0, INPUT);

  // TimerA0 initialization for 1kHz control-loop interrupt.
  TCA0.SINGLE.PER = 999; //
  TCA0.SINGLE.CMP1 = 999; //
  TCA0.SINGLE.CTRLA = TCA_SINGLE_CLKSEL_DIV16_gc | TCA_SINGLE_ENABLE_bm; //16 prescaler, 1M.
  TCA0.SINGLE.INTCTRL = TCA_SINGLE_CMP1_bm;

  // TimerB0 initialization for PWM output
  TCB0.CTRLA = TCB_CLKSEL_CLKDIV1_gc | TCB_ENABLE_bm; //62.5kHz

  interrupts();  //enable interrupts.
  analogWrite(6, 120); //just a default state to start with
}







void loop() {
  digitalWrite(13, HIGH);
  if (loop_trigger == 1)
  { // FAST LOOP (1kHZ)
      state_num = next_state; //state transition
      V_Bat = analogRead(A0)*4.096/1.03; //check the battery voltage (1.03 is a correction for measurement error, you need to check this works for you)
      
      if ((V_Bat > 3700 || V_Bat < 2400)) 
      { //Checking for Error states (just battery voltage for now)
          state_num = 4; //go directly to jail
          next_state = 4; // stay in jail
          digitalWrite(7,true); //turn on the red LED
          current_ref = 0; // no current
      }

      current_measure = (ina219.getCurrent_mA()); // sample the inductor current (via the sensor chip)

      if (voltage_ref == 0)
      {
        error_amps = (current_ref - current_measure) / 1000; //PID error calculation
        pwm_out = pidi(error_amps); //Perform the PID controller calculation
        pwm_out = saturation(pwm_out, 0.99, 0.01); //duty_cycle saturation
        analogWrite(6, (int)(255 - pwm_out * 255)); // write it out (inverting for the Buck here)
      }
      
      else
      {
        error_volts = voltage_ref - V_Bat;
        current_volts = pidv(error_volts);
        current_volts = saturation(current_volts, 0.25, 0);
        error_amps = current_volts - (current_measure/(1000.0));
        pwm_out = pidi(error_amps);
        pwm_out = saturation(pwm_out, 0.99, 0.01);
        analogWrite(6, (int)(255 - pwm_out * 255));
      }
      
      int_count++; //count how many interrupts since this was last reset to zero
      loop_trigger = 0; //reset the trigger and move on with life
  }
  
  if (int_count == 1000) 
  { // SLOW LOOP (1Hz)
    input_switch = digitalRead(2); //get the OL/CL switch status
    
    switch (state_num) 
    { // STATE MACHINE (see diagram)
      
      case 0:
      { // Default state (no current, no LEDs)
        current_ref = 0;
        voltage_ref = 0;
        
        if (input_switch == 1)
        { // if switch, move to constant current (CC) charge state, green LED
          next_state = 2;
          digitalWrite(8,true);
        }
        
        else
        { // otherwise stay at Default state
          next_state = 0;
          digitalWrite(8,false);
          digitalWrite(7,false);
        }
        
        break;
      }
      
      case 1:
      { // constant current (CC) charge state (250mA and a green LED)
        current_ref = 250;
        voltage_ref = 0;
        
        if (V_Bat < 3400)
        { // if not fully charged to CV requirement, stay put
          next_state = 1;
          digitalWrite(8,true);
        }
        
        else
        { // otherwise go to constant voltage (CV) mode
          next_state = 2;
          digitalWrite(8,false);
          current_ref = 0;
        }
        
        if(input_switch == 0)
        { // UNLESS the switch = 0, then go back to Default state
          next_state = 0;
          digitalWrite(8,false);
        }
        
        break;
      }
      
      case 2:
      { // constant voltage (CV) charge state (3.6V and a green LED)
        //current_ref = 0;
        voltage_ref = 3500;
        
        if (current_measure > 50)
        { // if not fully charged battery, stay put
          next_state = 2;
          digitalWrite(8,true);
        }
        
        else
        { // otherwise go to charge rest state
          next_state = 3;
          digitalWrite(8,false);
        }
        
        if(input_switch == 0)
        { // UNLESS the switch = 0, then go back to Default state
          next_state = 0;
          digitalWrite(8,false);
        }
        
        break;
      }
      
      case 3:
      { // Charge Rest, green LED is off and no current
        current_ref = 0;
        voltage_ref = 0;
        
        if (rest_timer < 30)
        { // Stay here if timer < 30
          next_state = 3;
          digitalWrite(8,false);
          rest_timer++;
        }
        
        else
        { // Or move to Default state (and reset the timer)
          next_state = 0;
          digitalWrite(8,false);
          rest_timer = 0;
        }
        
        if(input_switch == 0)
        { // UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
        }
        
        break;        
      }
      
      case 4: 
      { // ERROR state RED led and no current
        current_ref = 0;
        voltage_ref = 0;
        next_state = 4; // Always stay here
        digitalWrite(7,true);
        digitalWrite(8,false);
        
        if(input_switch == 0)
        { //UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(7,false);
        }
        
        break;
      }

      /*
      case 5:
      { //Discharge state (-250mA and both LEDs)
         current_ref = -250;
         
         if (V_Bat > 2500)
         { // While not at minimum volts, stay here
           next_state = 5;
           digitalWrite(7,true);
           digitalWrite(8,true);
         }
         
         else
         { // If we reach full discharged, move to rest
           next_state = 6;
           digitalWrite(8,false);
         }
         
         if(input_switch == 0)
         { //UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
         }
         
        break; 
      }
      
      case 6:
      { // Discharge rest, no LEDs no current
        current_ref = 0;
        
        if (rest_timer < 30)
        { // Rest here for 30s like before
          next_state = 6;
          digitalWrite(8,false);
          rest_timer++;
        }
        
        else
        { // When thats done, move back to charging (and light the green LED)
          next_state = 1;
          //digitalWrite(8,true);
          rest_timer = 0;
        }
        
        if(input_switch == 0)
        { //UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
        }
        
        break;
      }
      */
      
      default :
      { // Should not end up here ....
        Serial.println("Boop");
        current_ref = 0;
        voltage_ref = 0;
        next_state = 4; // So if we are here, we go to error
        digitalWrite(7,true);
      }
      
    }

    //current measure SoC
    soc = soc + (integral(current_measure, current_previous))/(500);
    current_previous = current_measure;
    
    dataString = String(state_num) + "," + String(V_Bat) + "," + String(current_ref) + "," + String(current_measure) + "," + String(soc*100); //build a datastring for the CSV file
    Serial.println(dataString); // send it to serial as well in case a computer is connected
    File dataFile = SD.open("BatCycle.csv", FILE_WRITE); // open our CSV file
    
    if (dataFile)
    { //If we succeeded (usually this fails if the SD card is out)
      dataFile.println(dataString); // print the data
    }
    
    else
    {
      Serial.println("File not open"); //otherwise print an error
    }
    
    dataFile.close(); // close the file
    
    ////////////////////try write file
    File dataFile_soc = SD.open("SoC.csv", FILE_WRITE); // open SoC file
    if (dataFile_soc)
    { //If we succeeded (usually this fails if the SD card is out)
      dataFile_soc.println(String(soc*100 + soc_last_value)); // print the data
    }
    
    else
    {
      Serial.println("File not open"); //otherwise print an error
    }
    
    dataFile_soc.close(); // close the file 
    
    int_count = 0; // reset the interrupt count so we dont come back here for 1000ms
  }
  digitalWrite(13, LOW);
}




// Timer A CMP1 interrupt. Every 1000us the program enters this interrupt. This is the fast 1kHz loop
ISR(TCA0_CMP1_vect) 
{
  loop_trigger = 1; //trigger the loop when we are back in normal flow
  TCA0.SINGLE.INTFLAGS |= TCA_SINGLE_CMP1_bm; //clear interrupt flag
}


float saturation( float sat_input, float uplim, float lowlim) 
{ // Saturation function
  if (sat_input > uplim) sat_input = uplim;
  else if (sat_input < lowlim ) sat_input = lowlim;
  else;
  return sat_input;
}


// This is a PID controller for the voltage

float pidv( float pid_input){
  float e_integration;
  e0v = pid_input;
  e_integration = e0v;
 
  //anti-windup, if last-time pid output reaches the limitation, this time there won't be any intergrations.
  if(u1v >= uv_max) {
    e_integration = 0;
  } else if (u1v <= uv_min) {
    e_integration = 0;
  }

  delta_uv = kpv*(e0v-e1v) + kiv*Ts*e_integration + kdv/Ts*(e0v-2*e1v+e2v); //incremental PID programming avoids integrations.there is another PID program called positional PID.
  u0v = u1v + delta_uv;  //this time's control output

  //output limitation
  saturation(u0v,uv_max,uv_min);
  
  u1v = u0v; //update last time's control output
  e2v = e1v; //update last last time's error
  e1v = e0v; // update last time's error
  return u0v;
}

// This is a PID controller for the current

float pidi(float pid_input) 
{ // discrete PID function
  float e_integration;
  e0i = pid_input;
  e_integration = e0i;

  //anti-windup
  if (u1i >= ui_max) 
  {
    e_integration = 0;
  }
  else if (u1i <= ui_min)
  {
    e_integration = 0;
  }

  delta_ui = kpi * (e0i - e1i) + kii * Ts * e_integration + kdi / Ts * (e0i - 2 * e1i + e2i); //incremental PID programming avoids integrations.
  u0i = u1i + delta_ui;  //this time's control output

  //output limitation
  saturation(u0i, ui_max, ui_min);

  u1i = u0i; //update last time's control output
  e2i = e1i; //update last last time's error
  e1i = e0i; // update last time's error
  return u0i;
}


//////////////////try integration

float integral(float current_measure, float current_previous)
{ 
  float trapezoidal = (1.00/(2.00 * 3600.00)) * (current_measure + current_previous);
  return trapezoidal;
}




//////////////////////////try read file
float read_file (File soc_last)
{
  // open the file for reading:
    String temp;
    while (temp != -1)
    {
      temp = soc_last.read();
    }
    soc_last.close();
    return temp.toFloat();
}
