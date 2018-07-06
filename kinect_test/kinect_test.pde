import KinectPV2.*;
KinectPV2 kinect;

import processing.sound.*;
SoundFile whaleSound;
SoundFile rainSound;

PImage img;
PImage img1;
PImage img2;
PImage img3;

PImage imgWhalePlaying;
PImage imgRainPlaying;
PImage imgAllPlaying;
PImage imgNonePlaying;

PImage infra;
PImage infra1;

int offset = 600;

boolean playingWhale = false;
boolean playingRain = false;

InteractiveButton button1;
InteractiveButton button2;

boolean tempStatus = true;

class InteractiveButton {
  int _left;
  int _top;
  int _width;
  int _height;
  
  int _accumDensity = 0;
  int _minDensity = 350;
  
  public boolean _isPressed = false;
  
  
  public InteractiveButton(int _left, int _top, int _width, int _height) {
    this._left = _left;
    this._top = _top;
    this._width = _width;
    this._height = _height;
  }
  
  public void draw() {
    noFill();
    stroke(color(255, 0, 0));
    rect(this._left, this._top, this._width, this._height);
  }
  
  public boolean isPressed() {
    for (int i = this._left; (i < img.width) && (i < this._left + this._width); i++) {
      for (int j = this._top; (j < img.height) && (j < this._top + this._height); j++) {
        int index = (i + offset) + (j + offset) * img.width;
        if (img.pixels[index] == color(255, 255, 255)) {
          this._accumDensity += 1;
        }
      }
    }
    
    if (!_isPressed && (this._minDensity < this._accumDensity)) {
      _isPressed = true;
      this._accumDensity = 0;
      return true;
    }
    return false;
  }
  
  public void update() {
    boolean isFound = false;
    for (int i = this._left; (i < img.width) && (i < this._left + this._width); i++) {
      for (int j = this._top; (j < img.height) && (j < this._top + this._height); j++) {
        int index = (i + offset) + (j + offset) * img.width;
        if (img.pixels[index] == color(255, 255, 255)) {
          isFound = true;
        }
      }
    }
    
    if (_isPressed && !isFound) {
      this._isPressed = false;
      this._accumDensity = 0;
    }
  }
  
  public void reset() {
    this._accumDensity = 0;
  }
}

void setup(){
  //size(1536, 848); //512*424
  noCursor();
  fullScreen();
  kinect =new KinectPV2(this);
  kinect.enableDepthMaskImg(true);
  kinect.enableInfraredImg(true);
  kinect.enableInfraredLongExposureImg(true);
  //kinect.activateRawDepth(true);
  kinect.init();
  
  //img2 = createImage(512, 424, RGB);
  //img3 = createImage(512, 424, RGB);
  
  button1 = new InteractiveButton(220, 720, 200, 200);
  
  button2 = new InteractiveButton(860, 720, 200, 200);
  
  imgWhalePlaying = loadImage("playing-whale.png");
  imgRainPlaying = loadImage("playing-rain.png");
  imgAllPlaying = loadImage("playing-all.png");
  imgNonePlaying = loadImage("stop-all.png");
  
  whaleSound = new SoundFile(this, "sound-whale.wav");
  rainSound = new SoundFile(this, "sound-rain.wav");
}


void draw(){
  infra1 = kinect.getInfraredImage();
  infra = createImage(512, 424, RGB);
  
  for(int i = 0; i < infra1.pixels.length; i++) {
    if ( brightness(infra1.pixels[i]) < 30) {
      infra.pixels[i] = color(255, 255, 255);
    } else {
      infra.pixels[i] = color(0, 0, 0);
    }
  }
  
  
  //4500
  int[] rawData = kinect.getRawDepthData();  // [0-4500]
  //int[] rawData = kinect.getRawDepth256Data();  // [0-4500]
  float[] meterData = new float[512*424];  // meter converted data.
  
  // Convert raw depth values into meter values
  for (int i = 0; i < rawData.length; i++) {
    //meterData[i] = rawDepthToMeters(rawData[i]);
    meterData[i] = rawData[i];
  }
 
  img3 = img2;
  img2 = img1;
  
  img1 = createImage(512, 424, RGB);
  //img2 = createImage(512, 424, RGB);
  //img3 = createImage(512, 424, RGB);
  
  int minDepth = 950;
  int maxDepth = 980;
  
  // Draw an image.
  for(int i = 0; i < img1.pixels.length; i++) {
    if (meterData[i] <= minDepth) {
      img1.pixels[i] = color(0, 0, 0);
    } else if (meterData[i] > minDepth && meterData[i] < maxDepth) {
      //float a = lerp(200, 255, (meterData[i] - 770) / (800 - 770));
      img1.pixels[i] = color(255, 255, 255);
    } else {
      img1.pixels[i] = color(0, 0, 0);
    }
  }
  
  img = createImage(512, 424, RGB);

  if (img2 != null && img3 != null) {
    for (int i = 0; i < img.width; i++) {
      for (int j = 0; j < img.height; j++) {
        int index = i + j * img.width;
        int reversedIndex = (img.width - i - 1) + j * img.width;
        if (
            (img1.pixels[index] == img2.pixels[index]) && 
            (img2.pixels[index] == img3.pixels[index]) && 
            (img3.pixels[index] == img1.pixels[index])
        ) {
          if ((img1.pixels[index] == color(255, 255, 255)) && (infra.pixels[index] == color(255, 255, 255))) {
            img.pixels[reversedIndex] = color(255, 255, 255);
          } else {
            img.pixels[reversedIndex] = color(0, 0, 0);
          }
        } else {
          img.pixels[reversedIndex] = color(0, 0, 0);
        }
      }
    }
    
    //for(int i = 0; i < img.pixels.length; i++) {
    //  //println(img1.pixels[i] + " | " + img2.pixels[i] + " | " + img3.pixels[i]);
    //  if (
    //      (img1.pixels[i] == img2.pixels[i]) && 
    //      (img2.pixels[i] == img3.pixels[i]) && 
    //      (img3.pixels[i] == img1.pixels[i])
    //  ) {
    //    if ((img1.pixels[i] == color(255, 255, 255)) && (infra.pixels[i] == color(255, 255, 255))) {
    //      img.pixels[i] = color(255, 255, 255);
    //    } else {
    //      img.pixels[i] = color(0, 0, 0);
    //    }
    //  } else {
    //    img.pixels[i] = color(0, 0, 0);
    //  }
    //}
  }
  
  img.resize(2850, 2800);
  //image(img, -offset, -offset);
  
  //pushMatrix();
  //translate(1024, 424);
  //scale(-1, 1);
 
  //image(infra,-512,0);
  //popMatrix();
  
  //fill(color(255, 255, 255));
  //stroke(color(0, 0, 0, 0));
  //rect(0, 0, 512, 424);
  
  //if (tempStatus) {
  //  button1.draw();
  //  if (button1.isPressed()) {
  //    button1.reset();
  //    button2.reset();
  //    tempStatus = !tempStatus;
  //  }
  //} else {
  //  button2.draw();
  //  if (button2.isPressed()) {
  //    button1.reset();
  //    button2.reset();
  //    tempStatus = !tempStatus; 
  //  }
  //}
  
  if (!playingWhale && !playingRain) {
    image(imgNonePlaying, 0, 0, 1280, 1024);
    
    
  } else if (playingWhale && !playingRain) {
    image(imgWhalePlaying, 0, 0, 1280, 1024);
    
    
  } else if (!playingWhale && playingRain) {
    image(imgRainPlaying, 0, 0, 1280, 1024);
    
    
  } else if (playingWhale && playingRain) {
    image(imgAllPlaying, 0, 0, 1280, 1024);
  }
 
  
  button1.update();
  button2.update();
  
  if (button1.isPressed()) {
    if (!playingWhale) {
      playingWhale = true;
      whaleSound.play();
    } else {
      playingWhale = false;
      whaleSound.stop();
    }
  }
  
  if (button2.isPressed()) {
    if (!playingRain) {
      playingRain = true;
      rainSound.play();
    } else {
      playingRain = false;
      rainSound.stop();
    }
  }
}

//float rawDepthToMeters(int depthValue) {
//  return 0.1236 * tan(depthValue / 2842.5 + 1.1863);
//  //return 1.0 / (depthValue * -0.0030711016 + 3.3309495161);
//}
