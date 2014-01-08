public class WarpDisplay2 implements Display {

  PImage bgImage;
  PImage overlayImage;
  PImage shipIcon;
  PImage planetImage;

  //22

  //state things
  boolean haveFailed = false;    //have we failed/
  long failStart = 0;            //when fail started
  long failDelay = 0;
  long exitStartTime = -1;

  float timeRemaining = 30;
  float lastTimeRemaining = 30;
  long lastUpdate = 0;
  boolean thisIsFail = false;


  int gridWidth = 20;
  int gridHeight = 20;
  Point[][] gridPts;

  int gridX = 0;
  int gridY = 279;

  float warpAmount = 0.0f;
  long sceneStart = 0;
  boolean warpingIn = false;
  boolean warpingOut = false;
  float sinOffset = 0.0;
  Point[] stars = new Point[50];
  PGraphics warpGrid;
  
  int planetX;
  float planetScale = 0.6f;

  public WarpDisplay2() {
    bgImage = loadImage("hyperspace2.png");
    overlayImage = loadImage("hyperfailoverlay.png");
    shipIcon = loadImage("hyperShipIcon.png");
    planetImage = loadImage("hyperPlanet.png");
    //setup grid points
    int cellW = (2*width)/ gridWidth;
    int cellH = 400 / gridHeight;
    gridPts = new Point[gridWidth][gridHeight];
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        int tlx = gridX + cellW * x;
        int tly = cellH * y;
        gridPts[x][y] = new Point(tlx, tly);
      }
    }

    for (int i = 0 ; i < 50; i++) {
      stars[i] = new Point((int)random(width + 100), int(gridY + random(400)));
    }  
    warpGrid = createGraphics(width, 400);
  }


  public void oscMessage(OscMessage theOscMessage) {
    if (theOscMessage.checkAddrPattern("/scene/warp/updatestats")==true) {
      lastTimeRemaining = timeRemaining;
      timeRemaining = theOscMessage.get(1).floatValue();
      thisIsFail = theOscMessage.get(2).intValue() == 1 ? true : false;
      lastUpdate = millis();
    }
    else if (theOscMessage.checkAddrPattern("/scene/warp/failjump") == true) {
      haveFailed = true;
      failStart = millis();
      failDelay = theOscMessage.get(0).intValue() * 1000;
      bannerSystem.setSize(700, 300);
      bannerSystem.setTitle("WARNING");
      bannerSystem.setText("GRAVITATIONAL BODY DETECTED, TUNNEL COLLAPSING, PREPARE FOR UNPLANNED REENTRY");
      bannerSystem.displayFor(5000);
    }
  }
  public void start() {
    sceneStart = millis();
    timeRemaining = 30;
    warpingIn = true;
    warpingOut = false;
    planetX = width;
    thisIsFail = false;
    planetScale = 0.6f;
    exitStartTime = -1;
  }
  public void stop()
  {
    haveFailed = false;
    warpAmount = 0.0f;
    warpingIn = false;
  }

  void drawGrid() {
    warpGrid.beginDraw();
    warpGrid.background(0, 0, 0);
    warpGrid.stroke(255, 0, 0);
    warpGrid.strokeWeight(1);
    sinOffset += 0.01f;
    if (sceneStart + 3000 > millis() && warpingIn) {
      warpAmount = map(millis() - sceneStart, 0, 3000, 0.0, 1.0);
    } 
    else {
      warpingIn = false;
    }
    if(warpingOut){
      warpAmount = map(millis() - exitStartTime, 0, 8000, 1.0, 0.0);
      warpAmount = clamp(warpAmount, 0.0f, 1.0f);
      
    }
    warpGrid.fill(255, 255, 255);
    warpGrid.noStroke();
    for (int i = 0; i < stars.length; i++) {
      stars[i].x -= 55 * warpAmount;
      if (stars[i].x < 0) {
        stars[i].x = width + (int)random(100);
        stars[i].y = (int)random(400);
      }
      warpGrid.rect(stars[i].x, stars[i].y, 40 * (warpAmount + 0.1), 1);
    }
    warpGrid.strokeWeight(1);
    warpGrid.stroke(255, 0, 0);
    warpGrid.noFill();
    for (int y = 0; y < gridHeight - 1; y++) {
      for (int x = 0; x < gridWidth - 1; x++) {

        //calc sin offset
        float s = 10 - abs(y - 10) - ((y - 10) * (y - 10)) * warpAmount * 20.0f;
        // s = sin(s) * (mouseX / 100.0f);
        float sNext = 10 - abs(y - 9) - ((y - 9) * (y - 9)) * warpAmount * 20.0f ;
        // sNext = sin(sNext) * (mouseX / 100.0f);



        Point tl = gridPts[x][y];
        Point tr = gridPts[x + 1][y];
        Point bl = gridPts[x][y+1];
        Point br = gridPts[x + 1][y + 1];

        int randAmt = haveFailed == true ? 1: 0;

        float tlx = tl.x + s + random(15) * randAmt;
        float trx = tr.x + s + random(15) * randAmt;
        float blx = bl.x + sNext + random(15) * randAmt;
        float brx = br.x + sNext + random(15) * randAmt;

        //tlx = clamp(tlx, 17, width - 22);
        //trx = clamp(trx, 17, width - 22);
        // blx = clamp(blx, 17, width - 22);
        //brx = clamp(brx, 17, width - 22);
        warpGrid.stroke(0, 0, map(sin((millis() / 250.0f) + (x * 0.1)), -1.0f, 1.0f, 120, 255));

        warpGrid.quad(tlx, tl.y, trx, tr.y, brx, br.y, blx, bl.y);
      }
    }
    warpGrid.endDraw();
    image(warpGrid, gridX, gridY);
  }

  private float clamp(float in, float min, float max) {
    if (in < min) {
      return min;
    } 
    else if (in > max) {
      return max;
    } 
    else {
      return in;
    }
  }

  public void draw() {

    background(0, 0, 0);

    drawGrid();
    
    if(thisIsFail){
      int pW = (int)(planetImage.width * planetScale);
      int pH = (int)(planetImage.height * planetScale);
      
      planetX = (int)lerp(width, 637, (millis() - sceneStart) / 20000.0f);
      planetScale = lerp(0.6f, 1.0f, (millis() - sceneStart) / 20000.0f);
      image(planetImage, planetX + pW/2, 485 - pH / 2, pW, pH);
    }


    image(bgImage, 0, 0, width, height);

    image(shipIcon, 75, 422);
    fill(255, 255, 0);
    textFont(font, 40);
    if (timeRemaining >= 0.0f) {
      float t = lerp(lastTimeRemaining, timeRemaining, (millis() - lastUpdate) / 250.0f); 
      text(t, 756, 114);
    } 
    else {
      if(warpingOut == false){
        exitStartTime = millis();
        warpingOut = true;
      }
      text("EXITING HYPERSPACE", 260, 180);
    }
  }
  public void serialEvent(String evt) {
  }
}

