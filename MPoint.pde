class MPoint {
  //point location
  PVector pointPosition;
  //progress of animation [0..1]
  float progress = 0;
  float animationSpeed = 0.01;
  int groupID = 0;
  
  boolean singleShot = false;
  
int motionMode = 0; 
int shpMode = 0;
int colMode = 0;

float colOffset = 0.1;
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

