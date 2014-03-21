/** during the drop scene
 * show warning that systems are offline
 * show references to flight manual for patching emergency jump power in
 */

public class DropDisplay implements Display {

  PImage bg ;
  PImage repairedBg;
  PImage structFailOverlay;
  PImage offlineBlinker;
  PImage damagedIcon;

  PFont font;

  boolean fixed = false;
  boolean structFail = false;
  boolean jumpCharged = false;



  int curStep = -1;

  public DropDisplay() {
    bg = loadImage("dropBackground.png");


    repairedBg = loadImage("dropscenefixed.png");
    structFailOverlay = loadImage("structuralFailure.png");
    damagedIcon = loadImage("dropDamage.png");
    offlineBlinker = loadImage("dropOffline.png");
 


    font = loadFont("HanzelExtendedNormal-48.vlw");
  }

  public void start() {
    fixed = false;
    structFail = false;
    jumpCharged = false;
    //probe for current cable state
    probeCableState();
  }

  public void stop() {
  }

  public void draw() {
    background(0);
    fill(255, 255, 255);
    image(bg, 0, 0, width, height);
    if (fixed) {
      strokeWeight(8);
      stroke(0, map(millis() % 1250, 0, 1250, 0, 255), 0);
      line(462, 280, 585, 280);
      textFont(font, 30);
      fill(0, 255, 0);
      if (jumpCharged) {

        text("JUMP SYSTEM CHARGING", 10, 148);
        textFont(font, 20);

        text("CHARGING", 61, 440);
      } 
      else {
        text("JUMP SYSTEM READY", 10, 148);
        textFont(font, 20);

        text("READY", 61, 440);
      }
    } 
    else {
      strokeWeight(8);
      stroke(map(millis() % 250, 0, 250, 0, 255), 0, 0);
      line(462, 280, 585, 280);
      image(damagedIcon, 530, 204);

      //if (globalBlinker) {
      textFont(font, 30);
      fill(map(millis() % 800, 0, 800, 0, 255), 0, 0);
      text("JUMP SYSTEM OFFLINE", 10, 148);
      textFont(font, 20);
      text("OFFLINE", 61, 440);
      // }
    }

    if (structFail) { //show the "structural failure" warning

      image(structFailOverlay, 128, 200);
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
    //   println(theOscMessage);
    if (theOscMessage.checkAddrPattern("/scene/drop/structuralFailure")==true) {
      structFail = true;
    } 
    else if (theOscMessage.checkAddrPattern("/ship/jumpStatus") == true) {
      int v = theOscMessage.get(0).intValue();
      if (v == 0) {
        jumpCharged = false;
      } 
      else if (v == 1) {
        jumpCharged = true;
      }
    }
  }

  public void serialEvent(String evt) {
    String[] evtData = evt.split(":");
    println(evt);
    if (evtData[0].equals("CONDUITCONNECT")) {

      char c = evtData[1].charAt(0);
      if (c >= '0' && c < '9') {
        OscMessage myMessage = new OscMessage("/scene/drop/conduitConnect");
        myMessage.add(Integer.parseInt(evtData[1]));
        OscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      }
    } 
    else if (evtData[0].equals("CONDUITDISCONNECT")) {

      char c = evtData[1].charAt(0);
      if (c >= '0' && c < '9') {
        OscMessage myMessage = new OscMessage("/scene/drop/conduitDisconnect");
        myMessage.add(Integer.parseInt(evtData[1]));
        OscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      }
    } 
   
  }
}

