import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

import processing.serial.*;

import java.awt.Point;
import oscP5.*;
import netP5.*;

import java.util.Hashtable;
import java.awt.*;
import java.awt.image.BufferedImage;


//CHANGE ME for testing
//disables serial port access
//and sets server to localhost
boolean testMode = false;



//dont change anything past here. Things will break


boolean serialEnabled = false;
String serverIP = "127.0.0.1";

OscP5 oscP5;

//audio
Minim minim;
ConsoleAudio consoleAudio;

DropDisplay dropDisplay; //display for the drop scene
WarpDisplay2 warpDisplay; //warp scene
WeaponsConsole weaponsDisplay;  //tactical weapons display
SignalTracker signalTracker;    //signal tracker for nebula scene
TowingDisplay towingDisplay;    //grappling hook display

BootDisplay bootDisplay; //boot up sequence

//system for displaying messageboxes
BannerOverlay bannerSystem = new BannerOverlay();

//time (local ms) in which the ship died
long deathTime = 0;


//default display font (hanzelextended)
PFont font;

//display handling, maps server osc strings to displays defined above. Add new displays to this
Hashtable<String, Display> displayMap = new Hashtable<String, Display>();
Display currentScreen;  //screen that is currently being displayed

//power for something, not sure what
int systemPower = -1;

//serial stuff
Serial serialPort;
String serialBuffer = "";
String lastSerial = "";


//hearbeat blinking timer
long heartBeatTimer = 0;

//time we last got damaged
int damageTimer = -1000;
PImage noiseImage; //static image that flashes


//global var for blinking things, this toggles true/false every 750ms
boolean globalBlinker = false;
long blinkTime = 0;


ShipState shipState = new ShipState();

void setup() {
  size(1024, 768, P3D);
  frameRate(25);
  hideCursor();



  shipState.poweredOn = true;
  if (testMode) {
    serialEnabled = false;
    serverIP = "127.0.0.1";
    //shipState.poweredOn = true;
  } 
  else {
    serialEnabled = true;
    serverIP = "10.0.0.100";
    frame.setLocation(1024, 0);
    serialPort = new Serial(this, "COM3", 9600);
  }




  oscP5 = new OscP5(this, 12004);
  dropDisplay = new DropDisplay();
  //radarDisplay = new RadarDisplay();
  warpDisplay = new WarpDisplay2();
  weaponsDisplay = new WeaponsConsole(oscP5, serverIP, this);
  signalTracker = new SignalTracker(oscP5, serverIP);
  //towingDisplay = new TowingDisplay(oscP5, serverIP);


  displayMap.put("weapons", weaponsDisplay);
  displayMap.put("drop", dropDisplay);
  displayMap.put("hyperspace", warpDisplay);
  displayMap.put("signalTracker", signalTracker);
  displayMap.put("selfdestruct", new DestructDisplay());
  // displayMap.put("towing", towingDisplay);
  displayMap.put("pwned", new PwnedDisplay());
  currentScreen = dropDisplay;

  bootDisplay = new BootDisplay();
  displayMap.put("boot", bootDisplay);    ///THIS    

  font = loadFont("HanzelExtendedNormal-48.vlw");

  /* power down the tac console panel */
  if (serialEnabled) {
    serialPort.write("p,");
  }
  noiseImage = loadImage("noise.png");

  //audio stuff
  minim = new Minim(this);
  consoleAudio = new ConsoleAudio(minim);

  /*sync to current game screen*/
  OscMessage myMessage = new OscMessage("/game/Hello/TacticalStation");  
  oscP5.send(myMessage, new NetAddress(serverIP, 12000));
}

/* these are just for testing when serial devices arent available */
void keyPressed() {
  if (key >= '0' && key <= '9') {
    consoleAudio.randomBeep();
    currentScreen.serialEvent("KEY:" + key);
  } 
  else if ( key == ' ') {
    currentScreen.serialEvent("KEY:SCAN");
  } 
  else if ( key == 'm') {
    currentScreen.serialEvent("KEY:FIRELASER" );
  } 
  else if ( key == 'f') {
    currentScreen.serialEvent("KEY:DECOY");
  } 
  else if (key == 'g') {
    currentScreen.serialEvent("KEY:GRAPPLEFIRE");
  } 
  else if (key == 'h') {
    currentScreen.serialEvent("KEY:GRAPPLERELEASE");
  }
}

/* expected vals:
 * 0-9 from keypad
 * ' ' = scan key
 * 'F' = any of the beam bank buttons
 * 'm' = decoy button
 * 'X' = conduit puzzle failed
 * 'P' = conduit puzzle complete
 * 'CX' = cable X connected correctly
 */
void dealWithSerial(String vals) {
  // println(vals);

  char c = vals.charAt(0);
  if (c >= '0' && c <= '9') {
    String v = "KEY:" + c;
    consoleAudio.randomBeep();
    currentScreen.serialEvent(v);
  }
  if (c == ' ') {
    currentScreen.serialEvent("KEY:SCAN");
  }
  if (c == 'F') {
    currentScreen.serialEvent("KEY:FIRELASER");
  }
  if (c == 'm') {
    currentScreen.serialEvent("KEY:DECOY");
  }

  if (c == 'X') {
    currentScreen.serialEvent("CONDUIT:X");
  } 
  if (c == 'P') {
    currentScreen.serialEvent("CONDUIT:P");
  }
  if (c == 'C') {

    currentScreen.serialEvent("CONDUIT:" + vals.charAt(1));
  }
}

/* switch to a new display */
void changeDisplay(Display d) {
  currentScreen.stop();
  currentScreen = d;
  currentScreen.start();
}


void draw() {
  if (blinkTime + 750 < millis()) {
    blinkTime = millis();
    globalBlinker = ! globalBlinker;
  }
  noSmooth();
  if (serialEnabled) {
    while (serialPort.available () > 0) {
      char val = serialPort.readChar();
      //println(val);
      if (val == ',') {
        //get first char
        dealWithSerial(serialBuffer);
        serialBuffer = "";
      } 
      else {
        serialBuffer += val;
      }
    }
  }




  background(0, 0, 0);

  if (shipState.areWeDead) {
    fill(255, 255, 255);
    if (deathTime + 2000 < millis()) {
      textFont(font, 60);
      text("YOU ARE DEAD", 50, 300);
      textFont(font, 20);
      int pos = (int)textWidth(shipState.deathText);
      text(shipState.deathText, (width/2) - pos/2, 340);
    }
  } 
  else {

    if (shipState.poweredOn) {
      currentScreen.draw();
    } 
    else {
      if (shipState.poweringOn) {
        bootDisplay.draw();
        if (bootDisplay.isReady()) {
          shipState.poweredOn = true;
          shipState.poweringOn = false;
          /* sync current display to server */
          OscMessage myMessage = new OscMessage("/game/Hello/TacticalStation");  
          oscP5.send(myMessage, new NetAddress(serverIP, 12000));
          oscP5.send(myMessage, new NetAddress(serverIP, 12000));
          bannerSystem.cancel();
          println("BOOTED");
        }
      }
    }
    hint(DISABLE_DEPTH_TEST) ;
    bannerSystem.draw();
  }

  if (heartBeatTimer > 0) {
    if (heartBeatTimer + 400 > millis()) {
      int a = (int)map(millis() - heartBeatTimer, 0, 400, 255, 0);
      fill(0, 0, 0, a);
      rect(0, 0, width, height);
    } 
    else {
      heartBeatTimer = -1;
    }
  }
  if ( damageTimer + 1000 > millis()) {
    if (random(10) > 3) {
      image(noiseImage, 0, 0, width, height);
    }
  }
}

void oscEvent(OscMessage theOscMessage) {
  // println(theOscMessage);
  if (theOscMessage.checkAddrPattern("/scene/change")==true) {
    /*
    int disp = theOscMessage.get(0).intValue();
     if (disp > displayListMap.length ) {
     disp = 0;
     }
     println(disp);
     disp = displayListMap[disp];
     println(disp);
     displayList[currentDisplay].stop();
     currentDisplay = disp;
     displayList[currentDisplay].start();
     return;*/
  } 
  else if (theOscMessage.checkAddrPattern("/scene/warzone/weaponState") == true) {
    int msg = theOscMessage.get(0).intValue();
    if (msg == 1) {
      if (serialEnabled) {
        serialPort.write("P,");
      }
    } 
    else {
      if (serialEnabled) {

        serialPort.write("p,");
      }
    }

    currentScreen.oscMessage(theOscMessage);
  } 
  else if (theOscMessage.checkAddrPattern("/system/reactor/stateUpdate")==true) {
    int state = theOscMessage.get(0).intValue();
    String flags = theOscMessage.get(1).stringValue();
    String[] fList = flags.split(";");
    //reset flags
    bootDisplay.brokenBoot = false;
    for (String f : fList) {
      if (f.equals("BROKENBOOT")) {
        println("BROKEN BOOT");
        bootDisplay.brokenBoot = true;
      }
    }

    if (state == 0) {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
      bootDisplay.stop();
      bootDisplay.stop();
      bannerSystem.cancel();
      if (serialEnabled) {
        serialPort.write("p,");
      }
    } 
    else {


      if (!shipState.poweredOn ) {
        shipState.poweringOn = true;

        changeDisplay(bootDisplay);
        if (serialEnabled) {
          serialPort.write("P,");
        }
      }
    }
  } 
  else if (theOscMessage.checkAddrPattern("/scene/youaredead") == true) {
    //oh noes we died
    shipState.areWeDead = true;
    deathTime = millis();
    shipState.deathText = theOscMessage.get(0).stringValue();
    if (serialEnabled) {
      serialPort.write("p,");
    }
  } 
  else if (theOscMessage.checkAddrPattern("/game/reset") == true) {
    //reset the entire game
    changeDisplay(weaponsDisplay);
    shipState.areWeDead = false;
    shipState.poweredOn = false;
    shipState.poweringOn = false;
    if (serialEnabled) {
      serialPort.write("p,");
    }
    shipState.smartBombsLeft = 6;
  } 
  else if (theOscMessage.checkAddrPattern("/system/subsystemstate") == true) {
    systemPower = theOscMessage.get(1).intValue() + 1;
    currentScreen.oscMessage(theOscMessage);
  }
  else if (theOscMessage.checkAddrPattern("/tactical/powerState") == true) {

    if (theOscMessage.get(0).intValue() == 1) {
      shipState.poweredOn = true;
      shipState.poweringOn = false;
      bootDisplay.stop();
      OscMessage myMessage = new OscMessage("/game/Hello/TacticalStation");  
      oscP5.send(myMessage, new NetAddress(serverIP, 12000));
      if (serialEnabled) {

        serialPort.write("P,");
      }
    } 
    else {
      shipState.poweredOn = false;
      shipState.poweringOn = false;
      if (serialEnabled) {

        serialPort.write("p,");
      }
    }
  }
  else if (theOscMessage.checkAddrPattern("/ship/effect/heartbeat") == true) {
    heartBeatTimer = millis();
  } 
  else if (theOscMessage.checkAddrPattern("/ship/damage")==true) {

    damageTimer = millis();
    if (serialEnabled) {

      serialPort.write("S,");
    }
    float damage = theOscMessage.get(0).floatValue();
    if (damage > 8.0 && random(100) < 10) {
      if (serialEnabled) {
        serialPort.write("T,");
        println("popping panel..");
      }
    }
  } 
  else if (theOscMessage.checkAddrPattern("/control/subsystemstate") == true) {
    int beamPower = theOscMessage.get(3).intValue() - 1;  //write charge rate
    println(beamPower);
    if (serialEnabled) {
      serialPort.write("L" + beamPower + ",");
    }
    currentScreen.oscMessage(theOscMessage);
  } 
  else if (theOscMessage.checkAddrPattern("/ship/transform") == true) {
    shipState.shipPos.x = theOscMessage.get(0).floatValue();
    shipState.shipPos.y = theOscMessage.get(1).floatValue();
    shipState.shipPos.z = theOscMessage.get(2).floatValue();

    shipState.shipRot.x = theOscMessage.get(3).floatValue();
    shipState.shipRot.y = theOscMessage.get(4).floatValue();
    shipState.shipRot.z = theOscMessage.get(5).floatValue();

    shipState.shipVel.x = theOscMessage.get(6).floatValue();
    shipState.shipVel.y = theOscMessage.get(7).floatValue();
    shipState.shipVel.z = theOscMessage.get(8).floatValue();
  } 
  else if ( theOscMessage.checkAddrPattern("/clientscreen/TacticalStation/changeTo") ) {
    String changeTo = theOscMessage.get(0).stringValue();
    try {
      Display d = displayMap.get(changeTo);
      println("found display for : " + changeTo);
      if (d == null) { 
        d = weaponsDisplay;
      }
      changeDisplay(d);
    } 
    catch(Exception e) {
      println("no display found for " + changeTo);
      changeDisplay(weaponsDisplay);
    }
  } 
  else if (theOscMessage.checkAddrPattern("/clientscreen/showBanner") ) {
    String title = theOscMessage.get(0).stringValue();
    String text = theOscMessage.get(1).stringValue();
    int duration = theOscMessage.get(2).intValue();

    bannerSystem.setSize(700, 300);
    bannerSystem.setTitle(title);
    bannerSystem.setText(text);
    bannerSystem.displayFor(duration);
  } 
  else if (theOscMessage.checkAddrPattern("/system/boot/diskNumbers") ) {

    int[] disks = { 
      theOscMessage.get(0).intValue(), theOscMessage.get(1).intValue(), theOscMessage.get(2).intValue()
      };
      println(disks);
    bootDisplay.setDisks(disks);
  } 
  else if (theOscMessage.checkAddrPattern("/control/grapplingHookState")) {

    weaponsDisplay.hookArmed = theOscMessage.get(0).intValue() == 1 ? true : false;
    bannerSystem.displayFor(1500);
  }
  else {
    currentScreen.oscMessage(theOscMessage);
  }
}

void mouseClicked() {
  println (":" + mouseX + "," + mouseY);
}

boolean decoyLightState = false;
void decoyLightState(boolean s) {
  if (serialEnabled == false) { 
    return;
  };
  if (s && decoyLightState == false) {
    // println("poo");
    decoyLightState = true;
    serialPort.write("D,");
  } 
  else if (!s && decoyLightState == true) {
    serialPort.write("d,");
    decoyLightState = false;
  }
}


public class ShipState {

  public int smartBombsLeft = 6;
  public boolean poweredOn = false;
  public boolean poweringOn = false ;
  public boolean areWeDead = false;
  public String deathText = "";

  public PVector shipPos = new PVector(0, 0, 0);
  public PVector shipRot = new PVector(0, 0, 0);
  public PVector shipVel = new PVector(0, 0, 0);


  public ShipState() {
  };

  public void resetState() {
  }
}

void hideCursor(){
  BufferedImage cursorImg = new BufferedImage(16, 16, BufferedImage.TYPE_INT_ARGB);
  Cursor blankCursor = Toolkit.getDefaultToolkit().createCustomCursor(
  cursorImg, new Point(0, 0), "blank cursor");
  frame.setCursor(blankCursor);
}


/* change this scene to show the altitude and predicted death time*/
public interface Display {

  public void draw();
  public void oscMessage(OscMessage theOscMessage);
  public void start();
  public void stop();
  public void serialEvent(String content);
}

