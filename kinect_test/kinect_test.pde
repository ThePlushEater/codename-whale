import KinectPV2.*;
KinectPV2 kinect;

PImage img;
PImage img1;
PImage img2;
PImage img3;

PImage infra;
PImage infra1;


void setup(){
  size(1024,424); //512*424
  kinect =new KinectPV2(this);
  kinect.enableDepthMaskImg(true);
  kinect.enableInfraredImg(true);
  kinect.enableInfraredLongExposureImg(true);
  //kinect.activateRawDepth(true);
  kinect.init();
  
  //img2 = createImage(512, 424, RGB);
  //img3 = createImage(512, 424, RGB);
}


void draw(){
  infra1 = kinect.getInfraredImage();
  infra = createImage(512, 424, RGB);
  
  for(int i = 0; i < infra1.pixels.length; i++) {
    if ( brightness(infra1.pixels[i]) > 20) {
      infra.pixels[i] = color(255, 255, 255);
    } else {
      infra.pixels[i] = color(0, 0, 0);
    }
  }
  
  image(infra,0,0);
  
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
  
  // Draw an image.
  for(int i = 0; i < img1.pixels.length; i++) {
    if (meterData[i] <= 770) {
      img1.pixels[i] = color(0, 0, 0);
    } else if (meterData[i] > 770 && meterData[i] < 800) {
      //float a = lerp(200, 255, (meterData[i] - 770) / (800 - 770));
      img1.pixels[i] = color(255, 255, 255);
    } else {
      img1.pixels[i] = color(0, 0, 0);
    }
  }
  
  img = createImage(512, 424, RGB);

  if (img2 != null && img3 != null) {
    for(int i = 0; i < img.pixels.length; i++) {
      //println(img1.pixels[i] + " | " + img2.pixels[i] + " | " + img3.pixels[i]);
      if (
          (img1.pixels[i] == img2.pixels[i]) && 
          (img2.pixels[i] == img3.pixels[i]) && 
          (img3.pixels[i] == img1.pixels[i])
      ) {
        if ((img1.pixels[i] == color(255, 255, 255)) && (infra.pixels[i] == color(255, 255, 255))) {
          img.pixels[i] = color(255, 255, 255);
        } else {
          img.pixels[i] = color(0, 0, 0);
        }
      } else {
        img.pixels[i] = color(0, 0, 0);
      }
    }
  }
  
  image(img, 512, 0);
}

float rawDepthToMeters(int depthValue) {
  return 0.1236 * tan(depthValue / 2842.5 + 1.1863);
  //return 1.0 / (depthValue * -0.0030711016 + 3.3309495161);
}
