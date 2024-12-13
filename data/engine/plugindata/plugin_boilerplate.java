import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

public class CustomPlugin {

  public PApplet app;
  public PGraphics g;
  
  public final String P2D = PApplet.P2D;
  public final String P3D = PApplet.P3D;
  public final float PI = PApplet.PI;
  public final float HALF_PI = PApplet.HALF_PI;
  public final float TWO_PI = PApplet.TWO_PI;

  public final int QUADS = PApplet.QUADS;
  public final int QUAD = PApplet.QUAD;
  public final int POINT = PApplet.POINT;

  private String getString(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (String)ret;
  }

  private float getFloat(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (float)ret;
  }
  
  private int getInt(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (int)ret;
  }
  
  
  private boolean getBool(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
    return (boolean)ret;
  }

  private void call(int op, Object... argss) {
    apiOpCode = op;
    for (int i = 0; i < argss.length; i++) {
      args[i] = argss[i];
    }
    apiCall.run();
  }

  // API calls.

  public String test(int number) {
    return getString(1, number);
  }

  public void sprite(String name, String img) {
    call(2, name, img);
  }

  public void sprite(String name) {
    sprite(name, name);
  }

  public void print(Object... stufftoprint) {
    apiOpCode = 3;
    if (stufftoprint.length >= 127) {
      warn("You've put too many args in print()!");
      return;
    }
    // First arg used for length of list
    args[0] = stufftoprint.length+1;
    // Continue here.
    for (int i = 1; i < stufftoprint.length+1; i++) {
      args[i] = stufftoprint[i-1];
    }
    apiCall.run();
  }

  public void warn(String message) {
    call(4, message);
  }

  public void moveSprite(String name, float x, float y) {
    call(5, name, x, y);
  }

  public float getTime() {
   return getFloat(6);
  }
  
  public float getDelta() {
    return getFloat(7);
  }

  public float getTimeSeconds() {
    return getFloat(8);
  }

  public float getSpriteX(String name) {
    return getFloat(9, name);
  }

  public float getSpriteY(String name) {
    return getFloat(10, name);
  }

  public void img(String imgName, float x, float y) {
    call(11, imgName, x, y);
  }

  public void scaleSprite(String name, float wi, float hi) {
    call(12, name, wi, hi);
  }
  
  public void scaleSprite(String name, float wihi) {
    scaleSprite(name, wihi, wihi);
  }

  public void spriteBop(String name, float amount) {
    call(13, name, amount);
  }

  public void spriteBop(String name) {
    spriteBop(name, 0.2f);
  }
  
  public String getPath() {
    return getString(14);
  }
  
  public String getPathDirectorified() {
    return getString(15);
  }
  
  public PImage getImg(String name) {
    apiOpCode = 16;
    args[0] = name;
    apiCall.run();
    return (PImage)ret;
  }

  public void largeImg(String name, float x, float y, float w, float h) {
    call(17, name, x, y, w, h);
  }

  public int beatIndex() {
    return getInt(18);
  }

  public int stepIndex() {
    return getInt(19);
  }

  public int beat() {
    return beatIndex()+1;
  }

  public int step() {
    return stepIndex()+1;
  }

  ///////////////////
  // 20
  public float beatSaw(int beatoffset, int stepoffset, int everyxbeat) {
    return getFloat(20, beatoffset, stepoffset, everyxbeat);
  }
  
  public float beatSaw(int beatoffset, int everyxbeat) {
    return beatSaw(beatoffset, 0, everyxbeat);
  }
  
  public float beatSaw(int beatoffset) {
    return beatSaw(beatoffset, 0, 1);
  }
  
  public float beatSawOffbeat(int beatoffset, int everyxbeat) {
    return beatSaw(beatoffset, 2, everyxbeat);
  }

  public float beatSawOffbeat(int beatoffset) {
    return beatSaw(beatoffset, 2, 1);
  }
  
  public float beatSawOffbeat() {
    return beatSaw(0, 2, 1);
  }
  
  public float beatSaw() {
    return beatSaw(0, 0, 1);
  }

  ///////////////////
  // 21
  public float stepSaw() {
    return getFloat(21);
  }

  public float beatToTime(int beat) {
    return getFloat(22, beat);
  }

  public float beatToTime(int beat, int step) {
    return getFloat(23, beat);
  }

  public boolean between(int start, int end) {
    return beat() >= start && beat() <= end;
  }

  public void shaderUniforms(Object... uniforms) {
    apiOpCode = 24;
    if (uniforms.length >= 127) {
      warn("You've put too many args in shaderUniforms()!");
      return;
    }
    // First arg used for length of list
    args[0] = uniforms.length;
    // Continue here.
    for (int i = 1; i < uniforms.length+1; i++) {
      args[i] = uniforms[i-1];
    }
    apiCall.run();
  }
  
  public boolean keyDown(char c) {
    return getBool(25, c);
  }

  public boolean keyOnce(char c) {
    return getBool(26, c);
  }

  public void toClipboard(String text) {
    call(27, text);
  }
  
  public float getAutoFloatTest() {
    return getFloat(28);
  }
  
  public float getAutoFloat(String name) {
    return getFloat(29, name);
  }



  



// We need a start() and run() method here which is
// automatically inserted by the generator.

// when parsing this line is automatically replaced
// by plugin code.
[plugin_code]





  // Plugin-host communication methods
  private Runnable apiCall;
  private int apiOpCode = 0;
  private Object[] args = new Object[128];
  private Object ret;

  public int getCallOpCode() {
    return apiOpCode;
  }

  public Object[] getArgs() {
    return args;
  }

  public void setRet(Object ret) {
    this.ret = ret;
  }

  public void setup(PApplet p, Runnable api, PGraphics g) {
    this.app = p;
    this.apiCall = api;
    this.g = g;

    // Start doesn't exist in this file alone,
    // but should be there after generator processes
    // plugin.
    start();
  }
}