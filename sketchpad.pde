import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.filechooser.FileSystemView;


public class Sketchpad extends Screen {
  
  class AutomationBar {
    
    public float myHeight = 100f;
    public float LABEL_HEIGHT = 28f;
    public float SELECTION_BOX_WIDTH = 200f;
      
    float TOP_Y = 0f;
    float BOTTOM_Y = 0f;
    float LEFT_X = 0f;
    float RIGHT_X = 0f;
    
    public String name  = "Automation bar";
    protected color mycolor = color(255, 198, 75);
    public boolean snapping = true;
    public boolean beatsVisible = false;
    
    public AutomationBar(String name) {
      this.name = name;
    }
    
    public AutomationBar() {
      
    }
    
    public float getHeight() {
      return myHeight+LABEL_HEIGHT;
    }
    
    private boolean resizing = false;
    public boolean display(float yFromBottom) {
      BOTTOM_Y = HEIGHT-myLowerBarWeight;
      TOP_Y = BOTTOM_Y-yFromBottom-getHeight();
      RIGHT_X = middle();
      
      float y = TOP_Y;
      
      boolean mouseInPane = (input.mouseX() > 0f && input.mouseX() < RIGHT_X-2 && input.mouseY() > y && input.mouseY() < y+myHeight+LABEL_HEIGHT);
      
      app.stroke(200);
      app.strokeWeight(2f);
      app.fill(60);
      app.rect(0f, y, RIGHT_X-2, myHeight+LABEL_HEIGHT);
      app.line(0f, y+LABEL_HEIGHT, RIGHT_X, y+LABEL_HEIGHT);
      app.fill(255);
      app.textAlign(LEFT, TOP);
      app.textSize(LABEL_HEIGHT-10f);
      app.text(name, 5, y+5);
      app.text(nf(getFloatVal(time), 0, 3), RIGHT_X*0.4f, y+5);
      
      boolean colorpickerClicked = ui.buttonImg("nothing", RIGHT_X*0.5f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      app.fill(mycolor);
      app.noStroke();
      app.rect(RIGHT_X*0.5f+2f, y+2f, LABEL_HEIGHT-4f, LABEL_HEIGHT-4f);
      if (colorpickerClicked) {
        Runnable r = new Runnable() {
          public void run() {
            mycolor = ui.getPickedColor();
            save();
          }
        };
        ui.colorPicker(RIGHT_X*0.5f+LABEL_HEIGHT, y+LABEL_HEIGHT, r);
      }
      
      // Snapping button
      if (snapping) app.tint(255);
      else app.tint(127);
      boolean snaptoClicked = ui.buttonImg("snapto_64", RIGHT_X*0.5f+LABEL_HEIGHT+10f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      app.noTint();
      if (snaptoClicked) {
        snapping = !snapping;
        if (snapping) sound.playSound("select_bigger");
        else sound.playSound("select_smaller");
        save();
      }
      
      // Show music bars button
      if (beatsVisible) app.tint(255);
      else app.tint(127);
      boolean beatsClicked = ui.buttonImg("music", RIGHT_X*0.5f+(LABEL_HEIGHT+10f)*2f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      app.noTint();
      if (beatsClicked) {
        beatsVisible = !beatsVisible;
        if (beatsVisible) sound.playSound("select_bigger");
        else sound.playSound("select_smaller");
        save();
      }
      
      
      
      // Resizer
      boolean resizerClicked = ui.buttonImg("dragger_64", RIGHT_X-(LABEL_HEIGHT+10f)*2f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      if (resizerClicked) {
        resizing = true;
      }
      if (resizing) {
        myHeight = max(BOTTOM_Y-input.mouseY()-yFromBottom-LABEL_HEIGHT/2f, 30f);
        if (!input.primaryDown) {
          resizing = false;
          save();
        }
      }
      
      // Cross button
      boolean crossClicked = ui.buttonImg("cross", RIGHT_X-LABEL_HEIGHT-5f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      if (crossClicked) {
        sound.playSound("select_smaller");
        displayAutomationBars.remove(this);
        save();
      }
      
      display.clip(0f, y+LABEL_HEIGHT, RIGHT_X, myHeight);
      app.noStroke();
      //app.fill(0, 127);
      //app.rect(5, 5, SELECTION_BOX_WIDTH, LABEL_HEIGHT-10f);
      
      prev_x = 0f;
      TOP_Y += LABEL_HEIGHT;
      
      if (beatsVisible) {
        renderBeats();
      }
      
      renderData();
      
      display.noClip();
      
      return mouseInPane;
    }
    
    public float getFloatVal(float ttime) {
      return engine.noise(ttime*0.1);
    }
    
    private float prev_x = 0f;
    protected float plotLine(float normalizedX, boolean showVal) {
      float TOTAL_WIDTH = timeLength*5f;
      float tt = time/timeLength;
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      
      float x = (normalizedX)*TOTAL_WIDTH;
      
      float posToTime_prev = (prev_x/TOTAL_WIDTH)*timeLength;
      float posToTime = (x/TOTAL_WIDTH)*timeLength;
      
      float prev_y = TOP_Y+myHeight*(1f-getFloatVal(posToTime_prev));
      float y = TOP_Y+myHeight*(1f-getFloatVal(posToTime));
      
      float actualPrevX = prev_x+offX;
      float actualX = x+offX;
      
      prev_x = x;
      
      if ((actualPrevX > RIGHT_X && actualX > RIGHT_X) || (actualPrevX < 0f && actualX < 0f)) {
        return actualX;
      }
      app.line(actualPrevX, prev_y, actualX, y);
      
      if (showVal) {
        app.textSize(10);
        app.textAlign(CENTER, TOP);
        app.text(getFloatVal(posToTime_prev), x+offX, y-15f);
      }
      
      return actualX;
    }
    
    protected float plotLine(float normalizedX) {
      return plotLine(normalizedX, false);
    }
    
    protected void save() {
      
    }
    
    protected float screenXToTime(float x) {
      float TOTAL_WIDTH = timeLength*5f;
      float tt = time/timeLength;
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      float val = (x-offX)/TOTAL_WIDTH;
      float xx = val*timeLength;
      
      return xx;
    }
    
    protected float normalizedXToScreenX(float normalizedX) {
      float TOTAL_WIDTH = timeLength*5f;
      float tt = time/timeLength;
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      
      float x = (normalizedX)*TOTAL_WIDTH;
      float actualX = x+offX;
      
      return actualX;
    }
    
    
    protected float closestBeatSnap = -1f;
    protected float BEATSNAP_THRESHOLD = 10f;
    protected void renderBeats() {
      
      app.stroke(30, 180);
      app.strokeWeight(2f);
      closestBeatSnap = -1f;
      
      int l = (int)(timeLength/sound.framesPerBeat())+1;
      for (int i = 0; i < l; i++) {
        float x = normalizedXToScreenX((sound.framesPerBeat()*float(i))/timeLength);
        
        if (input.mouseX() > x-BEATSNAP_THRESHOLD && input.mouseX() < x+BEATSNAP_THRESHOLD) {
          closestBeatSnap = screenXToTime(x);
        }
        
        app.line(x, TOP_Y, x, BOTTOM_Y);
      }
    }
    
    protected void renderData() {
      app.stroke(mycolor);
      app.strokeWeight(2f);
      app.noFill();
      
      float MAX = 1000f;
      for (float i = 0; i < MAX; i++) {
        plotLine((i)/MAX);
      }
      app.stroke(255, 127);
      app.line(RIGHT_X/2f, TOP_Y, RIGHT_X/2f, BOTTOM_Y);
    }
  }
  
  class LerpAutomationBar extends AutomationBar {
    
    class Point {
      public Point(float t, float val) {
        this.t = t;
        this.val = val;
      }
      
      float t = 0f;
      float val = 0f;
      
      //public Point addPoint(float t, float val) {
      //  Point newPoint = new Point(t, val);
      //  next = newPoint;
      //  return newPoint;
      //}
    }
    
    
    ArrayList<Point> points = new ArrayList<Point>();
    
    public LerpAutomationBar(JSONObject json) {
      super();
      load(json);
    }
    
    public LerpAutomationBar(String name) {
      super(name);
      save();
    }
    
    @Override
    public float getFloatVal(float ttime) {
      return getFloatVal(ttime, false);
    }
    
    public float getVal() {
      return getFloatVal(time, false);
    }
    
    // How to find the index with an arbritrary float value?
    // Do it the lazy way cus I can't be bothered with a big algorithm.
    // Select an approximate point and then backtrace until we find a point between our float val.
    public float getFloatVal(float ttime, boolean countiterations) {
      // Calc approx
      int l = points.size();
      int index = min((int)((ttime/timeLength)*((float)l)), l-1);
     
      
      try {
        int count = 0;
        while (index > 0 && points.get(index).t > ttime) {
          count++;
          index--;
        }
        while (index < l-3 && points.get(index+1).t < ttime) {
          count++;
          index++;
        }
        Point lowerPoint = points.get(index);
        Point higherPoint = points.get(index+1);
        
        float timerange = higherPoint.t-lowerPoint.t;
        float t = ttime-lowerPoint.t;
        float percentage = t/timerange;
        
        if (countiterations) {
          console.log(count);
        }
        
        
        return PApplet.lerp(lowerPoint.val, higherPoint.val, percentage);
      }
      catch (IndexOutOfBoundsException e) {
        //console.warn("EXCEPTION");
        return 0f;
      }
    }
    
    
    
    private boolean lineRect(float x1, float y1, float x2, float y2, float rx, float ry, float rw, float rh) {
  
      // check if the line has hit any of the rectangle's sides
      // uses the Line/Line function below
      boolean left =   lineLine(x1,y1,x2,y2, rx,ry,rx, ry+rh);
      boolean right =  lineLine(x1,y1,x2,y2, rx+rw,ry, rx+rw,ry+rh);
      boolean top =    lineLine(x1,y1,x2,y2, rx,ry, rx+rw,ry);
      boolean bottom = lineLine(x1,y1,x2,y2, rx,ry+rh, rx+rw,ry+rh);
    
      // if ANY of the above are true, the line
      // has hit the rectangle
      if (left || right || top || bottom) {
        return true;
      }
      return false;
    }
    
    
    // LINE/LINE
    private boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
    
      // calculate the direction of the lines
      float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
      float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
      // if uA and uB are between 0-1, lines are colliding
      if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
    
        return true;
      }
      return false;
    }
    
    
    AtomicBoolean saving = new AtomicBoolean(false);
    
    @Override
    public void save() {
      if (saving.get()) {
        // If already saving don't bother.
        // Ideally we should put the thread into a waiting state
        // until saving goes false but cant be bothered.
        return;
      }
      
      JSONArray jsonarr = new JSONArray();
      JSONObject barjson = new JSONObject();
      
      for (int i = 0; i < points.size(); i++) {
        Point p = points.get(i);
        JSONObject jsonpoint = new JSONObject();
        jsonpoint.setFloat("val", p.val);
        jsonpoint.setFloat("t", p.t);
        jsonarr.setJSONObject(i, jsonpoint);
      }
      
      barjson.setString("name", name);
      barjson.setString("type", "LerpAutomationBar");
      barjson.setFloat("height", myHeight);
      barjson.setInt("color", mycolor);
      barjson.setBoolean("snapping", snapping);
      barjson.setBoolean("beats_visible", beatsVisible);
      barjson.setBoolean("in_view", displayAutomationBars.contains(this));
      barjson.setJSONArray("data", jsonarr);
      
      
      Thread t = new Thread(new Runnable() {
        public void run() {
          // Ensure autobars path exists
          file.mkdir(sketchiePath+"autobars/");
          app.saveJSONObject(barjson, sketchiePath+"autobars/"+name+".json");
          saving.set(false);
        }
      }
      );
      saving.set(true);
      t.start();
    }
    
    public void load(JSONObject json) {
      this.name = json.getString("name");
      this.mycolor = json.getInt("color", color(0,0,0));
      this.snapping = json.getBoolean("snapping", false);
      this.beatsVisible = json.getBoolean("beats_visible", false);
      this.myHeight = json.getFloat("height", 100f);
      if (json.getBoolean("in_view", false)) {
        displayAutomationBars.add(this);
      }
      JSONArray jsonarr = json.getJSONArray("data");
      if (jsonarr == null) {
        console.warn("Autobar "+name+" file is missing data array.");
        return;
      }
      
      int l = jsonarr.size();
      for (int i = 0; i < l; i++) {
        JSONObject obj = jsonarr.getJSONObject(i);
        if (obj != null) {
          points.add(new Point(obj.getFloat("t"), obj.getFloat("val")));
        }
      }
    }
    
    // Can't be bothered commenting so long story short...
    // - We move our mouse int to the point
    // - Point glows indicating its clickable
    // - We try moving the point
    // - Point becomes deselected as our mouse is outside of the clicking bounds of the point cus we moved it too fast
    // - We rage
    // solution: good ol' keeping track of shiz.
    private int draggingIndex = -1;
    private int hoverLineIndex = -1;
    private boolean unsnapDragX = false;
    private boolean unsnapDragY = false;
    
    protected void renderData() {
      app.strokeWeight(2f);
      app.textSize(10);
      app.textAlign(CENTER, TOP);
      
      final float RECTWIHI = 12f;
      final float HALFWIHI = RECTWIHI/2f;
      final float UNSNAP_THRESHOLD = 20f;
      final float VAL_SNAP_THRESHOLD = 0.05f;
      
    
      if (!input.primaryDown && draggingIndex != -1) {
        draggingIndex = -1;
        save();
      }
      
      // Must have at least 2 points
      if (points.size() == 0) {
        points.add(new Point(0f, 0.5f));
        points.add(new Point(timeLength, 0.5f));
      }
      
      float lineSelectorX = input.mouseX()-RECTWIHI;
      float lineSelectorY = input.mouseY()-RECTWIHI;
      
      int pointIndexForDeletion = -1;
      int createPointAtIndex = -1;
      
      int l = points.size();
      float prevActualX = 0f, prevActualY = 0f;
      for (int i = 0; i < l; i++) {
        app.fill(255);
        app.strokeWeight(2f);
        
        if (hoverLineIndex == i) {
          app.stroke(255);
          hoverLineIndex = -1;
        }
        else {
          app.stroke(mycolor);
        }
        
        Point point = points.get(i);
        
        float x = plotLine(point.t/timeLength, true);
        
        float actualX = x-HALFWIHI;
        float actualY = TOP_Y+(1f-point.val)*myHeight-HALFWIHI;
        
        //if (actualX > RIGHT_X+200f || actualX < 0f) {
        //  continue;
        //}
        
        if (input.mouseX() > actualX && input.mouseX() < actualX+RECTWIHI && input.mouseY() > actualY && input.mouseY() < actualY+RECTWIHI && !playing) {
          app.fill(255);
          hoverLineIndex = -1;
          
          if (input.primaryOnce) {
            draggingIndex = i;
            unsnapDragX = false;
            unsnapDragY = false;
          }
          if (input.secondaryOnce) {
            pointIndexForDeletion = i;
          }
        }
        else if (lineRect(actualX, actualY, prevActualX, prevActualY, lineSelectorX, lineSelectorY, RECTWIHI, RECTWIHI) && !playing) {
          hoverLineIndex = i;
          app.fill(mycolor);
          
          if (input.secondaryOnce) {
            createPointAtIndex = i;
          }
        }
        else {
          app.fill(mycolor);
        }
        
        if (draggingIndex == i) {
          app.fill(255);
          // Update point to new position.
          
          // Unsnapping mechanism so that we can adjust one axis without affecting the other.
          // Both for x/y
          // No unsnapping for Y
          //if (!unsnapDragY) {
          //  if (input.mouseY() > actualY + UNSNAP_THRESHOLD || input.mouseY() < actualY - UNSNAP_THRESHOLD) {
          //    unsnapDragY = true;
          //    point.val = min(max(1f-(input.mouseY()-TOP_Y)/myHeight, 0f), 1f);
          //  }
          //}
          //else {
            float vv = min(max(1f-(input.mouseY()-TOP_Y)/myHeight, 0f), 1f);
            
            point.val = vv;
            if (snapping) {
              // Point behind
              app.strokeWeight(1f);
              app.stroke(255, 127);
              if (i-1 >= 0) {
                float prevval = points.get(i-1).val;
                if (vv < prevval+VAL_SNAP_THRESHOLD && vv > prevval-VAL_SNAP_THRESHOLD) {
                  point.val = prevval;
                  app.line(0, actualY+HALFWIHI, RIGHT_X, actualY+HALFWIHI);
                }
              }
              
              // Point behind
              if (i+1 < points.size()) {
                float nextval = points.get(i+1).val;
                if (vv < nextval+VAL_SNAP_THRESHOLD && vv > nextval-VAL_SNAP_THRESHOLD) {
                  point.val = nextval;
                  app.line(0, actualY+HALFWIHI, RIGHT_X, actualY+HALFWIHI);
                }
              }
            }
          //}
          
          // X pos
          // No dragging for start and end points of the entire line.
          if (i != 0 && i != points.size()-1) {
            if (!unsnapDragX) {
              if (input.mouseX() > actualX + UNSNAP_THRESHOLD || input.mouseX() < actualX - UNSNAP_THRESHOLD) {
                unsnapDragX = true;
                
                point.t = screenXToTime(input.mouseX());
              }
            }
            else {
                // Limit dragging x pos to next and prev point's position.
                float MICRO_OFFSET = 0.025;
                float minx = 0f;
                float maxx = timeLength;
                
                if (i-1 >= 0) {
                  minx = points.get(i-1).t+MICRO_OFFSET;
                }
                if (i+1 < points.size()) {
                  maxx = points.get(i+1).t-MICRO_OFFSET;
                }
                
                point.t = min(max(screenXToTime(input.mouseX()), minx), maxx);
                if (snapping && beatsVisible && closestBeatSnap > 0f) {
                  point.t = closestBeatSnap;
                }
            }
          }
          
        }
        
        
        app.noStroke();
        app.rect(actualX, actualY, RECTWIHI, RECTWIHI);
        
        prevActualX = actualX;
        prevActualY = actualY;
      }
      
      // Do not allow deletion of index 0
      if (pointIndexForDeletion > 0 && points.size() > 2) {
        points.remove(pointIndexForDeletion);
        pointIndexForDeletion = -1;
        save();
      }
      else if (createPointAtIndex != -1) {
        points.add(createPointAtIndex, new Point(screenXToTime(input.mouseX()), min(max(1f-(input.mouseY()-TOP_Y)/myHeight, 0f), 1f)));
        createPointAtIndex = -1;
        save();
      }
      
      // For performance testing
      //getFloatVal(time, true);
      
      
      app.stroke(255, 127);
      app.line(RIGHT_X/2f, TOP_Y, RIGHT_X/2f, BOTTOM_Y);
      
    }
  }
  
  
  
  
  
  
  private String sketchiePath = "";
  private TWEngine.PluginModule.Plugin plugin;
  private FFmpegEngine ffmpeg;
  private String code = "";
  private AtomicBoolean compiling = new AtomicBoolean(false);
  private AtomicBoolean successful = new AtomicBoolean(false);
  private AtomicBoolean once = new AtomicBoolean(true);
  private SpriteSystemPlaceholder sprites;
  private SpriteSystemPlaceholder gui;
  private PGraphics canvas;
  private float canvasScale = 1.0;
  private float canvasX = 0.0;
  private float canvasY = 0.0;
  private float canvasPaneScroll = 0.;
  private float codePaneScroll = 0.;
  private ArrayList<String> imagesInSketch = new ArrayList<String>();  // This is so that we can know what to remove when we exit this screen.
  private ArrayList<PImage> loadedImages = new ArrayList<PImage>();
  private JSONObject configJSON = null;
  private AtomicBoolean loading = new AtomicBoolean(true);
  private AtomicInteger processAfterLoadingIndex = new AtomicInteger(0);
  private float textAreaZoom = 22.0;
  private boolean configMenu = false;
  private boolean renderMenu = false;
  private boolean errorMenu  = false;
  private boolean automationBarSelectMenu = false;
  private String errorLog = "";
  private float errorHeight = 0f;
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
  //private float musicVolume = 0.5;
  private String[] musicFiles = new String[0];
  private String[] loadedShaders = new String[0];
  private String selectedMusic = "";
  private String selectedShader = "";
  public Object[] shaderParams = null;
  
  
  
  
  private boolean playing = false;
  private boolean loop = false;
  private float time = 0f;
  private float timeLength = 10f*60f;
  private float bpm = 120f;
  
  // Canvas 
  private float beginDragX = 0.;
  private float beginDragY = 0.;
  private float prevCanvasX = 0.;
  private float prevCanvasY = 0.;
  private boolean isDragging = false;
  
  // Selected pane
  private int selectedPane = 0;
  private int lastSelectedPane = 0;   // Mostly just so I can use the space bar.
  
  final static int CANVAS_PANE = 1;
  final static int CODE_PANE = 2;
  final static int TIMELINE_PANE = 3;
  final static int AUTOBAR_PANE = 4;
  
  private final int MAX_DISPLAY_AUTOMATION_BARS = 8;
  private HashMap<String, AutomationBar> automationBars = new HashMap<String, AutomationBar>();
  private ArrayList<AutomationBar> displayAutomationBars = new ArrayList<AutomationBar>();
  
  
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
    
    gui = new SpriteSystemPlaceholder(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/sketchpad/");
    gui.interactable = false;
    
    
    plugin = plugins.createPlugin();
    
    createCanvas(1024, 1024, 1);
    resetView();
    
    canvasY = myUpperBarWeight;
    
    input.keyboardMessage = "";
    code = "";
    // Load default code into keyboardMessage
    for (String s : defaultCode) {
      code += s+"\n";
    }
    
    ffmpeg = new FFmpegEngine();
    
    lastSelectedPane = CODE_PANE;
    
    //sound.streamMusic(engine.APPPATH+"engine/music/test.mp3");
  }
  
  //{
  //  if (file.exists(engine.APPPATH+engine.CACHE_PATH)) {
  //    File[] cacheFolder = (new File(engine.APPPATH+engine.CACHE_PATH)).listFiles();
  //    for (File f : cacheFolder) {
  //      console.log(file.getExt(f.getName()));
  //      if (file.getExt(f.getName()).equals("jar")) {
  //        f.delete();
  //      }
  //    }
  //  }
  //}
  
  
  
  
  
  
  
  
  
  
  
  ////////////////////////////////////////////////////
  // SETUP AND LOADING
  
  private void createCanvas(int wi, int hi, int smooth) {
    //console.log("CANVAS "+wi+" "+hi);
    canvas = createGraphics(wi, hi, P2D);
    if (smooth == 0) {
      // Nearest neighbour (hey remember this ancient line of code?)
      ((PGraphicsOpenGL)canvas).textureSampling(2);    
    }
    else {
      canvas.smooth(smooth);
    }
    
    shaderCanvas = createGraphics(canvas.width, canvas.height, P2D);
    ((PGraphicsOpenGL)shaderCanvas).textureSampling(2);   // Disable texture smoothing
    
    plugin.sketchioGraphics = canvas;
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
  // - config is saved when we click "confirm"
  // - autobars are saved as they're modified
  private void saveScripts() {
    // Not gonna bother putting a TODO but you know that the script isn't going to stick to
    // a keyboard forever.
    String[] strs = new String[1];
    strs[0] = code;
    file.backupMove(sketchiePath+"scripts/main.java");
    app.saveStrings(sketchiePath+"scripts/main.java", strs);
    
    console.log("Saved.");
  }
  
  private void saveConfig() {
    JSONObject json = new JSONObject();
    json.setInt("canvas_width", canvas.width);
    json.setInt("canvas_height", canvas.height);
    json.setInt("smooth", canvasSmooth);
    json.setFloat("time_length", timeLength);
    json.setString("music_file", selectedMusic);
    json.setBoolean("show_code_editor", codeEditorShown);
    json.setFloat("bpm", bpm);
    json.setBoolean("loop", loop);
    json.setString("shader", selectedShader);
    
    
    app.saveJSONObject(json, sketchiePath+"sketch_config.json");
  }
  
  private void loadConfig() {
    if (file.exists(sketchiePath+"sketch_config.json")) {
      configJSON = app.loadJSONObject(sketchiePath+"sketch_config.json");
      // Need to load the canvas from a seperate thread
      // But while we're here, now's a good time to set the music file.
      // and timelength cus why not.
      timeLength = configJSON.getFloat("time_length", 10.0);
      selectedMusic = configJSON.getString("music_file", "");
      codeEditorShown = configJSON.getBoolean("show_code_editor", true);
      bpm = configJSON.getFloat("bpm", 120f);
      sound.setBPM(bpm);
      loop = configJSON.getBoolean("loop", false);
      selectedShader = configJSON.getString("shader", "");
    }
  }
  
  private void loadAutobars() {
    if (file.exists(sketchiePath+"autobars/")) {
      File ff = new File(sketchiePath+"autobars/");
      File[] files = ff.listFiles();
      for (File f : files) {
        try {
          JSONObject json = app.loadJSONObject(f.getAbsolutePath());
          if (json == null) {
            console.warn("Failed to load autobar "+f.getAbsolutePath()+": null");
            continue;
          }
          
          String name = json.getString("name", "null");
          String type = json.getString("type", "null");
          
          if (type.equals("LerpAutomationBar")) {
            automationBars.put(name, new LerpAutomationBar(json));
          }
        }
        catch (RuntimeException e) {
          console.warn("Failed to load autobar "+f.getAbsolutePath()+": "+e.getMessage());
        }
      }
      
    }
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
        
        if (file.getExt(scriptAbsolutePath).equals("java")) {
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
    println(" ---------------------- CODE: ----------------------");
    println(ccode);
    return ccode;
  }
  
  
  private void loadSketchie(String path) {
    // Just in case the thread is still running
    terminateFileUpdateThread();
    
    imagesInSketch.clear();
    loadedImages.clear();
    processAfterLoadingIndex.set(0);
    
    // Undirectorify path
    if (path.charAt(path.length()-1) == '/') {
      path.substring(0, path.length()-1);
    }
    
    if (!file.getExt(path).equals(engine.SKETCHIO_EXTENSION) || !file.isDirectory(path)) {
      console.warn("Not a valid sketchie file: "+path);
      return;
    }
    
    // Re-directorify path
    path = file.directorify(path);
    sketchiePath = path;
    
    //////////////////
    // IMAGES
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
        // So that we can check for file updates
        imgsMap.add(name);
        numberImages++;
      }
      processAfterLoadingIndex.set(numberImages);
    }
    
    
    ///////////////////
    // SHADERS
    String shaderPath = "";
    if (file.exists(path+"shaders")) shaderPath = path+"shaders";
    if (file.exists(path+"shader")) shaderPath = path+"shader";
    
    // Shader path
    if (shaderPath.length() > 0) {
      // List out all the files, get each image.
      File[] sh = (new File(shaderPath)).listFiles();
      loadedShaders = new String[sh.length];
      for (int i = 0; i < sh.length; i++) {
        File f = sh[i];
        
        String fullPath = f.getAbsolutePath().replaceAll("\\\\", "/");
        String ext = file.getExt(fullPath);
        String name = file.getIsolatedFilename(fullPath);
        
        if (ext.equals("glsl") || ext.equals("vert")) {
          display.loadShader(fullPath);
          loadedShaders[i] = name;
        }
        else {
          loadedShaders[i] = name+" (invalid)";
        }
        // GLSL shaders are loaded with vert shaders.
      }
    }
    
    
    ///////////////////
    // SPRITES
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
    
    
    //////////////////
    // SCRIPT
    // And now: script
    code = loadScript();
    
    //////////////////
    // MUSIC
    // Load em into a list
    if (file.exists(path+"music")) {
      File[] files = (new File(path+"music")).listFiles();
      musicFiles = new String[files.length];
      for (int i = 0; i < files.length; i++) {
        musicFiles[i] = files[i].getName();
      }
    }
    
    //////////////////
    // CONFIG
    // Load sketch config
    loadConfig();
    
    //////////////////
    // AUTOBARS
    // Load the autobars
    loadAutobars();
    
    // Should be safe to check the update checker thread
    startFileUpdateThread();
  }
  
  private void compileCode(String code) {
    compiling.set(true);
    Thread t1 = new Thread(new Runnable() {
      public void run() {
        successful.set(plugin.compile(code));
        compiling.set(false);
        once.set(true);
      }
    });
    t1.start();
  }
  
  private void setMusic(String musicFileName) {
    sound.stopMusic();
    // Passing "" will stop any music.
    if (musicFileName.length() == 0) return;
    
    String path = sketchiePath+"music/"+musicFileName;
    if (file.exists(path)) {
      sound.streamMusic(path);
    }
    else {
      console.warn(musicFileName+" music file not found.");
      selectedMusic = "";
    }
  }
  
  
  
  
  
  
  
  
  
  //////////////////////////////////////////////
  // UTIL METHODS STUFF
  
  // methods for use by the API
  public float getTime() {
    return time/60.;
  }
  
  public float getDelta() {
    // When we're rendering, all the file IO and expensive rendering operations will
    // inevitably make the actual framerate WAY lower than what we're aiming for and therefore
    if (rendering) return display.BASE_FRAMERATE/renderFramerate;
    else return display.getDelta();
  }
  
  public String getPath() {
    // Undirectorify path
    if (sketchiePath.charAt(sketchiePath.length()-1) == '/') {
      return sketchiePath.substring(0, sketchiePath.length()-1);
    }
    return sketchiePath;
  }
  
  public String getPathDirectorified() {
    return sketchiePath;
  }
  
  public float getAutoFloat(String autobarname) {
    if (automationBars.containsKey(autobarname)) {
      return automationBars.get(autobarname).getFloatVal(time);
    }
    // TODO: proper warning mechanism
    return -1f;
  }
  
  public boolean codeOK() {
    return (successful.get() && !compiling.get() && !loading.get());
  }
  
  private void addAutomationBarToDisplay(AutomationBar bar) {
    if (!displayAutomationBars.contains(bar)) {
      displayAutomationBars.add(bar);
      bar.save();
      if (displayAutomationBars.size() > MAX_DISPLAY_AUTOMATION_BARS) {
        AutomationBar b = displayAutomationBars.remove(0);
        b.save();
      }
    }
  }
  
  ////////////////////////////
  
  private boolean menuShown() {
    return configMenu || renderMenu || rendering || automationBarSelectMenu;
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
  
  // Creating this funciton because I think the width of
  // canvas v the code editor will likely change later
  // and i wanna maintain good code.
  
  private boolean codeEditorShown = true;
  private float middle() {
    if (codeEditorShown || rendering)
      return WIDTH/2;
    else
      return WIDTH;
  }
  
  private boolean codeEditorShown() {
    return codeEditorShown || rendering;
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
  
  private void togglePlay() {
    if (playing) {
      pause();
    }
    else {
      play();
    }
  }
  
  private void pause() {
    if (playing) {
      playing = false;
      sound.pauseMusic();
    }
  }
  
  private void play() {
    if (!playing) {
      playing = true;
      sound.continueMusic();
    }
  }
  
  private void disableSpritesClick() {
    if (sprites != null) {
      sprites.mouseInputEnabled = false;
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  ////////////////////////////////////////////
  // CANVAS & CODE EDITOR
  
  private boolean inCanvasPane = false;
  
  private void displayCanvas(boolean allowMouseActivity) {
    if (input.altDown && input.shiftDown && input.keys[int('s')] == 2) {
      input.backspace();
      resetView();
    }
    
    boolean menuShown = menuShown();
    if ((lastSelectedPane == CANVAS_PANE || !codeEditorShown()) && input.keyActionOnce("playPause") && !menuShown) {
       togglePlay();
       input.backspace();   // Don't want the unintended space.
    }
    
    // Difficulty: we have 2 scroll areas: canvas zoom, and code editor.
    // if mouse is in canvas pane
    boolean canvasPane = input.mouseX() < middle() && !menuShown();
    if (canvasPane && allowMouseActivity) {
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
    
    
    if (canvasPane && sprites.selectedSprite == null && input.mouseY() < HEIGHT-myLowerBarWeight && input.mouseY() > myUpperBarWeight && allowMouseActivity) {
      if (input.primaryOnce && !isDragging && selectedPane == 0) {
        beginDragX = input.mouseX();
        beginDragY = input.mouseY();
        prevCanvasX = canvasX;
        prevCanvasY = canvasY;
        isDragging = true;
        selectedPane = CANVAS_PANE;
        lastSelectedPane = CANVAS_PANE;
      }
    }
    if (isDragging && selectedPane == CANVAS_PANE) {
      canvasX = prevCanvasX+(input.mouseX()-beginDragX);
      canvasY = prevCanvasY+(input.mouseY()-beginDragY);
      
      if (!input.primaryDown || sprites.selectedSprite != null) {
        isDragging = false;
      }
    }
    
    // Sprite selected, then we right-click it
    // Brings up the menu
    if (sprites.selectedSprite != null && sprites.selectedSprite.mouseWithinSprite() && input.secondaryOnce && !ui.miniMenuShown() && allowMouseActivity) {
      showSpriteMenu();
    }
    
    sprites.setMouseScale(canvasScale, canvasScale);
    float xx = canvasX-canvas.width*canvasScale*0.5;
    float yy = canvasY-canvas.height*canvasScale*0.5;
    sprites.setMouseOffset(xx, yy);
    
    // Shader canvas cus that's where our final frame is drawn even if we don't have any post-processing shaders active.
    
    if (codeOK()) {
      app.image(shaderCanvas, xx, yy, canvas.width*canvasScale, canvas.height*canvasScale);
    }
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
      
      if (input.primaryOnce) {
        lastSelectedPane = CODE_PANE;
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
      
      // BIG TODO: This is not the safest solution. Please fix.
      if (!menuShown() && !loading.get() && input.keyboardMessage.length() > 0) code = input.keyboardMessage;
      
      // This should really be in the displayCanvas code but it's more convenient to have it here for now.
      // Damn I'm really giving myself coding debt for adding shortcuts.
      //boolean shortcuts = input.keyActionOnce("playPause");
      //if (lastSelectedPane == CANVAS_PANE && shortcuts) {
      //  input.backspace();   // Don't want the unintended space.
      //}
      
      
      // ctrl+s save keystroke
      // Really got to fix this input.keys flaw thing.
      if (!input.altDown && input.ctrlDown && input.keys[int('s')] == 2) {
        saveScripts();
      }
      
      
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
  
  
  public void showError() {
    if (errorHeight < 40f) return;
    
    app.fill(255, 200, 200);
    app.noStroke();
    app.rect(0, myUpperBarWeight, middle(), errorHeight);
    app.fill(0);
    app.textFont(display.getFont("Source Code"), 20);
    app.text(errorLog, 5, myUpperBarWeight+5, middle()-10, errorHeight-10);
    
    
    ui.useSpriteSystem(gui);
    boolean close = false;
    
    if (codeEditorShown()) {
      close = ui.button("close-error-1", "cross", "");
    }
    else {
      close = ui.button("close-error-2", "cross", "");
    }
    
    if (close) {
      errorMenu = false;
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  /////////////////////////////////////// 
  // MENU
  
  TextField widthField  = new TextField("config-width", "Width: ");
  TextField heightField = new TextField("config-height", "Height: ");
  TextField timeLengthField = new TextField("config-timelength", "Video length: ");
  TextField framerateField = new TextField("render-framerate", "Framerate: ");
  TextField bpmField = new TextField("config-bpm", "BPM: ");
  private boolean smoothChangesMade = false;
  public void displayMenu() {
    if (menuShown()) {
      // Bug fix to prevent sprite being selected as we click the menu.
      if (!loading.get()) sprites.selectedSprite = null;
    }
    
    //////////////////
    // CONFIG MENU
    //////////////////
    if (configMenu) {
      
      // Background
      gui.spriteVary("config-back-1", "black");
      
      // Title
      textSprite("config-menu-title", "--- Sketch config ---");
      
      
      
      app.fill(255);
      
      // Width field
      widthField.display();
      
      // Height field
      heightField.display();
      
      // Time length field
      timeLengthField.display();
      // Lil button next to timelength field to sync time to music
      if (ui.buttonVary("config-syncmusictime", "music_time_128", "")) {
        selectedField = null;
        sound.playSound("select_any");
        timeLengthField.value = str(sound.getCurrentMusicDuration());
        //try {
        //  String musicPath = sketchiePath+"music/"+selectedMusic;
        //  if (selectedMusic.length() > 0 && file.exists(musicPath)) {
        //    Movie music = new Movie(app, musicPath);
        //    music.read();
        //    timeLengthField.value = str(music.duration());
        //  }
        //}
        //catch (RuntimeException e) {
        //  console.warn("Sound duration get failed. "+e.getMessage());
        //}
      }
      
      // Anti-aliasing field
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
        actions[0] = new Runnable() {public void run() { canvasSmooth = 0; smoothChangesMade = true; }};
        
        labels[1] = "1x anti-aliasing";
        actions[1] = new Runnable() {public void run() { canvasSmooth = 1; smoothChangesMade = true; }};
        
        labels[2] = "2x anti-aliasing";
        actions[2] = new Runnable() {public void run() { canvasSmooth = 2; smoothChangesMade = true; }};
        
        labels[3] = "4x anti-aliasing";
        actions[3] = new Runnable() {public void run() { canvasSmooth = 4; smoothChangesMade = true; }};
        
        labels[4] = "8x anti-aliasing";
        actions[4] = new Runnable() {public void run() { canvasSmooth = 8; smoothChangesMade = true; }};
        
        
        ui.createOptionsMenu(labels, actions);
      }
      
      
      // Music selection field
      String musicDisp = (musicFiles.length > 0 ? selectedMusic : "(no files available)");
      if (selectedMusic.length() == 0) musicDisp = "(None)";
      if (textSprite("config-music", "Music: "+musicDisp) && !ui.miniMenuShown()) {
        if (musicFiles.length > 0) {
          String[] labels = new String[musicFiles.length+1];
          Runnable[] actions = new Runnable[musicFiles.length+1];
          
          // None option
          labels[0] = "(None)";
          actions[0] = new Runnable() {public void run() { selectedMusic = ""; }};
          
          for (int i = 0; i < musicFiles.length; i++) {
            final int index = i;
            labels[i+1]  = musicFiles[i];
            actions[i+1] = new Runnable() {
              public void run() { 
                selectedMusic = musicFiles[index]; 
                setMusic(selectedMusic);
              }
            };
          }
          
          ui.createOptionsMenu(labels, actions);
        }
      }
      
      // BPM field
      bpmField.display();
      
      // Shader selection
      String shaderDisp = (loadedShaders.length > 0 ? selectedShader : "(no shaders)");
      if (shaderDisp.length() == 0) shaderDisp = "(None)";
      if (textSprite("config-shader", "Post-processing shader: "+shaderDisp) && !ui.miniMenuShown()) {
        if (loadedShaders.length > 0) {
          String[] labels = new String[loadedShaders.length+1];
          Runnable[] actions = new Runnable[loadedShaders.length+1];
          
          // None option
          labels[0] = "(None)";
          actions[0] = new Runnable() {public void run() { selectedShader = ""; }};
          
          for (int i = 0; i < loadedShaders.length; i++) {
            final int index = i;
            labels[i+1]  = loadedShaders[i];
            actions[i+1] = new Runnable() {
              public void run() { 
                selectedShader = loadedShaders[index]; 
              }
            };
          }
          
          ui.createOptionsMenu(labels, actions);
        }
      }
      
      
      
      // Cross button
      if (ui.buttonVary("config-cross-1", "cross", "")) {
        sound.playSound("select_smaller");
        input.keyboardMessage = code;
        configMenu = false;
      }
      
      // Apply button
      if (ui.buttonVary("config-ok", "tick_128", "Apply")) {
        sound.playSound("select_any");
        //time = 0.;
        
        try {
          int wi = Integer.parseInt(widthField.value);
          int hi = Integer.parseInt(heightField.value);
          timeLength = Float.parseFloat(timeLengthField.value)*60.;
          bpm = Float.parseFloat(bpmField.value);
          sound.setBPM(bpm);
          
          // Only recreate if changes have been made.
          if (wi != (int)canvas.width ||
              hi != (int)canvas.height ||
              smoothChangesMade
          ) {
            createCanvas(wi, hi, canvasSmooth);
          }
        }
        catch (NumberFormatException e) {
          console.log("Invalid inputs!");
          return;
        }
        //setMusic(selectedMusic);
        
        
        saveConfig();
        
        // End
        input.keyboardMessage = code;
        configMenu = false;
      }
    }
    
    
    /////////////////////
    // RENDER MENU
    /////////////////////
    else if (renderMenu) {
      
      // Background
      gui.spriteVary("render-back-1", "black");
      
      // Title
      textSprite("render-menu-title", "--- Render ---");
      
      // Framerate field
      framerateField.display();
      
      // That massive block below is indeed the
      // compression field.
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
      
      // Pixel upscale field
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
      
      
      // Start rendering button
      if (ui.buttonVary("render-ok", "tick_128", "Start rendering")) {
        sound.playSound("select_any");
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
      
      // Close menu button
      if (ui.buttonVary("render-cross-1", "cross", "")) {
        sound.playSound("select_smaller");
        input.keyboardMessage = code;
        renderMenu = false;
      }
      
      // Render info
      {
        // Size estimations for rendering (per frame):
        //400% 16mb
        //300% 9mb
        //200% 4mb
        //100% 1mb
        //50% 0.25mb
        //25% 0.0625mb
        //
        // Formula = width * height * 4 * scale * timeLength * framespersecond 
        //
        try {
          float framerate = Float.parseFloat(framerateField.value);
          long requiredSize = (long)(canvas.width*upscalePixels)*(long)(canvas.height*upscalePixels)*4L*(long)( (timeLength/display.BASE_FRAMERATE) *framerate);
          int sizemb = int(requiredSize/(1024L*1024L));
          float sizegb = float(sizemb)/1024f;
          String renderInfo = "This render requires "+nf(sizegb, 0, 1)+"GB of free disk space.";
          textSprite("render-menu-info1", renderInfo, 20f);
        }
        catch (NumberFormatException e) {
          
        }
      }
    }
    else if (automationBarSelectMenu) {
      
      // Background
      gui.spriteVary("automation-back-1", "black");
      
      // Title
      textSprite("automation-menu-title", "Select automation type:");
      
      // Close menu button
      if (ui.buttonVary("automation-cross-1", "cross", "")) {
        sound.playSound("select_smaller");
        automationBarSelectMenu = false;
      }
      
      // Close menu button
      if (ui.buttonVary("automation-lerp", "cube_128", "Linear")) {
        sound.playSound("select_any");
        automationBarSelectMenu = false;
        
        Runnable r = new Runnable() {
          public void run() {
            if (input.keyboardMessage.length() < 1) {
              console.log("Please enter a valid name!");
              return;
            }
            
            LerpAutomationBar bar = new LerpAutomationBar(input.keyboardMessage);
            automationBars.put(input.keyboardMessage, bar);
            addAutomationBarToDisplay(bar);
          }
        };
        
        engine.beginInputPrompt("Enter name:", r);
      }
      
    }
  }
  
  /////////////////////////////////////////////////
  // TEXT FIELD CLASS
  /////////////////////////////////////////////////
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
        gui.spriteVary(spriteName, disp);
        value = input.keyboardMessage;
      }
      else {
        if (ui.buttonVary(spriteName, disp, "")) {
          selectedField = this;
          input.keyboardMessage = value;
          input.cursorX = input.keyboardMessage.length();
        }
      }
      
      float x = gui.getSpriteVary(spriteName).getX();
      float y = gui.getSpriteVary(spriteName).getY();
      
      
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
  
  public boolean textSprite(String name, String val, float textSize) {
    String disp = gui.interactable ? "white" : "nothing";
    boolean clicked = ui.buttonVary(name, disp, "");
    
    float x = gui.getSpriteVary(name).getX();
    float y = gui.getSpriteVary(name).getY();
    float wi = gui.getSpriteVary(name).getWidth();
    float hi = gui.getSpriteVary(name).getHeight();
    
    app.textAlign(LEFT, TOP);
    app.textSize(textSize);
    app.text(val, x, y, wi, hi);
    return clicked;
  }
  
  public boolean textSprite(String name, String val) {
    return textSprite(name, val, 32);
  }
  
  private Runnable resetSpriteSize(int scale) {
    Runnable r = new Runnable() {
      public void run() {
        if (sprites.selectedSprite != null) {
          // Try catch here cus otherwise we'd have to do multiple null checks here and I'd rather my code
          // not be an untidy mess.
          try {
            PImage img = display.systemImages.get(sprites.selectedSprite.imgName).pimage;
            int wi = img.width;
            int hi = img.height;
            sprites.selectedSprite.setWidth(wi*scale);
            sprites.selectedSprite.setHeight(hi*scale);
          }
          catch (NullPointerException e) {
            console.warn(e.getMessage());
          }
        }
      }
    };
    
    return r;
  }
  
  private void showSpriteMenu() {
    String[] labels = new String[6];
    Runnable[] actions = new Runnable[6];
    
    labels[0] = "Set mode SINGLE";
    actions[0] = new Runnable() {
      public void run() {
        if (sprites.selectedSprite != null) {
          SpriteSystemPlaceholder.Sprite s = sprites.selectedSprite;
          sprites.selectedSprite.mode = sprites.SINGLE;
          if (s.getX() > canvas.width || s.getX() < -s.getWidth() || s.getY() > canvas.height || s.getY() < -s.getHeight()) {
            s.setX(0);
            s.setY(0);
          }
        }
      }
    };
    
    labels[1] = "Set mode DOUBLE";
    actions[1] = new Runnable() {
      public void run() {
        if (sprites.selectedSprite != null) {
          SpriteSystemPlaceholder.Sprite s = sprites.selectedSprite;
          sprites.selectedSprite.mode = sprites.DOUBLE;
          if (s.getX() > canvas.width || s.getX() < -s.getWidth() || s.getY() > canvas.height || s.getY() < -s.getHeight()) {
            s.setX(0);
            s.setY(0);
          }
        }
      }
    };
    
    labels[2] = "Set mode VERTEX";
    actions[2] = new Runnable() {
      public void run() {
        if (sprites.selectedSprite != null) {
          SpriteSystemPlaceholder.Sprite s = sprites.selectedSprite;
          if (s.getX() > canvas.width || s.getX() < -s.getWidth() || s.getY() > canvas.height || s.getY() < -s.getHeight()) {
            s.setX(0);
            s.setY(0);
          }
          sprites.selectedSprite.mode = sprites.VERTEX;
          s.vertex.v[0].x = s.getX();
          s.vertex.v[0].y = s.getY();
          s.vertex.v[1].x = s.getX()+s.getWidth();
          s.vertex.v[1].y = s.getY();
          s.vertex.v[2].x = s.getX()+s.getWidth();
          s.vertex.v[2].y = s.getY()+s.getHeight();
          s.vertex.v[3].x = s.getX();
          s.vertex.v[3].y = s.getY()+s.getHeight();
        }
      }
    };
    
    //labels[3] = "Set mode ROTATE";
    //actions[3] = setSpriteMode(sprites.ROTATE);
    
    labels[3] = "Reset size (x1)";
    actions[3] = resetSpriteSize(1);
    
    // Same as before, but we just slap *2 on to it
    labels[4] = "Reset size (x2)";
    actions[4] = resetSpriteSize(2);
    
    // Same as before, but we just slap *3 on to it
    labels[5] = "Reset size (x3)";
    actions[5] = resetSpriteSize(3);
    
    
    ui.createOptionsMenu(labels, actions);
  }
  
  
  
  
  
  ///////////////////////////////////////////////
  // RENDERING
  
  private void beginRendering() {
    // Don't even bother if our code is not working
    if (!successful.get()) {
      console.log("Fix compilation errors before rendering!");
      return;
    }
    
    // Check frames folder
    // Using File class cus we need to make dir if it dont exist
    String framesPath = engine.APPPATH+"frames/";
    File f = new File(framesPath);
    if (!f.exists()) {
      f.mkdir();
    }
    
    // Create our canvases (absolutely no scaling allowed)
    if (upscalePixels != 1.) {
      scaleCanvas = createGraphics(int(canvas.width*upscalePixels), int(canvas.height*upscalePixels), P2D);
      ((PGraphicsOpenGL)scaleCanvas).textureSampling(2);   // Disable texture smoothing
    }
    
    // set our variables
    time = 0.0;
    renderFrameCount = 0;
    power.allowMinimizedMode = false;
    play();
    // Pause music so that it's not playing during rendering.
    sound.pauseMusic();
    
    // Give a little bit of time so the UI can disappear for better user feedback.
    timeBeforeStartingRender = 5;
    
    // Now we begin.
    rendering = true;
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  ///////////////////////////////////////////////////////
  // THE MOST IMPORTANT STUFF
  
  private void runCanvas() {
    // Display compilation status
    if (!compiling.get() && once.compareAndSet(true, false)) {
      if (!successful.get()) {
        errorLog = plugin.errorOutput;
        app.textSize(20);
        errorHeight = getTextHeight(errorLog);
        errorMenu = true;
        pause();
      }
      else {
        errorMenu = false;
        console.log("Successful compilation!");
        play();
        //time = 0.;
      }
    }
    
    // Need to use the right sprite system
    ui.useSpriteSystem(sprites);
    sprites.interactable = !menuShown();
    
    // Use our custom delta funciton (which force sets it to the correct value while rendering)
    sprites.setDelta(getDelta());
    
    // Switch canvas, then begin running the plugin code
    if (codeOK()) {
      canvas.beginDraw();
      canvas.fill(255, 255);
      display.setPGraphics(canvas);
      plugin.run();
      canvas.endDraw();
    }
    
    sprites.updateSpriteSystem();
    if (sprites != null) {
      sprites.mouseInputEnabled = true;
    }
    
    display.setPGraphics(app.g);
    
    if (codeOK()) {
      shaderCanvas.beginDraw();
      // Apply post-processing shader
      if (selectedShader.length() > 0 && shaderParams != null) {
        display.shaderUniformList(shaderCanvas, selectedShader, shaderParams);
      }
      shaderCanvas.clear();
      shaderCanvas.image(canvas, 0, 0, shaderCanvas.width, shaderCanvas.height);
      shaderCanvas.endDraw();
    }
    // Still need to draw to the shader canvas even if no shader's selected.
    
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
    if (rendering && !converting && successful.get() && !compiling.get()) {
      // This path has already been created so it will DEFO work
      String frame = engine.APPPATH+"frames/"+nf(renderFrameCount++, 6, 0)+".tiff";
      
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
          pause();
          beginConversion();
          
          // TODO: open output file
        }
        else {
          // Restart if looping, stop playing if not
          if (!loop) pause();
          else time = 0.;
        }
      }
    }
  }
  
  boolean mouseInAutomationBarPane = false;
  
  public void content() {
    power.setAwake();
    
    // Set engine typing settings.
    input.addNewlineWhenEnterPressed = codeEditorShown;
    engine.allowShowCommandPrompt = !codeEditorShown;
    
    
    if (!loading.get()) {
      if (processAfterLoadingIndex.get() > 0) {
        int i = processAfterLoadingIndex.decrementAndGet();
        
        // Create large image, I don't want the lag
        // TODO: option to select large image or normal pimage.
        LargeImage largeimg = display.createLargeImage(loadedImages.get(i));
        
        
        // Add to systemimages so we can use it in our sprites
        display.systemImages.put(imagesInSketch.get(i), new DImage(largeimg, loadedImages.get(i)));
        
        
        if (i == 0) {
          if (configJSON != null) {
            canvasSmooth = configJSON.getInt("smooth", 1);
            createCanvas(configJSON.getInt("canvas_width", 1024), configJSON.getInt("canvas_height", 1024), canvasSmooth);
            setMusic(selectedMusic);
          }
          
          
          input.keyboardMessage = code;
          input.cursorX = code.length();
          compileCode(code);
          
        }
      }
      
      // Update music time so functions like beat() work properly
      sound.setCustomMusicTime(time/60f);
      
      
      // Run the actual sketchio file's code.
      runCanvas();
      displayCanvas(!mouseInAutomationBarPane);
      
      // Woops, gotta get the boolean value a frame late, who cares.
      
      // Display timesets and stuff
      
      mouseInAutomationBarPane = false;
      if (!menuShown()) {
        float y = 0f;
        for (int i = 0; i < displayAutomationBars.size(); i++) {
          // Why not just y += displayAutomationBars.get(i).getHeight();?
          // Because displayAutomationBars.get(i).display may remove bar from displayAutomationBars,
          // causing an indexoutofbounds afterwards.
          float hh = displayAutomationBars.get(i).getHeight();
          mouseInAutomationBarPane |= displayAutomationBars.get(i).display(y);
          y += hh;
        }
      }
      
      if (mouseInAutomationBarPane) {
        disableSpritesClick();
        if (input.primaryOnce) {
          selectedPane = AUTOBAR_PANE;
        }
      }
      
      if (codeEditorShown()) {
        displayCodeEditor();
      }
      
      if (!input.primaryDown) {
        selectedPane = 0;
      }
      
      // Show error output.
      if (errorMenu) {
        showError();
      }
      
      checkForFileUpdates();
      
      // we "stop" the music by simply muting the audio, in the background it's still playing tho,
      // but it makes coding a lot more simple.
      if (playing && !rendering) {
        //sound.setMusicVolume(musicVolume);
        sound.syncMusic(time/60f);
      }
      else {
        //sound.setMusicVolume(0.);
      }
      
    }
    else {
      ui.loadingIcon(WIDTH/4, HEIGHT/2);
      app.textFont(engine.DEFAULT_FONT, 32);
      app.fill(255);
      app.textAlign(CENTER, TOP);
      app.text("Loading...", WIDTH/4, HEIGHT/2+128);
    }
    
    ((IOEngine)engine).displaySketchioInput();
  }
  
  private void cancelRendering() {
    sound.playSound("select_smaller");
    pause();
    rendering = false;
    converting = false;
    power.allowMinimizedMode = true;
    console.log("Rendering cancelled.");
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
        if (ui.buttonVary("renderinginfoscreen-cancel", "cross_128", "Stop rendering")) {
          cancelRendering();
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
        
        if (ui.buttonVary("renderinginfoscreen-cancel", "cross_128", "Stop rendering")) {
          cancelRendering();
          cancelConversion();
        }
      }
    }
    
    if (!menuShown()) {
      if (ui.button("compile_button", "media_128", "Compile")) {
        // Don't allow to compile if it's already compiling
        // (cus we gonna end up with threading issues!)
        if (!compiling.get()) {
          sound.playSound("select_any");
          // If not showing code editor, we are most likely using an external ide to program this.
          // So do not save what we have in memory.
          if (codeEditorShown) {
            saveScripts();
          }
          compileCode(loadScript());
        } 
      }
      
      if (ui.button("openscript_button", "doc_128", "Extern open")) {
        sound.playSound("select_any");
        file.open(sketchiePath+"scripts/main.java");
        if (codeEditorShown) {
          codeEditorShown = false;
          saveConfig();
        }
      }
      
      if (ui.button("showcode_button", "code_128", codeEditorShown ? "Hide code" : "Show code")) {
        sound.playSound("select_any");
        codeEditorShown = !codeEditorShown;
        saveConfig();
      }
      
      if (ui.button("automation_button", "cube_128", "Automation")) {
        int l = automationBars.size();
        String[] labels = new String[l+1];
        Runnable[] actions = new Runnable[l+1];
        
        int i = 0;
        for (AutomationBar bar : automationBars.values()) {
          labels[i] = bar.name;
          actions[i] = new Runnable() {public void run() {
            addAutomationBarToDisplay(bar);
          }};
          i++;
        }
        
        labels[l] = "[Create automation bar]";
        actions[l] = new Runnable() {public void run() {
            automationBarSelectMenu = true;
        }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      if (ui.button("settings_button", "doc_128", "Sketch config")) {
        sound.playSound("select_any");
        widthField.value = str(canvas.width);
        heightField.value = str(canvas.height);
        timeLengthField.value = str(timeLength/60.);
        bpmField.value = str(bpm);
        selectedField = null;
        configMenu = true;
        input.keyboardMessage = "";
      }
      
      if (ui.button("render_button", "image_128", "Render")) {
        sound.playSound("select_any");
        selectedField = null;
        framerateField.value = "60";
        renderMenu = true;
        input.keyboardMessage = "";
      }
      
      if (ui.button("folder_button", "folder_128", "Show files")) {
        sound.playSound("select_any");
        pause();
        file.open(sketchiePath);
      }
      
      if (ui.button("back_button", "back_arrow_128", "Explorer")) {
        quit();
      }
      
      if (compiling.get()) {
        ui.loadingIcon(WIDTH-64-10, myUpperBarWeight+64+10, 128);
      }
    }
    else {
      displayMenu();
    }
    
    gui.updateSpriteSystem();
    
  }
  
  private boolean selectedPaneTimeline() {
    return !rendering && (selectedPane == 0 || selectedPane == TIMELINE_PANE);
  }
  
  public void quit() {
    terminateFileUpdateThread();
    sound.playSound("select_any");
    sound.stopMusic();
    
    // TODO: really need some sort of file change detection instead of relying on the
    // editor being hidden to know whether or not we have an outdated version in memory.
    if (codeEditorShown) {
      saveScripts();
      sound.playSound("chime");
    }
    previousScreen();
  }
  
  public void lowerBar() {
    //display.shader("fabric", "color", 0.43,0.4,0.42,1., "intensity", 0.1);
    myLowerBarColor = color(78, 73, 73);
    super.lowerBar();
    app.resetShader();
    
    float BAR_X_START = 70.;
    float BAR_X_LENGTH = WIDTH-120.-BAR_X_START;
    
    // Display timeline
    // bar
    float y = HEIGHT-myLowerBarWeight;
    app.fill(50);
    app.noStroke();
    app.rect(BAR_X_START, y+(myLowerBarWeight/2)-2, BAR_X_LENGTH, 4);
    
    // Times
    app.textAlign(LEFT, CENTER);
    app.fill(255);
    app.textFont(engine.DEFAULT_FONT, 20);
    app.text("T "+PApplet.nf(time/60f, 2, 2) + "\nB " + PApplet.nf(sound.beat+1, 3) + ":" + (sound.step+1),
    BAR_X_START+BAR_X_LENGTH+10,
    y+(myLowerBarWeight/2));
    
    float percent = time/timeLength;
    float timeNotchPos = BAR_X_START+BAR_X_LENGTH*percent;
    
    // Notch
    app.fill(255);
    app.rect(timeNotchPos-4, y+(myLowerBarWeight/2)-25, 8, 50); 
    
    display.imgCentre(playing ? "pause_128" : "play_128", BAR_X_START/2, y+(myLowerBarWeight/2), myLowerBarWeight, myLowerBarWeight);
    
    if ((input.mouseY() > y || selectedPane == TIMELINE_PANE) && !ui.miniMenuShown()) {
      if (input.mouseX() > BAR_X_START) {
        // If in bar zone
        disableSpritesClick();
        if (input.primaryDown && selectedPaneTimeline()) {
          float notchPercent = min(max((input.mouseX()-BAR_X_START)/BAR_X_LENGTH, 0.), 1.);
          time = timeLength*notchPercent;
        }
        
        // Messy code over there so it only acts once
        if (input.primaryOnce) {
          selectedPane = TIMELINE_PANE;
        }
      }
      else {
        // If in play button area
        if (input.primaryOnce && selectedPaneTimeline()) {
          // Toggle play/pause button
          togglePlay();
          // Restart if at end
          if (playing && time > timeLength) time = 0.;
        }
        // Right click action to show minimenu
        else if (input.secondaryOnce && selectedPaneTimeline()) {
          String[] labels = new String[1];
          Runnable[] actions = new Runnable[1];
          
          labels[0] = loop ? "Disable loop" : "Enable loop";
          actions[0] = new Runnable() {public void run() {
              loop = !loop;
              saveConfig();
          }};
          
          ui.createOptionsMenu(labels, actions);
        }
      }
    }
    
    
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  /////////////////////////////////////////////////
  // FFMPEG STUFF
  // (mostly stolen from MovieMaker source code lol
  private SwingWorker<Throwable, Object> ffmpegWorker = null;
  
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
    ffmpegWorker = new SwingWorker<Throwable, Object>() {
  
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
        } catch (InterruptedException ignored1) {
          t = null;
          return;
        } catch (java.util.concurrent.CancellationException ignored2) {
          t = null;
          return;
        }
        catch (Exception ex) {
          t = ex;
          console.log(t.getClass().getName());
        }
        
        if (t != null) {
          // Create error log
          String log = "FFMPEG FAILED TO RENDER\nMessage: "+t.getMessage()+"\n\n";
          
          // Write stack trace
          StringWriter sw = new StringWriter();
          PrintWriter pw = new PrintWriter(sw);
          t.printStackTrace(pw);
          String sStackTrace = sw.toString();
          log += "Stack trace: "+sStackTrace+"\n\n";
          
          log += "FFMPEG log: "+ffmpeg.log;
          
          String[] write = new String[1];
          write[0] = log;
          
          app.saveStrings(engine.APPPATH+"ffmpeg_errlog.txt", write);
          
          file.open(engine.APPPATH+"ffmpeg_errlog.txt");
          
          console.warn("createMovie: Failed to create movie, check ffmpeg_errlog.txt for debug info.");
        }
        else {
          console.log("Done render!");
          
          // Show the file in file explorer
          file.open(engine.APPPATH+"output/");
          sound.playSound("render_finish_ding");
        }
        
        rendering = false;
        converting = false;
        power.allowMinimizedMode = true;
      }
    };
    
    ffmpegWorker.execute();
  }
  
  private void cancelConversion() {
    if (ffmpegWorker != null) {
      ffmpegWorker.cancel(true);
    }
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
    
    // Include music
    String musicPath = sketchiePath+"music/"+selectedMusic;
    if (!file.exists(musicPath) || selectedMusic.equals("")) {
      musicPath = "";
    }
    
    createMovie(outputFolder+nf(outIndex, 4, 0)+ext, musicPath, engine.APPPATH+"frames/", wi, hi, (double)renderFramerate, renderFormat);
  }
  
  
  //////////////////////////////////////
  // UPDATE CHECKING THREAD
  
  // file updates thread
  private Thread fileUpdatesThread = null;
  private AtomicBoolean terminateUpdatesThread = new AtomicBoolean(false);
  
  // updateItems must NOT be touched unless fileUpdateAvailable is true.
  private ArrayList<String> updateItems = new ArrayList<String>();
  private HashSet<String> imgsMap = new HashSet<String>();
  private AtomicBoolean fileUpdateAvailable = new AtomicBoolean(false);
  
  private void startFileUpdateThread() {
    String imgPath = "";
    if (file.exists(sketchiePath+"imgs")) imgPath = sketchiePath+"imgs";
    if (file.exists(sketchiePath+"img")) imgPath = sketchiePath+"img";
    
    final String imgPathFinal = imgPath;
    
    // Prepare our thread code
    fileUpdatesThread = new Thread(new Runnable() {
        public void run() {
          while (true) {
            boolean update = false;
            // fileUpdateAvailable being true at this stage is a sign that the main thread
            // hasn't finished loading the new assets, so skip this file check if it's true.
            if (fileUpdateAvailable.get() == false) {
            
              // Check files
              File[] imgs = (new File(imgPathFinal)).listFiles();
              for (File f : imgs) {
                // Basically check if files that weren't previously in the dir are now in the dir
                String name = file.getIsolatedFilename(f.getAbsolutePath().replaceAll("\\\\", "/"));
                if (!imgsMap.contains(name)) {
                  update = true;
                  updateItems.add(f.getAbsolutePath().replaceAll("\\\\", "/"));
                  imgsMap.add(name);
                }
              }
            }
            
            
            // After all the file checking
            if (update) {
              fileUpdateAvailable.set(true);
            }
            try {
              Thread.sleep(1000);
            }
            catch (InterruptedException e) {
              // Finish up and exit loop when called
              if (terminateUpdatesThread.compareAndSet(true, false) == true) {
                break;
              }
            }
          }
        }
      }
    );
    
    fileUpdatesThread.start();
    
  }
  
  private void terminateFileUpdateThread() {
    if (fileUpdatesThread != null) {
      // Terminate it.
      terminateUpdatesThread.set(true);
      fileUpdatesThread.interrupt();
    }
  }
  
  private void checkForFileUpdates() {
    // Update assets if the file update thread detects something
    if (fileUpdateAvailable.get() == true) {
      int count = 0;
      for (String path : updateItems) {
        PImage img = loadImage(path);
        LargeImage largeimg = display.createLargeImage(img);
        
        // Add to systemimages so we can use it in our sprites
        display.systemImages.put(file.getIsolatedFilename(path), new DImage(largeimg, img));
        count++;
      }
      updateItems.clear();
      
      if (count == 1) console.log("Updated 1 item.");
      else console.log("Updated "+count+" items.");
      
      fileUpdateAvailable.set(false);
    }
  }
  
  
  //////////////////////////////////////
  // CUSTOM COMMANDS
  protected boolean customCommands(String command) {
    if (engine.commandEquals(command, "/reload")) {
      loadSketchieInSeperateThread(sketchiePath);
      console.log("Reloading...");
      return true;
    }
    else {
      return false;
    }
  }
  
  
  
  //////////////////////////////////////
  // FINALIZATION
  
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
