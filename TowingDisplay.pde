

public class TowingDisplay implements Display {

  PImage bgImage, shipIcon;
  public  int bootCount = 0;
  PFont font;
  OscP5 oscP5;
  String serverIP;

  float distance = 0.0f;
  float lastDistance = -1.0f;
  float tension = 0.0f;
  float lastTension = -1.0f;
  long lastUpdateTime = 0;

  public TowingDisplay(OscP5 p, String sIp) {
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("towingtitle.png");
    shipIcon = loadImage("shipIconSide.png");
    serverIP = sIp;
    oscP5 = p;
  }


  public void start() {
    lastDistance = -1;
    lastTension = -1;
  }
  public void stop() {
    lastDistance = -1;
    lastTension = -1;
  }


  public void draw() {
    noStroke();
    //image(bgImage, 0,0,width,height);
    background(0, 0, 0);
    fill(255, 255, 255);
    image(bgImage, 24, 18);
    image(shipIcon, 85, 280);
    float d = lerp(lastDistance, distance, (millis() - lastUpdateTime) / 250.0f);
    int xpos = 300 + (int)map(d, 0, 140, 0, 450);
    image(shipIcon, xpos, 280);
    
    d = lerp(lastTension, tension, (millis() - lastUpdateTime) / 250);
    fill((int)map(d, 25, 0, 255, 0), (int)map(d, 25, 0, 0, 255), 0);
    
    rect(286,396, xpos - 246, map(d, 0,25, 10,5));
    
    if(d >= 18){
      text("DANGER!!", 367,542);
    } else if(d >= 22){
      text("WARNING!!!!", 367,542);
    }
    
    textFont(font, 19);
    String h = String.format("%.2f", d);
    text("TETHER TENSION: " + h, 366, 480);
  }

  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/clientscreen/TacticalStation/towState")) {
      float d = theOscMessage.get(0).floatValue();

      if (lastDistance < 0) {
        lastDistance = d;
      } 
      else {
        lastDistance = distance;
      }
      distance = d;


      d = theOscMessage.get(1).floatValue();

      if (lastTension < 0) {
        lastTension = d;
      } 
      else {
        lastTension = tension;
      }
      tension = d;
      lastUpdateTime = millis();
    }
  }

  public void serialEvent(String evt) {
    String action = evt.split(":")[1];

     if (action.equals("GRAPPLERELEASE")) {
      OscMessage myMessage = new OscMessage("/system/targetting/releaseGrappling");
      oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
    } else if (action.equals("FIRELASER") ) {
      println("Releasing..");
      OscMessage myMessage = new OscMessage("/system/targetting/releaseGrappling");
      oscP5.flush(myMessage, new NetAddress(serverIP, 12000));
    }

  }

  public void keyPressed() {
  }
  public void keyReleased() {
  }
}

