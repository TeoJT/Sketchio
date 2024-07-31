


public class Blank extends Screen {
  TWEngine.PluginModule.Plugin plugin;
  boolean completeCompilation = false;
  boolean successful = false;
  SpriteSystemPlaceholder sprites;
  SpriteSystemPlaceholder gui;
  PGraphics canvas;
  
  public Blank(TWEngine engine) {
    super(engine);
    
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/test/");
    gui.interactable = false;
    
    sprites = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"test/");
    sprites.interactable = true;
    ui.useSpriteSystem(sprites);
    
    canvas = createGraphics(int(WIDTH/2), int(HEIGHT), P2D);
    
    plugin = plugins.createPlugin();
    
    
    input.keyboardMessage = """
public void start() {
  print("Hello worlddd");
}

int tmr = 0;
public void run() {
  app.background(120, 100, 140);
  sprite("app-3", "logo");
  float y = app.sin(getTimeSeconds())*50.f;
  moveSprite("app-3", 0, y);
}
  """;
    compileCode();
    
  
  }
  
  private void compileCode() {
    final String code = input.keyboardMessage;
    Thread t1 = new Thread(new Runnable() {
      public void run() {
          completeCompilation = false;
          successful = plugin.compile(code);
          completeCompilation = true;
          once = true;
        }
      }
    );
    t1.start();
  }
  
  private void runCode() {
    if (completeCompilation && once) {
      once = false;
      if (!successful) {
        console.log(plugin.errorOutput);
      }
      else {
        console.log("Successful compilation!");
      }
    }
    ui.useSpriteSystem(sprites);
    if (successful && completeCompilation) {
      //canvas.beginDraw();
      //canvas.background(210);
      //display.setPGraphics(canvas);
      plugin.run();
      //canvas.endDraw();
      //display.setPGraphics(app.g);
    }
    sprites.updateSpriteSystem();
  }
  
  boolean once = true;
  public void content() {
    runCode();
    //app.image(canvas, 0, myUpperBarWeight, WIDTH/4, HEIGHT/2);
    input.addNewlineWhenEnterPressed = true;
    engine.allowShowCommandPrompt = false;
    ui.displayTextArea(WIDTH/2, myUpperBarWeight, WIDTH/2, HEIGHT-myUpperBarWeight-myLowerBarWeight);
    
  }
  
  public void upperBar() {
    super.upperBar();
    ui.useSpriteSystem(gui);
    if (ui.button("compile_button", "media_128", "Compile")) {
      compileCode();
    }
    
    if (!completeCompilation) {
      ui.loadingIcon(WIDTH-myUpperBarWeight/2-10, myUpperBarWeight/2, myUpperBarWeight);
    }
    gui.updateSpriteSystem();
  }
}
