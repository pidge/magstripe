import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import javax.swing.*; 


String theFile = "blah blah";

Minim minim;
AudioSample trackFile;
Waveform trackWave;
Points extremes;
Data trackData;

// offset from the beginning of the 
int offset = 0;

int variable = 5;

abstract class Span{
  int begin, end;
  Span(int begin, int end){
    this.begin = begin;
    this.end = end;
  }

  int length() {
    return end - begin;
  }
}

class Bit extends Span {
  int value;

  Bit(int value, int begin, int end){
    super(begin, end);
    this.value = value;
  }

  String toString() {
    return str(value);
  }


  void draw(int offset) {
    stroke(40);
    if (value == 1) fill(32);
    else fill(0);
    rect(begin-offset, -4, this.length(), height+4);
  }
}

class Data {
  ArrayList bits;

  Data(ArrayList bits) {
    this.bits = bits;
  }

  String toString() {
    String newString = "";

    for (Iterator iter = bits.iterator(); iter.hasNext();) {
      newString += ((Bit) iter.next()).toString();
    }

    return newString;
  }

  void draw(int offset) {
    for (int i = 0; i < bits.size(); i++) {
      ((Bit) bits.get(i)).draw(offset);
    }
  }
}


class Waveform {
  float[] samples;
  Waveform(float[] samples) {
    this.samples = samples;
  }

  void reverse() {
    this.samples = PApplet.reverse(this.samples);
  }

  Points findExtremes() {
    float minHeight = max(samples)/15;
    ArrayList extremes = new ArrayList();
    int peak, valley, n;
    peak = n = 0;

    while ( n < samples.length ) {
      // track local maximum until value decreases at least the minimum amplitude
      while ( (n < samples.length) && ((samples[peak] - minHeight) < samples[n]) ) {
        if (samples[n] > samples[peak])
          peak = n;
        n++;
      }
      extremes.add(peak);
      if (n >= samples.length) break;
      valley = n;
      // track local minimum until value increases at least the minimum amplitude
      while ( (n < samples.length) && ((samples[valley] + minHeight) > samples[n]) ){

        if (samples[n] < samples[valley])
          valley = n;
        n++;
      }	
      extremes.add(valley);
      peak = n;
    }
    return new Points(extremes, this);
  }

  Waveform derivative() {
    float[] results = new float[samples.length - 1];
    for(int i=0; i < samples.length - 1; i++) {
      results[i] = samples[i+1] - samples[i];
    }
    return new Waveform(results);
  }

  int length() {
    return samples.length;
  }

  // should implement scaling to normalize max value to half height 
  void draw(int offset, int y, int h) {
    stroke(255);
    for(int i = offset; (i < samples.length - 3) && (i < width+offset); i++) {
      line(i-offset, (1 + samples[i])*h/2, i+1-offset,  + (1+samples[i+1])*h/2);
    }
  }
}

class Points {
  ArrayList points;
  Waveform wave;

  Points(ArrayList points, Waveform wave) {
    this.points = points;
    this.wave = wave;
  }

  Points interpolate() {
    ArrayList middles = new ArrayList();

    int e2 = (Integer) points.get(0);
    int e1;

    Iterator iter = points.listIterator(1);

    while (iter.hasNext()) {
      e1 = e2;
      e2 = (Integer) iter.next();

      middles.add( (e1+e2)/2 );
    }

    return new Points(middles, wave);
  }

  Data toData() {

    ArrayList bits = new ArrayList();

    int now = (Integer)points.get(0);
    int nowPlusOne = (Integer)points.get(1);
    int nowPlusTwo;

    int zeroSize = nowPlusOne - now;

    int indice = 2;
    while (indice < points.size()) {
      nowPlusTwo = (Integer)points.get(indice);

      int dist1 = abs(now + zeroSize - nowPlusOne);
      int dist2 = abs(now + zeroSize - nowPlusTwo);

      if (dist1 < dist2) {
        bits.add(new Bit(0, now, nowPlusOne));
        zeroSize = nowPlusOne - now + variable;
        now = nowPlusOne;
        nowPlusOne = nowPlusTwo;
        indice = indice + 1;
      } 
      else {
        bits.add(new Bit(1, now, nowPlusTwo));
        zeroSize = nowPlusTwo - now - variable;
        now = nowPlusTwo;
        nowPlusOne = (Integer)points.get(indice+1);
        indice = indice + 2;
      }

    }

    return new Data(bits);
  }


  void drawSquareWave(int offset, int y, int h) {
    ListIterator iter = points.listIterator(1);
    int e1;
    int e2 = (Integer) points.get(0);

    while (iter.hasNext()) {
      e1 = e2;
      e2 = (Integer) iter.next();

      stroke(255, 0, 0);
      line(e1-offset, y, e1-offset, y+h);
      if (wave.samples[e1] < wave.samples[e2]) {
        line(e1-offset, y+h, e2-offset, y+h);
      }
      else {
        line(e1-offset, y, e2-offset, y);
      }
    }
  }

  void drawOverWaveform(int offset, int y, int h) {
    fill(255,0,0);
    stroke(255, 0, 0);
    int pt = (Integer) points.get(0);
    for(int i=0; (i < points.size()) && (pt < width+offset); i++) {
      pt = (Integer) points.get(i);
      if (pt >= offset) {
        rect(pt-offset-1, y + (1 + wave.samples[pt])*h/2 - 1, 3, 3);
        //point(pt-offset, y + (1 + wave.samples[pt])*h/2);
      }
    }
  }
}






void setup()
{
  

  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  });
   
  // File-choosin' crap:
  
  // set system look and feel 
  try { 
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); 
  } 
  catch (Exception e) { 
    e.printStackTrace();  
  } 
 
  // create a file chooser 
  final JFileChooser fc = new JFileChooser(); 
  fc.showOpenDialog(this); 
  File file = fc.getSelectedFile(); 

  
  
  size(800, 140);
  minim = new Minim(this);
  trackFile = minim.loadSample(file.getPath());
  trackWave = new Waveform(trackFile.getChannel(1));
  trackWave.reverse();
  extremes = trackWave.findExtremes();
  trackData = extremes.toData();
  println(trackData.toString());

  background(0);
  stroke(255);
  noLoop();
  smooth();
  //print("samples.length: ");
  //println(samples.length);
}

void draw()
{
  background(0);

  // copy global offset to a local variable incase it changes while we're drawing
  int offset;
  offset=this.offset;

  // draw bit values 
  trackData.draw(offset);

  // mark spaces between extremes
  extremes.drawSquareWave(offset, 110, 20);

  // waveform
  trackWave.draw(offset, 0, 100);

  // mark found extremes
  //extremes.drawOverWaveform(offset, 0, 100);

  // draw strip magnetic value
  extremes.drawSquareWave(offset, 110, 20);

  // top bar shows position in file:
  stroke(255);
  line(offset*width/trackWave.length(), height-1, (offset+width)*width/trackWave.length(), height-1);
}


/* Interaction Stuff */
void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      setOffset( offset - 10 );
    } 
    else if (keyCode == RIGHT) {
      setOffset( offset + 10 );
    } 
  } 
  else if (key == 'r') {
    redraw();
  }


  else if (key == '+') {
    variable += 1;
    trackData = extremes.toData();
    println(variable);
    redraw();
  }
  else if (key == '-') {
    variable -= 1;
    trackData = extremes.toData();
    println(variable);
    redraw();
  }
  else if (key == 'd') {
    println(trackData.toString());
  }
}

void mouseClicked() {
  mouseDragged();
}

void mouseDragged() {
  setOffset( ( (trackWave.length()-width) * mouseX) / width );
}

boolean setOffset(int to) {
  offset = constrain(to, 0, trackWave.length()-width);
  //  print("offset: ");
  //  println(offset);
  redraw();
  return to == offset;
}

void mouseWheel(int delta) {
  println(delta);
  setOffset(offset + delta*4);
}
