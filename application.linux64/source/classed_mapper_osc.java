import processing.core.*; 
import processing.data.*; 
import processing.opengl.*; 

import oscP5.*; 
import netP5.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class classed_mapper_osc extends PApplet {




// semipermamapper v2
//
// based on:
//mipmap, a quick mappign system.
// ephemeral mapper
// from version by maxD 20130917
//
// version 2:
// adding saving and loading xml feature
// version 2.1:
// adding ascii char pixelbrush
// rfboyce@gmail.com 20130923

// todo list:
//
//threading? management - render - other?
//
//step mode with9 external inconsistent slow clock

// note: 
//arrow keys and mouse to map.


OscP5 oscP5;
NetAddress myRemoteLocation;


ArrayList<MPoint> points;
XML xml;
float distance = 0.1f;
int sizer = 10;
int trailmix = 10;
int current = 0;
int groupCol = 0;
float colOffset = 0;

//renderer settings
int motionMode = 1; 
int shpMode = 1;
int colMode = 1;

int motionNum = 3;
int shpNum = 3;
int colNum = 3;

boolean doMapping = true;
boolean mouseEnabled = true;
boolean trails = true;
//boolean doFill = false;

//0 is blackPoints, 1 is all,
int groupIndex = 2;
int selectedGroup = 1;

// 0 blackout, 1 edit, 2 rainbow kittens.

int px = 0;
int py = 0;

int x1 = 0;
int x2 = 0;
int y1 = 0;
int y2 = 0;

int pcol = color(0, 0, 0);

int shift = 0;
PFont font;



public void setup() {

  size(1034, 778, P3D);
  oscP5 = new OscP5(this, 4567);
  points = new ArrayList();
  smooth();
  noCursor();
  colorMode(HSB, 360, 100, 100);
  background(0);
  font = createFont("Georgia", 24);
  blackPoint();
  //blackPoint();
}

public void draw() {
  // draw background
  drawBackground();
  // render lines
  render();
}

///////////////////   Render Loop \\\\\\\\\\\\\\\\\\\\\\
public void render() {
  // mapping Mode 
  if (doMapping) {
    // add line to cursor
    placePoint();
    // set mousePosition
    if (mouseEnabled) {
      px=mouseX;
      py=mouseY;
    }
    crossHair(px, py);
  }
  if (points.size()>2) {
    for (int i = points.size()-1; i > 2; i--) {
      int j = i - 1;
      if (points.get(i).groupID>0) { // black points have groupIndex=255
        //current point
        current = i;
        // determine coordinates for current line
        x1 = PApplet.parseInt(points.get(j).pointPosition.x);
        y1 = PApplet.parseInt(points.get(j).pointPosition.y);
        x2 = PApplet.parseInt(points.get(i).pointPosition.x);
        y2 = PApplet.parseInt(points.get(i).pointPosition.y);  

        if (selectedGroup!=1 && selectedGroup == points.get(i).groupID) {
          groupHighlight();
        }
        // get the point animationSpeed of current line
        distance = points.get(i).animationStep();
        if (points.get(i).singleShot && distance>1) break;
        motionMode = points.get(i).motionMode;
        shpMode = points.get(i).shpMode;
        colMode = points.get(i).colMode;
        sizer = points.get(i).sizer;
        // render line 
        // mapping mode
        if (doMapping) mapping();
        // group select mode
        else animationSelector();
      }
      //  if (doFill) filler();
    }
    // if in mapping Mode, remove line to cursor
    if (doMapping) removePoint();
  }
}
///////////////////   movement    \\\\\\\\\\\\\\\\\\\\\\

public void animationSelector() {
  switch(motionMode) {
  case 0:
    polka();
    break;
  case 1:
    dotted();
    break;
  case 2:
    linnen();
    break;
  }
}


public void filler() {
  for (int i = points.size()-1; i > 1; i--) {
    int ha = PApplet.parseInt(points.get(i).pointPosition.z);
    noStroke();
    fill(0, 0, 100);
    beginShape();
    while (points.get (i).pointPosition.z==ha) {
      vertex(points.get(i).pointPosition.x, points.get(i).pointPosition.y);
      if (i>0)i--;
      else break;
    }
    endShape(CLOSE);
  }
}


public void polka() {
  thingner(PApplet.parseInt(x1+distance*(x2-x1)), PApplet.parseInt(y1+distance*(y2-y1)));
}

public void dotted() {
  int n = 24;
  //adjust number of dots:
  int l = PApplet.parseInt(sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)));
  n=l/(points.get(current).sizer*5);
  for (float k = 0; k<n;k++) {  
    float e = (distance+k)/n;    
    thingner(PApplet.parseInt(x1+e*(x2-x1)), PApplet.parseInt(y1+e*(y2-y1)));
  }
}



/////// STUFF THAT MAKES PIXELS CHANGE COLOR  \\\\\\\\\\\\

///////////////////  things
public void thingner(int xx, int yy) {
  switch(shpMode) {
  case 0:
    pnt(xx, yy);
    break;
  case 1:
    arrow(xx, yy);
    break;
  case 2:
    liner(xx, yy);
    break;
  case 3:
    ascii(xx, yy);
    break;
  }
}

public int colorizer() {
  colOffset+=0.006f;
  int c = color(0, 0, 0);
  switch(colMode) {
  case 0:
    c = color(0, 0, 100);
    break;
  case 1:
    c =  color(points.get(current).pointPosition.z, 100, 100);
    break;
  case 2:
    c =  color(((current*5)+colOffset)%360, 255, 255);
    break;
  }
  return c;
}

public void pnt(int xx, int yy) {
  strokeWeight(sizer);
  stroke(colorizer());
  point(xx, yy);
}

public void liner(int xx, int yy) {
  stroke(colorizer());
  strokeWeight(3);
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  line(0, sizer, 0, -sizer);
  popMatrix();
}

public void arrow(int xx, int yy) {
  stroke(colorizer());
  strokeWeight(3);
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  line(0, 0, sizer, sizer);
  line(0, 0, sizer, -sizer);
  popMatrix();
}

public void ascii(int xx, int yy) {
  textFont(font);
  textAlign(CENTER, CENTER);
  //char letter = char(123);
  char letter = PApplet.parseChar(79);
  char[] letters = {
    'x', 'X'
  };
  letter = letters[PApplet.parseInt(random(0, letters.length))];
  fill(colorizer());
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  text(letter, 0, 0);
  popMatrix();
}

public void linnen() {
  stroke(colorizer());
  strokeWeight(sizer);
  line(x1, y1, x2, y2);
}

// render lines in mapping mode
public void mapping() {
  if (points.get(current).groupID==0) stroke(0, 0, 255); // invisible lines
  else if (points.get(current).groupID==selectedGroup) stroke(255, 0, 255); //current group in white
  else { //any other group in random
    // give each group a different color
    int hueValue = points.get(current).groupID*15;
    // make sure it's not bigger than 100.
    // if it is, subtract 100 till it fits
    while (hueValue > 100) {
      hueValue -= 100;
    }
    stroke(hueValue, 255, 255);
  }
  strokeWeight(2);
  line(x1, y1, x2, y2);
  // if (distance > 1) distance=0;
  ellipse(x1+distance*(x2-x1), y1+distance*(y2-y1), 3, 3);
}

public void groupHighlight() {
  stroke(0, 0, 100);
  strokeWeight(15);
  point(x1, y1);
}

public void crossHair(int xx, int yy) {
  strokeWeight(3);
  stroke(0, 0, 100);
  int out = 20;
  int in = 5;
  if (mouseEnabled) {
    line(xx-out, yy-out, xx-in, yy-in);
    line(xx+out, yy+out, xx+in, yy+in);
    line(xx+out, yy-out, xx+in, yy-in);
    line(xx-out, yy+out, xx-in, yy+in);
  }
  else {
    line(xx-out, yy, xx-in, yy);
    line(xx+out, yy, xx+in, yy);
    line(xx, yy-out, xx, yy-in);
    line(xx, yy+out, xx, yy+in);
  }
}

//////SMALL FUNCTIONS\\\\\\\


public void queue() {
  for (int i = points.size()-1; i > 1; i--) {
    points.get(i).progress = 0;
  }
}

public void drawBackground() {
  if (trails && !doMapping) {
    fill(0, 0, 0, trailmix);
    stroke(0, 0, 0, trailmix);
    rect(0, 0, width, height);
  }
  else {
    background(0);
  }
}

public void placePoint() {
  points.add(new MPoint(px, py, groupCol, groupIndex));
}

public void blackPoint() {
  //removePoint();
  points.add(new MPoint(px, py, 0, 0));
}

public void removePoint() {
  if (points.size()>0) points.remove(points.size()-1);
}

public void newGroup() {
  groupIndex++;
  groupCol = PApplet.parseInt(random(0, 360));
  selectedGroup = groupIndex;
}

///////////////// settings manager  \\\\\\\\\\\\\

public void groupSetter(char cmd, int grp, float val) {
  for (int i = points.size()-1; i > 2; i--) {
    if (points.get(i).groupID>0) { 
      //apply setting to all
      if (grp == 1) {
        setter(cmd, i, val);
      }
      //apply setting to specific group
      else if (points.get(i).groupID == grp) {
        setter(cmd, i, val);
      }
    }
  }
}

public void setter(char cmd, int id, float val) {  
  switch(cmd) {
  case 'f':
    //doFill = !doFill;
  case 'o':
    //points.get(id).sizer-=1;
    points.get(id).sizer = intSetter(points.get(id).sizer, -1, PApplet.parseInt(val));
    break;
  case 'p':
    points.get(id).sizer = intSetter(points.get(id).sizer, 1, PApplet.parseInt(val));
    break;
  case 'q':
    points.get(id).progress = floatSetter(0, 0, val);
    break;
  case 'r':
    points.get(id).animationSpeed = points.get(id).animationSpeed * -1;
    break;
  case 'w':
    points.get(id).singleShot = !points.get(id).singleShot;
    break;
  case '-':
    points.get(id).animationSpeed = floatSetter(points.get(id).animationSpeed, -0.003f, val);
    break;
  case '=':
    points.get(id).animationSpeed = floatSetter(points.get(id).animationSpeed, 0.003f, val);
    break;
  case '1':
    points.get(id).motionMode = intSetter(points.get(id).motionMode, 1, PApplet.parseInt(val)); 
    points.get(id).motionMode = points.get(id).motionMode % motionNum;
    break;
  case '2':
    points.get(id).shpMode = intSetter(points.get(id).shpMode, 1, PApplet.parseInt(val)); 
    points.get(id).shpMode = points.get(id).shpMode % shpNum;
    break;
  case '3':
    points.get(id).colMode = intSetter(points.get(id).colMode, 1, PApplet.parseInt(val)); 
    points.get(id).colMode = points.get(id).colMode % colNum;
    break;
  }
}

public float floatSetter(float in, float inc, float val) {
  if (val== 999) return in+=inc;
  else return val;
}

public int intSetter(int in, int inc, int val) {
  if (val==999) return in+=inc;
  else return val;
}



/////////////////////  INPUT  \\\\\\\\\\\\\\\\\\\\\\\\\

public void oscEvent(OscMessage mess) {
  println(mess);
  if (mess.checkAddrPattern("/gmf/mapper")==true) {
    if (mess.checkTypetag("iif")) {
      char cmd = PApplet.parseChar(mess.get(0).intValue());
      int grp = mess.get(1).intValue();   
      float v = mess.get(2).floatValue(); 
      groupSetter(cmd, grp, v);
    }
  }
}

public void mousePressed() {
  if (doMapping&& mouseEnabled) {
    if (mouseButton == LEFT) {
      placePoint();
    }
    else if (mouseButton == RIGHT) {
      removePoint();
    }
    else {
      blackPoint();
    }
  }
}

public void keyReleased() {
  if (keyCode == SHIFT) {
    shift = 0;
  }
}

public void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {      
    case SHIFT:
      shift = 10;
      break;       
    case LEFT:
      px-=(1+shift);
      if (px<0) px=width;
      break;        
    case RIGHT:
      px+=(1+shift);
      px=px%height;
      break;    
    case UP:
      py-=(1+shift);
      if (py<0) py=height;
      break;      
    case DOWN:
      py+=(1+shift);
      py=py%width;
      break;
    }
  }


  else {
    globalSettings(key);
  }
}


public void globalSettings(char cmd) {
  switch(key) {
  case 'a':
    selectedGroup = 1;
    println("Edit ALL the groups");
    break;      
  case 'b':
    blackPoint();
    break;    
  case 'g':
    newGroup();
    println("New group : "+groupIndex);
    break;  
  case 'h':
    printHelp();
    break;      
  case 'k':
    mouseEnabled=!mouseEnabled;
    println("Mouse = "+mouseEnabled);
    break; 
  case 'l':
    //loadPoints(); 
  case 'm':
    doMapping = !doMapping;
  case 's':
    //savePoints();
    break;   
  case 't':
    trails=!trails;
    println("Trails = "+trails);
    break;       
  case 'z':
    removePoint();
    break;        
  case 32:
    placePoint();
    break;        
  case '[':
    trailmix-=1;
    println("Trailmix : "+trailmix);
    break;
  case ']':
    trailmix+=1;
    println("Trailmix : "+trailmix);
    break;

  case '`':
    selectedGroup++;
    if (selectedGroup > groupIndex) selectedGroup = 1;
    println(selectedGroup);
    break;
  case '~':
    selectedGroup--;
    if (selectedGroup < 1) selectedGroup = groupIndex;
    println(selectedGroup);
    break;
  default:
    groupSetter(key, selectedGroup, 999);
    break;
  }
}


public void printHelp() {
  println("SPACE OR left button -> place point");
  println("1 - 2 - 3 cycle animation brush and color");
  println("a edit ALL the points");
  println("z OR right button -> undo");
  println("b OR middle button break line");
  println("h help");
  println("l load points");
  println("k keyBoardEnabled");
  println("r reverse direction");
  println("s save points");
  println("t trails");
  println("g start new group");
  //println("f fills");
  println("w singleShot");
  println("p/o point size"); 
  println("q queue"); 
  println("0-9 modes");
  println("- animationSpeed--");
  println("= animationSpeedf++");
  println("[ trailmix--");
  println("[ trailmix++");
  println(" ` and shift + ~ cycle through groups");
}


/* save points as XML */
/*
void savePoints() {
 if (points.size()>2) {
 // create empty XML
 String data = "<points></points>";
 // xml = parseXML(data);
 // populate XML with ArrayList contents
 for (int i = 1; i < points.size(); i++) {
 // save each point attribute to an xml item 
 XML newChild = xml.addChild("point");
 newChild.setFloat("x", points.get(i).pointPosition.x);
 newChild.setFloat("y", points.get(i).pointPosition.y);
 newChild.setFloat("z", points.get(i).pointPosition.z);
 newChild.setContent("point" + i);
 println(newChild);
 }
 //saveXML(xml, "points.xml");
 println("Points saved as points.xml");
 }
 else println("Not enough points to save.");
 }
 */
/* load new points from XML */
/*
void loadPoints() {
 // clear points ArrayList
 points.clear();
 xml = loadXML("points.xml");
 XML[] children = xml.getChildren("point");
 // check to see if XML is parsing properly
 for (int i = 0; i < children.length; i++) {
 int ptX = int(children[i].getFloat("x"));
 int ptY = int(children[i].getFloat("y"));
 int ptZ = int(children[i].getFloat("z"));
 // set ArrayList items to loaded values
 points.add(new MPoint(ptX, ptY, ptZ));
 println("point " + i + ": " + ptX + ", " + ptY + ", " + ptZ);
 }
 println("Loaded points.xml");
 }
 */
class MPoint {
  //point location
  PVector pointPosition;
  //progress of animation [0..1]
  float progress = 0;
  float animationSpeed = 0.01f;
  int groupID = 0;
  
  boolean singleShot = false;
  
int motionMode = 0; 
int shpMode = 0;
int colMode = 0;

float colOffset = 0.1f;
int sizer = 8;
  
  // constructor
  public MPoint(float xx, float yy, float zz, int gID) {
    pointPosition =  new PVector(xx, yy, zz);
    groupID = gID;
  }

  public float animationStep() {
    progress = progress+animationSpeed;
    if (!singleShot) {
      if (progress>1) progress=0;
      if (progress<0) progress=1;
    }
    return progress;
  }
}

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--full-screen", "--bgcolor=#666666", "--hide-stop", "classed_mapper_osc" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
