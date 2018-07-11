import KinectPV2.*;
import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

KinectPV2 kinect;
OpenCV opencv;

SoundFile whaleSound;
SoundFile rainSound;

ArrayList<Contour> contours;
ArrayList<Contour> polygons;

PImage shapeImage;

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

int minDepth = 950;
int maxDepth = 980;

int shapeMinDepth = 890;
int shapeMaxDepth = 935;

int kinectWidth = 512;
int kinectHeight = 424;
int kinectScaleX = 3150;
int kinectOffsetX = kinectScaleX / 4;
int kinectOffsetY = int(kinectOffsetX * 424f / 512f) - 100;


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
  int _minDensity = 300;
  
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
        int index = (i + kinectOffsetX) + (j + kinectOffsetY) * img.width;
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
        int index = (i + kinectOffsetX) + (j + kinectOffsetY) * img.width;
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
  frameRate(30);
  noCursor();
  fullScreen();
  kinect =new KinectPV2(this);
  kinect.enableDepthMaskImg(true);
  kinect.enableInfraredImg(true);
  kinect.enableInfraredLongExposureImg(true);
  kinect.init();
  
  button1 = new InteractiveButton(220, 720, 200, 200);
  button2 = new InteractiveButton(860, 720, 200, 200);
  
  imgWhalePlaying = loadImage("playing-whale.png");
  imgRainPlaying = loadImage("playing-rain.png");
  imgAllPlaying = loadImage("playing-all.png");
  imgNonePlaying = loadImage("stop-all.png");
  
  whaleSound = new SoundFile(this, "sound-whale.wav");
  rainSound = new SoundFile(this, "sound-rain.wav");
  
  opencv = new OpenCV(this, kinectWidth, kinectHeight);
  //kinectScaleX, int(kinectScaleX * 424f / 512f)
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
  //float[] meterData = new float[512*424];  // meter converted data.
  
  //// Convert raw depth values into meter values
  //for (int i = 0; i < rawData.length; i++) {
  //  //meterData[i] = rawDepthToMeters(rawData[i]);
  //  meterData[i] = rawData[i];
  //}
 
  img3 = img2;
  img2 = img1;
  
  img1 = createImage(512, 424, RGB);
  //img2 = createImage(512, 424, RGB);
  //img3 = createImage(512, 424, RGB);
  
  
  
  // Detect shape image.
  
  shapeImage = createImage(512, 424, RGB);
  
  for (int i = 0; i < shapeImage.width; i++) {
      for (int j = 0; j < shapeImage.height; j++) {
        int index = i + j * shapeImage.width;
        int reversedIndex = (shapeImage.width - i - 1) + j * shapeImage.width;
        
        if (rawData[index] <= shapeMinDepth) {
          shapeImage.pixels[reversedIndex] = color(0, 0, 0);
        } else if (rawData[index] > shapeMinDepth && rawData[index] < shapeMaxDepth) {
          //float a = lerp(200, 255, (meterData[i] - 770) / (800 - 770));
          shapeImage.pixels[reversedIndex] = color(255, 255, 255);
        } else {
          shapeImage.pixels[reversedIndex] = color(0, 0, 0);
        }
      }
  }
  
  opencv.loadImage(shapeImage);
  //opencv.gray();
  //opencv.threshold(0);
  contours = opencv.findContours();
  println("Found " + contours.size() + " contours");
  
  // Draw an image.
  for(int i = 0; i < img1.pixels.length; i++) {
    if (rawData[i] <= minDepth) {
      img1.pixels[i] = color(0, 0, 0);
    } else if (rawData[i] > minDepth && rawData[i] < maxDepth) {
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
  }
  
  //img.resize(kinectScale, kinectScale);
  shapeImage.resize(kinectScaleX, int(kinectScaleX * 424f / 512f));
  image(shapeImage, -kinectOffsetX, -kinectOffsetY);
  
  //image (shapeImage, 0, 0);
  
  noFill();
  strokeWeight(1);
  for (Contour contour : contours) {
    stroke(0, 0, 255);
    contour.draw();
    
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    if (points.size() == 4) { // Rectangle
      if ((points.get(0).dist(points.get(1)) > 25) && points.get(1).dist(points.get(2)) > 25) {
        stroke(255, 0, 0);
        beginShape();
        for (PVector point : points) {
          vertex(point.x, point.y);
        }
        vertex(points.get(0).x, points.get(0).y);
        endShape();
      }
    }
    
    
  }
}
