import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.io.PrintWriter;

/**
*********************************** Sketchio ***********************************
*     A fork of the Timeway engine repurposed to be the new Sketchiepad.
* 
* 
*
*
* 
**/














IOEngine timewayEngine;
boolean sketch_showCrashScreen = false;
String sketch_ERR_LOG_PATH;

// Set to true if you want to show the error log like in an exported build
// rather than throw the error to processing (can be useful if you need more
// error info)
final boolean sketch_FORCE_CRASH_SCREEN = false;
final boolean sketch_MAXIMISE = true;

void settings() {
  try {
    // TODO... we're disabling graphics acceleration?!
    if (isLinux())
      System.setProperty("jogl.disable.openglcore", "true");
    size(displayWidth, displayHeight, P2D);
    //size(900, 1800, P2D);
    //size(750, 1200, P2D);
    smooth(1);
    pixelDensity(1);
    
    
    // Ugly, I know. But we're at the lowest level point in the program, so ain't
    // much we can do.
    final String iconLocation = "data/engine/img/icon.png";
    File f = new File(sketchPath()+"/"+iconLocation);
    if (f.exists()) {
      setDesktopIcon(iconLocation);
    }
    
    Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
        public void run() {
            shutdown();
        }
    }, "Shutdown-thread"));
    
  }
  catch (Exception e) {
    minimalErrorDialog("A fatal error has occurred: \n"+e.getMessage()+"\n"+e.getStackTrace());
  }
}

void shutdown() {
  timewayEngine.stats.save();
  timewayEngine.stats.set("last_closed", (int)(System.currentTimeMillis() / 1000L));
}


void sketch_openErrorLog(String mssg) {
  
  // Write the file
  try {
    FileWriter myWriter = new FileWriter(sketch_ERR_LOG_PATH);
    myWriter.write(mssg);
    myWriter.close();
    println(mssg);
  } catch (IOException e2) {}
  
  openErrorLog();
}

void sketch_openErrorLog(Exception e) {
  StringWriter sw = new StringWriter();
  PrintWriter pw = new PrintWriter(sw);
  e.printStackTrace(pw);
  String sStackTrace = sw.toString();
  
  String errMsg = 
  "Sorry! "+timewayEngine.getAppName()+" crashed :(\n"+
  "Please provide Teo Taylor with this error log, thanks <3\n\n\n"+
  e.getClass().toString()+"\nMessage: \""+
  e.getMessage()+"\"\nStack trace:\n"+
  sStackTrace;
  
  sketch_openErrorLog(errMsg);
}


// This is all the code you need to set up and start running
// the timeway engine.
void setup() {
    hint(DISABLE_OPENGL_ERRORS);
    background(0);
    
    if (isAndroid()) {
      //orientation(LANDSCAPE);    
    }
    
    // Are we running in Processing or as an exported application?
    File f1 = new File(sketchPath()+"/lib");
    sketch_showCrashScreen = f1.exists();
    println("ShowcrashScreen: ", sketch_showCrashScreen);
    sketch_ERR_LOG_PATH = sketchPath()+"/data/error_log.txt";
    
    timewayEngine = new IOEngine(this);
    timewayEngine.startScreen(new Startup(timewayEngine));
    
    surface.setTitle(timewayEngine.getAppName());
    
    requestAndroidPermissions();
}

void draw() {
  if (timewayEngine == null) {
    timewayEngine = new IOEngine(this);
  }
  else {
      // Show error message on crash
      if (sketch_showCrashScreen || sketch_FORCE_CRASH_SCREEN) {
        
        try {
          // Run Timeway.
          timewayEngine.engine();
        }
        catch (java.lang.OutOfMemoryError outofmem) {
          sketch_openErrorLog(timewayEngine.getAppName()+" has run out of memory.");
          exit();
        }
        catch (Exception e) {
          // Open a text document containing the error message
          sketch_openErrorLog(e);
          // Then shut it all down.
          exit();
        }
      }
      
      // Run Timeway.
      else timewayEngine.engine();
  }
}


void keyPressed() {
  if (timewayEngine != null && timewayEngine.input != null) {
    timewayEngine.input.keyboardAction(key, keyCode);
    timewayEngine.input.lastKeyPressed     = key;
    timewayEngine.input.lastKeycodePressed = keyCode;

    // Begin the timer. This will automatically increment once it's != 0.
    timewayEngine.input.keyHoldCounter = 1;
    
    //timewayEngine.console.log(char(key)+" "+int(key));
  }
}


void keyReleased() {
    // Stop the hold timer. This will no longer increment.
  if (timewayEngine != null && timewayEngine.input != null) {
    timewayEngine.input.keyHoldCounter = 0;
    timewayEngine.input.releaseKeyboardAction(key, keyCode);
    //timewayEngine.console.log(char(key)+" "+int(key)+" "+char(keyCode)+" "+int(keyCode));
  }
  
}

void mouseWheel(MouseEvent event) {
  if (timewayEngine != null && timewayEngine.input != null) timewayEngine.input.rawScroll = event.getCount();
  //println(event.scrollAmount());
  //TODO: ifShiftDown is horizontal scrolling!
  //println(event.isShiftDown());
  //println(timewayEngine.rawScroll);
}

void outputFileSelected(File selection) {
  if (timewayEngine != null) {
    timewayEngine.file.outputFileSelected(selection);
  }
}

void mouseClicked() {
  if (timewayEngine != null && timewayEngine.input != null) timewayEngine.input.clickEventAction();
}


// Because TWEngine is designed to be isolated from the rest of... well, Timeweay,
// there are some things that TWEngine needs to access that are external to the engine,
// and isolating it would mean those external dependancies wouldn't exist.
// These methods handle these external dependencies required by the engine through
// void methods
@SuppressWarnings("unused")
void twengineRequestEditor(String path) {
  //timewayEngine.requestScreen(new Editor(timewayEngine, path));
}

void twengineRequestSketch(String path) {
  timewayEngine.requestScreen(new Sketchpad(timewayEngine, path));
}

@SuppressWarnings("unused")
void twengineRequestUpdater(JSONObject json) {
  //timewayEngine.requestScreen(new Updater(timewayEngine, json));
}

//@SuppressWarnings("unused")
void twengineRequestBenchmarks() {
  //timewayEngine.requestScreen(new Updater(timewayEngine, json));
  //timewayEngine.requestScreen(new Benchmark(this));
}

@SuppressWarnings("unused")
void twengineRequestReadonlyEditor(String path) {
  
}

//@SuppressWarnings("unused")
boolean hasPixelrealm() {
  return false;
}


//@SuppressWarnings("unused")
boolean pixelrealmCache() {
  //boolean cacheHit = false;
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".wav");
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".ogg");
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+PixelRealm.REALM_BGM+".mp3");
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+file.unhide(PixelRealm.REALM_BGM+".wav"));
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+file.unhide(PixelRealm.REALM_BGM+".ogg"));
  //cacheHit |= sound.cacheHit(DEFAULT_DIR+"/"+file.unhide(PixelRealm.REALM_BGM+".mp3"));
  //cacheHit |= sound.cacheHit(APPPATH+PixelRealm.REALM_BGM_DEFAULT);
  //cacheHit |= sound.cacheHit(APPPATH+PixelRealm.REALM_BGM_DEFAULT_LEGACY);
  //return cacheHit;
  return true;
}
