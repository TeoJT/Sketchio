import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

public class CustomPlugin {

  public PApplet app;
  public PGraphics g;
  public final float PI = PApplet.PI;
  public final float HALF_PI = PApplet.HALF_PI;
  public final float TWO_PI = PApplet.TWO_PI;

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