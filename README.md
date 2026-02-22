
<img width="713" height="230" alt="sicon_1_-removebg-preview" src="https://github.com/user-attachments/assets/ea07cd36-af13-44b9-b0d6-3637ded6225b" />


<h2>Giving Nature a Voice through IoT & AI</h2>
<div align="center">
<img src="https://img.shields.io/badge/Arduino-00979D?style=for-the-badge&logo=Arduino&logoColor=white" alt="Arduino" />
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
<img src="https://img.shields.io/badge/Python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54" alt="Python" />
<img src="https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi" alt="FastAPI" />
<img src="https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB" />

<br />

**Sprout** is an intelligent plant monitoring system that bridges the gap between nature and technology. By combining real-time IoT sensor data with Google’s Gemini AI, Sprout transforms raw environmental metrics into a casual, friendly conversation with your houseplant.

</div>

---

## 🚀 Overview

Sprout isn't just a dashboard; it's a personality. The system monitors Moisture, Temperature, Humidity, and Light, feeding this data into a sophisticated 6-tier AI backend. Your plant doesn't just show you graphs—it tells you how it feels, gives you care tips, and provides a weekly "Botanist's Report" on its health.

---

## ✨ Key Features

* **Live Vitals Dashboard:** Real-time data visualization connecting physical sensors to a Flutter frontend via Bluetooth Classic.
* **Casual Chat Interface:** A "roommate-style" conversation engine that avoids robotic jargon.
* **6-Tier AI Fallback:** Automated cascading logic using Gemini models to ensure 100% uptime.
* **Smart Database Logging:** Optimizes MongoDB storage by only logging significant environmental shifts, avoiding data bloat.
* **Glassmorphism UI:** A modern, clean aesthetic using frosted glass effects and organic colors.

---

## 🔌 Hardware Architecture

Sprout is built on a robust, logic-level protected microcontroller architecture. 



### Components & Signal Routing
* **Microcontroller:** Arduino Uno Rev3
* **Wireless Communication:** HC-05 Bluetooth Module (Classic SPP)
* **Analog Sensors (Continuous Data via ADC):**
  * Resistive Soil Moisture Sensor (Pin A0)
  * Photoresistor / LDR (Pin A1)
* **Digital Sensors (Binary Data Streams):**
  * DHT11 (Pin 2) for ambient Temperature & Humidity.

> **🛠️ Engineering Note — Logic Level Protection:** > The architecture features a custom 1kΩ/4kΩ Voltage Divider to safely step down the Arduino's 5V TX signal to the HC-05's 3.3V RX logic level, preventing long-term hardware degradation. Additionally, a 4kΩ pull-down resistor is utilized for precise light level calibration on the LDR.

---

## 💻 Software & Backend



| Component | Technology | Description |
| :--- | :--- | :--- |
| **Backend Framework** | Python / FastAPI | High-performance, asynchronous REST API. |
| **AI Engine** | Google GenAI SDK | Powers the conversational engine using Gemini. |
| **Database** | MongoDB Atlas | Motor Async driver for historical health logs. |
| **Frontend App** | Flutter / Dart | Cross-platform mobile UI with FL Chart for biological trends. |
| **Connectivity** | Bluetooth Serial | Standard SPP communication for local telemetry. |

---

## 🧠 AI Strategy: The 6-Tier Fallback

To ensure Sprout never "loses its mind," the backend implements a specific priority sequence for AI requests. If a model hits a rate limit or is overloaded, the system automatically attempts the next tier:

1. **Gemini 2.5 Flash Lite** *(Primary / Fast)*
2. **Gemini 2.5 Flash** *(Stable)*
3. **Gemini 2.0 Flash** *(Next-Gen Stable)*
4. **Gemini 2.0 Flash Lite** *(High Volume / Unlimited TPM)*
5. **Gemini 2.0 Flash Exp** *(Experimental Performance)*
6. **Gemini 2.5 Pro** *(Deep Reasoning / Complex Diagnostics)*

---

## 📁 Project Structure

```plaintext
sprout_project/
├── sprout_backend/         # Python FastAPI Backend
│   ├── main.py             # API Endpoints & Routing
│   ├── ai_service.py       # Gemini Integration & Fallback Logic
│   ├── database.py         # Smart Logging & History Retrieval
│   └── .env                # API Keys (Keep Secret!)
├── sprout_app/             # Flutter Mobile Application
│   ├── lib/
│   │   ├── screens/        # Dashboard & Chat Screens
│   │   ├── services/       # Bluetooth Classic & API Integration
│   │   └── theme/          # Sprout Organic Design System
└── sprout_hardware/        # Arduino Firmware
    └── sprout_ble.ino      # Sensor Polling & JSON Serial Output
```

⚙️ Installation & Setup
### 1. Backend Setup
Navigate to the backend directory and install the required dependencies:

```bash
cd sprout_backend
pip install fastapi uvicorn google-genai python-dotenv motor
```
Create a .env file and add your configuration:
```bash
GEMINI_KEY=your_google_api_key_here
MONGO_URI=your_mongodb_connection_string
```
Run the server:
```bash
uvicorn main:app --reload
```
### 2. Mobile App Setup
Ensure you have the Flutter SDK installed, then navigate to the app directo
```bash
cd sprout_app
flutter pub get
flutter run
```
## 💬 Conversation Style (The "Vibe")

Sprout is designed to be your friend. It avoids "Assistant-speak" (like *"How can I help you?"*). Instead, it utilizes its system prompt to speak in casual, everyday English based on its current telemetry:

> **User:** "How are you doing?"  
> **Sprout *(Moisture 10%)*:** "Honestly? I'm pretty parched. A little water would be amazing right now."  
> **Sprout *(Healthy)*:** "I'm having a great day. Just vibing in the sunlight. You look good today too!"

---

## 🧪 Future Roadmap

* **Plant Vision:** Disease detection using Gemini Multimodal Vision capabilities.
* **Hardware Upgrade:** Transitioning to Capacitive Soil Sensors for long-term corrosion resistance in wet soil.
* **Auto-Watering:** Integration with 5V submersible water pumps and relays for autonomous care.
* **Social Sprout:** Let multiple plants talk to each other over the local MQTT network.
