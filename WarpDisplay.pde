public class WarpDisplay implements Display {

  PImage bgImage;
  PImage overlayImage;

  //22

  //state things
  boolean haveFailed = false;    //have we failed/
  long failStart = 0;            //when fail started
  long failDelay = 0;

  float timeRemaining = 30;

  public WarpDisplay() {
    bgImage = loadImage("inwarp.png");
    overlayImage = loadImage("hyperfailoverlay.png");
  }


  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/scene/warp/updatestats")==true) {
      timeRemaining = (int)theOscMessage.get(1).floatValue();
    }
    else if (theOscMessage.checkAddrPattern("/scene/warp/failjump") == true) {
      haveFailed = true;
      failStart = millis();
      failDelay = theOscMessage.get(0).intValue() * 1000;
    }
  }
  public void start() {
  }
  public void stop()
  {
    haveFailed = false;
  }
  public void draw() {

    background(0, 0, 0);

    noStroke();
    for (int i = 0; i < 22; i++) {
      fill(0, 0, map(sin((millis() / 250.0f) + (i * -0.1)), -1.0f, 1.0f, 0, 255));
      rect(185 + i * 32, 0, 32, 600);
    } 
    image(bgImage, 0, 0, width, height);
    
    fill(255,255,0);
    textFont(font, 40);
    if(timeRemaining >= 0.0f){
      
      text("Time Remaining: " + timeRemaining, 193, 136);
    } else {
      text("EXITING HYPERSPACE", 193, 136);
    
    }
    if (haveFailed) {
      image(overlayImage, 140, 200);
    }
  }
  public void serialEvent(String evt) {
  }
}

