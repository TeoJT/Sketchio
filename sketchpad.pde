import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.filechooser.FileSystemView;


public class Sketchpad extends Screen {
  
  
  
  
  private String sketchiePath = "";
  private TWEngine.PluginModule.Plugin plugin;
  private FFmpegEngine ffmpeg;
  private String code = "";
  private AtomicBoolean compiling = new AtomicBoolean(false);
  private AtomicBoolean successful = new AtomicBoolean(false);
  private boolean runtimeCrash = false;
  private AtomicBoolean once = new AtomicBoolean(false);
  private SpriteSystem sprites;
  private SpriteSystem gui;
  private PGraphics canvas;
  private float canvasScale = 1.0;
  private float canvasX = 0.0;
  private float canvasY = 0.0;
  private float canvasPaneScroll = 0.;
  private ArrayList<String> imagesInSketch = new ArrayList<String>();  // This is so that we can know what to remove when we exit this screen.
  private ArrayList<PImage> loadedImages = new ArrayList<PImage>();
  private JSONObject configJSON = null;
  private AtomicBoolean loading = new AtomicBoolean(true);
  private AtomicInteger processAfterLoadingIndex = new AtomicInteger(0);
  private float textAreaZoom = 22.0;
  private boolean errorMenu  = false;
  private String errorLog = "";
  private float errorHeight = 0f;
  private int canvasSmooth = 1;
  private String renderFormat = "MPEG-4";
  private float upscalePixels = 1.;
  private boolean rendering = false;
  private boolean converting = false;           // TODO: get rid of converting
  private int timeBeforeStartingRender = 0;
  private PGraphics shaderCanvas;
  private PGraphics scaleCanvas;
  private int renderFrameCount = 0;
  private float renderFramerate = 0.;
  //private float musicVolume = 0.5;
  private String selectedMusic = "";
  private String selectedShader = "";
  public Object[] shaderParams = null;
  
  
  
  
  
  private boolean playing = false;
  private boolean loop = false;
  private float time = 0f;
  private float timeLength = 10f;
  private float bpm = 120f;
  
  // Canvas 
  private float beginDragX = 0.;
  private float beginDragY = 0.;
  private float prevCanvasX = 0.;
  private float prevCanvasY = 0.;
  private boolean isDragging = false;
  
  // Panes (windows)
  // There are really two groups of panes:
  // - The ones that use the Pane class
  // - The ones that are fixed (timeline, canvas) and don't have a Pane object associated with it.
  // Therefore, pane status is kept as integers, as dissatisfying as it is.
  // Pane id's 0-99 are reserved for fixed panes.
  
  // NOTE ON ACTIVE PANES:
  // We face a complex problem because, when we render stuff, we run code from bottom to top.
  // The code we run first is at the bottom of the UI. I.e. the canvas is at the bottom, followed by automation bars,
  // followed by windows etc.
  // But of course, we need a way for each pane to have the chance to be active, if that makes any sense.
  // Therefore the system I propose is:
  // - Each pane tries to become active by setting a temp "activePane" variable.
  // - If there's a pane overlapping it, it gets run later in the code and sets the temp "activePane" variable.
  // - This repeats until we've reached the top of the UI, where the last object to set the "activePane" variable will become the winner.
  // - After this point, the real "activePane" is updated.
  // This temp "activePane" will be called candidateActivePane
  
  private int candidateActivePane = -1;
  private int activePane = CANVAS_PANE;
  private Pane activePaneObject = null; // This variable is technically a bit redundant since we already have activePane, but it helps to have
                                        // have it there so we can access any pane object.
  private Pane draggingPane = null;
  private Pane priorityPane = null;     // When this is set, only one pane, the one set in priorityPane, will be shown.
  private float paneStartDragX;
  private float paneStartDragY;
  
  private int paneIDCounter = 100;          // Starts at 100 because 0-99 is reserved for canvas, timeline, autobar etc.
  private boolean activePaneSwitch = false;
  private LinkedList<Pane> panes = new LinkedList<Pane>();
  
  
  final static int CANVAS_PANE = 1;
  final static int TIMELINE_PANE = 3;
  final static int AUTOBAR_PANE = 4;
  
  private final int MAX_DISPLAY_AUTOMATION_BARS = 8;
  private HashMap<String, AutomationBar> automationBars = new HashMap<String, AutomationBar>();
  private ArrayList<AutomationBar> displayAutomationBars = new ArrayList<AutomationBar>();
  
  // Panes
  TestPane testPane = null;
  ConfigPane configPane = null;
  AutomationTypeSelectPane automationTypeSelectPane = null;
  AutomationNamePane automationNamePane = null;
  Pane renderingPane = null; // For both RenderOptionsPane and RenderingPane
  
  
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
    public boolean quartersVisible = false;
    
    public AutomationBar(String name) {
      this.name = name;
    }
    
    public AutomationBar() {
      
    }
    
    public float getHeight() {
      return myHeight+LABEL_HEIGHT;
    }
    
    
    public void resizeTime() {
      
    }
    
    public void rescaleTempo(float scale) {
      
    }
    
    private boolean resizing = false;
    public boolean display(float yFromBottom) {
      BOTTOM_Y = HEIGHT-myLowerBarWeight;
      TOP_Y = BOTTOM_Y-yFromBottom-getHeight();
      RIGHT_X = WIDTH;
      
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
      app.text(name == null ? "null" : name, 5, y+5);
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
      // It has 3 modes: off, beats, and quarters
      if (quartersVisible) app.tint(255);
      else if (beatsVisible) app.tint(180);
      else app.tint(100);
      boolean beatsClicked = ui.buttonImg("music", RIGHT_X*0.5f+(LABEL_HEIGHT+10f)*2f, y, LABEL_HEIGHT, LABEL_HEIGHT);
      app.noTint();
      if (beatsClicked) {
        if (quartersVisible) {
          quartersVisible = false;
          beatsVisible = false;
          sound.playSound("select_smaller");
        }
        else if (beatsVisible) {
          quartersVisible = true;
          sound.playSound("select_bigger");
        }
        else {
          beatsVisible = true;
          sound.playSound("select_bigger");
          
        }
        
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
    
    public float timeLength() {
      return timeLength*60f;
    }
    
    public float time() {
      return time*60f;
    }
    
    public float getActualX(float pointV) {
      float normalizedX = pointV/timeLength();
      float TOTAL_WIDTH = timeLength()*autoBarZoom;
      float tt = time()/timeLength();
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      
      float x = (normalizedX)*TOTAL_WIDTH;
      
      float posToTime_prev = (prev_x/TOTAL_WIDTH)*timeLength();
      float posToTime = (x/TOTAL_WIDTH)*timeLength();
      
      float prev_y = TOP_Y+myHeight*(1f-getFloatVal(posToTime_prev));
      float y = TOP_Y+myHeight*(1f-getFloatVal(posToTime));
      
      float actualPrevX = prev_x+offX;
      float actualX = x+offX;
      
      return actualX;
    }
    
    private float prev_x = 0f;
    protected float plotLine(float normalizedX, boolean showVal) {
      float TOTAL_WIDTH = timeLength()*autoBarZoom;
      float tt = (time())/timeLength();
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      
      float x = (normalizedX)*TOTAL_WIDTH;
      
      float posToTime_prev = (prev_x/TOTAL_WIDTH)*timeLength();
      float posToTime = (x/TOTAL_WIDTH)*timeLength();
      
      // Honestly, I have no idea what any of this code I wrote does.
      // All I know is that these two lines I added below are a working bug fix.
      // Because timeLength and time used to be frames (1 sec = 60), now they're in seconds.
      // So I guess these two variables were stuck in frames or something.
      posToTime_prev /= 60f;
      posToTime /= 60f;
      
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
        app.text(getFloatVal(posToTime), x+offX, y-19f);
      }
      
      return actualX;
    }
    
    protected float plotLine(float normalizedX) {
      return plotLine(normalizedX, false);
    }
    
    protected void save() {
      
    }
    
    protected float screenXToTime(float x) {
      float TOTAL_WIDTH = timeLength()*autoBarZoom;
      float tt = (time())/timeLength();
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      float val = (x-offX)/TOTAL_WIDTH;
      float xx = val*timeLength();
      
      return xx;
    }
    
    protected float normalizedXToScreenX(float normalizedX) {
      float TOTAL_WIDTH = timeLength()*autoBarZoom;
      float tt = time()/timeLength();
      float offX = (RIGHT_X/2f)-tt*TOTAL_WIDTH;
      
      float x = (normalizedX)*TOTAL_WIDTH;
      float actualX = x+offX;
      
      return actualX;
    }
    
    
    protected float closestBeatSnap = -1f;
    protected float BEATSNAP_THRESHOLD = 10f;
    protected void renderBeats() {
      
      app.strokeWeight(2f);
      closestBeatSnap = -1f;
      
      float framesPerX = quartersVisible ? sound.framesPerQuarter() : sound.framesPerBeat();
      
      int l = (int)(timeLength()/framesPerX)+1;
      for (int i = 0; i < l; i++) {
        float x = normalizedXToScreenX((framesPerX*float(i))/timeLength());
        
        if (input.mouseX() > x-BEATSNAP_THRESHOLD && input.mouseX() < x+BEATSNAP_THRESHOLD) {
          closestBeatSnap = screenXToTime(x);
        }
        
        if (quartersVisible && i % 4 != 0) {
          app.stroke(200, 100);
          app.strokeWeight(1f);
        }
        else {
          app.stroke(30, 180);
          app.strokeWeight(3f);
        }
        
        
        if (x > 0f && x < RIGHT_X) {
          app.line(x, TOP_Y, x, BOTTOM_Y);
        }
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
      return getFloatVal((time), false);
    }
    
    // Simply brings the last point to the end of the animation.
    @Override
    public void resizeTime() {
      // Delete all points in shortening timelength.
      // (Except the last point)
      ArrayList<Point> pointsToDelete = new ArrayList<Point>();
      for (int i = 0; i < points.size(); i++) {
        if (points.get(i).t > timeLength() && i != points.size()-1) {
          pointsToDelete.add(points.get(i));
        }
      }
      for (Point p : pointsToDelete) {
        points.remove(p);
      }
      
      // Move last point to the new time position
      if (points.size() > 0) {
        points.get(points.size()-1).t = timeLength();
      }
    }
    
    
    // How to find the index with an arbritrary float value?
    // Do it the lazy way cus I can't be bothered with a big algorithm.
    // Select an approximate point and then backtrace until we find a point between our float val.
    public float getFloatVal(float ttime, boolean countiterations) {
      ttime *= 60f;
      // Calc approx
      int l = points.size();
      int index = min((int)((ttime/timeLength())*((float)l)), l-1);
      
      if (ttime >= timeLength()-0.0002) {
        return points.get(l-1).val;
      }
      
      try {
        int count = 0;
        while (index > 0 && points.get(index).t > ttime) {
          count++;
          index--;
        }
        while (index < l-2 && points.get(index+1).t < ttime) {
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
      barjson.setBoolean("quarters_visible", quartersVisible);
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
      this.name = json.getString("name", "null");
      this.mycolor = json.getInt("color", color(0,0,0));
      this.snapping = json.getBoolean("snapping", false);
      this.beatsVisible = json.getBoolean("beats_visible", false);
      this.quartersVisible = json.getBoolean("quarters_visible", false);
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
    
    // Can't be bothered commenting so long story short, this is what happened previously (bad):
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
      final float VAL_SNAP_THRESHOLD = settings.getFloat("snapping_threshold", 0.025f);
      
    
      if (!input.primaryDown && draggingIndex != -1) {
        draggingIndex = -1;
        save();
      }
      
      // Must have at least 2 points
      if (points.size() == 0) {
        points.add(new Point(0f, 0.5f));
        points.add(new Point(timeLength(), 0.5f));
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
        
        // Hovering over line makes it white
        if (hoverLineIndex == i) {
          app.stroke(255);
          hoverLineIndex = -1;
        }
        else {
          app.stroke(mycolor);
        }
        
        // Get point
        Point point = points.get(i);
        
        // Now render said line from prev to current.
        float x = plotLine(point.t/timeLength(), true);
        
        // Physical x/y position of the point to render on the screen.
        float actualX = x-HALFWIHI;
        float actualY = TOP_Y+(1f-point.val)*myHeight-HALFWIHI;
        
        //if (actualX > RIGHT_X+200f || actualX < 0f) {
        //  continue;
        //}
        
        // Hovering over the square point (makes it white)
        if (input.mouseX() > actualX && input.mouseX() < actualX+RECTWIHI && input.mouseY() > actualY && input.mouseY() < actualY+RECTWIHI && !playing) {
          app.fill(255);
          hoverLineIndex = -1;
          
          // Clicking and holding to begin dragging that square.
          if (input.primaryOnce) {
            draggingIndex = i;
            unsnapDragX = false;
            unsnapDragY = false;
          }
          
          // Delete the point
          if (input.secondaryOnce) {
            pointIndexForDeletion = i;
          }
        }
        
        // Overing over the line with the mouse (uses lineRect collisison detection)
        else if (lineRect(actualX, actualY, prevActualX, prevActualY, lineSelectorX, lineSelectorY, RECTWIHI, RECTWIHI) && !playing) {
          hoverLineIndex = i;
          app.fill(mycolor);
          
          // Create point when right-clicked (of course, needs to be a blank area, we cannot access this part of the code if we're already hovering over an existing square)
          if (input.secondaryOnce) {
            createPointAtIndex = i;
          }
        }
        else {
          // Normal fill
          app.fill(mycolor);
        }
        
        // Currently dragging point
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
            
            // Convert raw mouse x/y to the 0.0 - 1.0 value that the points use.
            float vv = min(max(1f-(input.mouseY()-TOP_Y)/myHeight, 0f), 1f);
            
            // get prev and next vals.
            // TODO: delete
            //float nextval = timeLength;
            //float prevval = -1;
            //if (i-1 >= 0) {
            //  prevval = points.get(i-1).val;
            //}
            //if (i+1 < points.size()) {
            //  nextval = points.get(i+1).val;
            //}
            
            // Snapping logic for all on-screen visible points.
            point.val = vv;
            if (snapping) {
              // Point behind
              app.strokeWeight(1f);
              app.stroke(255, 127);
              
              // This loop looks at all prev and next points that are visible on-screen and snaps the current dragging point to one of these points
              for (int j = 0; j < points.size(); j++) {
                float jactualX = getActualX(points.get(j).t);
                if (j != i && jactualX > 0f && jactualX < WIDTH) {
                  float jval = points.get(j).val;
                  if (vv < jval+VAL_SNAP_THRESHOLD && vv > jval-VAL_SNAP_THRESHOLD) {
                    point.val = jval;
                    app.line(0, actualY+HALFWIHI, RIGHT_X, actualY+HALFWIHI);
                    break;
                  }
                }
              }
              
              // Point infront
              //if (i+1 < points.size()) {
              //  if (vv < nextval+VAL_SNAP_THRESHOLD && vv > nextval-VAL_SNAP_THRESHOLD) {
              //    point.val = nextval;
              //    app.line(0, actualY+HALFWIHI, RIGHT_X, actualY+HALFWIHI);
              //  }
              //}
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
                float maxx = timeLength();
                
                float nextT = timeLength();
                float prevT = -1;
                
                if (i-1 >= 0) {
                  minx = points.get(i-1).t+MICRO_OFFSET;
                  prevT = points.get(i-1).t;
                }
                if (i+1 < points.size()) {
                  maxx = points.get(i+1).t-MICRO_OFFSET;
                  nextT = points.get(i+1).t;
                }
                
                // Update the point's x pos
                float newPointXPos = screenXToTime(input.mouseX());
                
                // Snap to the beats on the bars
                if (snapping && beatsVisible && closestBeatSnap > 0f
                  && newPointXPos > prevT
                  && newPointXPos < nextT
                ) {
                  point.t = closestBeatSnap;
                }
                else {
                  point.t = min(max(newPointXPos, minx), maxx);
                }
            }
          }
          
        }
        
        
        app.noStroke();
        app.rect(actualX, actualY, RECTWIHI, RECTWIHI);
        
        prevActualX = actualX;
        prevActualY = actualY;
      }
      
      // Do not allow deletion of index 0 or the last index.
      if (pointIndexForDeletion > 0 && points.size() > 2 && pointIndexForDeletion != points.size()-1) {
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
  
  
  
  
  
  /////////////////////////////////////////////////
  // TEXT FIELD CLASS
  /////////////////////////////////////////////////
  
  private TextField selectedField = null;
  
  private class TextField {
    protected String spriteName = "";
    public String value = "";
    protected String labelDisplay = "";
    public boolean interactable = true;
    
    final float MIN_FIELD_VISIBLE_SIZE = 150f;
    final float EXPAND_HITBOX = 10f;
    
    public TextField(String spriteName, String labelDisplay) {
      this.spriteName = spriteName;
      this.labelDisplay = labelDisplay;
      
      updateDimensions();
    }
    
    protected void updateDimensions() {
      app.textFont(engine.DEFAULT_FONT, 24f);
      float textww = app.textWidth(labelDisplay+" ");
      float inputfield = app.textWidth(value+" ");
      float ww = PApplet.max(textww+inputfield, textww+MIN_FIELD_VISIBLE_SIZE);
      if (gui != null) {
        gui.sprite(spriteName, "nothing"); // Just to get the sprite to exist if it don't already exist.
        gui.hackSpriteDimensions(gui.getSprite(spriteName), int(ww), int((app.textAscent()+app.textDescent())+EXPAND_HITBOX+6f));
      }
    }
    
    protected boolean click() {
      return gui.getSprite(spriteName).mouseWithinHitbox() && input.primaryOnce && !input.mouseMoved && interactable && !ui.miniMenuShown() && !gui.interactable;
    }
        
    
    public void display() {
      gui.sprite(spriteName, "nothing");
      SpriteSystem.Sprite sprite = gui.getSprite(spriteName);
      
      if (click()) {
          engine.allowShowCommandPrompt = false;
          selectedField = this;
          input.cursorX = value.length();
      }
      
      if (selectedField == this) {
        input.addNewlineWhenEnterPressed = false;
      }
      
      
      app.textAlign(LEFT, TOP);
      app.textFont(engine.DEFAULT_FONT, 24f);

      String displayText = "";
      if (selectedField == this) {
        value = input.getTyping(value, false);
        displayText = labelDisplay+" "+input.keyboardMessageDisplay(value);
        
        if (input.keyOnce) {
          updateDimensions();
        }
      }
      else {
        displayText = labelDisplay+" "+value;
      }
      
      float x = sprite.xpos;
      float y = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2f+10f;
      app.stroke(255f);
      app.strokeWeight(1f);
      app.fill(0f, 200f);
      app.rect(x+app.textWidth(labelDisplay+" ")-10f, y-EXPAND_HITBOX, PApplet.max(app.textWidth(value)+30f, MIN_FIELD_VISIBLE_SIZE)+EXPAND_HITBOX*2f+10f, sprite.getHeight());
      app.fill(255f);
      app.text(displayText, x, y);
      
      //app.rect(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());
    }
  }
  
  
  // Extending cus I can't be bothered copy+pasting or re-typing out everything.
  private class OptionsField extends TextField {
    
    public String[] options;
    
    public OptionsField(String spriteName, String labelDisplay, String defaultVal, String... options) {
      super(spriteName, labelDisplay);
      this.options = options;
      value = defaultVal;
      updateDimensions();
    }
    
    public void display() {
      gui.sprite(spriteName, "nothing");
      SpriteSystem.Sprite sprite = gui.getSprite(spriteName);
      
      if (click()) {
        Runnable[] actions = new Runnable[options.length];
        
        for (int i = 0; i < options.length; i++) {
          final String finalOption = options[i];
          actions[i] = new Runnable() {public void run() {
              value = finalOption;
              updateDimensions();
          }};
        }
        
        ui.createOptionsMenu(options, actions);
      }
      
      
      app.textAlign(LEFT, TOP);
      app.textFont(engine.DEFAULT_FONT, 24f);

      String displayText = labelDisplay+" "+value;
      
      float x = sprite.xpos;
      float y = sprite.ypos-app.textDescent()+EXPAND_HITBOX/2f+10f;
      app.stroke(255f);
      app.strokeWeight(1f);
      app.fill(0f, 200f);
      float boxx = x+app.textWidth(labelDisplay+" ")-10f;
      float boxwi = PApplet.max(app.textWidth(value)+30f, MIN_FIELD_VISIBLE_SIZE)+EXPAND_HITBOX*2f+10f;
      app.rect(boxx, y-EXPAND_HITBOX, boxwi, sprite.getHeight());
      
      display.img("down_triangle_64", boxx+boxwi-sprite.getHeight(), y, sprite.getHeight()-20f, sprite.getHeight()-20f);
      app.fill(255f);
      app.text(displayText, x, y);
      
      //app.rect(sprite.getX(), sprite.getY(), sprite.getWidth(), sprite.getHeight());
    }
  }
  
  
  
  
  
  
  
  
  
  private class Pane {
    public String windowName = "";
    public int paneID = -1;
    protected float xpos = 50f;
    protected float ypos = 50f;
    protected float paneWi = 0f;
    protected float paneHi = 0f;
    private float originalXpos = xpos;
    private float originalYpos = ypos;
    private HashMap<String, TextField> textFields = new HashMap<String, TextField>();
    public boolean showXButton = true;
    
    
    public Pane(String name, float x, float y) {
      windowName = name;
      paneID = paneIDCounter;
      paneIDCounter++;
      
      xpos = x;
      ypos = y;
      originalXpos = xpos;
      originalYpos = ypos;
    }
    
    public void bringToFront() {
      // Easy way to do this.
      panes.remove(this);
      panes.add(this);
    }
    
    protected boolean enter() {
      return (input.enterOnce && !engine.commandPromptShown && activePane == paneID);
    }
    
    // TODO: several of the same sprites being called at once is problematic.
    // This means having multiple of the same type of windows is a really bad idea.
    // Fix the bug for having multiple of the same sprites inside SpriteSystem.
    public boolean button(String name, String texture, String displayText) {
      boolean value = ui.button(name, texture, displayText);
      gui.getSprite(name).offmove(xpos-originalXpos, ypos-originalYpos);
      
      if (activePane == paneID && !gui.interactable) {
        return value;
      }
      else {
        return false;
      }
    }
    
    public TextField getField(String name) {
      TextField f = textFields.get(name);
      if (f == null) {
        console.bugWarn("getField: Field "+name+" doesn't exist!");
        return new TextField("dummy-textField", "null");
      }
      return f;
    }
    
    public TextField textField(String name, String label, String defaultValue) {
      // Create if non-existant (first run)
      if (!textFields.containsKey(name)) {
        TextField f = new TextField(name, label);
        textFields.put(name, f);
        f.value = defaultValue;
      }
      
      // Move with the window
      gui.getSprite(name).offmove(xpos-originalXpos, ypos-originalYpos);
      
      // Display the field.
      TextField field = textFields.get(name);
      field.interactable = (activePane == paneID);
      field.display();
      
      // Return it.
      return field;
    }
    
    public OptionsField optionsField(String name, String label, String defaultValue, String... options) {
      // Create if non-existant (first run)
      if (!textFields.containsKey(name)) {
        OptionsField f = new OptionsField(name, label, defaultValue, options);
        textFields.put(name, f);
      }
      
      // Move with the window
      gui.getSprite(name).offmove(xpos-originalXpos, ypos-originalYpos);
      
      // Display the field.
      // Yes, textFields is used to store TextField but since it extends TextField it can also be used to store OptionsField.
      // Quick PSA on design: really you should use an interface rather than inheritance. But I'm lazy and want to save some
      // duplicated code, so that's why I'm doing it here.
      OptionsField field = (OptionsField)textFields.get(name);
      field.interactable = (activePane == paneID);
      field.display();
      
      // Return it.
      return field;
    }
    
    
    
    public void textSprite(String name, String val, float textSize) {
      String disp = gui.interactable ? "text_sprite_debug_mask" : "nothing";
      gui.getSprite(name).offmove(xpos-originalXpos, ypos-originalYpos);
      gui.sprite(name, disp);
      
      float x = gui.getSprite(name).getX();
      float y = gui.getSpriteVary(name).getY();
      float wi = gui.getSpriteVary(name).getWidth();
      float hi = gui.getSpriteVary(name).getHeight();
      
      app.textAlign(LEFT, TOP);
      app.textFont(engine.DEFAULT_FONT, textSize);
      app.text(val, x, y, wi, hi);
    }
    
    public void textSprite(String name, String val) {
      textSprite(name, val, 24f);
    }
    
    
    
    public void display() {
      final float TAB_BAR_HEIGHT = 25f;
      
      // Display invisible sprite for the window width/height.
      gui.getSprite("window-"+windowName).move(xpos, ypos+TAB_BAR_HEIGHT);
      gui.sprite("window-"+windowName, "nothing");
      paneWi = gui.getSprite("window-"+windowName).getWidth();
      paneHi = gui.getSprite("window-"+windowName).getHeight();
      
      // Give it a coloured border if the pane is chosen.
      if (activePane == paneID) {
        app.stroke(50f, 50f, 255f);
        
        // While we're here, set this variable.
        if (activePaneObject != this) {
          activePaneObject = this;
          
          // And, additionally while we're here, this will only fire once when we click on the window,
          // which is a good time to bring it to the front.
          bringToFront();
        }
      }
      else {
        app.stroke(0f);
      }
      app.strokeWeight(1f);
      
      
      // Dragging pane
      if (draggingPane == this) {
        // Max/min keeps it within draggable area.
        xpos = max(min(input.mouseX()-paneStartDragX, WIDTH-30f), -paneWi+TAB_BAR_HEIGHT+30f);
        ypos = max(min(input.mouseY()-paneStartDragY, HEIGHT-myLowerBarWeight-TAB_BAR_HEIGHT), myUpperBarWeight);
        if (!input.primaryDown) {
          draggingPane = null;
        }
      }
      
      boolean mouseInTabBar = (activePane == paneID) && ui.mouseInArea(xpos, ypos, paneWi, TAB_BAR_HEIGHT);
      boolean mouseInXButton = (activePane == paneID) && ui.mouseInArea(xpos+paneWi-TAB_BAR_HEIGHT, ypos, TAB_BAR_HEIGHT, TAB_BAR_HEIGHT) && showXButton;
      
      // Tab bar
      if (mouseInTabBar && !mouseInXButton) {
        // Clicking it begins dragging
        if (input.primaryOnce) {
          draggingPane = this;
          paneStartDragX = input.mouseX()-xpos;
          paneStartDragY = input.mouseY()-ypos;
        }
        app.fill(40f, 230f);
      }
      else {
        app.fill(0f, 230f);
      }
      app.rect(xpos, ypos, paneWi, TAB_BAR_HEIGHT);
      
      // Pane background
      app.fill(0f, 220f);
      app.rect(xpos, ypos+TAB_BAR_HEIGHT, paneWi, paneHi);
      
      // Close button (cancels)
      if (showXButton) {
        app.noStroke();
        if (mouseInXButton) {
          app.fill(245f, 80f, 80f, 200f);
          // Clicking it closes the pane (obviously)
          if (input.primaryOnce) {
            closeCancel();
          }
        }
        else {
          app.fill(225f, 40f, 40f, 200f);
        }
        app.rect(xpos+paneWi-TAB_BAR_HEIGHT, ypos, TAB_BAR_HEIGHT, TAB_BAR_HEIGHT);
      }
      
      
      // try to claim active pane.
      if (ui.mouseInArea(xpos, ypos, paneWi, TAB_BAR_HEIGHT+paneHi)) {
        tryClaimActivePane(paneID);
      }
    }
    
    public void closeCancel() {
      panes.remove(this);
      activePaneObject = null;
      if (priorityPane == this) priorityPane = null;
    }
    
    public void closeOK() {
      panes.remove(this);
      if (priorityPane == this) priorityPane = null;
    }
  }
  
  private Pane newPane(Pane pane) {
    panes.add(pane);
    forceSetActivePane(pane.paneID);
    return pane;
  }
  
  private void forceSetActivePane(int paneid) {
    if (sprites != null) sprites.selectedSprite = null;
    
    activePane = paneid;
    
    // Set it to null for the fixed, non-object panes. Don't worry, our pane object will realise it's the chosen one
    // and will set this variable accordingly.
    activePaneObject = null;
  }
  
  private void removePane(Pane pane) {
    if (pane == null) return;
    try {
      panes.remove(pane);
    }
    catch (RuntimeException e) {
      
    }
  }
  
  // Called after each pane to try to become the active one.
  private void tryClaimActivePane(int paneID) {
    if (!activePaneSwitch && input.primaryOnce) {
      candidateActivePane = paneID;
    }
  }
  
  
  
  
  
  
  
  private class TestPane extends Pane {
    public TestPane() {
      super("Test", 400f, 500f);
    }
    
    public void display() {
      super.display();
      
      if (button("panetest-1", "media_128", "Itemize")) {
        console.log("Itemize operation");
      }
      if (button("panetest-tick", "tick_128", "Confirm")) {
        closeOK();
      }
      
      textField("panetest-field", "Item name: ", "[default]");
      textField("panetest-field-2", "Max size (MB): ", "10");
      
      optionsField("panetest-Options1", "Graphics API: ", "OpenGL",  /*Options>>*/  "OpenGL", "Vulkan", "WebGPU", "A very long option with loads of text");
    }
  }
  
  
  
  
  private class ConfigPane extends Pane {
    
    private String[] musicFiles = null;
    
    public ConfigPane() {
      super("Config", 400f, 200f);
      
      // Get list of music
      if (file.exists(sketchiePath+"music")) {
        File[] files = (new File(sketchiePath+"music")).listFiles();
        musicFiles = new String[files.length+1];
        musicFiles[0] = "(None)";
        
        for (int i = 0; i < files.length; i++) {
          musicFiles[i+1] = files[i].getName();
        }
      }
      
      
      
      
      
      
      
      
      
      
      // TODO: Bring back shader selection
      
      // Shader selection
      //String shaderDisp = selectedShader;
      //if (shaderDisp.length() == 0) shaderDisp = "(None)";
      //if (textSprite("config-shader", "Post-processing shader: "+shaderDisp) && !ui.miniMenuShown()) {
        
      //  ///////////////////
      //  // SHADERS
        
      //  // TODO: BAD
      //  String shaderPath = "";
      //  if (file.exists(sketchiePath+"shaders")) shaderPath = sketchiePath+"shaders";
      //  if (file.exists(sketchiePath+"shader")) shaderPath = sketchiePath+"shader";
        
      //  // Shader path
      //  if (shaderPath.length() > 0) {
      //    // List out all the files, get each image.
      //    File[] sh = (new File(shaderPath)).listFiles();
      //    String[] loadedShaders = new String[sh.length];
      //    for (int i = 0; i < sh.length; i++) {
      //      File f = sh[i];
            
      //      String fullPath = f.getAbsolutePath().replaceAll("\\\\", "/");
      //      String ext = file.getExt(fullPath);
      //      String name = file.getIsolatedFilename(fullPath);
            
      //      if (ext.equals("glsl") || ext.equals("vert")) {
      //        display.loadShader(fullPath);
      //        loadedShaders[i] = name;
      //      }
      //      else {
      //        loadedShaders[i] = name+" (invalid)";
      //      }
      //      // GLSL shaders are loaded with vert shaders.
      //    }
          
      //    if (loadedShaders.length > 0) {
      //      String[] labels = new String[loadedShaders.length+1];
      //      Runnable[] actions = new Runnable[loadedShaders.length+1];
            
      //      // None option
      //      labels[0] = "(None)";
      //      actions[0] = new Runnable() {public void run() { selectedShader = ""; }};
            
      //      for (int i = 0; i < loadedShaders.length; i++) {
      //        final int index = i;
      //        labels[i+1]  = loadedShaders[i];
      //        actions[i+1] = new Runnable() {
      //          public void run() { 
      //            selectedShader = loadedShaders[index]; 
      //          }
      //        };
      //      }
            
      //      ui.createOptionsMenu(labels, actions);
      //    }
      //  }
      //}
      
      
    }
    
    public void display() {
      super.display();
      
      // Width/height fields
      textField("configpane-width", "Width (pixels): ", str(canvas.width));
      textField("configpane-height", "Height (pixels): ", str(canvas.height));
      
      textField("configpane-length", "Video length (secs):", str(timeLength));
      
      if (button("configpane-musictimesync", "music_time_128", "Set to length of music")) {
        getField("configpane-length").value = str(sound.getCurrentMusicDuration());
      }
      
      // Anti-aliasing field
      String smoothDisp = "";
      switch (canvasSmooth) {
        case 0:
        smoothDisp = "None (pixelated)";
        break;
        case 1:
        smoothDisp = "x1";
        break;
        case 2:
        smoothDisp = "x2";
        break;
        case 4:
        smoothDisp = "x4";
        break;
        case 8:
        smoothDisp = "x8";
        break;
      }
      
      optionsField("configpane-antialias", "Anti-aliasing: ", smoothDisp,  /*Options>>*/ "None (pixelated)", "x1", "x2", "x4", "x8");
      
      // Music selection field
      optionsField("configpane-music", "Music: ", selectedMusic.equals("") ? "(None)" : selectedMusic, /*Options>>*/ musicFiles);
      
      // BPM field
      textField("configpane-bpm", "BPM: ", str(bpm));
      
      // Apply button
      if (button("configpane-ok", "tick_128", "Apply") || enter()) {
        try {
          int wi = Integer.parseInt(getField("configpane-width").value);
          int hi = Integer.parseInt(getField("configpane-height").value);
          timeLength = Float.parseFloat(getField("configpane-length").value);
          resizeAutomationBarTimes();
          bpm = Float.parseFloat(getField("configpane-bpm").value);
          sound.setBPM(bpm);
          
          selectedMusic = getField("configpane-music").value.equals("(None)") ? "" : getField("configpane-music").value;
          
          boolean smoothChangesMade = false;
          String antialiasVal = getField("configpane-antialias").value;
          int newCanvasSmooth = -1;
          if (antialiasVal.equals("None (pixelated)"))  newCanvasSmooth = 0;
          else if (antialiasVal.equals("x1")) newCanvasSmooth = 1;
          else if (antialiasVal.equals("x2")) newCanvasSmooth = 2;
          else if (antialiasVal.equals("x4")) newCanvasSmooth = 4;
          else if (antialiasVal.equals("x8")) newCanvasSmooth = 8;
          
          if (newCanvasSmooth != canvasSmooth) {
            canvasSmooth = newCanvasSmooth;
            smoothChangesMade = true;
          }
          
          
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
        
        closeOK();
      }
    }
  }
  
  
  private static final int AUTOMATION_LINEAR = 1;
  
  private class AutomationTypeSelectPane extends Pane {
    
    public AutomationTypeSelectPane() {
      super("Automation selection type", 400f, 100f);
    }
    
    public void display() {
      super.display();
      
      // Title
      textSprite("automationpane-type-text", "Select automation type:");
      
      
      if (button("automationpane-lerp", "automation_lerp_128", "Linear")) {
        closeOK();
        
        removePane(automationNamePane);
        automationNamePane = new AutomationNamePane(AUTOMATION_LINEAR, xpos, ypos);
        newPane(automationNamePane);
      }
      
      button("automationpane-unkown", "unknown_128", "More types coming soon!");
      
    }
  }
  
  
  private class AutomationNamePane extends Pane {
    private int selectedAutomationType = 0;
    
    public AutomationNamePane(int automationType, float x, float y) {
      super("Automation selection name", 400, 200);
      xpos = x;
      ypos = y;
      selectedAutomationType = automationType;
    }
    
    public void display() {
      super.display();
      
      // Text
      textSprite("automationpane-name-text", "Create name for automation bar:");
      
      // Input field
      textField("automationpane-name-input", "Name: ", "");
      
      // OK Button
      if (button("automationpane-name-ok", "tick_128", "OK") || enter()) {
        String name = getField("automationpane-name-input").value;
        
        // Name check
        if (name.length() == 0) {
          console.log("Invalid name!");
          sound.playSound("nope");
        }
        
        // Existing item check
        else if (automationBars.containsKey(name)) {
          console.log(name+" already exists!");
          sound.playSound("nope");
        }
        
        // Name invalid.
        else {
          
          // Now for each automation bar type.
          switch (selectedAutomationType) {
            
            // Linear
            case AUTOMATION_LINEAR:
            LerpAutomationBar bar = new LerpAutomationBar(name);
            automationBars.put(name, bar);
            addAutomationBarToDisplay(bar);
            break;
            
            // Error
            default:
            console.bugWarn("Unknown automation type "+selectedAutomationType);
            closeCancel();
            return;
            
            
          }
          closeOK();
        }
        
      }
    }
  }
  
  
  private class RenderOptionsPane extends Pane {
    
    public RenderOptionsPane() {
      super("Render", 350f, 150f);
    }
    
    public void display() {
      super.display();
      
      // Framerate field
      textField("renderpane-framerate", "Framerate: ", "60");
      
      optionsField("renderpane-format", "File type: ", "MPEG-4",  
      /*Options>>*/ 
      "MPEG-4", 
      "MPEG-4 (Lossless 4:2:0)", 
      "MPEG-4 (Lossless (4:4:4)", 
      "Apple ProRes 4444", 
      "Animated GIF",
      "Animated GIF (Loop)");
      
      optionsField("renderpane-scale", "Pixel scale: ", "100% (No scaling)",  /*Options>>*/ "25%", "50%", "100% (No scaling)", "200%", "300%", "400%");
      
      
      // Render info
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
        float framerate = Float.parseFloat(getField("renderpane-framerate").value);
        long requiredSize = (long)(canvas.width*upscalePixels)*(long)(canvas.height*upscalePixels)*4L*(long)( (timeLength)*framerate);
        int sizemb = int(requiredSize/(1024L*1024L));
        float sizegb = float(sizemb)/1024f;
        String renderInfo = "This render requires "+nf(sizegb, 0, 1)+"GB of free disk space.";
        textSprite("renderpane-info1", renderInfo, 16f);
      }
      catch (NumberFormatException e) {
        
      }
      
      
      // Start rendering button
      if (button("renderpane-ok", "tick_128", "Start rendering")) {
        renderFormat = getField("renderpane-format").value;
        
        String pixelscale = getField("renderpane-scale").value;
        if (pixelscale.equals("25%")) upscalePixels = 0.25f;
        else if (pixelscale.equals("50%")) upscalePixels = 0.5f;
        else if (pixelscale.equals("100% (No scaling)")) upscalePixels = 1.0f;
        else if (pixelscale.equals("200%")) upscalePixels = 2.0f;
        else if (pixelscale.equals("300%")) upscalePixels = 3.0f;
        else if (pixelscale.equals("400%")) upscalePixels = 4.0f;
        
        try {
          renderFramerate = Float.parseFloat(getField("renderpane-framerate").value);
        }
        catch (NumberFormatException e) {
          console.log("Invalid inputs!");
          sound.playSound("nope");
          return;
        }
        
        beginRendering();
        
        closeOK();
        
        removePane(renderingPane);
        renderingPane = new RenderingPane();
        newPane(renderingPane);
        priorityPane = renderingPane;
        
      }
      
      
    }
  }
  
  
  
  
  
  private class RenderingPane extends Pane {
    public RenderingPane() {
      super("Rendering...", 400f, 150f);
      showXButton = false;
    }
    
    private void percentageBar(float completion) {
      SpriteSystem.Sprite s = gui.getSprite("renderinginfopane-percentage");
      app.noStroke();
      app.fill(58, 60, 65);
      app.rect(s.getX(), s.getY(), s.getWidth(), s.getHeight());
      
      app.fill(30f, 190f, 90f);
      app.rect(s.getX(), s.getY(), s.getWidth()*completion, s.getHeight());
      
      textSprite("renderinginfopane-percentage", "" /*int(completion*100f)+"%"*/, 40f);
      
    }
    
    public void display() {
      super.display();
      ui.loadingIcon(xpos+paneWi/2f, ypos+paneHi/2f);
      
      
      // We have one for stage 1 and stage 2
      if (!converting) {
        textSprite("renderinginfopane-txt1", "Rendering...\nStage 1/2");
        
        percentageBar(time/timeLength);
        
        if (button("renderinginfopane-cancel", "cross_128", "Stop rendering")) {
          cancelRendering();
          closeCancel();
        }
      }
      else {
        textSprite("renderinginfopane-txt1", 
        "Converting to "+renderFormat+"...\n"+
        "Stage 2/2\n"+
        "("+ffmpeg.framecount+"/"+renderFrameCount+")");
        
        percentageBar((float)ffmpeg.framecount/(float)renderFrameCount);
        
        
        if (button("renderinginfopane-cancel", "cross_128", "Stop rendering")) {
          cancelRendering();
          cancelConversion();
          closeCancel();
        }
        
        if (ffmpeg.framecount >= renderFrameCount) {
          closeOK();
        }
      }
      
    }
  }
  
  
  
  
  
  
  
  
  
  
  

  public Sketchpad(TWEngine engine, String path) {
    this(engine);
    
    loadSketchieInSeperateThread(path);
  }
  
  public Sketchpad(TWEngine engine) {
    super(engine);
    myUpperBarWeight = 100.;
    
    gui = new SpriteSystem(engine, engine.APPPATH+engine.PATH_SPRITES_ATTRIB()+"gui/sketchpad/");
    gui.interactable = false;
    
    
    plugin = plugins.createPlugin();
    
    createCanvas(1024, 1024, 1);
    resetView();
    
    canvasY = myUpperBarWeight;
    
    code = "";
    // Load default code into keyboardMessage
    for (String s : defaultCode) {
      code += s+"\n";
    }
    
    ffmpeg = new FFmpegEngine();
    
    myUpperBarColor = 0xFF3B3A47;
    myLowerBarColor = 0xFF3B3A47;
    myBackgroundColor = 0xFF0E0D0F;
    
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
    json.setBoolean("show_code_editor", false);
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
      //codeEditorShown = configJSON.getBoolean("show_code_editor", true);
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
    //println(" ---------------------- CODE: ----------------------");
    //println(ccode);
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
    // SPRITES
    // Next: load sprites. Not too hard.
    String spritePath = "";
    if (file.exists(path+"sprites")) spritePath = path+"sprites/";
    if (file.exists(path+"sprite")) spritePath = path+"sprite/";
    
    // If sprites exist.
    if (spritePath.length() > 0) {
      // Load our new sprite system, EZ.
      sprites = new SpriteSystem(engine, spritePath);
      sprites.interactable = true;
    }
    
    
    //////////////////
    // SCRIPT
    // And now: script
    code = loadScript();
    
    
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
        runtimeCrash = false;
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
    return time;
  }
  
  public float getBMP() {
    return bpm;
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
    else {
      console.warnOnce("Unknown autobar \""+autobarname+"\"");
    }
    return -1f;
  }
  
  public boolean codeOK() {
    //console.log("loading "+!loading.get());
    //console.log("compiling "+!compiling.get());
    //console.log("successful "+successful.get());
    return (successful.get() && !compiling.get() && !loading.get() && !runtimeCrash);
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
  
  public void resizeAutomationBarTimes() {
    for (AutomationBar b : automationBars.values()) {
      b.resizeTime();
      b.save();
    }
  }
  
  ////////////////////////////
  
  private void resetView() {
    canvasX = canvas.width*canvasScale*0.5;
    canvasY = canvas.height*canvasScale*0.5;
    canvasScale = 1.0;
    // Only reset view if the mouse is in the canvas pane
  }
  
  // Creating this funciton because I think the width of
  // canvas v the code editor will likely change later
  // and i wanna maintain good code.
  
  
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
      if (codeOK()) {
        play();
      }
      else {
        console.log("Please fix code errors first!");
      }
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
  
  private void displayCanvas() {
    if (input.altDown && input.shiftDown && input.keyDownOnce('s')) {  // TODO: really need customisable keyboard shortcuts...
      resetView();
    }
    
    
    
    boolean withinCanvasPane = input.mouseY() < HEIGHT-myLowerBarWeight && input.mouseY() > myUpperBarWeight;
    boolean usingCanvasPane = (activePane == CANVAS_PANE);
    boolean notDraggingSprites = sprites.selectedSprite == null;
    
    // Need a way to go into the canvas pane in the first place.
    
    // Process scrolling
    if (usingCanvasPane) {
      canvasPaneScroll = input.processScroll(canvasPaneScroll, 100., 2500.);
    }
    
    // Begin moving around.
    // TODO: middleclick to move too.
    // !gui.interactable is added to make it less annyoing while moving UI elements on windows.
    if (usingCanvasPane && notDraggingSprites && withinCanvasPane && !gui.interactable) {
      if (input.primaryOnce && !isDragging) {
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
      
      if (!input.primaryDown || sprites.selectedSprite != null || activePane != CANVAS_PANE) {
        isDragging = false;
      }
    
    }
    
    // Sprite selected, then we right-click it
    // Brings up the menu
    if (sprites.selectedSprite != null && sprites.selectedSprite.mouseWithinSprite() && input.secondaryOnce && !ui.miniMenuShown()) {
      showSpriteMenu();
    }
    
    // Scroll is negative
    canvasScale = (2500f+canvasPaneScroll)/1000f;
    
    sprites.setMouseScale(canvasScale, canvasScale);
    float xx = canvasX-canvas.width*canvasScale*0.5;
    float yy = canvasY-canvas.height*canvasScale*0.5;
    sprites.setMouseOffset(xx, yy);
    
    // Shader canvas cus that's where our final frame is drawn even if we don't have any post-processing shaders active.
    
    if (codeOK()) {
      app.image(shaderCanvas, xx, yy, canvas.width*canvasScale, canvas.height*canvasScale);
    }
    
    // Needs to be last here, we take control of the active pane here. 
    if (withinCanvasPane) {
      tryClaimActivePane(CANVAS_PANE);
    }
  }
  
  
  
  public void showError() {
    //if (errorHeight < 40f) return;
    
    app.fill(255, 200, 200);
    app.noStroke();
    app.rect(0, myUpperBarWeight, WIDTH, errorHeight);
    app.fill(0);
    app.textFont(display.getFont("Source Code"), 20);
    app.text(errorLog, 5, myUpperBarWeight+5, WIDTH-10, errorHeight-10);
    
    
    ui.useSpriteSystem(gui);
    boolean close = false;
    
    close = ui.button("close-error-2", "cross", "");
    
    if (close) {
      errorMenu = false;
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public void showError(String mssg) {
    errorLog = mssg;
    app.textSize(20);
    errorHeight = getTextHeight(errorLog);
    if (errorHeight < 40f) {
      errorLog += "\n\n";
      errorHeight = getTextHeight(errorLog);
    }
    errorMenu = true;
    pause();
  }
  
  private Runnable resetSpriteSize(int scale) {
    Runnable r = new Runnable() {
      public void run() {
        if (sprites.selectedSprite != null) {
          // Try catch here cus otherwise we'd have to do multiple null checks here and I'd rather my code
          // not be an untidy mess.
          try {
            PImage img = display.systemImages.get(sprites.selectedSprite.imgName);
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
          SpriteSystem.Sprite s = sprites.selectedSprite;
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
          SpriteSystem.Sprite s = sprites.selectedSprite;
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
          SpriteSystem.Sprite s = sprites.selectedSprite;
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
    
    sprites.interactable = false;
    sprites.selectedSprite = null; // Just in case.
    
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
        showError(plugin.errorOutput);
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
    
    // Use our custom delta funciton (which force sets it to the correct value while rendering)
    sprites.setDelta(getDelta());
    
    // Only allow sprites to be dragged while canvas pane is selected, otherwise doing stuff like moving window panes
    // will move sprites too which will be incredibly annoying.
    if (activePane != CANVAS_PANE) {
      disableSpritesClick();
    }
    
    // Switch canvas, then begin running the plugin code
    if (codeOK()) {
      canvas.beginDraw();
      canvas.fill(255, 255);
      display.setPGraphics(canvas);
      
      boolean runok = plugin.run();
      
      if (!runok) {
        runtimeCrash = true;
        showError(plugin.exceptionMessage);
      }
      
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
    if (rendering && !converting && codeOK()) {
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
    
    if (rendering && runtimeCrash) {
      console.warn("Runtime crash while rendering.");
      exitRendering();
    }
    
    // Update time
    if (playing) {
      time += getDelta()/60f;
      
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
  
  private void displayPaneObjects() {
    ui.useSpriteSystem(gui);
    
    if (input.primaryOnce) {
      selectedField = null;
    }
    
    if (priorityPane != null) {
      priorityPane.display();
    }
    else {
      for (Pane pane : panes) {
        pane.display();
      }
    }
  }
  
  
  private float autoBarZoom = 5f;
  private float autoBarZoomScroll = -2000f;
  private int autoBarsZoomPauseTimeout = 60;
  
  
  public void content() {
    power.setAwake();
    
    // From the previous frame, see which pane won (at the top of the UI) for becoming the active pane.
    activePaneSwitch = false;  // This will get set to true if switching panes.
    
    if (candidateActivePane != -1) {
      if (activePane != candidateActivePane) {
        if (sprites != null) sprites.selectedSprite = null;
        
        
        activePane = candidateActivePane;
        
        // Set it to null for the fixed, non-object panes. Don't worry, our pane object will realise it's the chosen one
        // and will set this variable accordingly.
        activePaneObject = null;
        
        // This is set ultimately by clicking. Because that was last frame, 
        // clicks will be reset by now. So let's artifically set em again.
        // TODO: need it for right-clicking. That's complex.
        input.primaryOnce = true;
        
        // Need to set this to true to prevent weird buggy behaviour in tryClaimActivePane
        activePaneSwitch = true;
      }
    }
    
    // Reset to -1 for the next candidate selection.
    candidateActivePane = -1;
    
    if (!loading.get()) {
      if (processAfterLoadingIndex.get() > 0) {
        int i = processAfterLoadingIndex.decrementAndGet();
        
        // Create large image, I don't want the lag
        
        
        // Add to systemimages so we can use it in our sprites
        display.systemImages.put(imagesInSketch.get(i), loadedImages.get(i));
        
        
        if (i == 0) {
          if (configJSON != null) {
            canvasSmooth = configJSON.getInt("smooth", 1);
            createCanvas(configJSON.getInt("canvas_width", 1024), configJSON.getInt("canvas_height", 1024), canvasSmooth);
            setMusic(selectedMusic);
          }
          
          input.cursorX = code.length();
          compileCode(code);
          
        }
      }
      
      // Update music time so functions like beat() work properly
      sound.setCustomMusicTime(time);
      
      
      if (!input.typingActive() && input.keyActionOnce("playPause", ' ')) {
         togglePlay();
      }
      
      
      // Run the actual sketchio file's code.
      runCanvas();
      displayCanvas();
      
      // Woops, gotta get the boolean value a frame late, who cares.
      
      // Display timesets and stuff
      
      boolean mouseInAutomationBarPane = false;
      float y = 0f;
      
      // Don't display automation bars while a priority pane is showing.
      if (priorityPane == null) {
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
        if (input.primaryOnce) {
          tryClaimActivePane(AUTOBAR_PANE);
        }
        
        // Copy+paste crap
        // This if statement? There's a bug where as soon as we launch a project,
        // it seems to automatically make it shrink.
        // So instead of figuring out why the heck this happens, let's just apply
        // a pause before we can zoom out the bars. EZ.
        if (activePane == AUTOBAR_PANE) {
          if (autoBarsZoomPauseTimeout <= 0) {
            autoBarZoomScroll = input.processScroll(autoBarZoomScroll, -100f, 4000f);
          }
        }
      }
      if (autoBarsZoomPauseTimeout > 0) autoBarsZoomPauseTimeout--;
      
      autoBarZoom = -autoBarZoomScroll/500f;
      
      // Show error output.
      if (errorMenu) {
        //console.log("Error");
        showError();
      }
      
      checkForFileUpdates();
      
      // we "stop" the music by simply muting the audio, in the background it's still playing tho,
      // but it makes coding a lot more simple.
      if (playing && !rendering) {
        //sound.setMusicVolume(musicVolume);
        sound.syncMusic(time);
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
    
    // We run this here because we want all windows to be layered over everything, and the lowerbar is the last thing to be rendered (I think)
    displayPaneObjects();
    
    
    ((IOEngine)engine).displaySketchioInput();
  }
  
  private void cancelRendering() {
    sound.playSound("select_smaller");
    pause();
    exitRendering();
    console.log("Rendering cancelled.");
  }
  
  
  public void upperBar() {
    display.shader("fabric", "color", red(myUpperBarColor)/255f, green(myUpperBarColor)/255f, blue(myUpperBarColor)/255f, 1.0f, "intensity", 0.02);
    super.upperBar();
    app.resetShader();
    ui.useSpriteSystem(gui);
    
    if (!rendering && priorityPane == null) {
      if (ui.button("compile_button", "media_128", "Compile")) {
        // Don't allow to compile if it's already compiling
        // (cus we gonna end up with threading issues!)
        if (!compiling.get()) {
          sound.playSound("select_any");
          // If not showing code editor, we are most likely using an external ide to program this.
          // So do not save what we have in memory.
          compileCode(loadScript());
        } 
      }
      
      if (ui.button("openscript_button", "doc_128", "Extern open")) {
        sound.playSound("select_any");
        file.open(sketchiePath+"scripts/main.java");
      }
      
      if (ui.button("automation_button", "automation_128", "Automation")) {
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
          removePane(automationTypeSelectPane);
          automationTypeSelectPane = new AutomationTypeSelectPane();
          newPane(automationTypeSelectPane);
        }};
        
        ui.createOptionsMenu(labels, actions);
      }
      
      if (ui.button("settings_button", "doc_128", "Sketch config")) {
        sound.playSound("select_any");
        //widthField.value = str(canvas.width);
        //heightField.value = str(canvas.height);
        //timeLengthField.value = str(timeLength/60.);
        //bpmField.value = str(bpm);
        //selectedField = null;
        removePane(configPane);
        configPane = new ConfigPane();
        newPane(configPane);
        priorityPane = configPane;
        
        // TODO: Close config menu
      }
      
      if (ui.button("render_button", "image_128", "Render")) {
        sound.playSound("select_any");
        
        removePane(renderingPane);
        renderingPane = new RenderOptionsPane();
        newPane(renderingPane);
      }
      
      if (ui.button("folder_button", "folder_128", "Show files")) {
        sound.playSound("select_any");
        pause();
        file.open(sketchiePath);
      }
      
      if (ui.button("back_button", "back_arrow_128", "Explorer")) {
        quit();
      }
    }
    
    if (compiling.get()) {
      ui.loadingIcon(WIDTH-64-10, myUpperBarWeight+64+10, 128);
    }

    
    gui.updateSpriteSystem();
    
  }
  
  
  public void quit() {
    terminateFileUpdateThread();
    sound.playSound("select_any");
    sound.stopMusic();
    
    previousScreen();
  }
  
  float textBeatFlash = 0f;
  int previousBeat = 0;
  
  public void lowerBar() {
    //display.shader("fabric", "color", 0.43,0.4,0.42,1., "intensity", 0.1);
    super.lowerBar();
    app.resetShader();
    
    float BAR_X_START = 70.;
    float BAR_X_LENGTH = WIDTH-120.-BAR_X_START;
    
    // Display timeline
    // bar
    float y = HEIGHT-myLowerBarWeight;
    app.fill(0xFF646370);
    app.noStroke();
    app.rect(BAR_X_START, y+(myLowerBarWeight/2)-2, BAR_X_LENGTH, 4);
    
    textBeatFlash -= display.getDelta()*0.08f;
    textBeatFlash = max(textBeatFlash, 0f);
    // Beat flash calculation
    if (previousBeat != sound.beat) {
      previousBeat = sound.beat;
      textBeatFlash = 1f;
    }
    
    // Times
    app.textAlign(LEFT, CENTER);
    app.fill(255);
    app.textFont(engine.DEFAULT_FONT, 20);
    app.text("T "+PApplet.nf(time, 2, 2), BAR_X_START+BAR_X_LENGTH+10, y+(myLowerBarWeight*0.25));
    
    app.fill(lerp(255f, 230f, textBeatFlash), lerp(255f, 120f, textBeatFlash), lerp(255f, 200f, textBeatFlash));
    app.text("B " + PApplet.nf(sound.beat+1, 3) + ":" + (sound.step+1), BAR_X_START+BAR_X_LENGTH+10, y+(myLowerBarWeight*0.75));
    
    
    
    float percent = time/timeLength;
    float timeNotchPos = BAR_X_START+BAR_X_LENGTH*percent;
    
    // Notch
    app.fill(255);
    app.rect(timeNotchPos-4, y+(myLowerBarWeight/2)-25, 8, 50); 
    
    display.imgCentre(playing ? "pause_128" : "play_128", BAR_X_START/2, y+(myLowerBarWeight/2), myLowerBarWeight, myLowerBarWeight);
    
    // Timeline pane input (clicking n stuff)
    // TIMELINE_PANE will get set automatically if there's no overlapping windows.
    if (activePane == TIMELINE_PANE && !rendering && !ui.miniMenuShown()) {
      // If the mouse is in the timeline area.
      if (input.mouseY() > y) {
        // Mouse in time bar area (after pause button)
        if (input.mouseX() > BAR_X_START) {
          // If in bar zone
          if (input.primaryDown) {
            float notchPercent = min(max((input.mouseX()-BAR_X_START)/BAR_X_LENGTH, 0.), 1.);
            time = timeLength*notchPercent;
          }
          
        }
        // Mouse before bar area (in pause button range)
        else {
          // If in play button area
          if (input.primaryOnce) {
            // Toggle play/pause button
            togglePlay();
            // Restart if at end
            if (playing && time > timeLength) time = 0.;
          }
          // Right click action to show minimenu
          else if (input.secondaryOnce) {
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
    
    if (input.mouseY() > y) {
      tryClaimActivePane(TIMELINE_PANE);
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
        exitRendering();
      }
    };
    
    ffmpegWorker.execute();
  }
  
  private void cancelConversion() {
    if (ffmpegWorker != null) {
      ffmpegWorker.cancel(true);
    }
  }
  
  private void exitRendering() {
    rendering = false;
    converting = false;
    power.allowMinimizedMode = true;
    sprites.interactable = true;
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
        
        // Add to systemimages so we can use it in our sprites
        display.systemImages.put(file.getIsolatedFilename(path), img);
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
    else if (engine.commandEquals(command, "/testpane")) {
      removePane(testPane);
      testPane = new TestPane();
      newPane(testPane);
      
      console.log("Opened test pane");
      return true;
    }
    else {
      return false;
    }
  }
  
  
  
  //////////////////////////////////////
  // FINALIZATION
  
  public void endScreenAnimation() {
    free();
  }
  
  public void free() {
     // Clear the images from systemimages to clear up used images.
     for (String s : imagesInSketch) {
       display.systemImages.remove(s);
     }
     imagesInSketch.clear();
     System.gc();
  }
}
