import gab.opencv.*;

import processing.video.*;

Capture cam;


PImage whale_left, whale_right,rex;
int imagesize = 200;
OpenCV opencv;

ArrayList<Contour> contours;
ArrayList<Contour> polygons;

void setup() {
  
  size(960, 540);
  
  cam = new Capture(this, 960, 540, 24);
  cam.start();
  
  opencv = new OpenCV(this, 960, 540);
  
  whale_left = loadImage("whale_left.png");
  whale_right= loadImage("whale_right.png"); 
  rex = loadImage("rex.png"); 
  
  //opencv = new OpenCV(this, src);

  
  //dst = opencv.getOutput();

  //contours = opencv.findContours();
  //println("found " + contours.size() + " contours");
}

void draw() {
  if(cam.available()) {
    cam.read();
  }
  image(cam, 0, 0);
  
  opencv.loadImage(cam);
  
  opencv.gray();
  opencv.threshold(100);
  
  contours = opencv.findContours();
  println("found " + contours.size() + " contours");
  
  //scale(0.5);
  //image(src, 0, 0);
  //image(dst, src.width, 0);

  noFill();
  strokeWeight(3);
  
  for (Contour contour : contours) {
    stroke(0, 0, 0);
    contour.draw();
    
    
    
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    if (points.size() == 3) { // Triangle
      if ((points.get(0).dist(points.get(1)) > 25) && points.get(1).dist(points.get(2)) > 25) {
        float totalX = 0f;
        float totalY = 0f;
        
        stroke(255, 255, 255);
        beginShape();
        for (PVector point : points) {
          vertex(point.x, point.y);
          totalX += point.x;
          totalY += point.y;
        }
        vertex(points.get(0).x, points.get(0).y);
        endShape();
        
        fill(255, 255, 255);
        text("Triangle", int(totalX / 3f), int(totalY / 3f));
        image(rex, int(totalX / 3f) - imagesize/2, int(totalY / 3f) - imagesize/2, imagesize, imagesize);
        noFill();
      }
    }
    
    if (points.size() == 4) { // Rectangle
      if ((points.get(0).dist(points.get(1)) > 25) && points.get(1).dist(points.get(2)) > 25) {
        float totalX = 0f;
        float totalY = 0f;
        
        //stroke(255, 255, 255);
        //beginShape();
        for (PVector point : points) {
          //vertex(point.x, point.y);
          totalX += point.x;
          totalY += point.y;
        }
        //vertex(points.get(0).x, points.get(0).y);
        //endShape();
        
        PVector center = new PVector(int(totalX / 4f), int(totalY / 4f));
        
        fill(255, 255, 255);
        
        
        if (center.x < 540) {
          //text("Default", center.x, center.y);
          image(whale_left, center.x - imagesize/2, center.y - imagesize/2, imagesize, imagesize);
        } else {
          //text("Flipped", center.x, center.y);
          //pushMatrix();
          //scale(-1, 1);
          image(whale_right, center.x - imagesize/2, center.y - imagesize/2, imagesize, imagesize);
          //popMatrix();
        }
        
        
        noFill();
      }
    }
    
  }
}
