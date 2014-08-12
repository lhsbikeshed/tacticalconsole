import java.util.Collections;
import java.util.List;
/*

 
 */


public class WeaponsConsole2 implements Display {

  public static final int MODE_SCANNER = 0;
  public static final int MODE_LOCKED = 1;

  //images etc
  PImage[] banners = new PImage[3];
  PImage bgImage;
  PImage scannerImage, titleImage, hullStateImage;
  PImage decoyButton, beamButton, decoyButtonD, beamButtonD;
  PImage grappleButton, grappleButtonD;
  PImage launchDetected;

  PFont font; 
  float firingTime = 0; //time a laser firing started

  //current screen mode
  int mode = MODE_SCANNER;

  //targetting crap
  List<TargetObject> targets = Collections.synchronizedList(new ArrayList<TargetObject>());
  TargetObject currentTarget;

  long smartBombFireTime = 0;

  long missileStartTime = 0;
  float scannerAngle = 0;
  String scanString = "";
  boolean isScanning = false;
  int scanTimeout = 100;
  int scanTargetIndex;
  int numMissiles = 0;

  float maxBeamRange = 1300;
  int radarTicker = 175;

  int beamPower = 2;
  int sensorPower = 2;

  //states
  boolean flareEnabled = false;
  boolean offline = false;
  boolean fireEnabled = false;
  boolean blinkenBool = false;
  long blinkenBoolTimer  =0;

  public boolean hookArmed = false;

  //sensor power to range mapping
  int[] sensorRanges = { 
    0, 600, 900, 1200
  };



  OscP5 osc;
  String serverIP = "";
  PApplet parent;

  public WeaponsConsole2(OscP5 p, String sIp, PApplet parent) {
    this.parent = parent;
    osc = p;
    serverIP = sIp;
    //load resources
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("tacticalscreen3.png");
    titleImage = loadImage("weaponsTitle.png");


    scannerImage = loadImage("radarscanner.png");

    launchDetected = loadImage("launchDetected.png");
    beamButton = loadImage("firebeam.png");
    decoyButton = loadImage("firedecoy.png");
    beamButtonD = loadImage("firebeamD.png");
    decoyButtonD = loadImage("firedecoyD.png");

    grappleButton = loadImage("grappleFireOn.png");
    grappleButtonD = loadImage("grappleFireOff.png");
    hullStateImage = loadImage("hulldamageoverlay.png");
  }



  public void draw() {



    //general blink thing used for any blinking displays
    if (blinkenBoolTimer + 750 < millis()) {
      blinkenBoolTimer = millis();
      blinkenBool = !blinkenBool;
    }

    background(0, 0, 0);    
    noStroke();    
    if (mode == MODE_SCANNER) {
      fill(0, 128, 0, 100);
      int sensorSize = sensorRanges[sensorPower - 1];
      ellipse(364, 707, sensorSize, sensorSize );
      radarTicker += 10;
      noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
      arc(364, 707, radarTicker, radarTicker, 4.2, 5.23);
      if (radarTicker > sensorRanges[sensorPower - 1]) {
        radarTicker = 175;
      }


      image(bgImage, 0, 0);
      drawTargets();
    }
    drawSideBar();
    stroke(255);
    fill(255);


    //does the current target have hull/weapons/engines stats? If so draw them
    String[] stats = {
      "hullHealth", "weaponHealth", "engineHealth"
    };
    //textFont(font, 15);
    //text("TARGET INFO:\r\n HULL: 100%\r\nWEAPONS: 100%\r\nENGINES: 100%", mouseX, mouseY);
  }

  void drawSideBar() {
    image(titleImage, 7, 5);
    //draw sidebar stuff
    fill(255, 255, 255);
    textFont(font, 56);
    text(shipState.smartBombsLeft, 212, 706);
    fill(0,255,0);
    rect(47, 742, 25, beamPower * -33);
    rect(106, 742, 25, sensorPower * -33);
   //text("Beam Power:" + (beamPower * 25) + "%", 776, 64);
    //text("Sensor Power:" + (sensorPower * 25) + "%", 776, 84);

   // text("Max Beam Range: " + maxBeamRange, 780, 500);
    //text("Sensor range: " + sensorRanges[sensorPower - 1], 780, 520);
    synchronized(targets) {
      Collections.sort(targets);  //sorted by distance from ship
      int ypos = 144;
      for (TargetObject t : targets) {
        if (t.targetted) {
          fill(255, 0, 0);
        }
        else {
          if (t.pos.mag() < sensorRanges[sensorPower - 1]) {
            fill(0, 255, 0);
          } 
          else {
            fill(100, 100, 100);
          }
        }
        if (t.pos.mag() > sensorRanges[sensorPower - 1]) {
          text("???", 710, ypos);
        } 
        else {
          text(t.scanId, 710, ypos);
        }
        String h = String.format("%.0f", t.pos.mag());
        text(h, 780, ypos);

        String name = t.name;
        if (name.length() > 12) {
          name = name.substring(0, 12) + "..";
        }
        if (t.pos.mag() > sensorRanges[sensorPower - 1]) {
          name = "???";
        }
        text(name, 855, ypos);

        if (ypos + 20 > 400) {
          break;
        } 
        else {
          ypos += 20;
        }
      }
    }
    //text in the scanning ID field
    fill(0, 255, 0);
    textFont(font, 70);
    text(scanString, 727, 675);




    
   
    if (blinkenBool && fireEnabled) { 
      image(beamButton, 714, 431);
    }
      
    

    if (smartBombFireTime + 1000 > millis()) {
      float radius = (millis() - smartBombFireTime) / 1000.0f;
      noFill();
      strokeWeight(3);
      stroke(70, 70, 255);
      ellipse( 364, 707, radius * 900, radius * 900);
    }

    //draw hull damage
    tint( (int)map(shipState.hullState, 0, 100, 255, 0), (int)map(shipState.hullState, 0, 100, 0, 255), 0);
    image(hullStateImage, 486, 620);
    textFont(font, 23);
    text((int)shipState.hullState + "%", 463, 646);
    noTint();
  }



  void drawTargets() {


    textFont(font, 12);
    fireEnabled = false;
    strokeWeight(1);
    synchronized(targets) {
      for (int i = targets.size() - 1; i >= 0; i--) {
        TargetObject t = targets.get(i);
        //update logic bits
        //if no update received for 280ms then remove this target
        if (millis() - t.lastUpdateTime > 300) {
          if (t.targetted) {
            consoleAudio.playClip("targetDestroyed");
          }
          targets.remove(i);
        }


        float lerpX = lerp(t.lastPos.x, t.pos.x, (millis() - t.lastUpdateTime ) / 250.0f);
        float lerpY = lerp(t.lastPos.z, t.pos.z, (millis() - t.lastUpdateTime ) / 250.0f);
        float lerpZ = lerp(t.lastPos.y, t.pos.y, (millis() - t.lastUpdateTime ) / 250.0f);

        // float x = 352 + map(lerpX, -2000, 2000, -352, 352);
        //float y = 426 + map(lerpY, -2000, 2000, -426, 426);
        //364,707
        PVector p = PVector.fromAngle(t.randomAngle);
        p.mult(75 + t.pos.mag() / 3.0f ); //new pos
        PVector lp = PVector.fromAngle(t.randomAngle);
        lp.mult(75 + t.lastPos.mag() / 3.0f );

        float x = 364 + lerp(lp.x, p.x, (millis() - t.lastUpdateTime ) / 250.0f);
        ;
        float y = 707 + lerp(lp.y, p.y, (millis() - t.lastUpdateTime ) / 250.0f);
        ;


        //set target colour

        if (t.pos.mag() > sensorRanges[sensorPower - 1]) {
          fill(100, 100, 100);
          x += random(-5, 5);
          y += random(-5, 5);
        } 
        else if (t.pos.mag() < 200) {

          fill(255, 0, 0);
        } 
        else if (t.pos.mag() < 500) {
          fill(255, 255, 0);
        } 
        else {
          fill(0, 255, 0);
        }

        //draw the target on the radar

        ellipse(x, y, 10, 10);
        String scanCode = "" + t.scanId;
        if (t.scanId < 1000) {
          scanCode = "0" + scanCode;
        }
        if (t.pos.mag() < sensorRanges[sensorPower - 1]) {    //grey it out if its outside of sensor range, if not then draw
          textFont(font, 12);

          String h = String.format("%.2f", t.stats[0] * 100);
          text(t.name +": " + h + "%", x + 10, y + 15);
          text(scanCode, x + 10, y);
          //are there any extended stats on this? 
          Float f = t.getStat("scanning");
          if (f != null && f > 0.0f) {
            //draw a scanning effect around the target
            int maxSize = 70;
            int size = (int)map( millis() % 2000, 0, 2000, 0, maxSize);
            noFill();
            strokeWeight(2);
            stroke(0, 128, 255, map(size, 0, maxSize, 255, 0));
            ellipse(x, y, size, size);
            size = (int)map( (millis() + 1000) % 2000, 0, 2000, 0, maxSize);
            stroke(0, 128, 255, map(size, 0, maxSize, 255, 0));
            ellipse(x, y, size, size);
          }
          f = t.getStat("chargingWeapons");
          if (f != null && f > 0.0f) {
            //warn the player that the target is charging its weapons
          }
        } 
        else {
          fill(128);
          StringBuilder s = new StringBuilder(t.name);
          for (int c = 0; c < (int)random(3,s.length()); c++) {
            s.setCharAt( (int)random(0, s.length()), (char)random(0, 255));
          }
          text(s.toString(), x + 10, y);
        }

        if (t.dead) {
          targets.remove(i);
        }

        //scanning stuff
        if (t.scanCountDown > 0) {
          if (t.scanCountDown - 1 > 0) {
            t.scanCountDown --;
          } 
          else {
            //target this motherfucker
            t.scanCountDown --;
            OscMessage myMessage = new OscMessage("/system/targetting/targetObject");
            myMessage.add(t.hashCode);
            osc.flush(myMessage, new NetAddress(serverIP, 12000));
            currentTarget = t;
            consoleAudio.playClip("targetLocked");
          }
          pushMatrix();
          translate(x, y);
          rotate(radians((millis() / 10.0f) % 360));
          noFill();
          stroke(255, 255, 0);
          float scale = map(t.scanCountDown, 100, 0, 10, 1);
          rect(-15 * scale, -15* scale, 30 * scale, 30 * scale);
          popMatrix();

          text("scanning: " + t.scanCountDown, x + 10, y + 10);
        }

        if (t.targetted) {
          stroke(0, 255, 0);
          noFill();
          // rect(x-10, y-10, 20, 20);

          if (t.pos.mag() < maxBeamRange) {
            text("FIRE BEAMS", x + 10, y + 10);
            fireEnabled = true;
          } 
          else {
            text("OUT OF RANGE", x + 10, y + 10);
          }

          pushMatrix();
          translate(x, y);
          rotate(radians((millis() / 10.0f) % 360));
          noFill();
          stroke(255, 255, 0);
          float scale = map(t.scanCountDown, 100, 0, 10, 1);
          rect(-15, -15, 30, 30 );
          popMatrix();
        }

        //draw a beam out to the target if we are firing
        if (t.beingFiredAt && firingTime + 400 > millis()) {
          stroke(255, 255, 0);
          strokeWeight(2);
          line(364, 707, x, y);
        }
        //draw a beam to the ship if the target is firing at us
        Float f = t.getStat("firing");
        if (f != null && f > 0.0f) {
          stroke(255, 0, 0);
          strokeWeight(4);
          line(x, y, 364, 707);
        }
      }
    }
  }


  void serialEvent(String contents) {
    String action = contents.split(":")[1];



    if (action.equals("FIRELASER") ) {

      if (hookArmed) {
        OscMessage myMessage = new OscMessage("/system/targetting/fireGrappling");
        osc.flush(myMessage, new NetAddress(serverIP, 12000));
        println("Fire grapple");
      } 
      else {
        OscMessage myMessage = new OscMessage("/system/targetting/fireAtTarget");
        osc.flush(myMessage, new NetAddress(serverIP, 12000));
        if (currentTarget != null && currentTarget.pos.mag() < maxBeamRange) {
          consoleAudio.playClip("firing");
        } 
        else {
          consoleAudio.playClip("outOfRange");
        }

        println("Fire at target");
      }
      return;
    }

    if (action.equals("GRAPPLEFIRE")) {
      OscMessage myMessage = new OscMessage("/system/targetting/fireGrappling");
      osc.flush(myMessage, new NetAddress(serverIP, 12000));
    } 
    else if (action.equals("GRAPPLERELEASE")) {
      OscMessage myMessage = new OscMessage("/system/targetting/releaseGrappling");
      osc.flush(myMessage, new NetAddress(serverIP, 12000));
    }

    if (action.equals("DECOY")) {
      if (shipState.smartBombsLeft > 0) {
        if (smartBombFireTime + 1000 < millis()) {
          println("FLARE");
          OscMessage myMessage = new OscMessage("/system/targetting/fireFlare");
          osc.flush(myMessage, new NetAddress(serverIP, 12000));

          shipState.smartBombsLeft --;
          smartBombFireTime = millis();
        }
      } 
      else {
        //warn we have no flares left
      }
      return;
    }

    if (isScanning == false) {
      if (action.equals("SCAN")) {
        scanTarget();
      } 
      else {
        println(action.charAt(0));
        if ( action.charAt(0) >= '0' && action.charAt(0) <= '9') {
          scanString = scanString + action;
          if (scanString.length() >= 4 ) {
            scanTarget();
          }
        }
      }
    }
  }

  void scanTarget() {
    currentTarget = null;
    println("scan");

    int sId = 0;
    try {
      sId = Integer.parseInt(scanString);
      //find what were scanning
      boolean targetFound = false;
      synchronized(targets) {
        for (TargetObject t : targets) {
          if (sId == t.scanId) {
            t.scanCountDown = (5 - sensorPower) * 21;
            targetFound = true;
          } 
          else {
            if (t.targetted) {
              t.scanCountDown = -1;
              t.targetted = false;
              t.beingFiredAt = false;
              OscMessage myMessage = new OscMessage("/system/targetting/untargetObject");
              myMessage.add(t.hashCode);
              osc.flush(myMessage, new NetAddress(serverIP, 12000));
            }
          }
        }

        if (targetFound) {
          consoleAudio.playClip("targetting");
        } 
        else {
          consoleAudio.playClip("outOfRange");
        }
      }
    } 
    catch (NumberFormatException e) {
    }

    scanString = "";
  }


  public void oscMessage(OscMessage theOscMessage) {


    if (theOscMessage.checkAddrPattern("/control/subsystemstate") == true) {
      beamPower = theOscMessage.get(3).intValue() + 1;
      sensorPower = theOscMessage.get(2).intValue() + 1;
      maxBeamRange = (1000 + ( beamPower - 1) * 300);
    } 
    else if (theOscMessage.checkAddrPattern("/tactical/weapons/targetUpdate")) {


      int tgtHash = theOscMessage.get(0).intValue();
      synchronized(targets) {
        TargetObject t = findTargetById(tgtHash);
        boolean newTarget = false;
        if (t == null) {
          println("new target: " + tgtHash);
          t = new TargetObject();
          t.hashCode = tgtHash;
          newTarget = true;
          targets.add(t);
          consoleAudio.playClip("newTarget");
        }
        t.scanId = theOscMessage.get(1).intValue();
        t.trackingPlayer = theOscMessage.get(2).intValue() == 1 ? true : false;
        t.targetted = theOscMessage.get(3).intValue() == 1 ? true : false;
        float x = theOscMessage.get(4).floatValue();
        float y = theOscMessage.get(5).floatValue();
        float z = theOscMessage.get(6).floatValue();
        if (newTarget) {
          t.lastPos.x = x;
          t.lastPos.y = y;
          t.lastPos.z = z;
          t.randomAngle = map(random(100), 0, 100, 4.2f, 5.23f);
        } 
        else {

          t.lastPos.x = t.pos.x;
          t.lastPos.y = t.pos.y;
          t.lastPos.z = t.pos.z;
        }
        t.lastUpdateTime = millis();
        t.pos = new PVector(x, y, z);
        t.stats[0] = theOscMessage.get(7).floatValue();
        // t.stats[1] = theOscMessage.get(8).floatValue();
        t.statNames[0] = theOscMessage.get(8).stringValue();
        //  t.statNames[1] = theOscMessage.get(10).stringValue();        
        t.name = theOscMessage.get(9).stringValue();


        //now unpack the stat string
        String statString = theOscMessage.get(10).stringValue();
        String[] pairs = statString.split(",");
        for (String p : pairs) {          
          String[] vals = p.split(":");
          t.setStat(vals[0], Float.parseFloat(vals[1]));
        }
      }
    } 
    else if (theOscMessage.checkAddrPattern("/tactical/weapons/targetRemove")) {
      synchronized(targets) {
        int tgtHash = theOscMessage.get(0).intValue();
        TargetObject t = findTargetById(tgtHash);
        if (t != null) {
          t.dead = true;
          t.targetted = false;
          println("target remove");
          if (t.targetted) {
            consoleAudio.playClip("targetDestroyed");
          }
        }
      }
    } 
    else if (theOscMessage.checkAddrPattern("/tactical/weapons/firingAtTarget")) {
      synchronized(targets) {
        int tgtHash = theOscMessage.get(0).intValue();
        TargetObject t = findTargetById(tgtHash);
        if (t!=null) {
          t.beingFiredAt = true;
          firingTime = millis();
        }
      }
    }
  }

  //find a target  by hashcode
  private TargetObject findTargetById(int id) {
    for (TargetObject t : targets) {
      if (t.hashCode == id) {
        return t;
      }
    }
    return null;
  }


  public void start() {
    offline = false;
    targets = new ArrayList<TargetObject>();
  }

  public void stop() {
    offline = false;
  }

  public class TargetObject implements Comparable<TargetObject> {
    public int hashCode = 0;
    public PVector pos = new PVector(0, 0, 0);
    public PVector lastPos = new PVector(0, 0, 0);
    public long lastUpdateTime = 0;
    public int scanId = 0;
    public boolean trackingPlayer = false;
    public boolean targetted = false;
    public int scanCountDown = -1;
    public boolean beingFiredAt = false;
    public boolean dead = false;
    public String name = "missile";
    public float[] stats = new float[2];
    public String[] statNames = new String[2];

    public float randomAngle;
    protected HashMap<String, Float> statMap = new HashMap<String, Float>();

    public TargetObject() {
      //4.2 - 5.23 
      randomAngle = map(random(100), 0, 100, 4.2f, 5.23f);
    }


    public int compareTo(TargetObject other) {
      return (int)(this.pos.mag() - other.pos.mag());
    }

    public void clearStats() {
      statMap.clear();
    }

    public void setStat(String name, float val) {
      Float f = new Float(val);
      // println("setting stat: " + name);
      statMap.put(name, val);
    }

    public Float getStat(String name) {
      Float f = statMap.get(name);
      return f;
    }
  }
}

