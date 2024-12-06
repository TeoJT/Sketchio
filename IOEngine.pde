




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
  
  public void displaySketchioInput() {
    if (inputPromptShown) {
      app.fill(100);
      app.stroke(200);
      app.strokeWeight(2);
      float promptWi = 600;
      float promptHi = 250;
      app.rect(display.WIDTH/2-promptWi/2, display.HEIGHT/2-promptHi/2, promptWi, promptHi);
      displayInputPrompt();
    }
  }
    
}
