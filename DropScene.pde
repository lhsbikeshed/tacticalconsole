/** during the drop scene
 * show warning that systems are offline
 * show references to flight manual for patching emergency jump power in
 */

public class DropDisplay implements Display {

  PImage bg ;
  PImage repairedBg;
  PImage structFailOverlay;
  PFont font;

  boolean fixed = false;
  boolean structFail = false;


  int curStep = -1;

  public DropDisplay() {
    bg = loadImage("dropscene.png");
    repairedBg = loadImage("dropscenefixed.png");
    structFailOverlay = loadImage("structuralFailure.png");
    font = loadFont("HanzelExtendedNormal-48.vlw");
  }

  public void start() {
    fixed = false;
    structFail = false;
  }

  public void stop() {
  }

  public void draw() {
    background(0);
    fill(255, 255, 255);
    if (!fixed) {
      image(bg, 0, 0, width, height);
    } 
    else {
      image(repairedBg, 0, 0, width, height);
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
  }

  public void serialEvent(String evt) {
    String[] evtData = evt.split(":");
    println(evt);
    if (evtData[0].equals("CONDUIT")) {

      char c = evtData[1].charAt(0);
      if (c >= '0' && c < '9') {
        OscMessage myMessage = new OscMessage("/scene/drop/conduit");
        myMessage.add(Integer.parseInt(evtData[1]));
        OscP5.flush(myMessage, new NetAddress(serverIP, 12000));
      } 
      else if (c == 'P') {
        OscMessage myMessage = new OscMessage("/scene/drop/droppanelrepaired");
        myMessage.add(1);
        OscP5.flush(myMessage, new NetAddress(serverIP, 12000));
        fixed = true;
      } 
      else if (c =='X') {
        OscMessage myMessage = new OscMessage("/scene/drop/conduitFail");

        OscP5.flush(myMessage, new NetAddress(serverIP, 12000));
        fixed = false;
      }
    }
  }
}

