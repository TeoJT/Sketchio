


public class Sketchpad extends Screen {
  private TWEngine.PluginModule.Plugin plugin;
  private boolean completeCompilation = false;
  private boolean successful = false;
  private SpriteSystemPlaceholder sprites;
  private SpriteSystemPlaceholder gui;
  private PGraphics canvas;
  private float canvasScale = 1.0;
  private float canvasX = 0.0;
  private float canvasY = 0.0;
  boolean once = true;
  
  
  public Sketchpad(TWEngine engine) {
    super(engine);
    
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/test/");
    gui.interactable = false;
    
    sprites = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"test/");
    sprites.interactable = true;
    ui.useSpriteSystem(sprites);
    
    canvas = createGraphics(int(WIDTH/2), int(HEIGHT), P2D);
    resetView();
    
    canvasY = myUpperBarWeight;
    
    plugin = plugins.createPlugin();
    plugin.sketchioGraphics = canvas;
    
    
    input.keyboardMessage = """
public void start() {
  print("Hello worlddd");
}

int tmr = 0;
public void run() {
  g.background(120, 100, 140);
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
  
  private void resetView() {
    canvasX = canvas.width*canvasScale*0.5;
    canvasY = canvas.height*canvasScale*0.5;
    canvasScale = 1.0;
    input.scrollOffset = -1000.;
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
      canvas.beginDraw();
      canvas.background(210);
      display.setPGraphics(canvas);
      plugin.run();
      canvas.endDraw();
      display.setPGraphics(app.g);
    }
    sprites.updateSpriteSystem();
  }
  
  float beginDragX = 0.;
  float beginDragY = 0.;
  float prevCanvasX = 0.;
  float prevCanvasY = 0.;
  boolean isDragging = false;
  private void displayCanvas() {
    if (input.altDown && input.shiftDown && input.keys[int('s')] == 2) {
      input.backspace();
      resetView();
    }
    
    input.processScroll(100., 2500.);
    canvasScale = (-input.scrollOffset)/1000.;
    if (engine.mouseX() < WIDTH/2 && sprites.selectedSprite == null) {
      if (input.primaryDown && !isDragging) {
        beginDragX = engine.mouseX();
        beginDragY = engine.mouseY();
        prevCanvasX = canvasX;
        prevCanvasY = canvasY;
        isDragging = true;
      }
    }
    if (isDragging) {
      canvasX = prevCanvasX+(engine.mouseX()-beginDragX);
      canvasY = prevCanvasY+(engine.mouseY()-beginDragY);
      
      if (!input.primaryDown || sprites.selectedSprite != null) {
        isDragging = false;
      }
    }
    
    sprites.setMouseScale(canvasScale, canvasScale);
    float xx = canvasX-canvas.width*canvasScale*0.5;
    float yy = canvasY-canvas.height*canvasScale*0.5;
    sprites.setMouseOffset(xx, yy);
    
    app.image(canvas, xx, yy, canvas.width*canvasScale, canvas.height*canvasScale);
  }
  
  
  public void content() {
    power.setAwake();
    runCode();
    displayCanvas();
    
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
