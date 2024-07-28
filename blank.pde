


public class Blank extends Screen {
  TWEngine.PluginModule.Plugin plugin;
  boolean completeCompilation = false;
  boolean successful = false;
  SpriteSystemPlaceholder sprites;
  
  public Blank(TWEngine engine) {
    super(engine);
    
    sprites = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"test/");
    sprites.interactable = true;
    ui.useSpriteSystem(sprites);
    
    plugin = plugins.createPlugin();
    
    String code = """
      public void start() {
        app.println("Hello worlddd");
      }
      
      int tmr = 0;
      public void run() {
        app.background(120, 100, 140);
        sprite("logo");
      }
  """;
    
    Thread t1 = new Thread(new Runnable() {
      public void run() {
          completeCompilation = false;
          successful = plugin.compile(code);
          completeCompilation = true;
        }
      }
    );
    t1.start();
  }
  
  boolean once = true;
  public void content() {
    if (completeCompilation && once) {
      once = false;
      if (!successful) {
        console.log(plugin.errorOutput);
      }
      else {
        console.log("Successful compilation!");
      }
    }
    if (successful && completeCompilation) {
      plugin.run();
      sprites.updateSpriteSystem();
    }
  }
}
