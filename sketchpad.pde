


public class Sketchpad extends Screen {
  private String sketchiePath = "";
  private TWEngine.PluginModule.Plugin plugin;
  private String code = "";
  private boolean compiling = false;
  private boolean successful = false;
  private SpriteSystemPlaceholder sprites;
  private SpriteSystemPlaceholder gui;
  private PGraphics canvas;
  private float canvasScale = 1.0;
  private float canvasX = 0.0;
  private float canvasY = 0.0;
  private float canvasPaneScroll = 0.;
  private float codePaneScroll = 0.;
  boolean once = true;
  private ArrayList<String> imagesInSketch = new ArrayList<String>();  // This is so that we can know what to remove when we exit this screen.
  private ArrayList<PImage> loadedImages = new ArrayList<PImage>();
  private AtomicBoolean loading = new AtomicBoolean(true);
  private AtomicInteger processAfterLoadingIndex = new AtomicInteger(0);
  float textAreaZoom = 22.0;
  private boolean configMenu = false;
  private boolean renderMenu = false;
  private int canvasSmooth = 1;
  
  private boolean playing = false;
  private boolean loop = false;
  private float time = 0.;
  private float timeLength = 10.*60.;
  
  // Canvas 
  private float beginDragX = 0.;
  private float beginDragY = 0.;
  private float prevCanvasX = 0.;
  private float prevCanvasY = 0.;
  private boolean isDragging = false;
  
  
  private String[] defaultCode = {
    "public void start() {",
    "  ",
    "}",
    "",
    "public void run() {",
    "  g.background(120, 100, 140);",
    "  ",
    "}"
  };
  

  public Sketchpad(TWEngine engine, String path) {
    this(engine);
    
    loadSketchieInSeperateThread(path);
  }
  
  public Sketchpad(TWEngine engine) {
    super(engine);
    myUpperBarWeight = 100.;
    
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB+"gui/sketchpad/");
    gui.interactable = false;
    
    createCanvas(1024, 1024, 1);
    resetView();
    
    canvasY = myUpperBarWeight;
    
    plugin = plugins.createPlugin();
    plugin.sketchioGraphics = canvas;
    
    input.keyboardMessage = "";
    // Load default code into keyboardMessage
    for (String s : defaultCode) {
      input.keyboardMessage += s+"\n";
    }
    input.cursorX = input.keyboardMessage.length();
    
    
//    input.keyboardMessage = """

//public void start() {
//  print("Hello worlddd");
//}

//public void run() {
//  g.background(120, 100, 140);
//  sprite("app-3", "logo");
//  float y = app.sin(getTimeSeconds())*50.f;
//  moveSprite("app-3", 0, y);
//}
//  """;
  
    //compileCode(input.keyboardMessage);
  }
  
  private void createCanvas(int wi, int hi, int smooth) {
    canvas = createGraphics(wi, hi, P2D);
    if (smooth == 0) {
      // Nearest neighbour (hey remember this ancient line of code?)
      ((PGraphicsOpenGL)canvas).textureSampling(2);    
    }
    else {
      canvas.smooth(smooth);
    }
  }
  
  private void loadSketchieInSeperateThread(String path) {
    loading.set(true);
    processAfterLoadingIndex.set(0);
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        loadSketchie(path);
        loading.set(false);
      }
    });
    t1.start();
  }
  
  // NOTE: there isn't an equivalent "saveSketchie" method because we don't have
  // to save the whole thing:
  // - sprite data is saved automatically by the sprite class
  // - images... well, I don't think they need to be saved.
  private void saveScripts() {
    // Not gonna bother putting a TODO but you know that the script isn't going to stick to
    // a keyboard forever.
    String[] strs = new String[1];
    strs[0] = code;
    app.saveStrings(sketchiePath+"scripts/main.pde", strs);
    
    console.log("Saved.");
  }
  
  private void saveConfig() {
    JSONObject json = new JSONObject();
    json.setInt("canvas_width", canvas.width);
    json.setInt("canvas_height", canvas.height);
    json.setInt("smooth", canvasSmooth);
    json.setFloat("time_length", timeLength);
    
    app.saveJSONObject(json, sketchiePath+"sketch_config.json");
  }
  
  private JSONObject loadedJSON = null;
  private void loadSketchie(String path) {
    imagesInSketch.clear();
    loadedImages.clear();
    processAfterLoadingIndex.set(0);
    
    // Undirectorify path
    if (path.charAt(path.length()-1) == '/') {
      path.substring(0, path.length()-1);
      console.log(path);
    }
    
    if (!file.getExt(path).equals(engine.SKETCHIO_EXTENSION) || !file.isDirectory(path)) {
      console.warn("Not a valid sketchie file: "+path);
      return;
    }
    
    // Re-directorify path
    path = file.directorify(path);
    sketchiePath = path;
    
    // Load images
    String imgPath = "";
    if (file.exists(path+"imgs")) imgPath = path+"imgs";
    if (file.exists(path+"img")) imgPath = path+"img";
    
    // Only if imgs folder exists
    if (imgPath.length() > 0) {
      // List out all the files, get each image.
      File[] imgs = (new File(imgPath)).listFiles();
      int numberImages = 0;
      for (File f : imgs) {
        if (f == null) continue;
        
        String pathToSingularImage = f.getAbsolutePath().replaceAll("\\\\", "/");
        String name = file.getIsolatedFilename(pathToSingularImage);
        
        // Only load images
        if (!file.isImage(pathToSingularImage)) {
          continue;
        }
        
        // Actual loading (you'll want to run loadSketchie in a seperate thread);
        PImage img = loadImage(pathToSingularImage);
        
        
        // Error checking
        if (img == null) {
          console.warn("Error while loading image "+name);
          continue;
        }
        if (img.width <= 0 && img.height <= 0) {
          console.warn("Error while loading image "+name);
          continue;
        }
        
        // To avoid race conditions, we need to put the images in a temp linked list
        // Add to list so we know what to clear from memory once we're done.
        imagesInSketch.add(name);
        loadedImages.add(img);
        numberImages++;
      }
      processAfterLoadingIndex.set(numberImages);
    }
    
    
    
    // Next: load sprites. Not too hard.
    String spritePath = "";
    if (file.exists(path+"sprites")) spritePath = path+"sprites/";
    if (file.exists(path+"sprite")) spritePath = path+"sprite/";
    
    // If sprites exist.
    if (spritePath.length() > 0) {
      // Load our new sprite system, EZ.
      sprites = new SpriteSystemPlaceholder(engine, spritePath);
      sprites.interactable = true;
    }
    
    
    // And now: script
    
    String scriptPath = "";
    if (file.exists(path+"scripts")) scriptPath = path+"scripts/";
    if (file.exists(path+"script")) scriptPath = path+"script/";
    // If scripts exist.
    if (scriptPath.length() > 0) {
      File[] scripts = (new File(scriptPath)).listFiles();
      for (File f : scripts) {
        String scriptAbsolutePath = f.getAbsolutePath();
        
        if (file.getExt(scriptAbsolutePath).equals("pde")) {
          String[] lines = app.loadStrings(scriptAbsolutePath);
          input.keyboardMessage = "";
          for (String s : lines) {
            input.keyboardMessage += s+"\n";
          }
          input.cursorX = input.keyboardMessage.length();
          
          // Big TODO here: we're just gonna load one script for now
          // until I get things working.
          break;
        }
      }
    }
    
    // Load sketch config
    if (file.exists(path+"sketch_config.json")) {
      loadedJSON = loadJSONObject(path+"sketch_config.json");
      // Need to load the canvas from a seperate thread
    }
    
  }
  
  // for use by the API
  public float getTime() {
    return time;
  }
  
  private boolean menuShown() {
    return configMenu || renderMenu;
  }
  
  private void compileCode(String code) {
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        compiling = true;
        successful = plugin.compile(code);
        compiling = false;
        once = true;
      }
    });
    t1.start();
  }
  
  private void resetView() {
    canvasX = canvas.width*canvasScale*0.5;
    canvasY = canvas.height*canvasScale*0.5;
    canvasScale = 1.0;
    // Only reset view if the mouse is in the canvas pane
    if (input.mouseX() < middle()) {
      canvasPaneScroll = -1000.;
    }
    else {
      input.scrollOffset = -1000.;
    }
    
  }
  
  private void runCode() {
    // Display compilation status
    if (!compiling && once) {
      once = false;
      if (!successful) {
        console.log(plugin.errorOutput);
        playing = false;
      }
      else {
        console.log("Successful compilation!");
        playing = true;
        time = 0.;
      }
    }
    
    // Need to use the right sprite system
    ui.useSpriteSystem(sprites);
    sprites.interactable = !menuShown();
    
    // Switch canvas, then begin running the plugin code
    if (successful && !compiling) {
      canvas.beginDraw();
      canvas.fill(255, 255);
      display.setPGraphics(canvas);
      plugin.run();
      canvas.endDraw();
    }
    sprites.updateSpriteSystem();
    display.setPGraphics(app.g);
    
    // Update time
    if (playing) {
      time += display.getDelta();
      if (time > timeLength) {
        if (!loop) playing = false;
        else time = 0.;
      }
    }
  }
  
  // Creating this funciton because I think the width of
  // canvas v the code editor will likely change later
  // and i wanna maintain good code.
  private float middle() {
    return WIDTH/2;
  }
  
  boolean inCanvasPane = false;
  
  private void displayCanvas() {
    if (input.altDown && input.shiftDown && input.keys[int('s')] == 2) {
      input.backspace();
      resetView();
    }
    
    // Difficulty: we have 2 scroll areas: canvas zoom, and code editor.
    // if mouse is in canvas pane
    boolean canvasPane = input.mouseX() < middle() && !menuShown();
    if (canvasPane) {
      if (!inCanvasPane) {
        inCanvasPane = true;
        // We need to switch to our scroll value for the zoom
        codePaneScroll   = input.scrollOffset;     // Update code pane
        input.scrollOffset = canvasPaneScroll;
      }
      input.processScroll(100., 2500.);
    }
    
    float scroll = input.scrollOffset;
    if (!canvasPane) {
      scroll = canvasPaneScroll;
    }
    canvasScale = (-scroll)/1000.;
    
    
    if (canvasPane && sprites.selectedSprite == null && input.mouseY() < HEIGHT-myLowerBarWeight && input.mouseY() > myUpperBarWeight) {
      if (input.primaryDown && !isDragging) {
        beginDragX = input.mouseX();
        beginDragY = input.mouseY();
        prevCanvasX = canvasX;
        prevCanvasY = canvasY;
        isDragging = true;
      }
    }
    if (isDragging) {
      canvasX = prevCanvasX+(input.mouseX()-beginDragX);
      canvasY = prevCanvasY+(input.mouseY()-beginDragY);
      
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
  
  // Ancient code copied from Timeway it aint my fault pls believe me.
  private int countNewlines(String t) {
      int count = 0;
      for (int i = 0; i < t.length(); i++) {
          if (t.charAt(i) == '\n') {
              count++;
          }
      }
      return count;
  }
  
  private float getTextHeight(String txt) {
    float lineSpacing = 8;
    return ((app.textAscent()+app.textDescent()+lineSpacing)*float(countNewlines(txt)+1));
  }
  
  private void displayCodeEditor() {
    if (!menuShown()) code = input.keyboardMessage;
    
    // Update scroll for code pane
    boolean inCodePane = input.mouseX() >= middle();
    if (inCodePane) {
      if (inCanvasPane) {
        inCanvasPane = false;
        // We need to switch to our scroll value for the code scroll
        canvasPaneScroll   = input.scrollOffset;     
        input.scrollOffset = codePaneScroll;
      }
      
      input.processScroll(0., max(getTextHeight(code)-(HEIGHT-myUpperBarWeight-myLowerBarWeight), 0));
    }
    
    // ctrl+s save keystroke
    // Really got to fix this input.keys flaw thing.
    if (input.ctrlDown && input.keys[int('s')] == 2) {
      saveScripts();
    }
    
    input.addNewlineWhenEnterPressed = true;
    engine.allowShowCommandPrompt = false;
    
    // Used to be a function in engine, moved it to here because complications with
    // scroll, don't care.
    float x = middle();
    float y = myUpperBarWeight;
    float wi = WIDTH-middle(); 
    float hi = HEIGHT-myUpperBarWeight-myLowerBarWeight;
    
    
    // TODO: I really wanna use our shaders to reduce shader-switching
    // instead of processing's shaders.
    app.resetShader();
    // Draw background
    app.fill(60);
    app.noStroke();
    app.rect(x, y, wi, hi);
    
    
    if (input.altDown && input.keys[int('=')] == 2) {
      textAreaZoom += 2.;
      input.backspace();
    }
    if (input.altDown && input.keys[int('-')] == 2) {
      textAreaZoom -= 2.;
      input.backspace();
    }
    
    // Scroll slightly when some y added t text.
    if (input.enterOnce) {
      if (getTextHeight(code) > (HEIGHT-myUpperBarWeight-myLowerBarWeight) && inCodePane) {
        input.scrollOffset -= (textAreaZoom);  // Literally just a random char
      }
    }
    
    x += 5;
    y += 5;
      
    app.fill(255);
    app.textAlign(LEFT, TOP);
    app.textFont(display.getFont("Source Code"), textAreaZoom);
    app.textLeading(textAreaZoom);
    
    float scroll = input.scrollOffset;
    if (!inCodePane) {
      scroll = codePaneScroll;
    }
    
    if (!menuShown()) {
      app.text(input.keyboardMessageDisplay(code), x, y+scroll);
    }
    else {
      app.text(code, x, y+scroll);
    }
  }
  
  TextField selectedField = null;
  class TextField {
    private String spriteName = "";
    public String value = "";
    private String labelDisplay = "";
    
    public TextField(String spriteName, String labelDisplay) {
      this.spriteName = spriteName;
      this.labelDisplay = labelDisplay;
    }
    
    public void display() {
      String disp = gui.interactable ? "white" : "nothing";
      if (selectedField == this) {
        gui.sprite(spriteName, disp);
        value = input.keyboardMessage;
      }
      else {
        if (ui.button(spriteName, disp, "")) {
          selectedField = this;
          input.keyboardMessage = value;
        }
      }
      
      float x = gui.getSprite(spriteName).getX();
      float y = gui.getSprite(spriteName).getY();
      
      
      app.textAlign(LEFT, TOP);
      app.textSize(32);
      if (selectedField == this) {
        app.text(labelDisplay+input.keyboardMessageDisplay(value), x, y);
      }
      else {
        app.text(labelDisplay+value, x, y);
      }
    }
  }
  
  
  
  public boolean textSprite(String name, String val) {
    String disp = gui.interactable ? "white" : "nothing";
    boolean clicked = ui.button(name, disp, "");
    
    float x = gui.getSprite(name).getX();
    float y = gui.getSprite(name).getY();
    
    app.textAlign(LEFT, TOP);
    app.textSize(32);
    app.text(val, x, y);
    return clicked;
  }
  
  
  TextField widthField  = new TextField("config-width", "Width: ");
  TextField heightField = new TextField("config-height", "Height: ");
  TextField timeLengthField = new TextField("config-timelength", "Video length: ");
  TextField framerateField = new TextField("render-framerate", "Framerate: ");
  public void displayMenu() {
    if (menuShown()) {
      // Bug fix to prevent sprite being selected as we click the menu.
      if (!loading.get()) sprites.selectedSprite = null;
    }
    
    // All config menu stuff
    if (configMenu) {
      
      gui.sprite("config-back-1", "black");
      
      textSprite("config-menu-title", "--- Sketch config ---");
      
      
      // Width and height fields
      app.fill(255);
      widthField.display();
      heightField.display();
      timeLengthField.display();
      
      String smoothDisp = "Anti-aliasing: ";
      switch (canvasSmooth) {
        case 0:
        smoothDisp += "None (pixelated)";
        break;
        case 1:
        smoothDisp += "1x";
        break;
        case 2:
        smoothDisp += "2x";
        break;
        case 4:
        smoothDisp += "4x";
        break;
        case 8:
        smoothDisp += "8x";
        break;
      }
      
      if (textSprite("config-smooth", smoothDisp) && !ui.miniMenuShown()) {
        String[] labels = new String[5];
        Runnable[] actions = new Runnable[5];
        
        labels[0] = "None (pixelated)";
        actions[0] = new Runnable() {public void run() { canvasSmooth = 0; }};
        
        labels[1] = "1x anti-aliasing";
        actions[1] = new Runnable() {public void run() { canvasSmooth = 1; }};
        
        labels[2] = "2x anti-aliasing";
        actions[2] = new Runnable() {public void run() { canvasSmooth = 2; }};
        
        labels[3] = "4x anti-aliasing";
        actions[3] = new Runnable() {public void run() { canvasSmooth = 4; }};
        
        labels[4] = "8x anti-aliasing";
        actions[4] = new Runnable() {public void run() { canvasSmooth = 8; }};
        
        
        ui.createOptionsMenu(labels, actions);
      }
      
      
      if (ui.button("config-cross-1", "cross", "")) {
        input.keyboardMessage = code;
        configMenu = false;
      }
      
      if (ui.button("config-ok", "tick_128", "Apply")) {
        time = 0.;
        
        try {
          int wi = Integer.parseInt(widthField.value);
          int hi = Integer.parseInt(heightField.value);
          timeLength = Float.parseFloat(timeLengthField.value)*60.;
          
          createCanvas(wi, hi, canvasSmooth);
        }
        catch (NumberFormatException e) {
          console.log("Invalid inputs!");
          return;
        }
        
        saveConfig();
        
        // End
        input.keyboardMessage = code;
        configMenu = false;
      }
    }
    
    // We only ever show one of these menu's at a time.
    else if (renderMenu) {
      
      gui.sprite("render-back-1", "black");
      
      textSprite("render-menu-title", "--- Render ---");
      
      framerateField.display();
      
      String compressionDisp = "Compression: ";
      
      if (textSprite("render-compression", compressionDisp) && !ui.miniMenuShown()) {
        String[] labels = new String[6];
        Runnable[] actions = new Runnable[6];
        
        labels[0] = "MPEG-4";
        actions[0] = new Runnable() {public void run() {  }};
        
        labels[1] = "MPEG-4 (Lossless 4:2:0)";
        actions[1] = new Runnable() {public void run() {  }};
        
        labels[2] = "MPEG-4 (Lossless (4:4:4)";
        actions[2] = new Runnable() {public void run() {  }};
        
        labels[3] = "Apple ProRes 4444";
        actions[3] = new Runnable() {public void run() {  }};
        
        labels[4] = "Animated GIF";
        actions[4] = new Runnable() {public void run() {  }};
        
        labels[5] = "Animated GIF (loop)";
        actions[5] = new Runnable() {public void run() {  }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      String upscaleDisp = "Pixel upscale: ";
      if (textSprite("render-upscale", upscaleDisp) && !ui.miniMenuShown()) {
        String[] labels = new String[6];
        Runnable[] actions = new Runnable[6];
        
        labels[0] = "x1 (None)";
        actions[0] = new Runnable() {public void run() {  }};
        
        labels[1] = "x2";
        actions[1] = new Runnable() {public void run() {  }};
        
        labels[2] = "x3";
        actions[2] = new Runnable() {public void run() {  }};
        
        labels[3] = "x4";
        actions[3] = new Runnable() {public void run() {  }};
        
        labels[4] = "x5";
        actions[4] = new Runnable() {public void run() {  }};
        
        labels[5] = "x6";
        actions[5] = new Runnable() {public void run() {  }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      if (ui.button("render-cross-1", "cross", "")) {
        input.keyboardMessage = code;
        renderMenu = false;
      }
    }
  }
  
  public void content() {
    power.setAwake();
    
    if (!loading.get()) {
      if (processAfterLoadingIndex.get() > 0) {
        int i = processAfterLoadingIndex.decrementAndGet();
        
        // Create large image, I don't want the lag
        // TODO: option to select large image or normal pimage.
        LargeImage largeimg = display.createLargeImage(loadedImages.get(i));
        
        
        // Add to systemimages so we can use it in our sprites
        display.systemImages.put(imagesInSketch.get(i), new DImage(largeimg, loadedImages.get(i)));
        
        if (i == 0) {
          if (loadedJSON != null) {
            timeLength = loadedJSON.getFloat("time_length", 10.0);
            createCanvas(loadedJSON.getInt("canvas_width", 1024), loadedJSON.getInt("canvas_height", 1024), loadedJSON.getInt("smooth", 1));
          }
          
          compileCode(code);
        }
      }
      
      runCode();
      displayCanvas();
      displayCodeEditor();
    }
    else {
      ui.loadingIcon(WIDTH/4, HEIGHT/2);
      app.textFont(engine.DEFAULT_FONT, 32);
      app.fill(255);
      app.textAlign(CENTER, TOP);
      app.text("Loading...", WIDTH/4, HEIGHT/2+128);
    }
  }
  
  
  public void upperBar() {
    display.shader("fabric", "color", 0.43,0.4,0.42,1., "intensity", 0.1);
    super.upperBar();
    app.resetShader();
    ui.useSpriteSystem(gui);
    
    if (!menuShown()) {
      if (ui.button("compile_button", "media_128", "Compile")) {
        compileCode(code);
      }
      
      if (ui.button("settings_button", "doc_128", "Sketch config")) {
        widthField.value = str(canvas.width);
        heightField.value = str(canvas.height);
        timeLengthField.value = str(timeLength/60.);
        selectedField = null;
        configMenu = true;
        input.keyboardMessage = "";
      }
      
      if (ui.button("render_button", "image_128", "Render")) {
        selectedField = null;
        renderMenu = true;
        input.keyboardMessage = "";
      }
      
      if (ui.button("back_button", "back_arrow_128", "Explorer")) {
        saveScripts();
        previousScreen();
      }
      
      if (compiling) {
        ui.loadingIcon(WIDTH-myUpperBarWeight/2-10, myUpperBarWeight/2, myUpperBarWeight);
      }
    }
    else {
      displayMenu();
    }
    
    gui.updateSpriteSystem();
  }
  
  public void lowerBar() {
    display.shader("fabric", "color", 0.43,0.4,0.42,1., "intensity", 0.1);
    super.lowerBar();
    app.resetShader();
    
    float BAR_X_START = 70.;
    float BAR_X_LENGTH = WIDTH-120.-BAR_X_START;
    
    // Display timeline
    float y = HEIGHT-myLowerBarWeight;
    app.fill(50);
    app.noStroke();
    app.rect(BAR_X_START, y+(myLowerBarWeight/2)-2, BAR_X_LENGTH, 4);
    
    float percent = time/timeLength;
    float timeNotchPos = BAR_X_START+BAR_X_LENGTH*percent;
    
    app.fill(255);
    app.rect(timeNotchPos-4, y+(myLowerBarWeight/2)-25, 8, 50); 
    
    display.imgCentre(playing ? "pause_128" : "play_128", BAR_X_START/2, y+(myLowerBarWeight/2), myLowerBarWeight, myLowerBarWeight);
    
    if (input.mouseY() > y && !ui.miniMenuShown()) {
      if (input.mouseX() > BAR_X_START) {
        // If in bar zone
        if (input.primaryDown) {
          float notchPercent = min(max((input.mouseX()-BAR_X_START)/BAR_X_LENGTH, 0.), 1.);
          time = timeLength*notchPercent;
        }
      }
      else {
        // If in play button area
        if (input.primaryClick) {
          // Toggle play/pause button
          playing = !playing;
          // Restart if at end
          if (playing && time > timeLength) time = 0.;
        }
        // Right click action to show minimenu
        else if (input.secondaryClick) {
          String[] labels = new String[1];
          Runnable[] actions = new Runnable[1];
          
          labels[0] = loop ? "Disable loop" : "Enable loop";
          actions[0] = new Runnable() {public void run() {
              loop = !loop;
          }};
          
          ui.createOptionsMenu(labels, actions);
        }
      }
    }
  }
  
  
  public void finalize() {
    //free();
  }
  
  public void free() {
     // Clear the images from systemimages to clear up used images.
     for (String s : imagesInSketch) {
       display.systemImages.remove(s);
     }
     imagesInSketch.clear();
  }
}
