import processing.core.*;
import processing.data.*;
import processing.event.*;
import processing.opengl.*;

public class CustomPlugin {

  public PApplet app;

  // API calls.

  public String test(int number) {
    apiOpCode = 1;
    args[0] = number;
    apiCall.run();
    return (String)ret;
  }

  public void sprite(String name, String img) {
    apiOpCode = 2;
    args[0] = name;
    args[1] = img;
    apiCall.run();
  }

  public void sprite(String name) {
    sprite(name, name);
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

  public void setup(PApplet p, Runnable api) {
    this.app = p;
    this.apiCall = api;

    // Start doesn't exist in this file alone,
    // but should be there after generator processes
    // plugin.
    start();
  }
}