

public class ConsoleAudio {

  Minim minim;
  Hashtable<String, AudioSample> audioList;

  public ConsoleAudio(Minim minim) {
    this.minim = minim;
    loadSounds();
  }

  private void loadSounds() {
    //load sounds from soundlist.cfg
    audioList = new Hashtable<String, AudioSample>();
    String lines[] = loadStrings("audio/soundlist.cfg");
    println("Loading " + lines.length + " SFX");
    for (int i = 0 ; i < lines.length; i++) {
      String[] parts = lines[i].split("=");
      if(parts.length == 2 && !parts[0].startsWith("#")){
        println("loading: " + parts[1]);
        AudioSample s = minim.loadSample("audio/" + parts[1], 512);
        //move to left channel
        s.setBalance(-1.0f);
        audioList.put(parts[0], s);
      }

    }
  }

  public void playClip(String name) {
    AudioSample c = audioList.get(name);
    if(c != null){
      c.setBalance(-1.0f);
      c.trigger();
    } else {
      println("ALERT: tried to play " + name + " but not found");
    }
      
  }
}

