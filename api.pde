
// TimeWay's Interfacing Toolkit


public Object runTWIT(int opcode, Object[] args) {
  try {
    
    // Here, our list of API calls. 
      switch (opcode) {
        // test(int value)
        case 1:
        int val = (int)args[0];
        String mssg = "Hello World "+val;
        timewayEngine.console.log(mssg);
        return mssg;
        
        // sprite(String name, String img)
        case 2:
        timewayEngine.ui.currentSpritePlaceholderSystem.sprite((String)args[0], (String)args[1]);
        break;
        
        // print(Object[] args...)
        case 3:
        // print function can have unlimited args
        // First arg is the size of the args list.
        int len = min((int)args[0], 127);
        String message = "";
        for (int i = 1; i < len; i++) {
          String element = "";
          if (args[i] instanceof String) {
            element = (String)args[i];
          }
          else if (args[i] instanceof Integer) {
            element = str((int)args[i]);
          }
          else if (args[i] instanceof Float) {
            element = str((float)args[i]);
          }
          else if (args[i] instanceof Long) {
            element = str((long)args[i]);
          }
          else if (args[i] instanceof Boolean) {
            element = str((boolean)args[i]);
          }
          else {
            if (args[i] != null) element = args[i].getClass().getSimpleName();
          }
          message += (element + " ");
        }
        timewayEngine.console.log(message);
        break;
        
        case 4:
        timewayEngine.console.warn((String)args[0]);
        break;
        
        // moveSprite(float x, float y)
        case 5:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offmove((float)args[1], (float)args[2]);
        break;
        
        // getTime()
        case 6:
        return timewayEngine.display.getTime();
        
        // getDelta()
        case 7:
        return timewayEngine.display.getDelta();
        
        // getTimeSeconds()
        case 8:
        return timewayEngine.display.getTimeSeconds();
        
        

        
        
        default:
        timewayEngine.console.warn("Unknown opcode "+opcode);
        break;
      }
      
      
      
      
      
  }
  // Typically a bug in the boilerplate or here.
  catch (IndexOutOfBoundsException e) {
    
  }
  return null;
}
