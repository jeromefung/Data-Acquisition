/*
   PHA.ino - Arduino PHA program
   D. Briotta
   02/11/19
   - Changed to new command system,
   - upped baud rate to max 250000

   PROTOCOL: After reset, waits for:
            ID command ('?') -> sends host ID string ('PHA')
            Go command ('g') to enable interrupts for data collection
            Stop command('s') commands to disable
            enable/disable interrupts for data collection.

   INPUTS:  Interrupt on digital pin 2  -- from Linear Gate BUSY
            Analog input on A3          -- from S/H output (Pin 5)

   OUTPUTS: Reset on Pin 13 - to Flip/Flop clear (pin 1)
            A/D values printed in ASCII -- to Serial port

*/

const int     ledPin = 13;
volatile int  val = 0;
boolean       go = false;
char          num[15];
char          rcv;

void dataGrab() {
  if (go) {
    val = analogRead(A3);
    Serial.println(val);
  }
  digitalWrite(ledPin, LOW);  // always(!) reset the flip-flop
  digitalWrite(ledPin, HIGH);
}

void printID() {
  Serial.write("PHA");
}

void setup() {

  Serial.begin(250000);   // setup serial port:
  while (!Serial) ;         // and wait for it

  analogReference(DEFAULT);  // Analog default (+5V full scale) 
  pinMode(2, INPUT_PULLUP);  // INT signal on digital pin 2

  attachInterrupt(digitalPinToInterrupt(2), dataGrab, RISING); // call dataGrab on rising edge of pin

  pinMode(ledPin, OUTPUT);    // Use LED pin to reset flip-flop
  digitalWrite(ledPin, LOW);  // hold flip-flop cleared for now

  printID();
}

void loop() {
 // rcv = Serial.read();
      if (Serial.available() > 0) {
          rcv = Serial.read();     //Serial.println(rcv);
          if (rcv == int('g')) {
            go = true;
            digitalWrite(ledPin, HIGH); // enable flip-flop
            }
          if (rcv == int('s')) {
            go = false;
            digitalWrite(ledPin, LOW); // hold flip-flop cleared
            }
          if (rcv == int('?')) {
            printID();  // send program ID
            }
      }
 }

