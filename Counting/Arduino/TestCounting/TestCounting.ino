/*
 * Test program for nuclear counting experiment 
 *    Counts for maxticks ms and sends data
 *    Count input on Arduino Uno Pin 5
 */
unsigned long ticks     = 0;    //count interrupts 
unsigned long maxticks  = 1000; //Toggle LED every maxticks
int           counting  = 0;
unsigned long oldData   = 0;
unsigned long nover     = 0;
unsigned long lastmax   = 1000;
long          interval  = 0;
////////////////////////////////////////////////////////////////////
//Timer2 Compare Interrupt Vector, called every 1ms
ISR(TIMER2_COMPA_vect) {
    unsigned long temp;
    unsigned long data;
    //Serial.println("T2");
    if (++ticks > maxticks) {
        ticks = 0;
        if (counting) {
          temp = TCNT1 + (nover << 16);
          data = temp - oldData;
          oldData = temp - (nover << 16);
          nover = 0;
 //Fake data:
    int j;
    const int nrand=16;
    data=0;
    for (j=0; j<nrand; j++){
        data = data + random(1024);
        }
    data=int(data/nrand);
//
          Serial.println(data);
          digitalWrite(13, digitalRead(13)^1);
        }
    }
};
////////////////////////////////////////////////////////////////////
//Timer1 Overflow Interrupt Vector // count when T1 overflows
ISR(TIMER1_OVF_vect) {
    nover++;
};
////////////////////////////////////////////////////////////////////
void printID() {
  Serial.write("CNT"); 
}
////////////////////////////////////////////////////////////////////
void setup() {
    pinMode(5, INPUT_PULLUP); // input pulses to T1
    pinMode(13, OUTPUT);      // LED to blink

// setup the serial monitor
    Serial.begin(250000);
    while (!Serial) ;     // and wait for it
    printID();    //old: Serial.print("C");    // signal ready
// Stop timers
    TCCR1A  = 0;
    TCCR1B  = 0;
    TCCR2A  = 0;
    TCCR2B  = 0;
//
    ticks    = 0;
    interval = 0;
}
////////////////////////////////////////////////////////////////////
void loop() {
  int rcv = 0;
  if (Serial.available() > 0) {
      rcv = Serial.read();
      ////////////////////////////// GO
      if (rcv == int('g')) {
          if (interval > 0) {
            maxticks = interval;
            lastmax = interval;
          } else {
            maxticks = lastmax; // default to last interval
          }
          //Serial.println("Go");
          interval = 0;
          counting = 1;
          oldData = 0;
          ticks   = 0;
          nover   = 0;
// Reset prescalers to start from 0
          GTCCR = 0x83; // reset prescalers, sync counters
// Timer 1 counts pulses on pin 5
          TCCR1A = 0;
          TCCR1B = 0;
          TCCR1B = 0x07;
          TIFR1  = 0x00;
          TIMSK1 = 0x01;     // interrupt on overflow
// timer 2 generates 1 ms interrupt
          TCCR2A = 0;
          TCCR2B = 0;
          TCCR2A  = 0x02;           // CTC mode, match OCR2A
          TCCR2B  = 0x04;           // Prescaler = 64
          OCR2A   = 250 - 1 ;       //  for 1 kHz clock
          TIMSK2  = (1 << OCIE2A);  // interrupt on match A
// Go
          TCNT1  = 0;
          TCNT2  = 0;
          GTCCR   = 0;  // syncronous start both counters
      }
      ////////////////////////////// STOP
      if (rcv == int('s')) {
          TCCR1A = 0;
          TCCR1B = 0;
          TCCR2A = 0;
          TCCR2B = 0;
          counting = 0;
          interval = 0;
          //Serial.println("Stop");
      }
      ////////////////////////////// INTERVAL INPUT
      if (isdigit(rcv)) {
        interval = 10 * interval + int(rcv) - int('0');
      }
      ////////////////////////////// Send program ID
      if (rcv == int('?')) {
        printID();
      }
  }
}
 
