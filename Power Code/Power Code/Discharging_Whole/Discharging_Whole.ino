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
unsigned int rest_timer,rest_timer_rest;
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


/////////////try battery control
float V_measure_1, V_measure_2;
float V_measure_1_temp, V_measure_2_temp;
float V_max = 2500.00;

//added
float current_previous;
double soc_1, soc_2;


/////
float V_pd;
float V_pd_previous;
float V_pd_temp;


void setup() {
  //Some General Setup Stuff

  Wire.begin(); // We need this for the i2c comms for the current sensor
  Wire.setClock(700000); // set the comms speed for i2c
  ina219.init(); // this initiates the current sensor
  Serial.begin(9600); // USB Communications


  //Check for the SD Card
  Serial.println("\nInitializing SD card...");
  if (!SD.begin(chipSelect)) {
    Serial.println("* is a card inserted?");
    while (true) {} //It will stick here FOREVER if no SD is in on boot
  } else {
    Serial.println("Wiring is correct and a card is present.");
  }

  if (SD.exists("BatCycle.csv")) { // Wipe the datalog when starting
    SD.remove("BatCycle.csv");
  }

  
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

  //Vpd
  pinMode(A1, INPUT);

/////////////try battery
  pinMode(A2, INPUT); //V_measure_1
  pinMode(A3, INPUT); //V_measure_2
  pinMode(4, OUTPUT); //Rely_1
  pinMode(5, OUTPUT); //Rely_2


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
  if (loop_trigger == 1){ // FAST LOOP (1kHZ)
      state_num = next_state; //state transition
      //V_Bat = analogRead(A0)*4.096/1.03; //check the battery voltage (1.03 is a correction for measurement error, you need to check this works for you)
      V_pd = analogRead(A1)*2.69697*4.096/1.03;
        
       //////////////try battery balance
      V_measure_1 = analogRead(A2)*4.096/1.03;
      V_measure_2 = analogRead(A3)*4.096/1.03;
   
      /*
      if ((V_Bat > 3700 || V_Bat < 2400)) { //Checking for Error states (just battery voltage for now)
          state_num = 5; //go directly to jail
          next_state = 5; // stay in jail
          digitalWrite(7,true); //turn on the red LED
          current_ref = 0; // no current
      }
      */
      current_measure = (ina219.getCurrent_mA()); // sample the inductor current (via the sensor chip)
      error_amps = (current_ref - current_measure) / 1000; //PID error calculation
      pwm_out = pidi(error_amps); //Perform the PID controller calculation
      pwm_out = saturation(pwm_out, 0.99, 0.01); //duty_cycle saturation
      analogWrite(6, (int)(255 - pwm_out * 255)); // write it out (inverting for the Buck here)
      int_count++; //count how many interrupts since this was last reset to zero
      loop_trigger = 0; //reset the trigger and move on with life
  }
  
  if (int_count == 1000) { // SLOW LOOP (1Hz)
    input_switch = digitalRead(2); //get the OL/CL switch status
        switch (state_num) { // STATE MACHINE (see diagram)
            case 0:{ // Start state (nothing, LED off)
              current_ref = -350;
                if (input_switch == 1) { // if switch, move to charge
                 digitalWrite(4,false);
                  digitalWrite(5,false);
                   next_state = 1;
                  digitalWrite(8,true);
                } else { // otherwise stay put
                    
                    next_state = 0;
                    digitalWrite(8,false);
                    digitalWrite(7,false);
                 }
                break;
                 }
      
      case 1:{ // discharge state
        digitalWrite(4,false);
        digitalWrite(5,false);//off relays
        current_ref = -580;
        if (rest_timer < 20) { //within 30s, green LED charging
          next_state = 1;
          digitalWrite(8,true); 
          rest_timer++;         
        } else { // otherwise go to measure stage, red LED
          next_state = 2;
          digitalWrite(8,false);
          digitalWrite(7,true);
          rest_timer = 0;
        }
        if(input_switch == 0){ // UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
        }
        break;
      }
      case 2:{ // Measure stage, red LED
        if (rest_timer_rest < 3) { // Stay here if timer < 3
                    digitalWrite(5, true);
          digitalWrite(4, true);
          next_state = 2;
          digitalWrite(8,false);
            digitalWrite(7,true);
          rest_timer_rest ++;
        } 
        else
        {
          digitalWrite(5, true);
          digitalWrite(4, true);

          if(V_measure_1 > V_max)
            {
                V_measure_1_temp = V_measure_1;
                digitalWrite(5, false);
                

                if(2500.0 < V_measure_1_temp && V_measure_1_temp < 2900.0)
                {
                  soc_1 = 2;
                }
                else if(2900.0 < V_measure_1_temp && V_measure_1_temp < 3100.0)
                {
                  soc_1 = 5;
                }
                else if(3100.0 < V_measure_1_temp && V_measure_1_temp < 3200.0)
                {
                  soc_1 = 10;
                }
                else if(3200.0 < V_measure_1_temp && V_measure_1_temp < 3230.0)
                {
                  soc_1 = 15;
                }
                else if(3230.0 < V_measure_1_temp && V_measure_1_temp < 3250.0)
                {
                  soc_1 = 20;
                }
                else if(3250.0 < V_measure_1_temp && V_measure_1_temp < 3280.0)
                {
                  soc_1 = 25;
                }
                else if(3280.0 < V_measure_1_temp && V_measure_1_temp < 3300.0)
                {
                  soc_1 = 30;
                }
                else if(3300.0 < V_measure_1_temp && V_measure_1_temp < 3310.0)
                {
                  soc_1 = 40;
                }
                else if(3310.0 < V_measure_1_temp && V_measure_1_temp < 3320.0)
                {
                  soc_1 = 50;
                }
                else if(3320.0 < V_measure_1_temp && V_measure_1_temp < 3330.0)
                {
                  soc_1 = 60;
                }
                else if(3330.0 < V_measure_1_temp && V_measure_1_temp < 3340.0)
                {
                  soc_1 = 70;
                }
                else if(3340.0 < V_measure_1_temp && V_measure_1_temp < 3350.0)
                {
                  soc_1 = 80;
                }
                else if(3350.0 < V_measure_1_temp && V_measure_1_temp < 3360.0)
                {
                  soc_1 = 90;
                }
                else if(V_measure_1_temp > 3360.0)
                {
                  soc_1 = 100;
                }
                next_state = 1;
            }
          else
            {
                V_measure_1_temp = V_measure_1;
                digitalWrite(5, true);
                Serial.println("Battery 1 Discharged!");
                soc_1 = 0;
                next_state = 3;
                
            }
          
            if(V_measure_2 > V_max)
            {
                    V_measure_2_temp = V_measure_2;
                    digitalWrite(4, false);
                    
                if(2500.0 < V_measure_2_temp && V_measure_2_temp < 2900.0)
                {
                  soc_2 = 2;
                }
                else if(2900.0 < V_measure_2_temp && V_measure_2_temp < 3100.0)
                {
                  soc_2 = 5;
                }
                else if(3100.0 < V_measure_2_temp && V_measure_2_temp < 3200.0)
                {
                  soc_2 = 10;
                }
                else if(3200.0 < V_measure_2_temp && V_measure_2_temp < 3230.0)
                {
                  soc_2 = 15;
                }
                else if(3230.0 < V_measure_2_temp && V_measure_2_temp < 3250.0)
                {
                  soc_2 = 20;
                }
                else if(3250.0 < V_measure_2_temp && V_measure_2_temp < 3280.0)
                {
                  soc_2 = 25;
                }
                else if(3280.0 < V_measure_2_temp && V_measure_2_temp < 3300.0)
                {
                  soc_2 = 30;
                }
                else if(3300.0 < V_measure_2_temp && V_measure_2_temp < 3310.0)
                {
                  soc_2 = 40;
                }
                else if(3310.0 < V_measure_2_temp && V_measure_2_temp < 3320.0)
                {
                  soc_2 = 50;
                }
                else if(3320.0 < V_measure_2_temp && V_measure_2_temp < 3330.0)
                {
                  soc_2 = 60;
                }
                else if(3330.0 < V_measure_2_temp && V_measure_2_temp < 3340.0)
                {
                  soc_2 = 70;
                }
                else if(3340.0 < V_measure_2_temp && V_measure_2_temp < 3350.0)
                {
                  soc_2 = 80;
                }
                else if(3350.0 < V_measure_2_temp && V_measure_2_temp < 3360.0)
                {
                  soc_2 = 90;
                }
                else if(V_measure_2_temp > 3360.0)
                {
                  soc_2 = 100;
                }
                next_state = 1;
                    
            }
          else
          {
            V_measure_2_temp = V_measure_2;
            digitalWrite(4, true);
            Serial.println("Battery 2 finished!");
            next_state = 3;
            soc_2 = 100;
            
          }

          rest_timer_rest = 0;
        }
  
        
        if(input_switch == 0){ // UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
        }
        break;        
      }
      case 3:{ //CHarging finished, both LED

         Serial.println("DisCharging finished!!!");
         digitalWrite(8,true);
         digitalWrite(7,true);
        if(input_switch == 0){ //UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(8,false);
        }
        break;
      }
      case 5: { // ERROR state RED led and no current
        next_state = 5; // Always stay here
        digitalWrite(7,true);
        digitalWrite(8,false);
        if(input_switch == 0){ //UNLESS the switch = 0, then go back to start
          next_state = 0;
          digitalWrite(7,false);
        }
        break;
      }

      default :{ // Should not end up here ....
        Serial.println("Boop");
        current_ref = 0;
        next_state = 5; // So if we are here, we go to error
        digitalWrite(7,true);
      }
      
    }
    
    dataString = String(state_num) + "," + String(current_ref) + + "," + String(current_measure)+ "," +String(V_pd_temp) + "," + String(V_measure_1_temp) + "," + String (V_measure_2_temp)+ "," + String(soc_1)+ "," + String(soc_2); //build a datastring for the CSV file
    Serial.println(dataString); // send it to serial as well in case a computer is connected
    File dataFile = SD.open("BatCycle.csv", FILE_WRITE); // open our CSV file
    if (dataFile){ //If we succeeded (usually this fails if the SD card is out)
      dataFile.println(dataString); // print the data
    } else {
      Serial.println("File not open"); //otherwise print an error
    }
    dataFile.close(); // close the file
    int_count = 0; // reset the interrupt count so we dont come back here for 1000ms
  }
}

// Timer A CMP1 interrupt. Every 1000us the program enters this interrupt. This is the fast 1kHz loop
ISR(TCA0_CMP1_vect) {
  loop_trigger = 1; //trigger the loop when we are back in normal flow
  TCA0.SINGLE.INTFLAGS |= TCA_SINGLE_CMP1_bm; //clear interrupt flag
}

float saturation( float sat_input, float uplim, float lowlim) { // Saturation function
  if (sat_input > uplim) sat_input = uplim;
  else if (sat_input < lowlim ) sat_input = lowlim;
  else;
  return sat_input;
}

float pidi(float pid_input) { // discrete PID function
  float e_integration;
  e0i = pid_input;
  e_integration = e0i;

  //anti-windup
  if (u1i >= ui_max) {
    e_integration = 0;
  } else if (u1i <= ui_min) {
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
