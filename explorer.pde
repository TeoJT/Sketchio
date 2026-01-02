import java.awt.Desktop;

public class Explorer extends Screen {
  
  
  //private String currentDir = DEFAULT_DIR;
  
  private final String[] DEFAULT_CODE_NEON = {
    "public void start() {",
    "  ",
    "}",
    "",
    "public void run() {",
    "  g.background(120, 100, 140);",
    "  sprite(\"neon\");",
    "  ",
    "}"
  };
  
  private final String[] DEFAULT_CODE = {
    "public void start() {",
    "  ",
    "}",
    "",
    "public void run() {",
    "  g.background(120, 100, 140);",
    "  sprite(\"neon\");",
    "  ",
    "}"
  };
  
  //DisplayableFile backButtonDisplayable = null;
  SpriteSystem gui;
  private float scrollBottom = 0.0;
  private float scrollOffset = 0f;
  
  public Explorer(TWEngine engine) {
        super(engine);
        
        file.openDirInNewThread(engine.DEFAULT_DIR);
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
        gui.repositionSpritesToScale();
        gui.interactable = false;
        
        //myLowerBarColor   = color(120);
        //myUpperBarColor   = color(120);
        myBackgroundColor = color(0);
  }
  
  // Sorry for code duplication!
  public Explorer(TWEngine engine, String dir) {
        super(engine);
        
        file.openDirInNewThread(dir);
        gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/explorer/");
        gui.repositionSpritesToScale();
        gui.interactable = false;
        
        //myLowerBarColor   = color(120);
        //myUpperBarColor   = color(120);
        myBackgroundColor = color(0);
        
        //engine.openDir(dir);
  }
  
  // This method shall render all the files in the current dir
  private void renderDir() {
    
    final float TEXT_SIZE = 50;
    final float BOTTOM_SCROLL_EXTEND = 300;   // The scroll doesn't go all the way down to the bottom for whatever reason.
                                              // So let's add a little more room to scroll down to the bottom.
    
    app.textFont(engine.DEFAULT_FONT, 50);
    app.textSize(TEXT_SIZE);
    for (int i = 0; i < file.currentFiles.length; i++) {
      float textHeight = app.textAscent() + app.textDescent();
      float x = 50;
      float wi = TEXT_SIZE + 20;
      float y = 150 + i*TEXT_SIZE+scrollOffset;
      
      // Sorry not sorry
      try {
        if (file.currentFiles[i] != null) {
          if (engine.mouseX() > x && engine.mouseX() < x + app.textWidth(file.currentFiles[i].filename) + wi && engine.mouseY() > y && engine.mouseY() < textHeight + y) {
            // if mouse is overing over text, change the color of the text
            app.fill(100, 0, 255);
            app.tint(100, 0, 255);
            // if mouse is hovering over text and left click is pressed, go to this directory/open the file
            if (input.primaryOnce) {
              if (file.currentFiles[i].isDirectory())
                scrollOffset = 0.;
              
              file.open(file.currentFiles[i]);
            }
          } else {
            app.noTint();
            app.fill(255);
          }
          
          if (file.currentFiles[i].icon != null)
            display.img(file.currentFiles[i].icon, 50, y, TEXT_SIZE, TEXT_SIZE);
          app.textAlign(LEFT, TOP);
          app.text(file.currentFiles[i].filename, x + wi, y);
          app.noTint();
        }
      }
      catch (ArrayIndexOutOfBoundsException e) {
        
      }
      catch (NullPointerException ex) {
        
      }
    }
    
    scrollBottom = max(0, (file.currentFiles.length*TEXT_SIZE-HEIGHT+BOTTOM_SCROLL_EXTEND));
  }
    
  
  private void renderGui() {
    
    ui.useSpriteSystem(gui);
    
    // Buttons
    // Return here to not render them
    if (engine.inputPromptShown) return;
    
    //************NEW FOLDER************
    if (ui.button("new_folder", "new_folder_128", "New folder")) {
      
      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() <= 1) {
            console.log("Please enter a valid folder name!");
            return;
          }
          String foldername = file.currentDir+engine.promptInput;
          new File(foldername).mkdirs();
          refreshDir();
        }
      };
      
      engine.beginInputPrompt("Folder name:", r);
    }
    
    
    //************NEW SKETCHIO PROJECT************
    if (ui.button("new_project", "new_entry_128", "New project")) {
      
      Runnable r = new Runnable() {
        public void run() {
          if (engine.promptInput.length() <= 1) {
            console.log("Please enter a valid project name!");
            return;
          }
          String name = file.currentDir+engine.promptInput;
          createNewProject(name);
          refreshDir();
          file.open(name+"."+engine.SKETCHIO_EXTENSION);
        }
      };
      
      engine.beginInputPrompt("Project name:", r);
    }
    
    gui.updateSpriteSystem();
  }
  
  public void createNewProject(String path) {
    // .sketchio
    try {
      if (!path.substring(path.length()-9).equals(".sketchio")) {
        path += ".sketchio";
      }
    }
    catch (StringIndexOutOfBoundsException e) {
      path += ".sketchio";
    }
    file.mkdir(path);
    path += "/";
    
    file.mkdir(path+"img");
    file.mkdir(path+"music");
    file.mkdir(path+"scripts");
    file.mkdir(path+"shaders");
    file.mkdir(path+"sprites");
    
    if (file.exists(engine.APPPATH+"engine/other/neon.png")) {
      file.copy(engine.APPPATH+"engine/other/neon.png", path+"img/neon.png");
      app.saveStrings(path+"scripts/main.java", DEFAULT_CODE_NEON);
    }
    else {
      app.saveStrings(path+"scripts/main.java", DEFAULT_CODE);
    }
    
  }
  
  // Just use the default background
  public void backg() {
        app.fill(myBackgroundColor);
        app.noStroke();
        app.rect(0, 0, WIDTH, HEIGHT);
  }
  
  public void upperBar() {
    display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.upperBar();
    app.resetShader();
    renderGui();
    
    app.textAlign(LEFT, TOP);
    app.fill(0);
    app.textFont(engine.DEFAULT_FONT, 36);
    app.textFont(engine.DEFAULT_FONT, 36);
    app.text(file.currentDir, 10, 10);
  }
  
    
  public void lowerBar() {
    display.shader("fabric", "color", 0.5,0.5,0.5,1., "intensity", 0.1);
    super.lowerBar();
    display.resetShader();
  }
    
  
  public void refreshDir() {
    file.openDirInNewThread(file.currentDir);
  }
  
  
  // Let's render our stuff.
  public void content() {
    // TODO: Should have a function with this to remove code bloat?
      
      if (file.loading) {
        ui.loadingIcon(WIDTH/2, HEIGHT/2);
      }
      else {
        scrollOffset = input.processScroll(scrollOffset, 0., scrollBottom+1.0);
        renderDir();
      }
      
      ((IOEngine)engine).displaySketchioInput();
      
      // Render this on top.
      app.noStroke();
      app.fill(0);
      app.rect(0, 0, WIDTH, myUpperBarWeight+100);
      
      app.fill(255);
      app.textFont(engine.DEFAULT_FONT, 70);
      app.textAlign(LEFT, TOP);
      app.text("Explorer", 50, 80);
  }
  
}
