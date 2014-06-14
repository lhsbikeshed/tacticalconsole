

public class CablePuzzleDisplay implements Display {
  
  PImage bannerImg;
  int time;
  
  PFont font;
  
  int blinkTime = 0;
  boolean blinker = false;
  
  /*  sockets - > plugs
   *  [8, 6, 3] , [5, 12, 10]
    [2, 3, 11] , [10, 12, 4]
    [6, 11, 8] , [12, 4, 10]
    [3, 6, 8] , [10, 9, 5]
    [13, 3, 8] , [5, 6, 10]
  */
  int selectedPatch = 0;
  
  public CablePuzzleDisplay(){
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bannerImg = loadImage("cablepuzzle/banner.png");
    
  }
  
  
  public void start(){
   
  }
  public void stop(){
    
  }
  
  public void draw(){
    if(blinkTime + 1000 < millis()){
      blinker = !blinker;
      blinkTime = millis();
    }
    background(0,0,0);
    if(blinker){
      image(bannerImg, 247, 315);
      textFont(font, 15);
      text("Error code 0x0030400" + selectedPatch, 418,408);
    }
    
  }
  
  public void oscMessage(OscMessage msg){
    if(msg.checkAddrPattern("/system/cablePuzzle/puzzleComplete")){
     
    } else if (msg.checkAddrPattern("/system/cablePuzzle/connectionList")){
      selectedPatch = msg.get(0).intValue();
      
    }
  }

  public void serialEvent(String evt){}

  public void keyPressed(){}
  public void keyReleased(){}
}
