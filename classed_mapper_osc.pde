import oscP5.*;
import netP5.*;

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
float distance = 0.1;
int sizer = 10;
int trailmix = 10;
int current = 0;
int groupCol = 0;
float colOffset = 0;

//renderer settings
int motionMode = 1; 
int shpMode = 1;
int colMode = 1;

int motionNum = 4;
int shpNum = 4;
int colNum = 3;

boolean doMapping = true;
boolean fixedLength = true;
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

int ID = 0;

color pcol = color(0, 0, 0);

int shift = 0;
PFont font;

///SHADERS
PShader neb;




void setup() {

  size(1290, 810, P3D);
  oscP5 = new OscP5(this, 4443);
  points = new ArrayList();
  smooth();
  noCursor();
  colorMode(HSB, 360, 100, 100);
  background(0);
  font = createFont("Georgia", 24);
  blackPoint();
  //blackPoint();
  neb = loadShader("nebula.glsl");
  neb.set("resolution", float(width), float(height));
}

void draw() {
   neb.set("time", millis() / 500.0);  
  // draw background
  drawBackground();
  // render lines
  render();
}

///////////////////   Render Loop \\\\\\\\\\\\\\\\\\\\\\
void render() {
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
    corners();
  }
  if (points.size()>2) {
    for (int i = points.size()-1; i > 2; i--) {
      int j = i - 1;
      if (points.get(i).groupID>0) { // black points have groupIndex=255
        //current point
        current = i;
        // determine coordinates for current line
        x1 = int(points.get(j).pointPosition.x);
        y1 = int(points.get(j).pointPosition.y);
        x2 = int(points.get(i).pointPosition.x);
        y2 = int(points.get(i).pointPosition.y);  
        ID = points.get(i).groupID;
        if (selectedGroup!=1 && selectedGroup == ID) {
          num(x1,y1,ID);
        }
        // get the point animationSpeed of current line
        distance = points.get(i).animationStep();
        if (points.get(i).singleShot && distance>1) break;
        if (points.get(i).singleShot && distance>1) println("ha");
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
    }
    // if in mapping Mode, remove line to cursor
    if (doMapping) removePoint();
  }
}

void corners(){
  strokeWeight(60);
  stroke(0,0,100);
  point(0,0);
  point(width,0);
  point(0,height);
  point(width,height);
}

///////////////////   movement    \\\\\\\\\\\\\\\\\\\\\\

//animations can be combined!
void animationSelector() {
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
  case 3:
    filler();
    break;
  }
}


void filler() {
  for (int i = points.size()-1; i > 1; i--) {
    noStroke();
    fill(colorizer());
      shader(neb); 
    beginShape();
    while (points.get(i).groupID==ID) {
      vertex(points.get(i).pointPosition.x, points.get(i).pointPosition.y);
      if (i>0)i--;
      else break;
    }
    endShape(CLOSE);
  }
}


void polka() {
  thingner(int(x1+distance*(x2-x1)), int(y1+distance*(y2-y1)));
}

void dotted() {
  int n = 24;
  //adjust number of dots:
  int l = int(sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)));
  n=int(l/(0.0001+(points.get(current).sizer*5)));
  for (float k = 0; k<n;k++) {  
    float e = (distance+k)/n;    
    thingner(int(x1+e*(x2-x1)), int(y1+e*(y2-y1)));
  }
}



/////// STUFF THAT MAKES PIXELS CHANGE COLOR  \\\\\\\\\\\\

///////////////////  things
void thingner(int xx, int yy) {
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
  case 4:
    texter(xx,yy);
    break;
  case 5:
    filler();
    break;

  }
}

color colorizer() {
  colOffset+=0.03;
  color c = color(0, 0, 0);
  switch(colMode) {
  case 0:
    c = color(0, 0, 100);
    break;
  case 1:
    c =  color(points.get(current).pointPosition.z, 100, 100);
    break;
  case 2:
    c =  color(((current*5)+colOffset)%360, 100, 100);
    break;
  }
  return c;
}

void pnt(int xx, int yy) {
  strokeWeight(sizer);
  stroke(colorizer());
  point(xx, yy);
}

void liner(int xx, int yy) {
  stroke(colorizer());
  strokeWeight(3);
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  line(0, sizer, 0, -sizer);
  popMatrix();
}

void arrow(int xx, int yy) {
  stroke(colorizer());
  strokeWeight(3);
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  line(0, 0, sizer, sizer);
  line(0, 0, sizer, -sizer);
  popMatrix();
}

void ascii(int xx, int yy) {
  textFont(font);
  textAlign(CENTER, CENTER);
  //char letter = char(123);
  char letter = char(79);
  char[] letters = {
    'x', 'X'
  };
  letter = letters[int(random(0, letters.length))];
  fill(colorizer());
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  text(letter, 0, 0);
  popMatrix();
}

void texter(int xx, int yy){
  textFont(font);
  textAlign(CENTER, CENTER);
  String ha = "potatoes mashed";
  fill(colorizer());
  int l1 = int(sqrt((xx-x1)*(xx-x1)+(yy-y1)*(yy-y1)));
  int l2 = int(sqrt((xx-x2)*(xx-x2)+(yy-y2)*(yy-y2)));
  pushMatrix();
  translate(xx, yy);
  rotate(atan2(y1-y2, x1-x2));
  if(distance<0.5){
  for(int i = 0; i<ha.length() && i*15<l1;i++){
    
    text(ha.charAt(i), i*15, 0);
    if(i*15>l2)break;
  }
  }
  else{
   for(int i = ha.length(); i<1 && (ha.length()-i)*15<l1;i--){
    
    text(ha.charAt(i), i*15, 0);
    if(i*15>l1)break;
  }
  } 

  popMatrix();
}  





void num(int xx, int yy, int n) {
  textFont(font);
  textAlign(CENTER, CENTER);
  fill(0,0,100);
  pushMatrix();
  translate(xx, yy);
  text(n, 0, 0);
  popMatrix();
}




void linnen() {
  stroke(colorizer());
  strokeWeight(sizer);
  line(x1, y1, x2, y2);
}

// render lines in mapping mode
void mapping() {
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

void groupHighlight() {
  stroke(0, 0, 100);
  strokeWeight(15);
  point(x1, y1);
}

void crossHair(int xx, int yy) {
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


void queue() {
  for (int i = points.size()-1; i > 1; i--) {
    points.get(i).progress = 0;
  }
}

void drawBackground() {
  if (trails && !doMapping) {
    fill(0, 0, 0, trailmix);
    stroke(0, 0, 0, trailmix);
    rect(0, 0, width, height);
  }
  else {
    background(0);
  }
}

void placePoint() {
  points.add(new MPoint(px, py, groupCol, groupIndex));
}

void blackPoint() {
  //removePoint();
  points.add(new MPoint(px, py, 0, 0));
}

void removePoint() {
  if (points.size()>0) points.remove(points.size()-1);
}

void newGroup() {
  groupIndex++;
  groupCol = int(random(0, 360));
  selectedGroup = groupIndex;
}

///////////////// settings manager  \\\\\\\\\\\\\

void groupSetter(char cmd, int grp, float val) {
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

void setter(char cmd, int id, float val) {  
  switch(cmd) {
  case 'f':
    //doFill = !doFill;
  case 'o':
    //points.get(id).sizer-=1;
    points.get(id).sizer = intSetter(points.get(id).sizer, -1, int(val));
    break;
  case 'p':
    points.get(id).sizer = intSetter(points.get(id).sizer, 1, int(val));
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
    points.get(id).animationSpeed = floatSetter(points.get(id).animationSpeed, -0.003, val);
    break;
  case '=':
    points.get(id).animationSpeed = floatSetter(points.get(id).animationSpeed, 0.003, val);
    break;
  case '1':
    points.get(id).motionMode = intSetter(points.get(id).motionMode, 1, int(val)); 
    points.get(id).motionMode = points.get(id).motionMode % motionNum;
    break;
  case '2':
    points.get(id).shpMode = intSetter(points.get(id).shpMode, 1, int(val)); 
    points.get(id).shpMode = points.get(id).shpMode % shpNum;
    break;
  case '3':
    points.get(id).colMode = intSetter(points.get(id).colMode, 1, int(val)); 
    points.get(id).colMode = points.get(id).colMode % colNum;
    break;
  }
}

float floatSetter(float in, float inc, float val) {
  if (val== 999) return in+=inc;
  else return val;
}

int intSetter(int in, int inc, int val) {
  if (val==999) return in+=inc;
  else return val;
}



/////////////////////  INPUT  \\\\\\\\\\\\\\\\\\\\\\\\\

void oscEvent(OscMessage mess) {
  println(mess);
  if (mess.checkAddrPattern("/gmf/mapper")==true) {
    if (mess.checkTypetag("iif")) {
      char cmd = char(mess.get(0).intValue());
      int grp = mess.get(1).intValue();   
      float v = mess.get(2).floatValue(); 
      groupSetter(cmd, grp, v);
    }
  }
}

void mousePressed() {
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

void keyReleased() {
  if (keyCode == SHIFT) {
    shift = 0;
  }
}

void keyPressed() {
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


void globalSettings(char cmd) {
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


void printHelp() {
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
