
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
