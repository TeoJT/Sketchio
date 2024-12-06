




public class IOEngine extends TWEngine {
  
  public IOEngine(PApplet p) {
    super(p);
    power.allowMinimizedMode = false;
  }
  
  public String getAppName() {
    return "SketchIO";
  }
  
  public String getVersion() {
    return "Not versioned yet";
  }
  
  public String[] FORCE_CACHE_MUSIC() {
    String[] forceCacheMusic = {
      "engine/music/default.wav"
    };
    return forceCacheMusic;
  }
    
}
