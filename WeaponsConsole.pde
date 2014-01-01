import java.util.Collections;
import java.util.List;
/*

 
 */


public class WeaponsConsole implements Display {



  //images etc
  PImage[] banners = new PImage[3];
  PImage bgImage;
  PImage scannerImage;
  PImage decoyButton, beamButton, decoyButtonD, beamButtonD;
  PImage grappleButton, grappleButtonD;
  PImage launchDetected;

  PFont font; 
  float firingTime = 0; //time a laser firing started

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

  int beamPower = 2;
  int sensorPower = 2;

  //states
  boolean flareEnabled = false;
  boolean offline = false;
  boolean fireEnabled = false;
  boolean blinkenBool = false;
  long blinkenBoolTimer  =0;

  public boolean hookArmed = false;



  OscP5 osc;
  String serverIP = "";
  PApplet parent;

  public WeaponsConsole(OscP5 p, String sIp, PApplet parent) {
    this.parent = parent;
    osc = p;
    serverIP = sIp;
    //load resources
    font = loadFont("HanzelExtendedNormal-48.vlw");
    bgImage = loadImage("tacticalscreen2.png");



    scannerImage = loadImage("radarscanner.png");

    launchDetected = loadImage("launchDetected.png");
    beamButton = loadImage("firebeam.png");
    decoyButton = loadImage("firedecoy.png");
    beamButtonD = loadImage("firebeamD.png");
    decoyButtonD = loadImage("firedecoyD.png");

    grappleButton = loadImage("grappleFireOn.png");
    grappleButtonD = loadImage("grappleFireOff.png");
  }



  public void draw() {



    //general blink thing used for any blinking displays
    if (blinkenBoolTimer + 750 < millis()) {
      blinkenBoolTimer = millis();
      blinkenBool = !blinkenBool;
    }

    background(0, 0, 0);    
    noStroke();    
    image(bgImage, 0, 0);



    //gray shit out and put offline over the top
    if (offline) {
      fill(0, 0, 0, 200);
      rect(0, 0, width, height);
      fill(255, 255, 255);
      textFont(font, 80);
      text("OFFLINE", 250, 420);
    } 
    else {
      fill(255, 255, 0);
      textFont(font, 12);
      text("Smartbombs:" + shipState.smartBombsLeft, 776, 44);
      text("Beam Power:" + (beamPower * 25) + "%", 776, 64);
      text("Sensor Power:" + (sensorPower * 25) + "%", 776, 84);

      text("Max Beam Range: " + maxBeamRange, 780, 500);
      synchronized(targets) {
        Collections.sort(targets);  //sorted by distance from ship
        int ypos = 260;
        for (TargetObject t : targets) {
          if (t.targetted) {
            fill(255, 0, 0);
          }
          else {
            if (t.pos.mag() < maxBeamRange) {
              fill(0, 255, 0);
            } 
            else {
              fill(100, 100, 100);
            }
          }
          text(t.scanId, 710, ypos);
          String h = String.format("%.0f", t.pos.mag());
          text(h, 780, ypos);

          String name = t.name;
          if (name.length() > 12) {
            name = name.substring(0, 12) + "..";
          }
          text(name, 855, ypos);

          if (ypos + 20 > 420) {
            break;
          } 
          else {
            ypos += 20;
          }
        }
      }
      //text in the scanning ID field
      fill(0, 255, 0);
      text(scanString, 800, 190);



      drawTargets();
      if (hookArmed) {
        if (blinkenBool) {
          image(grappleButton, 790, 412);
        } 
        else {
          image(grappleButtonD, 790, 412);
        }
      } 
      else {
        if (blinkenBool && fireEnabled) { 
          image(beamButton, 790, 412);
        }
        if (blinkenBool && flareEnabled) { 
          image(decoyButton, 790, 480);
        }
      }

      if (smartBombFireTime + 1000 > millis()) {
        float radius = (millis() - smartBombFireTime) / 1000.0f;
        noFill();
        strokeWeight(3);
        stroke(70, 70, 255);
        ellipse( 352, 426, radius * 250, radius * 250);
      }
    }
    noStroke();
  }


  void drawTargets() {
    fireEnabled = false;
    strokeWeight(1);
    synchronized(targets) {
      for (int i = targets.size() - 1; i >= 0; i--) {
        TargetObject t = targets.get(i);
        //update logic bits
        //if no update received for 280ms then remove this target
        if (millis() - t.lastUpdateTime > 280) {
          if(t.targetted){
            consoleAudio.playClip("targetDestroyed");
          }
          targets.remove(i);
        }


        float lerpX = lerp(t.lastPos.x, t.pos.x, (millis() - t.lastUpdateTime ) / 250.0f);
        float lerpY = lerp(t.lastPos.z, t.pos.z, (millis() - t.lastUpdateTime ) / 250.0f);
        float lerpZ = lerp(t.lastPos.y, t.pos.y, (millis() - t.lastUpdateTime ) / 250.0f);

        float x = 352 + map(lerpX, -2000, 2000, -352, 352);
        float y = 426 + map(lerpY, -2000, 2000, -426, 426);
        if (t.pos.mag() < 200) {

          fill(255, 0, 0);
        } 
        else if (t.pos.mag() < 500) {
          fill(255, 255, 0);
        } 
        else {
          fill(0, 255, 0);
        }


        int size = (int) map(lerpZ, -2000, 2000, 1, 20);
        ellipse(x, y, size, size);
        String scanCode = "" + t.scanId;
        if (t.scanId < 1000) {
          scanCode = "0" + scanCode;
        }
        textFont(font, 12);
        if (sensorPower >= 3) {
          String h = String.format("%.2f", t.stats[0] * 100);
          text(t.name +": " + h + "%", x + 10, y + 30);
        } 
        else {
          text(t.name + ": ???%", x + 10, y +30);
        }
        text(scanCode, x + 10, y);

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

        if (t.beingFiredAt && firingTime + 400 > millis()) {
          stroke(255, 255, 0);
          strokeWeight(2);
          line(352, 426, x, y);
        }

        if (sensorPower > 3) {
          String h = String.format("%.2f", t.stats[1]);
          text(t.statNames[1] + ": "+ h, x + 10, y + 20);
        } 
        else {
          text(t.statNames[1] + ": ????", x + 10, y + 20);
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
      else {
        println(action.charAt(0));
        if ( action.charAt(0) >= '0' && action.charAt(0) <= '9') {
          scanString = scanString + action;
          if (scanString.length() > 4 ) {
            scanString = "";
          }
        }
      }
    }
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
        } 
        else {

          t.lastPos.x = t.pos.x;
          t.lastPos.y = t.pos.y;
          t.lastPos.z = t.pos.z;
        }
        t.lastUpdateTime = millis();
        t.pos = new PVector(x, y, z);
        t.stats[0] = theOscMessage.get(7).floatValue();
        t.stats[1] = theOscMessage.get(8).floatValue();
        t.statNames[0] = theOscMessage.get(9).stringValue();
        t.statNames[1] = theOscMessage.get(10).stringValue();
        t.name = theOscMessage.get(11).stringValue();
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
          if(t.targetted){
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


    public TargetObject() {
    }


    public int compareTo(TargetObject other) {
      return (int)(this.pos.mag() - other.pos.mag());
    }
  }
}

