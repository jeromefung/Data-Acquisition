/*
 * Test program for Arduino PHA
 * D. Briotta
 * 02/11/19 
 * 
 * Mimics the behavior of the PHA.ino program,
 * but returns random numbers for data
 * Random numbers should be approx Gaussian
 * around channel 512.
 * 
 */

char num[15];
char receivedChar;
boolean newData = false;
boolean go = false;
const int nrand=16;

void recvOneChar() {
  if (Serial.available() > 0) {
  receivedChar = Serial.read();
  newData = true;
 }
}

void printID() {
  Serial.write("PHA");
}

void setup() {
  // Setup serial port
    Serial.begin(250000);
    while(!Serial);
    delay(100);
    printID();
}

void loop() {
  char ch;
  int i,j, k;
  if (go) {
      //for (i=0; i<10; i++){
        k=0;
        for (j=0; j<nrand; j++){
            k = k + random(1024);
            }
        k=int(k/nrand);
        //sprintf(num,"%d",k);
        //Serial.println(num);
        Serial.println(k);
       //}
  }
  //delay(100);
  recvOneChar();
  if (newData) {
     newData=false;
     if (receivedChar=='g') {
        go = true;
     } else if (receivedChar=='s') {
        go = false;
     } else if (receivedChar=='?') {
        printID();
     } else
        sprintf(num,"%c%d",'\n',-int(receivedChar));
  }
}
