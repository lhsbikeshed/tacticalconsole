
public class SignalTracker implements Display {

  PImage bgImage;
  public  int bootCount = 0;
  PFont font;

  OscP5 oscP5;
  String serverIP;

  float signalStrength = 0.0f;

  public SignalTracker(OscP5 p, String sIp) {
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("nebulaSignal.png");
    serverIP = sIp;
  }


  public void start() {
    signalStrength = 0.0f;
  }
  public void stop() {
  }


  /* graph area is
   :97,146
   :928,574
   */
  public void draw() {
    //signalStrength = map(mouseY, 0, height, 0, 1.0f);
    background(0, 0, 0);
    image(bgImage, 0, 0, width, height);
    stroke(255, 255, 255);
    int ph = 546;
    int h = 546;
    for (int i = 0; i < 50; i++) {
      if (i > 10 && i < 40) {
        h = (int)(abs(25 - i) * abs(25 - i) );
        // h = (int)(map(h, 0, 225, 546, 146) + random(30)) ;
        h = 546-(int)((map(h, 0, 225, 400, 0) + random(30)) * signalStrength) + (int)random(30) ;
      } 
      else {
        h = 546 + (int)random(30);
      }

      line(100+i * 16, h, 100+ (i-1)* 16, ph);
      ph = h;
    }
  }

  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/clientscreen/TacticalStation/signalStrength")==true) {
      signalStrength = theOscMessage.get(0).floatValue() ;
    }
  }

  public void serialEvent(String evt) {
  }

  public void keyPressed() {
  }
  public void keyReleased() {
  }
}

