import KinectPV2.*;
import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

KinectPV2 kinect;
OpenCV opencv;

int kinectExecuteFrame = 0;
int kinectCurrentFrame = 0;

int kinectWidth = 512;
int kinectHeight = 424;
int kinectScaleX = 1550;
int kinectOffsetX = int(kinectScaleX / 3.9f);
int kinectOffsetY = int(kinectOffsetX * kinectHeight / float(kinectWidth)) - (kinectScaleX / 28);

ArrayList<Contour> contours;
ArrayList<Contour> polygons;

PImage shapeImage;

  
PFont myFont;

PImage img;
PImage img1;
PImage img2;
PImage img3;

PImage depth;
PImage infra;
PImage infra1;

int minDepth = 1190;
int maxDepth = 1200;
int infraThreshold = 20;

int shapeMinDepth = 1000;
int shapeMaxDepth = 1050;

Face face1;
Face face2;
Connect connect;

class Connect {
  Face _face1;
  Face _face2;
  public Connect(Face face1, Face face2) {
    this._face1 = face1;
    this._face2 = face2;
  }
  
  public void draw() {
    PVector location1 = this._face1.getPosition();
    PVector location2 = this._face2.getPosition();
    line(location1.x, location1.y, location2.x, location2.y);
    
    if (location1.dist(location2) < 200f) {
      background(color(255, 255, 255));
    } else if (location1.dist(location2) < 500f) {
      background(color(255, 0, 0));
    } else if (location1.dist(location2) < 800f) {
      background(color(0, 255, 0));
    } else {
      background(color(0, 0, 255));
    }
    
    
    textSize(32);
    fill(255);
    text(location1.dist(location2), width / 2, height - 100);
  }
}

class Face {
  float _angle;
  PVector _position;
  PImage _image;
  PVector _scale;
  
  public Face(PImage image) {
    this._image = image;
    this._angle = 0;
    this._position = new PVector(0, 0);
    this._scale = new PVector(0, 0);
    
    //this._image.filter(GRAY);
    //this._image.filter(INVERT);
    //this._image.filter(POSTERIZE, 8);
  }
  
  public void update(PVector[] rect) {
    if (rect[1].x > 0 && rect[1].x < width && rect[1].y > 0 && rect[1].y < height) {
      this._scale = new PVector(int(dist(rect[0].x, rect[0].y, rect[1].x, rect[1].y)), int(dist(rect[1].x,rect[1].y, rect[2].x, rect[2].y)));
      this._angle = acos((rect[3].x - rect[2].x) / dist(rect[3].x,rect[3].y, rect[2].x, rect[2].y));
      
      this._position = new PVector(rect[1].x, rect[1].y);
    }
  }
  
  public void draw() {
    
    //this._currentPosition = PVector.lerp(this._currentPosition, this._targetPosition, 0.05);
    
    pushMatrix();
    translate(this._position.x, this._position.y);
    rotate(-this._angle);
    scale(this._scale.x / this._image.width, this._scale.y / this._image.height);
    
    textFont(myFont);
    textAlign(CENTER, CENTER);
  
    tint(255, 0, 255);
    
    image(this._image, 0, 0);
    popMatrix();
    //drawCircle();
  }
  
  public void drawCircle() {
    pushMatrix();
    //this._image.resize(int(this._scale.x), int(this._scale.y));
    translate(this._position.x, this._position.y);
    rotate(-this._angle);
    
    ellipseMode(CORNER);
    stroke(color(255, 0, 0));
    strokeWeight(10);
    noFill();
    ellipse(0, 0, 500, 500);
    popMatrix();
  }
  
  public PVector getPosition() {
    return this._position;
  }
}

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
  noCursor();
  fullScreen();
  kinect =new KinectPV2(this);
  kinect.enableDepthMaskImg(true);
  kinect.enableInfraredImg(true);
  kinect.enableInfraredLongExposureImg(true);
  kinect.init();
 
  face1 = new Face(loadImage("jojo.jpg"));
  face2 = new Face(loadImage("ananya.jpg"));
  connect = new Connect(face1, face2);
  
  
  opencv = new OpenCV(this, kinectWidth, kinectHeight);
  myFont = createFont("Georgia", 32);
  //kinectScaleX, int(kinectScaleX * 424f / 512f)
}


void draw(){
  println(frameRate);
  background(color(255, 255, 255));
  
  face1.draw();
  face2.draw();
  
  //depth = kinect.getDepthImage(); 
  int[] rawData = kinect.getRawDepthData();  // [0-4500]
  
  // Detect shape image.
  shapeImage = createImage(512, 424, RGB);
  
  for (int i = 0; i < shapeImage.width; i++) {
    for (int j = 0; j < shapeImage.height; j++) {
      
      int index = i + j * shapeImage.width;
      int reversedIndex = (i) + (shapeImage.height - j - 1) * shapeImage.width;
      
      //int index = i + j * shapeImage.width;
      //int reversedIndex = (shapeImage.width - i - 1) + j * shapeImage.width;
      
      if (rawData[index] <= shapeMinDepth) {
        shapeImage.pixels[reversedIndex] = color(0, 0, 0);
      } else if (rawData[index] > shapeMinDepth && rawData[index] < shapeMaxDepth) {
        shapeImage.pixels[reversedIndex] = color(255, 255, 255);
      } else {
        shapeImage.pixels[reversedIndex] = color(0, 0, 0);
      }
    }
  }


  //image(shapeImage, 0, 0);
  stroke(0);
  text(frameRate, 10, 30);
  
  opencv.loadImage(shapeImage);
  opencv.gray();
  opencv.threshold(100);
  contours = opencv.findContours();
  //println("Found " + contours.size() + " contours");
  noFill();
  //strokeWeight(1);
  for (Contour contour : contours) {
    //stroke(0, 0, 0);
    //contour.draw();
    
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    if (points.size() == 4) { // Rectangle
      
      if ((points.get(0).dist(points.get(1)) > 5) && points.get(1).dist(points.get(2)) > 5) {
        //if ((points.get(0).dist(points.get(1)) < 25) && points.get(1).dist(points.get(2)) < 25) {
          stroke(0);
          text("RECT IS DETECTED", 10, 10);
          
          //fill(color(255, 0, 0));
          //beginShape();
          
          PVector[] rect = new PVector[4];
          
          for (int i = 0; i < points.size(); i++) {
            rect[i] = new PVector(points.get(i).x * (kinectScaleX / (float)kinectWidth) - kinectOffsetX, points.get(i).y * ((kinectScaleX * kinectHeight / float(kinectWidth)) / kinectHeight) - kinectOffsetY);
          }
          
          //for (int i = 0; i < rect.length; i++) {
          //  vertex(rect[i].x, rect[i].y);
          //}
          //vertex(rect[rect.length-1].x, rect[rect.length-1].y);
          //endShape();
          
          if (rect[1].x < width * 0.5) {
            face1.update(rect);
          } else {
            face2.update(rect);
          }
        //}
      }
    }
  }
  
  // Code for touch detection.
  infra1 = kinect.getInfraredImage();
  infra = createImage(512, 424, RGB);
  
  for (int i = 0; i < infra1.width; i++) {
    for (int j = 0; j < infra1.height; j++) {
      int index = i + j * infra1.width;
      int reversedIndex = (i) + (infra1.height - j - 1) * infra1.width;
      if ( brightness(infra1.pixels[index]) < infraThreshold) {
        infra.pixels[reversedIndex] = color(255, 255, 255);
      } else {
        infra.pixels[reversedIndex] = color(0, 0, 0);
      }
    }
  }
  
  img3 = img2;
  img2 = img1;
  
  img1 = createImage(512, 424, RGB);
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
  
  
  /*
  background(color(255, 255, 255));
  
  connect.draw();
  face1.draw();
  face2.draw();
  
  
  kinectCurrentFrame++;
  
  if (kinectCurrentFrame >= kinectExecuteFrame) {
    kinectCurrentFrame = 0;
    
    int[] rawData = kinect.getRawDepthData();  // [0-4500]
  
    // Detect shape image.
    shapeImage = createImage(512, 424, RGB);
    
    for (int i = 0; i < shapeImage.width; i++) {
      for (int j = 0; j < shapeImage.height; j++) {
        int index = i + j * shapeImage.width;
        int reversedIndex = (shapeImage.width - i - 1) + j * shapeImage.width;
        
        if (rawData[index] <= shapeMinDepth) {
          shapeImage.pixels[reversedIndex] = color(0, 0, 0);
        } else if (rawData[index] > shapeMinDepth && rawData[index] < shapeMaxDepth) {
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
    //println("Found " + contours.size() + " contours");
    noFill();
    //strokeWeight(1);
    for (Contour contour : contours) {
      //stroke(0, 0, 255);
      //contour.draw();
      
      ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
      if (points.size() == 4) { // Rectangle
        if ((points.get(0).dist(points.get(1)) > 25) && points.get(1).dist(points.get(2)) > 25) {
          if ((points.get(0).dist(points.get(1)) < 50) && points.get(1).dist(points.get(2)) < 50) {
            //fill(color(255, 255, 255));
            //beginShape();
            
            PVector[] rect = new PVector[4];
            
            for (int i = 0; i < points.size(); i++) {
              rect[i] = new PVector(points.get(i).x * (kinectScaleX / (float)kinectWidth) - kinectOffsetX, points.get(i).y * ((kinectScaleX * kinectHeight / float(kinectWidth)) / kinectHeight) - kinectOffsetY);
            }
            
            //for (int i = 0; i < rect.length; i++) {
            //  vertex(rect[i].x, rect[i].y);
            //}
            //vertex(rect[rect.length-1].x, rect[rect.length-1].y);
            //endShape();
            
            if (rect[1].x < width * 0.5) {
              face1.update(rect);
            } else {
              face2.update(rect);
            }
          }
        }
      }
    }
    
    // Code for touch detection.
    infra1 = kinect.getInfraredImage();
    infra = createImage(512, 424, RGB);
    
    for(int i = 0; i < infra1.pixels.length; i++) {
      if ( brightness(infra1.pixels[i]) < 30) {
        infra.pixels[i] = color(255, 255, 255);
      } else {
        infra.pixels[i] = color(0, 0, 0);
      }
    }
    
    
    img3 = img2;
    img2 = img1;
    
    img1 = createImage(512, 424, RGB);
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
    
    
    
    //img.resize(kinectScaleX, int(kinectScaleX * 424f / 512f));
    //image(img, -kinectOffsetX, -kinectOffsetY);
    
  }
  
  */
  
  
  
  /*
  
  
  
  
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
  
  
  
  
  
  opencv.loadImage(shapeImage);
  //opencv.gray();
  //opencv.threshold(0);
  contours = opencv.findContours();
  //println("Found " + contours.size() + " contours");
  
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
  
  
  
  //image(shapeImage, -kinectOffsetX, -kinectOffsetY);
  
  //image (shapeImage, 0, 0);
  
  noFill();
  //strokeWeight(1);
  for (Contour contour : contours) {
    //stroke(0, 0, 255);
    //contour.draw();
    
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    if (points.size() == 4) { // Rectangle
      if ((points.get(0).dist(points.get(1)) > 25) && points.get(1).dist(points.get(2)) > 25) {
        if ((points.get(0).dist(points.get(1)) < 50) && points.get(1).dist(points.get(2)) < 50) {
          //fill(color(255, 255, 255));
          //beginShape();
          
          PVector[] rect = new PVector[4];
          
          for (int i = 0; i < points.size(); i++) {
            rect[i] = new PVector(points.get(i).x * (kinectScaleX / (float)kinectWidth) - kinectOffsetX, points.get(i).y * ((kinectScaleX * kinectHeight / float(kinectWidth)) / kinectHeight) - kinectOffsetY);
          }
          
          //for (int i = 0; i < rect.length; i++) {
          //  vertex(rect[i].x, rect[i].y);
          //}
          //vertex(rect[rect.length-1].x, rect[rect.length-1].y);
          //endShape();
          
          if (rect[1].x < width * 0.5) {
            face1.update(rect);
          } else {
            face2.update(rect);
          }
        }
      }
    }
  }
  */
  
  
}
