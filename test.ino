#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>

// Configuration de wifi
const char* ssid = "ORANGE_22DC";
const char* pass = "ZyzT5k5t";

// configuration de protocol MQTT
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

const char* topic_in   = "pharmasmart/dispense";
const char* topic_out  = "pharmasmart/status";
const char* topic_state = "pharmasmart/esp/status";

// API de serveur 
const char* api = "https://api.pharmasmart.dpdns.org";

// client configuration
WiFiClient espClient;
PubSubClient client(espClient);

// PIN DE CHARIOT
#define STEP_X 25
#define DIR_X  26
#define EN_X   27

// PIN DE VERIN
#define STEP_Z 18
#define DIR_Z  19
#define EN_Z   21

// ¨PIN DE SWITCHES
#define HOME_SW 32
#define END_SW  33

// PIN DE SHIFT REGISTER
#define DATA  15
#define CLOCK 2
#define LATCH 4

// CONFIGURATION DE VITESSE
const int CASE_STEP  = 5000;
const int VERIN_STEP = 8800;
const int SPEED      = 200;

// ETAT INIALL
int currentPos = 1;
bool busy = false;

// LES FONCTIONS
void mqttCallback(char* topic, byte* payload, unsigned int length);
void reconnectMQTT();
void process(JsonArray meds);
void moveTo(int target);
void verin();
void returnHome();
void blinkAndHold(int pos);
void ledWrite(byte v);
void ledOff();
void homeMachine();
void stepMotor(int stepPin, int dirPin, bool dir, int steps);

// FONCTION DE LED
void ledWrite(byte v) {
  digitalWrite(LATCH, LOW);
  shiftOut(DATA, CLOCK, MSBFIRST, v);
  digitalWrite(LATCH, HIGH);
}
// FONCTION LED OFF
void ledOff() {
  ledWrite(0);
}

// FONCTION DE MOTOR
void stepMotor(int stepPin, int dirPin, bool dir, int steps) {

  digitalWrite(dirPin, dir);

  for (int i = 0; i < steps; i++) {
    if (stepPin == STEP_X && dir == LOW && digitalRead(END_SW) == LOW) {
      Serial.println(" CASE 7 DETECTED");
      digitalWrite(EN_X, HIGH);
      currentPos = 7;
      return;
    }

    digitalWrite(stepPin, HIGH);
    delayMicroseconds(SPEED);

    digitalWrite(stepPin, LOW);
    delayMicroseconds(SPEED);
  }
}

// FONCTION RETURN HOME
void homeMachine() {

  Serial.println(" HOMING START");

  if (digitalRead(HOME_SW) == LOW) {
    Serial.println(" ALREADY HOME");
    currentPos = 1;
    return;
  }

  digitalWrite(EN_X, LOW);
  delay(200);
  digitalWrite(DIR_X, HIGH);

  while (digitalRead(HOME_SW) == HIGH) {
    digitalWrite(STEP_X, HIGH);
    delayMicroseconds(250);
    digitalWrite(STEP_X, LOW);
    delayMicroseconds(250);
  }

  digitalWrite(EN_X, HIGH);
  currentPos = 1;
  Serial.println(" HOME DETECTED");
}

// FONCTION DE DEPPLACEMENT 
void moveTo(int target) {

  int diff = target - currentPos;
  if (diff == 0) return;

  digitalWrite(EN_X, LOW);
  delay(150);

  stepMotor(STEP_X, DIR_X, diff > 0 ? LOW : HIGH, abs(diff) * CASE_STEP);

  delay(150);
  digitalWrite(EN_X, HIGH);
  currentPos = target;
}

// FONCTION DE VERIN 
void verin() {

  digitalWrite(EN_Z, LOW);
  delay(150);

  stepMotor(STEP_Z, DIR_Z, LOW, VERIN_STEP);
  delay(150);
  stepMotor(STEP_Z, DIR_Z, HIGH, VERIN_STEP);
  delay(150);

  digitalWrite(EN_Z, HIGH);
}

// FONCTION DE LED POUR ALLUMER SELON LA POSITION 
void blinkAndHold(int pos) {

  byte led = (1 << (pos - 1));

  for (int i = 0; i < 3; i++) {
    ledWrite(led);
    delay(200);
    ledOff();
    delay(200);
  }

  ledWrite(led);
}

// LE DEMARCHE
struct Med {
  String name;
  int pos;
};

void process(JsonArray meds) {

  busy = true;

  homeMachine();

  Med list[7];
  int n = 0;

  for (JsonVariant m : meds) {

    int pos    = m["position"] | -1;
    String name = m["medicine"] | "";

    if (pos < 1 || pos > 7) continue;
    if (n >= 7) break;

    list[n++] = {name, pos};
  }

  // TRIE D'APRES LA POSITION 
  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      if (list[i].pos > list[j].pos) {
        Med t   = list[i];
        list[i] = list[j];
        list[j] = t;
      }
    }
  }

  //CONDITION SI ON LE MEME POSITION 
  Med unique[7];
  int u = 0;

  for (int i = 0; i < n; i++) {
    if (u == 0 || list[i].pos != unique[u - 1].pos) {
      unique[u++] = list[i];
    } else {
      Serial.print(" DUPLICATE SKIPPED: ");
      Serial.print(list[i].name);
      Serial.print(" -> CASE ");
      Serial.println(list[i].pos);
    }
  }

  HTTPClient http;
  http.begin(String(api) + "/api/machine");
  http.addHeader("Content-Type", "application/json");
  http.POST("{\"available\":false}");
  http.end();

  for (int i = 0; i < u; i++) {

    Serial.print(unique[i].name);
    Serial.print(" -> CASE ");
    Serial.println(unique[i].pos);

    moveTo(unique[i].pos);
    blinkAndHold(unique[i].pos);
    verin();

    delay(300);
    ledOff();
  }

  returnHome();

  client.publish(topic_out, "{\"type\":\"finished\"}");
  Serial.println(" FINISHED SENT");

  http.begin(String(api) + "/api/machine");
  http.addHeader("Content-Type", "application/json");
  http.POST("{\"available\":true}");
  http.end();

  busy = false;
  Serial.println(" READY");
}

// RETURN HOME
void returnHome() {
  homeMachine();
}
 
void mqttCallback(char* topic, byte* payload, unsigned int length) {

  String msg;

  for (int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }

  Serial.println("\n MQTT MESSAGE:");
  Serial.println(msg);

  DynamicJsonDocument doc(8192);

  DeserializationError error = deserializeJson(doc, msg);

  if (error) {
    Serial.print("JSON ERROR: ");
    Serial.println(error.c_str());
    return;
  }

  if (busy) {
    Serial.println(" BUSY");
    return;
  }

  if (String(doc["type"]) != "validation") {
    Serial.println(" WRONG TYPE");
    return;
  }

  JsonArray meds = doc["data"];
  process(meds);
}

// MQTT RECONNECT 
void reconnectMQTT() {

  while (!client.connected()) {

    Serial.print(" MQTT CONNECTING..");
    String clientId = "ESP32-";
    clientId += WiFi.macAddress();

    if (client.connect(clientId.c_str(), NULL, NULL, topic_state, 0, true, "offline")) {

      Serial.println(" CONNECTED");
      client.subscribe(topic_in);
      client.publish(topic_state, "online", true);

    } else {
      Serial.print(" FAILED rc=");
      Serial.println(client.state());
      delay(3000);
    }
  }
}

void setup() {

  Serial.begin(115200);

  pinMode(STEP_X, OUTPUT);
  pinMode(DIR_X, OUTPUT);
  pinMode(EN_X, OUTPUT);

  pinMode(STEP_Z, OUTPUT);
  pinMode(DIR_Z, OUTPUT);
  pinMode(EN_Z, OUTPUT);

  pinMode(HOME_SW, INPUT_PULLUP);
  pinMode(END_SW, INPUT_PULLUP);

  digitalWrite(EN_X, HIGH);
  digitalWrite(EN_Z, HIGH);

  pinMode(DATA, OUTPUT);
  pinMode(CLOCK, OUTPUT);
  pinMode(LATCH, OUTPUT);

  ledOff();

  WiFi.begin(ssid, pass);

  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }

  WiFi.setSleep(false);

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqttCallback);
  client.setBufferSize(8192);

  Serial.println("\n WIFI CONNECTED");
  Serial.println("READY");
}

void loop() {

  if (!client.connected()) {
    reconnectMQTT();
  }

  client.loop();
}