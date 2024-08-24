import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.filechooser.FileSystemView;




public class Sketchpad extends Screen {
  private String sketchiePath = "";
  private TWEngine.PluginModule.Plugin plugin;
  private FFmpegEngine ffmpeg;
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
  private String renderFormat = "MPEG-4";
  private float upscalePixels = 1.;
  private boolean rendering = false;
  private boolean converting = false;
  private int timeBeforeStartingRender = 0;
  private PGraphics shaderCanvas;
  private PGraphics scaleCanvas;
  private int renderFrameCount = 0;
  private float renderFramerate = 0.;
  
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
    
    ffmpeg = new FFmpegEngine();
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
  
  // TODO: only loads one script
  private String loadScript() {
    String scriptPath = "";
    String ccode = "";
    if (file.exists(sketchiePath+"scripts")) scriptPath = sketchiePath+"scripts/";
    if (file.exists(sketchiePath+"script")) scriptPath = sketchiePath+"script/";
    // If scripts exist.
    if (scriptPath.length() > 0) {
      File[] scripts = (new File(scriptPath)).listFiles();
      for (File f : scripts) {
        String scriptAbsolutePath = f.getAbsolutePath();
        
        if (file.getExt(scriptAbsolutePath).equals("pde")) {
          String[] lines = app.loadStrings(scriptAbsolutePath);
          ccode = "";
          for (String s : lines) {
            ccode += s+"\n";
          }
          
          
          // Big TODO here: we're just gonna load one script for now
          // until I get things working.
          break;
        }
      }
    }
    else {
      // Script doesn't exist: return default code instead
      for (String s : defaultCode) {
        ccode += s+"\n";
      }
    }
    return ccode;
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
    
    input.keyboardMessage = loadScript();
    input.cursorX = input.keyboardMessage.length();
    
    // Load sketch config
    if (file.exists(path+"sketch_config.json")) {
      loadedJSON = loadJSONObject(path+"sketch_config.json");
      // Need to load the canvas from a seperate thread
    }
    
  }
  
  // methods for use by the API
  public float getTime() {
    return time;
  }
  
  public float getDelta() {
    // When we're rendering, all the file IO and expensive rendering operations will
    // inevitably make the actual framerate WAY lower than what we're aiming for and therefore
    if (rendering) return display.BASE_FRAMERATE/renderFramerate;
    else return display.getDelta();
  }
  
  private boolean menuShown() {
    return configMenu || renderMenu || rendering;
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
    
    // Use our custom delta funciton (which force sets it to the correct value while rendering)
    sprites.setDelta(getDelta());
    
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
    
    // This is simply to allow a few frames for the UI to disappear for user feedback.
    // We skip rendering if true here.
    if (rendering && timeBeforeStartingRender > 0) {
      timeBeforeStartingRender--;
      if (timeBeforeStartingRender == 3) {
        // Delete all files that may be in this folder
        File[] leftoverFiles = (new File(engine.APPPATH+"frames/")).listFiles();
        if (leftoverFiles != null) {
          for (File ff : leftoverFiles) {
            ff.delete();
          }
        }
      }
      time = 0.;
      return;
    }
    
    // The actual part where we render our animation
    if (rendering && !converting && successful && !compiling) {
      // This path has already been created so it will DEFO work
      String frame = engine.APPPATH+"frames/"+nf(renderFrameCount++, 6, 0)+".tiff";
      
      // Do shader stuff (TODO later)
      // And another TODO: optimise, if we don't have any shaders,
      // save directly from canvas instead (big performance saves!)
      shaderCanvas.beginDraw();
      shaderCanvas.clear();
      shaderCanvas.image(canvas, 0, 0, shaderCanvas.width, shaderCanvas.height);
      shaderCanvas.endDraw();
      
      // Do scaling (yay)
      // But if we don't have scaling enabled skip this step, will save performance and time.
      if (upscalePixels != 1) {
        scaleCanvas.beginDraw();
        scaleCanvas.clear();
        scaleCanvas.image(shaderCanvas, 0, 0, scaleCanvas.width, scaleCanvas.height);
        scaleCanvas.endDraw();
        scaleCanvas.save(frame);
      }
      else {
        // If scaling is disabled, then shading canvas already has everything we need.
        shaderCanvas.save(frame);
      }
      
    }
    
    // Update time
    if (playing) {
      time += getDelta();
      
      // When we reach the end of the animation
      if (time > timeLength) {
        if (rendering) {
          playing = false;
          beginConversion();
          
          // TODO: open output file
        }
        else {
          // Restart if looping, stop playing if not
          if (!loop) playing = false;
          else time = 0.;
        }
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
    // Scroll is negative
    canvasScale = (2500.+scroll)/1000.;
    
    
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
    
    // Positioning of the text variables
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
    
    if (rendering) {
      // Use the same panel (code editor) for the rendering info.
    }
    // All of this is y'know... the actual code editor.
    else {
      // make sure code string is sync'd with keyboardmessage
      if (!menuShown()) code = input.keyboardMessage;
      
      
      // ctrl+s save keystroke
      // Really got to fix this input.keys flaw thing.
      if (!input.altDown && input.ctrlDown && input.keys[int('s')] == 2) {
        saveScripts();
      }
      
      // Set engine typing settings.
      input.addNewlineWhenEnterPressed = true;
      engine.allowShowCommandPrompt = false;
      
      
      // Zoom in/out keys
      if (input.altDown && input.keys[int('=')] == 2) {
        textAreaZoom += 2.;
        input.backspace();
      }
      if (input.altDown && input.keys[int('-')] == 2) {
        textAreaZoom -= 2.;
        input.backspace();
      }
      
      // Scroll slightly when some y added to text.
      if (input.enterOnce) {
        if (getTextHeight(code) > (HEIGHT-myUpperBarWeight-myLowerBarWeight) && inCodePane) {
          input.scrollOffset -= (textAreaZoom);  // Literally just a random char
        }
      }
      
      // Slight position offset
      x += 5;
      y += 5;
        
      // Prepare font
      app.fill(255);
      app.textAlign(LEFT, TOP);
      app.textFont(display.getFont("Source Code"), textAreaZoom);
      app.textLeading(textAreaZoom);
      
      // Scrolling (make sure to keep in account the whole mouse-in-left-or-right pane thing
      // (god my code is so messy)
      float scroll = input.scrollOffset;
      if (!inCodePane) {
        scroll = codePaneScroll;
      }
      
      // Display text
      if (!menuShown()) {
        app.text(input.keyboardMessageDisplay(code), x, y+scroll);
      }
      else {
        app.text(code, x, y+scroll);
      }
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
      
      String compressionDisp = "Compression: "+renderFormat;
      
      if (textSprite("render-compression", compressionDisp) && !ui.miniMenuShown()) {
        String[] labels = new String[6];
        Runnable[] actions = new Runnable[6];
        
        labels[0] = "MPEG-4";
        actions[0] = new Runnable() {public void run() { renderFormat = labels[0]; }};
        
        labels[1] = "MPEG-4 (Lossless 4:2:0)";
        actions[1] = new Runnable() {public void run() { renderFormat = labels[1]; }};
        
        labels[2] = "MPEG-4 (Lossless (4:4:4)";
        actions[2] = new Runnable() {public void run() { renderFormat = labels[2]; }};
        
        labels[3] = "Apple ProRes 4444";
        actions[3] = new Runnable() {public void run() { renderFormat = labels[3]; }};
        
        labels[4] = "Animated GIF";
        actions[4] = new Runnable() {public void run() { renderFormat = labels[4]; }};
        
        labels[5] = "Animated GIF (Loop)";
        actions[5] = new Runnable() {public void run() { renderFormat = labels[5]; }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      
      String upscaleDisp = "Pixel upscale: "+int(upscalePixels*100.)+"% "+(upscalePixels == 1. ? "(None)" : "");
      
      if (textSprite("render-upscale", upscaleDisp) && !ui.miniMenuShown()) {
        String[] labels = new String[6];
        Runnable[] actions = new Runnable[6];
        
        labels[0] = "25%";
        actions[0] = new Runnable() {public void run() { upscalePixels = 0.25; }};
        
        labels[1] = "50%";
        actions[1] = new Runnable() {public void run() { upscalePixels = 0.5; }};
        
        labels[2] = "100% (None)";
        actions[2] = new Runnable() {public void run() { upscalePixels = 1.; }};
        
        labels[3] = "200%";
        actions[3] = new Runnable() {public void run() { upscalePixels = 2.; }};
        
        labels[4] = "300%";
        actions[4] = new Runnable() {public void run() { upscalePixels = 3.; }};
        
        labels[5] = "400%";
        actions[5] = new Runnable() {public void run() { upscalePixels = 4.; }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      
      if (ui.button("render-ok", "tick_128", "Start rendering")) {
        try {
          renderFramerate = Float.parseFloat(framerateField.value);
        }
        catch (NumberFormatException e) {
          console.log("Invalid inputs!");
          return;
        }
        
        beginRendering();
        input.keyboardMessage = code;
        renderMenu = false;
      }
      
      if (ui.button("render-cross-1", "cross", "")) {
        input.keyboardMessage = code;
        renderMenu = false;
      }
    }
  }
  
  private void beginRendering() {
    // Don't even bother if our code is not working
    if (!successful) {
      console.log("Fix compilation errors before rendering!");
      return;
    }
    
    // Check frames folder
    // Using File class cus we need to make dir if it dont exist
    String framesPath = engine.APPPATH+"frames/";
    console.log(framesPath);
    File f = new File(framesPath);
    if (!f.exists()) {
      f.mkdir();
    }
    
    // Create our canvases (absolutely no scaling allowed)
    shaderCanvas = createGraphics(canvas.width, canvas.height, P2D);
    ((PGraphicsOpenGL)shaderCanvas).textureSampling(2);   // Disable texture smoothing
    
    if (upscalePixels != 1.) {
      scaleCanvas = createGraphics(int(canvas.width*upscalePixels), int(canvas.height*upscalePixels), P2D);
      ((PGraphicsOpenGL)scaleCanvas).textureSampling(2);   // Disable texture smoothing
    }
    
    // set our variables
    time = 0.0;
    renderFrameCount = 0;
    power.allowMinimizedMode = false;
    playing = true;
    
    // Give a little bit of time so the UI can disappear for better user feedback.
    timeBeforeStartingRender = 5;
    
    // Now we begin.
    rendering = true;
  }
  
  // Calls our cool and totally not stolen createMovie function
  // and runs ffmpeg
  private void beginConversion() {
    int wi = canvas.width;
    int hi = canvas.height;
    if (upscalePixels != 1.) {
      wi = scaleCanvas.width;
      hi = scaleCanvas.height;
    }
    
    // create output folder if it don't exist.
    String outputFolder = engine.APPPATH+"output/";
    
    int outIndex = 1;
    // Note that files are named as:
    // 0001.mp4
    // 0002.mp4
    // 0003.gif
    // etc
    // This is so we can save our animation without
    // replacing any files that may already exist in this folder.
    
    File f = new File(outputFolder);
    if (!f.exists()) {
      f.mkdir();
    }
    else {
      File[] files = f.listFiles();
      // Find the highest number count.
      int highest = 0;
      for (File ff : files) {
        // Not to worry if it's a string like "aaa", processing's
        // int() just returns 0 if that's the case.
        int num = int(file.getIsolatedFilename(ff.getName()));
        if (num > highest) {
          highest = num;
        }
      }
      // Now we have the highest
      outIndex = highest+1;
    }
    
    // Annnnnd the extension
    String ext = ".mp4";
    if (renderFormat.contains("GIF")) ext = ".gif";
    else if (renderFormat.contains("Apple")) ext = ".mov";
    
    converting = true;
    ffmpeg.framecount = 0;
    createMovie(outputFolder+nf(outIndex, 4, 0)+ext, "", engine.APPPATH+"frames/", wi, hi, (double)renderFramerate, renderFormat);
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
            canvasSmooth = loadedJSON.getInt("smooth", 1);
            createCanvas(loadedJSON.getInt("canvas_width", 1024), loadedJSON.getInt("canvas_height", 1024), canvasSmooth);
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
    
    // Display UI for rendering
    if (rendering) {
      // We have one for stage 1 and stage 2
      if (!converting) {
        ui.loadingIcon(WIDTH*0.75, HEIGHT/2);
        textSprite("renderinginfoscreen-txt1", "Rendering sketch...\nStage 1/2");
        if (ui.button("renderinginfoscreen-cancel", "cross_128", "Stop rendering")) {
          playing = false;
          rendering = false;
          power.allowMinimizedMode = true;
          console.log("Rendering cancelled.");
        }
      }
      else {
        ui.loadingIcon(WIDTH*0.75, HEIGHT/2);
        textSprite("renderinginfoscreen-txt1", 
        "Converting to "+renderFormat+"...\n"+
        "Stage 2/2\n"+
        "("+ffmpeg.framecount+"/"+renderFrameCount+")");
        
        // Finish rendering
        //if (ffmpeg.framecount >= renderFrameCount) {
        //}
        
        // TODO: progress bar?
      }
    }
    
    if (!menuShown()) {
      if (ui.button("compile_button", "media_128", "Compile")) {
        saveScripts();
        compileCode(loadScript());
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
        framerateField.value = "60";
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
        if (input.primaryDown && !rendering) {
          float notchPercent = min(max((input.mouseX()-BAR_X_START)/BAR_X_LENGTH, 0.), 1.);
          time = timeLength*notchPercent;
        }
      }
      else {
        // If in play button area
        if (input.primaryClick && !rendering) {
          // Toggle play/pause button
          playing = !playing;
          // Restart if at end
          if (playing && time > timeLength) time = 0.;
        }
        // Right click action to show minimenu
        else if (input.secondaryClick && !rendering) {
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
  
  
  
  // Literally copy+pasted straight from processing code.
  void createMovie(String path, String soundFilePath, String imgFolderPath, final int wi, final int hi, final double fps, final String formatName) {
    final File movieFile = new File(path);
  
    // ---------------------------------
    // Check input
    // ---------------------------------
    final File soundFile = soundFilePath.trim().length() == 0 ? null : new File(soundFilePath.trim());
    final File imageFolder = imgFolderPath.trim().length() == 0 ? null : new File(imgFolderPath.trim());
    if (soundFile == null && imageFolder == null) {
      timewayEngine.console.bugWarn("createMovie: Need soundFile imageFolder input");
      return;
    }
  
    if (wi < 1 || hi < 1 || fps < 1) {
      timewayEngine.console.bugWarn("createMovie: bad numbers");
      return;
    }
  
    // ---------------------------------
    // Create the QuickTime movie
    // ---------------------------------
    new SwingWorker<Throwable, Object>() {
  
      @Override
      protected Throwable doInBackground() {
        try {
          // Read image files
          File[] imgFiles;
          if (imageFolder != null) {
            imgFiles = imageFolder.listFiles(new FileFilter() {
              final FileSystemView fsv = FileSystemView.getFileSystemView();
  
              public boolean accept(File f) {
                return f.isFile() && !fsv.isHiddenFile(f) &&
                  !f.getName().equals("Thumbs.db");
              }
            });
            if (imgFiles == null || imgFiles.length == 0) {
              timewayEngine.console.bugWarn("createMovie: no images found");
            }
            Arrays.sort(imgFiles);
  
            // Delete movie file if it already exists.
            if (movieFile.exists()) {
              if (!movieFile.delete()) {
                return new RuntimeException("Could not replace " + movieFile.getAbsolutePath());
              }
            }
  
            ffmpeg.write(movieFile, imgFiles, soundFile, wi, hi, fps, formatName);
          }
          return null;
  
        } catch (Throwable t) {
          return t;
        }
      }
  
      @Override
      protected void done() {
        Throwable t;
        try {
          t = get();
        } catch (Exception ex) {
          t = ex;
        }
        if (t != null) {
          t.printStackTrace();
          console.warn("createMovie: Failed to create movie, sorry");
        }
        else {
          rendering = false;
          converting = false;
          power.allowMinimizedMode = true;
          console.log("Done render!");
          
          // Show the file in file explorer
          file.open(engine.APPPATH+"output/");
        }
      }
    }.execute();
  
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
