import processing.sound.*;

static final int PG_LEFT = 10;
static final int PG_RIGHT = 1260;
static final int PG_UP = 20;
static final int PG_DOWN = 780;
static final int PG_MIDDLE_X = (PG_RIGHT-PG_LEFT)/2+PG_LEFT;
static final int PG_MIDDLE_Y = (PG_DOWN-PG_UP)/2+PG_UP;
static final int PG_DASHES = 21;

static final int PADDLE_LEN = 80;
static final int PADDLE_WIDTH = 10;

static final int D_UP = -1;
static final int D_HOLD = 0;
static final int D_DOWN = 1;
static final int D_LEFT = -1;
static final int D_RIGHT = 1;

static final int COLOR_FOREGRND = 255;
static final int COLOR_BACKGRND = 0;

float ballX = 0;
float ballY = 0;
float ballXNew = 0;
float ballYNew = 0;
float slope = 0;
int ballDirection = D_RIGHT;
float ballStep = 4;

int p1Y = PG_MIDDLE_Y-PADDLE_LEN/2;
int p2Y = PG_MIDDLE_Y-PADDLE_LEN/2;
int p1CurrDirection = D_HOLD;
int p1PrevDirection = D_HOLD;
int p2CurrDirection = D_HOLD;
int p2PrevDirection = D_HOLD;
int pStep = 5;

int scoreMax = 10;

PFont scoreF;

int p1Score = 0;
int p2Score = 0;

TriOsc triangle;
float freqHit=600;
float freqMiss1=300;
float freqMiss2=200;
float plswidth=1;
float amp=0.7;
float add=0.0;
float pos=1;

boolean paused = true;
boolean gameOver = false;

void setup() {
  scoreF = createFont("Zig", 56, false);
  size(displayWidth, displayHeight);
  triangle = new TriOsc(this);
  triangle.set(freqHit, amp, add, pos);
  drawStartScreen();
}

void draw() {
  if (p1Score<5&&p2Score<5) {
    if (!paused) {
      drawPaddle();
      drawBall();
    }
  }
}

void drawDashedMiddleLine(int strokeWeight) {
  strokeWeight(strokeWeight);
  line(PG_MIDDLE_X, PG_UP, PG_MIDDLE_X, PG_DOWN);
  strokeWeight(strokeWeight+1);
  int len = (PG_DOWN-PG_UP)/PG_DASHES;
  setInvisible();
  for (int i=1; i<PG_DASHES; i+=2) {
    line(PG_MIDDLE_X, PG_UP+i*len+5, PG_MIDDLE_X, PG_UP+(i+1)*len+5);
  }  
  strokeWeight(strokeWeight);
  setVisible();
}


void drawStartScreen() {
  background(COLOR_BACKGRND, COLOR_BACKGRND, COLOR_BACKGRND);
  setVisible();

  strokeWeight(10);
  strokeCap(SQUARE); 
  line(PG_LEFT, PG_UP, PG_RIGHT+10, PG_UP);
  line(PG_LEFT, PG_DOWN, PG_RIGHT+10, PG_DOWN);
  drawDashedMiddleLine(10);
  strokeWeight(1);

  slope = random(-2, 2);
  ballDirection = computeBallDirection();
  ballX = PG_MIDDLE_X;
  ballY = PG_MIDDLE_Y;
  ballXNew = ballX;
  ballYNew = ballY;

  drawScore();
  drawPaddle();
  // draw "Press Space to continue"
  if (paused) {
    drawPaused(true);
  }
}

int computeBallDirection() {
  ballDirection  = round(random(0, 1));
  if (ballDirection==0) {
    ballDirection = D_LEFT;
  } else {
    ballDirection = D_RIGHT;
  } 
  return ballDirection;
}  

void computeBallPosition(int border) {
  if (border == PG_LEFT || border == PG_RIGHT) {
    ballDirection = ballDirection * (-1);
    slope = slope + random(-0.3, 0.3);
    ballXNew = round(ballXNew + ballDirection * ballStep);
    ballYNew = round(ballYNew + slope * ballStep);
  } else if (border == PG_UP || border == PG_DOWN) {
    slope = slope * (-1);
    ballXNew = ballXNew + ballDirection * ballStep;
    ballYNew = ballYNew + slope * ballStep;
  }
}

void drawBall() {
  // compute ballXNew and ballYNew
  // collision detection with paddles(left,right)  and boundaries(up,down)
  // draw a new ball

  // clear ball
  setInvisible();
  rect(ballXNew-5, ballYNew-5, 10, 10);
  setVisible();

  // draw middle line if neccessary
  if (ballXNew>=PG_MIDDLE_X-15&&ballXNew<=PG_MIDDLE_X+15) {
    drawDashedMiddleLine(10);
    strokeWeight(1);
  }

  ballXNew = ballX + ballDirection * ballStep;
  ballYNew = ballY + slope * ballStep;

  // test for left and right paddles
  if (ballXNew-15 <= PG_LEFT) {
    if (p1Y <= ballYNew+20 && ballYNew-20 <= (p1Y + PADDLE_LEN)) {
      // hit paddle
      computeBallPosition(PG_LEFT);
      thread("playSoundHit");
    } else {
      // missed paddle
      p2Score = p2Score + 1;
      paused = true;
      playSoundMiss();
      drawStartScreen();
    }
  } else if (ballXNew+5 >= PG_RIGHT) {
    if (p2Y <= ballYNew+20 && ballYNew-20 <= (p2Y + PADDLE_LEN)) {
      // hit paddle
      computeBallPosition(PG_RIGHT);
      thread("playSoundHit");
    } else {
      // missed paddle
      p1Score = p1Score + 1;
      paused = true;
      playSoundMiss();
      drawStartScreen();
    }
  }

  // test for upper and lower boundaries
  if (ballYNew-10 < PG_UP) {
    // hit boundary
    computeBallPosition(PG_UP);
  } else if (ballYNew+10 > PG_DOWN) {
    // hit boundary
    computeBallPosition(PG_DOWN);
  }

  // draw ball
  rect(ballXNew-5, ballYNew-5, 10, 10);
  ballX = ballXNew;
  ballY = ballYNew;

  drawScore();
}

void drawPaddle() {
  setInvisible();
  rect(PG_LEFT, p1Y, PADDLE_WIDTH, PADDLE_LEN);
  rect(PG_RIGHT, p2Y, PADDLE_WIDTH, PADDLE_LEN);

  int p1YNew = p1Y + p1CurrDirection * pStep;
  int p2YNew = p2Y + p2CurrDirection * pStep; 

  if (PG_UP+6<=p1YNew && p1YNew <= PG_DOWN-PADDLE_LEN-6) {
    p1Y = p1YNew;
  } 

  if (PG_UP+6<=p2YNew && p2YNew <= PG_DOWN-PADDLE_LEN-6) {
    p2Y = p2YNew;
  }  

  setVisible();
  rect(PG_LEFT, p1Y, PADDLE_WIDTH, PADDLE_LEN);
  rect(PG_RIGHT, p2Y, PADDLE_WIDTH, PADDLE_LEN);
}

void drawScore() {
  textFont(scoreF, 64);
  fill(COLOR_FOREGRND);
  text(p1Score, PG_MIDDLE_X - 200, PG_UP + 100);
  text(p2Score, PG_MIDDLE_X + 150, PG_UP + 100);
}

void drawPaused(boolean visible) {
  textFont(scoreF, 25);
  textMode(SHAPE);
 
  String message = "Press SPACE to continue - Press 'command' and 'Q' to quit";
  int offset = 250;
  if (p1Score>=scoreMax) {
    offset = 100;
    message = "Player 1 won";
    gameOver = true;
  } else if (p2Score>=scoreMax) {
    offset = 100;
    message = "Player 2 won";
    gameOver = true;
  }

  if (visible) {
    fill(COLOR_FOREGRND);
    text(message, PG_MIDDLE_X - offset, PG_DOWN - 50);
  } else {
    fill(COLOR_BACKGRND);
    for (int i=0; i<10; i++) {
      text(message, PG_MIDDLE_X - offset, PG_DOWN - 50);
    }
  }
}

void setVisible() {
  stroke(COLOR_FOREGRND, COLOR_FOREGRND, COLOR_FOREGRND);
  fill(COLOR_FOREGRND, COLOR_FOREGRND, COLOR_FOREGRND);
}
void setInvisible() {
  stroke(COLOR_BACKGRND, COLOR_BACKGRND, COLOR_BACKGRND);
  fill(COLOR_BACKGRND, COLOR_BACKGRND, COLOR_BACKGRND);
}

void playSoundHit() {
  triangle.freq(freqHit);
  triangle.play();
  delay(100);
  triangle.stop();
}

void playSoundMiss() {
  triangle.freq(freqMiss1);
  triangle.play();
  delay(150);
  triangle.freq(freqMiss2);
  delay(600);
  triangle.stop();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == SHIFT&&p1CurrDirection!=D_UP) {
      p1PrevDirection = p1CurrDirection; 
      p1CurrDirection = D_UP;
    } else if (keyCode == CONTROL&&p1CurrDirection!=D_DOWN) {
      p1PrevDirection = p1CurrDirection; 
      p1CurrDirection = D_DOWN;
    } 

    if (keyCode == UP&&p2CurrDirection!=D_UP) {
      p2PrevDirection = p2CurrDirection; 
      p2CurrDirection = D_UP;
      // println(i+" PRESSED: "+keyCode+" p2rev: " + p2PrevDirection + ", p2Curr: " + p2CurrDirection);
    } else if (keyCode == DOWN&&p2CurrDirection!=D_DOWN) {
      p2PrevDirection = p2CurrDirection; 
      p2CurrDirection = D_DOWN;
      // println(i+" PRESSED: "+keyCode+" p2rev: " + p2PrevDirection + ", p2Curr: " + p2CurrDirection);
    }
  }

  if (key==' '&&!gameOver) {
    paused=false;
    drawPaused(false);
  }
}

void keyReleased() {
  if (key == CODED) {

    if (keyCode == SHIFT) {
      if (p1CurrDirection==D_UP) {
        p1CurrDirection = p1PrevDirection;
      }
      p1PrevDirection = D_HOLD;
    } else if (keyCode == CONTROL) {
      if (p1CurrDirection==D_DOWN) {
        p1CurrDirection = p1PrevDirection;
      }
      p1PrevDirection = D_HOLD;
    } 

    if (keyCode == UP) {
      if (p2CurrDirection==D_UP) {
        p2CurrDirection = p2PrevDirection;
      }  
      p2PrevDirection = D_HOLD;
      // println(" RELEASED: "+keyCode+" p2rev: " + p2PrevDirection + ", p2Curr: " + p2CurrDirection);
    } else if (keyCode == DOWN) {
      if (p2CurrDirection==D_DOWN) {
        p2CurrDirection = p2PrevDirection;
      }
      p2PrevDirection = D_HOLD;
      // println(" RELEASED: "+keyCode+" p2rev: " + p2PrevDirection + ", p2Curr: " + p2CurrDirection);
    }
  }
}
