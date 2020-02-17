import ddf.minim.*;
import ddf.minim.ugens.*;
import controlP5.*;
import processing.sound.LowPass;
import processing.sound.HighPass;
import processing.sound.BandPass;

Minim minim;
ControlP5 controlP5;
AudioPlayer song;
FilePlayer filePlayer;
Oscil wave;
AudioOutput out;
ADSR env;
RadioButton waveshapeRadio;
RadioButton filterType;
Waveform waveShape =  Waves.SINE;
Group waveGroup;
MoogFilter  moogFilter;

boolean filterIsActve = false; 
int space = 50;
float attackTime = 0.17;
float decayTime= 0.17;
float sustainTime = 0;
float releaseTime = 0.06;
static final float MAXAMP = 1.0;
float amplitude = MAXAMP;
float filterFreq = 1200;
float resonance = 0.5;
int keyboardY = 360;
int keyboardBlackY = 500;

String pad01URL = "audio/808-Kicks07.wav";
String pad02URL = "audio/808-Kicks24.wav";
String pad03URL = "audio/808-Snare16.wav";
String pad04URL = "audio/808-HiHats02.wav";
String pad05URL = "audio/808-OpenHiHats05.wav";
String pad06URL = "audio/808-Ride1.wav";
String pad07URL = "audio/808-Clap16.wav";
String pad08URL = "audio/808-Stick1.wav";
String pad09URL = "audio/808-Cowbell1.wav";


// -------------------------------------------------------------------------------------------------------------------------
// Synth class est la classe utlisee pour generer le son du clavier.
// Elle implemente l'interface Instrument et donc les methodes noteOn() et noteOff()
class Synth implements Instrument {

  Synth(float frequency, float amplitude, Waveform waveform) {
    wave = new Oscil(frequency, amplitude, waveShape);
    env = new ADSR(MAXAMP, attackTime, decayTime, sustainTime, releaseTime, amplitude, amplitude);
    wave.patch(env);
  }

  // Override de l'interface Instrument
  void noteOn( float dur )
  {
    // demearre l'enveloppe ADSR
    env.noteOn();
    // connecte la classe a la sortie
    if (filterIsActve) {
      wave.patch(env).patch(moogFilter).patch( out );
    } else {
      env.patch( out );
    }
  }

  // Override de l'interface Instrument
  void noteOff()
  {
    // Dis a l'enveloppe de se deconnecter apres le release (relachement) de la touche.

    //env.unpatchAfterRelease( moogFilter );
    env.unpatch( moogFilter );
    env.unpatchAfterRelease( out );
    // appel de la methode noteOff() de l'enveloppe. 
    env.noteOff();
  }
}

// -------------------------------------------------------------------------------------------------------------------------
void setup() {
  size(720, 600);
  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 512);

  // Initialisation de l'enveloppe
  initEnveloppe(10, 10);
  // Initialisation de la forme d'onde
  initWaveshape(225, 10);
  // Initialisation des Pads
  initPad(555, 0);
  initFilter();
}

// -------------------------------------------------------------------------------------------------------------------------
// Cree le paneau de l'enveloppe
// les coordonnees x et y en paramètre permettent de déplacer l'ensemble du panneau
void initEnveloppe(int xCoord, int yCoord) {

  this.env = new ADSR(1.0, attackTime, decayTime, sustainTime, releaseTime, amplitude);
  controlP5 = new ControlP5(this);
  controlP5.addSlider("ATTACK", 0, 1, attackTime, xCoord, yCoord, 20, 100);
  controlP5.addSlider("DECAY", 0, 1, decayTime, xCoord + 50, yCoord, 20, 100);
  controlP5.addSlider("SUSTAIN", 0, 1, sustainTime, xCoord + 100, yCoord, 20, 100);
  controlP5.addSlider("REALEASE", 0, 1, releaseTime, xCoord + 150, yCoord, 20, 100);
  controlP5.addKnob("AMPLITUDE", 0, 1, amplitude, xCoord + 450, yCoord, 50);
}

// Label de L'enveloppe
void enveloppeLabel(int xCoord, int yCoord) {
  stroke(255);
  line(xCoord, yCoord + 120, xCoord + 180, yCoord + 120);
  fill(255, 255, 255);
  text("ADSR ENVELOPPE", xCoord + 40, yCoord + 140);
}

// -------------------------------------------------------------------------------------------------------------------------
// Cree le paneau des formes d'onde
// les coordonnees x et y en paramètre permettent de déplacer l'ensemble du panneau
void initWaveshape(int xCoord, int yCoord) {
  waveshapeRadio = controlP5.addRadio("waveshape").setPosition( xCoord, yCoord).setSize(20, 20)
    .addItem("sin", 1.0)
    .addItem("tri", 2.0)
    .addItem("sqr", 3.0)
    .addItem("saw", 4.0)
    .addItem("pulse", 5.0);
  waveGroup = controlP5.addGroup("waveGroup");
  waveGroup.add(waveshapeRadio);
}

// Label de la forme d'onde
void waveShapeLabel(int xCoord, int yCoord) {
  stroke(255);
  line(xCoord, 130, xCoord + 30, yCoord);
  fill(255, 255, 255);
  text("WAVE", 220, yCoord + 20);
}

// -------------------------------------------------------------------------------------------------------------------------
// Cree le paneau du flitre
void initFilter() {
  this.moogFilter = new MoogFilter (filterFreq, resonance);
  // ajout des potentiometres
  controlP5.addKnob("FREQ", 200, 12000, filterFreq, 290, 60, 50);
  controlP5.addKnob("RESONANCE", 0, 1, resonance, 350, 60, 50);

  // boutons radios permettant de choisir le type de filtre
  filterType =  controlP5.addRadio("filterType").setPosition( 420, 60).setSize(20, 20)
    .addItem("LP", 1)
    .addItem("HP", 2)
    .addItem("BP", 3);
}

// Label du filtre
void filterLabel(int xCoord, int yCoord) {
  stroke(255);
  line(xCoord, yCoord, xCoord + 110, yCoord);
  fill(255, 255, 255);
  text("FILTER", xCoord + 5, yCoord + 20);
}

// -------------------------------------------------------------------------------------------------------------------------
// Cree le paneau des Pad
// les coordonnees x et y en paramètre permettent de déplacer l'ensemble du panneau
void initPad(int xCoord, int yCoord) {
  controlP5.addButton("PAD7", 0, xCoord, yCoord, 50, 50);
  controlP5.addButton("PAD8", 0, xCoord + 55, yCoord, 50, 50);
  controlP5.addButton("PAD9", 0, xCoord + 110, yCoord, 50, 50);
  controlP5.addButton("PAD4", 0, xCoord, yCoord + 55, 50, 50);
  controlP5.addButton("PAD5", 0, xCoord + 55, yCoord + 55, 50, 50);
  controlP5.addButton("PAD6", 0, xCoord + 110, yCoord + 55, 50, 50);
  controlP5.addButton("PAD1", 0, xCoord, yCoord + 110, 50, 50);
  controlP5.addButton("PAD2", 0, xCoord + 55, yCoord + 110, 50, 50);
  controlP5.addButton("PAD3", 0, xCoord + 110, yCoord + 110, 50, 50);
}

// -------------------------------------------------------------------------------------------------------------------------
// dessine les formes d'onde
void drawWaveForm(int xCoord, int yCoord ) {  
  // reactangle de l'osciloscope
  fill(0);
  rect(xCoord, yCoord, 720, 150);
  for (int i = 0; i < out.bufferSize() - 1; i++)
  {
    // récupère l'absisce x pour chaque valeur du buffer alloué
    stroke(0, 255, 0);
    float x1  =  map( i, 0, out.bufferSize(), 0, width );
    float x2  =  map( i+1, 0, out.bufferSize(), 0, width );
    // trace une ligne entre un buffer et un autre pour les 2 pistes 'gauche / droite)
    line( x1, 250 + out.left.get(i)*50, x2, 250 + out.left.get(i+1)*50);
    line( x1, 300 + out.right.get(i)*50, x2, 300 + out.right.get(i+1)*50);
  }
}

// -------------------------------------------------------------------------------------------------------------------------
void draw() {
  background(42);

  // Dessine les note "blanches".
  stroke(0);
  for (int x = 10; x <= 850; x = x + space ) {
    fill(255);
    rect(x - 50, 360, x, height);
  }

  // Dessine mes notes "noires" des dièses et bémols.
  fill(0); 
  rect(40, keyboardY, 30, 135);
  rect(95, keyboardY, 30, 135);
  rect(190, keyboardY, 30, 135);
  rect(245, keyboardY, 30, 135);
  rect(295, keyboardY, 30, 135);
  rect(390, keyboardY, 30, 135);
  rect(445, keyboardY, 30, 135);
  rect(540, keyboardY, 30, 135);
  rect(595, keyboardY, 30, 135);
  rect(645, keyboardY, 30, 135);
  rect(745, keyboardY, 30, 135);

  enveloppeLabel(10, 10);

  waveShapeLabel(220, 130);

  drawWaveForm(0, 200);

  filterLabel(290, 130);
}

// -------------------------------------------------------------------------------------------------------------------------
//Gestion des interactions de l'utilisateur
void controlEvent(ControlEvent theEvent) {
  /*
    Controler du RadioButton de la forme d'onde
   */
  if (theEvent.isFrom("waveshape")) {
    if (theEvent.getValue() == 1.0) {
      waveShape = Waves.SINE ;
      println("sin");
    }
    if (theEvent.getValue() == 2.0) {
      waveShape = Waves.TRIANGLE ;
      println("tri");
    }
    if (theEvent.getValue() == 3.0) {
      waveShape = Waves.SAW ;
      println("sqr");
    }
    if (theEvent.getValue() == 4.0) {
      waveShape = Waves.SQUARE ;
      println("saw");
    }
    if (theEvent.getValue() == 5.0) {
      waveShape = Waves.QUARTERPULSE ;
      println("pulse");
    }
    if (theEvent.getValue() < 0.0) {
      println("no shape selected");
    }
  }
  if (theEvent.isFrom("filterType")) {
    if (theEvent.getValue() == 1.0) {
      filterIsActve = true;
      this.moogFilter.type = MoogFilter.Type.LP;
      println("LP Filter - IsActve = " + filterIsActve);
    } 
    if (theEvent.getValue() == 2.0) {
      filterIsActve = true;
      this.moogFilter.type = MoogFilter.Type.HP;
      println("HP Filter - IsActve = " + filterIsActve);
    } 
    if (theEvent.getValue() == 3.0) {
      filterIsActve = true;
      this.moogFilter.type = MoogFilter.Type.BP;
      println("BP Filter - IsActve = " + filterIsActve);
    } 
    if (theEvent.getValue() < 0.0) {
      filterIsActve = false;
      println("no filter selected - IsActve = " + filterIsActve);
    }
  }
  //Controller pour les potentiomètres 
  else if (theEvent.controller().getName() == "ATTACK") {
    this.attackTime = theEvent.controller().getValue();
    this.env.setParameters(this.amplitude, this.attackTime, this.decayTime, this.sustainTime, this.releaseTime, this.amplitude, this.amplitude);
  } else if (theEvent.controller().getName() == "SUSTAIN") {
    this.sustainTime = theEvent.controller().getValue();
    this.env.setParameters(this.amplitude, this.attackTime, this.decayTime, this.sustainTime, this.releaseTime, this.amplitude, this.amplitude);
  } else if (theEvent.controller().getName() == "DECAY") {
    this.decayTime = theEvent.controller().getValue();
    this.env.setParameters(this.amplitude, this.attackTime, this.decayTime, this.sustainTime, this.releaseTime, this.amplitude, this.amplitude);
  } else if (theEvent.controller().getName() == "REALEASE") {
    this.releaseTime = theEvent.controller().getValue();
    this.env.setParameters(this.amplitude, this.attackTime, this.decayTime, this.sustainTime, this.releaseTime, this.amplitude, this.amplitude);
  } else if (theEvent.controller().getName() == "AMPLITUDE") {
    this.amplitude = theEvent.controller().getValue();
    this.env.setParameters(this.amplitude, this.attackTime, this.decayTime, this.sustainTime, this.releaseTime, this.amplitude, this.amplitude);
  } else if (theEvent.controller().getName() == "FREQ") {
    this.filterFreq = theEvent.controller().getValue();    
    this.moogFilter.frequency.setLastValue(theEvent.controller().getValue());
  } else if (theEvent.controller().getName() == "RESONANCE") {
    this.moogFilter.resonance.setLastValue(theEvent.controller().getValue());
  }
}

// -------------------------------------------------------------------------------------------------------------------------
// Joue le son correspondant à l'url d'un son 
void playPad(int number, String padName) {
  song = minim.loadFile(padName, 2048);
  song.play();
  println("PAD "+number+" - " + padName);
}

void PAD1() {
  playPad(1, pad01URL);
}

void PAD2() {
  playPad(2, pad02URL);
}

void PAD3() {
  playPad(3, pad03URL);
}

void PAD4() {
  playPad(4, pad04URL);
}

void PAD5() {
  playPad(5, pad05URL);
}

void PAD6() {
  playPad(6, pad06URL);
}

void PAD7() {
  playPad(7, pad07URL);
}

void PAD8() {
  playPad(8, pad08URL);
}

void PAD9() {
  playPad(9, pad09URL);
}

// Actions liees a l'utilisation du pave numerique
void keyPressed() {
  // PAD 1
  if ( key == '1') {
    playPad(1, pad01URL);
  }
  // PAD 2
  if ( key == '2') {
    playPad(2, pad02URL);
  }
  // PAD 3
  if ( key == '3') {
    playPad(3, pad03URL);
  }
  // PAD 4
  if ( key == '4') {
    playPad(4, pad04URL);
  }
  // PAD 5
  if ( key == '5') {
    playPad(5, pad05URL);
  }
  // PAD 6
  if ( key == '6') {
    playPad(6, pad06URL);
  }
  // PAD 7
  if ( key == '7') {
    playPad(7, pad07URL);
  }
  // PAD 8
  if ( key == '8') {
    playPad(8, pad08URL);
  }
  // PAD 9
  if ( key == '9') {
    playPad(9, pad09URL);
  }
}


void keyReleased() {
  stop();
}

void stop()
{
  env.noteOff();
  env.unpatchAfterRelease( out );
}

void mouseReleased() {
  stop();
}


// -------------------------------------------------------------------------------------------------------------------------
// Mapping des coordonnees clickees et un son
void mousePressed() {
  // C3
  if ((mouseX > 10 &&  mouseX < 40 && mouseY < height && mouseY > keyboardY) || (mouseX > 10 && mouseX < 60 && mouseY > keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 261.626, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - C3 - 261.626Hz");
  }
  // C#3
  if (mouseX > 40 &&  mouseX < 70 && mouseY >keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 277.183, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - C#3 - 277.183Hz");
  }
  // D3
  if ((mouseX > 70 && mouseX < 95 && mouseY > keyboardY && mouseY > keyboardBlackY) || (mouseX > 60 && mouseX < 110 && mouseY > keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 293.66, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - D3 - 293.66Hz");
  }
  // D#3
  if ( mouseX > 95 && mouseX < 125 && mouseY > keyboardY && mouseY < keyboardBlackY) { 
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 311.127, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - D#3 - 311.127Hz");
  }
  // E3
  if ((mouseX > 110 && mouseX < 160 && mouseY > keyboardBlackY) || (mouseX > 125 && mouseX < 160 && mouseY > keyboardY && mouseY < height)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 329.63, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - E3 - 329.63Hz");
  }
  // F3
  if ((mouseX > 160 && mouseX < 210 && mouseY > keyboardBlackY) || (mouseX > 160 && mouseX < 190 && mouseY > keyboardY && mouseY < height)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 349.23, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - F3 - 349.23Hz");
  }
  // F#3
  if ( mouseX > 190 && mouseX < 225 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 369.99, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - F#3 - 369.99Hz");
  }
  // G3
  if ((mouseX > 210 && mouseX < 260 && mouseY > keyboardBlackY) || (mouseX > 220 && mouseX < 245 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 392, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - G3 - 392Hz");
  }
  // G#3
  if ( mouseX > 245 && mouseX < 275 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 415.3, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - G#3 - 415.3Hz");
  }
  // A3
  if ((mouseX > 260 && mouseX < 310 && mouseY > keyboardBlackY) || (mouseX > 275 && mouseX < 290 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 440, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - A3 - 440Hz");
  }
  // A#3
  if ( mouseX > 290 && mouseX < 325 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 466.16, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - A#3 - 466.16Hz");
  }
  // B3 
  if ((mouseX > 310 && mouseX < 325 && mouseY > keyboardBlackY)|| (mouseX > 325 && mouseX < 360 && mouseY > keyboardY && mouseY < height)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 493.88, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - B3 - 493.88Hz");
  }
  // C4
  if ((mouseX > 360 &&  mouseX < 410 &&  mouseY > keyboardBlackY) || (mouseX > 360 && mouseX < 390 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 523.251, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - C4 - 523.251Hz");
  }
  // C#4
  if (mouseX > 390 &&  mouseX < 415 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 554.365, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - C#4 - 554.365Hz");
  }
  // D4
  if ((mouseX > 410 && mouseX < 460 && mouseY > keyboardBlackY) || (mouseX > 420 && mouseX < 445 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 587.33, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - D4 - 587.33Hz");
  }
  // D#4
  if ( mouseX > 445 && mouseX < 475 && mouseY > keyboardY && mouseY < keyboardBlackY) { 
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 622.254, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - D#4 - 622.254Hz");
  }
  // E4
  if ((mouseX > 460 && mouseX < 510 && mouseY > keyboardBlackY) || (mouseX > 475 && mouseX < 510 &&  mouseY > keyboardY )) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 659.255, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - E4 - 659.255Hz");
  }
  // F4
  if ((mouseX > 510 && mouseX < 560 && mouseY > keyboardBlackY) || (mouseX > 510 && mouseX < 540 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 698.456, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - F4 - 698.456Hz");
  }
  // F#4
  if ( mouseX > 540 && mouseX < 570 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 739.989, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - F#4 - 739.989Hz");
  }
  // G4
  if ((mouseX > 560 && mouseX < 610 && mouseY > keyboardBlackY) || (mouseX > 570 && mouseX < 595 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 783.991, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - G4 - 783.991Hz");
  }
  // G#4
  if ( mouseX > 595 && mouseX < 625 && mouseY > keyboardY && mouseY < keyboardBlackY) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 830.609, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - G#4 - 830.609Hz");
  }
  // A4
  if ((mouseX > 610 && mouseX < 660 && mouseY > keyboardBlackY) || (mouseX > 620 && mouseX < 645 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 880, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - A4 - 880Hz");
  }
  // A#4
  if ( mouseX > 645 && mouseX < 675 && mouseY > keyboardY && mouseY < keyboardBlackY ) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 932.328, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - A#4 - 932.328Hz");
  }
  // B4
  if ((mouseX > 660 && mouseX < 710 && mouseY > keyboardBlackY)|| (mouseX > 675 && mouseX < 710 && mouseY > keyboardY && mouseY < keyboardBlackY)) {
    out.clearSignals();
    out.playNote( 0, 25, new Synth( 987.767, amplitude, waveShape ) );
    println(mouseX + " - " + mouseY + " - B4 - 987.767Hz");
  }
}
