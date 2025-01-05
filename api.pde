
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
        
        // moveSprite(String name, float x, float y)
        case 5:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offmove((float)args[1], (float)args[2]);
        break;
        
        // getTime()
        case 6:
        if (timewayEngine.currScreen instanceof Sketchpad) {
          Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
          return sk.getTime();
        }
        else return 0.;
        
        // getDelta()
        case 7:
        if (timewayEngine.currScreen instanceof Sketchpad) {
          Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
          return sk.getDelta();
        }
        return timewayEngine.display.getDelta();
        
        // getTimeSeconds()
        case 8:
        return timewayEngine.display.getTimeSeconds();
        
        // getSpriteX(String name)
        case 9:
        return timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).getX();
        
        // getSpriteY(String name)
        case 10:
        return timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).getY();

        // img(String imgName, float x, float y)
        case 11:
        timewayEngine.display.img((String)args[0], (float)args[1], (float)args[2]);
        break;
        
        // scaleSprite(String name, float wi, float hi)
        case 12:
        // X scale
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offsetWidth(int((float)args[1]));
        // Y scale
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offsetHeight(int((float)args[2]));
        break;
        
        // spriteBop(String name, float amount)
        case 13:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).bop(int((float)args[1]));
        break;
        
        // getPath()
        case 14:
        if (timewayEngine.currScreen instanceof Sketchpad) {
          Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
          return sk.getPath();
        }
        return "";
        
        // getPathDirectorified()
        case 15:
        if (timewayEngine.currScreen instanceof Sketchpad) {
          Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
          return sk.getPathDirectorified();
        }
        return "";
        
        // getImg(String name);
        case 16: {
          PImage img = timewayEngine.display.getImg((String)args[0]);
          if (img == null) return timewayEngine.display.errorImg;
          else return img;
        }
        
        // largeImg(String name, float x, float y, float w, float h)
        case 17: {
          PImage img = timewayEngine.display.getImg((String)args[0]);
          
          // Bit of error checking
          if (img == null) return timewayEngine.display.errorImg;
          if (timewayEngine.currScreen instanceof Sketchpad) {
          }
          else break;
          
          timewayEngine.display.img(img, (float)args[1], (float)args[2], (float)args[3], (float)args[4]);
          timewayEngine.console.warn("largeImg() is depricated.");
          break;
        }
        
        // beat()
        case 18: {
          return timewayEngine.sound.beat;
        }
        
        // step()
        case 19: {
          return timewayEngine.sound.step;
        }
        
        // beatSaw(int beatoffset, int stepoffset, int everyxbeat)
        case 20: {
          return timewayEngine.sound.beatSaw((int)args[0], (int)args[1], (int)args[2]);
        }
        
        // stepSaw()
        case 21: {
          return timewayEngine.sound.beatSaw();
        }
        
        // beatToTime()
        case 22: {
          return timewayEngine.sound.beatToTime(((int)args[0])-1);
        }
        
        // beatToTime()
        case 23: {
          return timewayEngine.sound.beatToTime(((int)args[0])-1, ((int)args[1])-1);
        }
        
        // shaderUniforms(params...)
        case 24: {
          if (timewayEngine.currScreen instanceof Sketchpad) {
            Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
            
            
            int l = (int)args[0];
            
            if (sk.shaderParams == null || sk.shaderParams.length != l) {
              sk.shaderParams = new Object[l];
            }
            
            for (int i = 0; i < l; i++) {
              // Copy data cus we don't want problem with args object being the same in API and sketchpad.
              sk.shaderParams[i] = args[i+1];
            }
          }
          break;
        }
        
        // keyDown(key)
        case 25: {
          char c = (char)args[0];
          return timewayEngine.input.keyDown(c);
        }
          
        // keyOnce(key)
        case 26: {
          char c = (char)args[0];
          return timewayEngine.input.keyDownOnce(c);
        }
          
        // toClipboard(text)
        case 27: {
          String text = (String)args[0];
          timewayEngine.clipboard.copyString(text);
          break;
        }
        
        // getAutoFloatTest()
        case 28: {
          if (timewayEngine.currScreen instanceof Sketchpad) {
            //Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
            
            return 0f;
          }
          break;
        }
        
        // getAutoFloat()
        case 29: {
          if (timewayEngine.currScreen instanceof Sketchpad) {
            Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
            return sk.getAutoFloat((String)args[0]);
          }
          return 0f;
        }
        
        // getBPM()
        case 30: {
          if (timewayEngine.currScreen instanceof Sketchpad) {
            Sketchpad sk = (Sketchpad)timewayEngine.currScreen;
            return sk.getBMP();
          }
          return 1f;
        }
        
        // spriteV0()
        case 31:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offvertex(0, (float)args[1], (float)args[2]);
        break;
        
        // spriteV1()
        case 32:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offvertex(1, (float)args[1], (float)args[2]);
        break;
        
        // spriteV2()
        case 33:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offvertex(2, (float)args[1], (float)args[2]);
        break;
        
        // spriteV3()
        case 34:
        timewayEngine.ui.currentSpritePlaceholderSystem.
        getSprite((String)args[0]).offvertex(3, (float)args[1], (float)args[2]);
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
