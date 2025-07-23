# 🦽 IoT-Enabled Hand-Controlled Wheelchair System

🎓 **Graduation Project** – A smart wheelchair system designed to assist physically disabled individuals by enabling control via **hand gestures** and **mobile Bluetooth app**.

---

## 🚀 Overview

This system empowers users to control a wheelchair in two ways:

- ✋ **Hand Gesture Mode** – Using MPU6050 motion sensor
- 📱 **Bluetooth Mobile App Mode** – Using HC-06 Bluetooth module

The project enhances independence, mobility, and safety for people with physical impairments.

---

## 🌟 Key Features

- ✅ **Dual control modes**: Gesture & Mobile App
- ✅ **Forward, Backward, Left, Right** navigation
- ✅ **Emergency buzzer alert** if the chair tilts dangerously (ADXL345 sensor)
- ✅ **Mode switching button** between Gesture and Bluetooth
- ✅ **Safety monitoring** with real-time tilt detection

---

## 🧩 Components Used

| Component          | Purpose                             |
|-------------------|-------------------------------------|
| Arduino UNO        | Main microcontroller board          |
| MPU6050            | Gesture sensor (accelerometer + gyro) |
| HC-06              | Bluetooth module for app control    |
| ADXL345            | Tilt/fall detection                 |
| TT Gear Motors     | Wheel movement                     |
| Motor Shield       | Drives motors                      |
| Buzzer             | Safety alert                       |
| Switch             | Change between Gesture and Bluetooth modes |
| Battery            | Power source                       |

---

## 🛠️ How to Use

1. **Upload code** to Arduino UNO.
2. **Connect hardware** as per circuit diagram.
3. Use **gesture mode** by tilting your hand.
4. Or use the **mobile app** (via Bluetooth HC-06) to send commands:
   - `F` = Forward
   - `B` = Backward
   - `L` = Turn Left
   - `R` = Turn Right
   - `S` = Stop

---

## 📸 Demo / Screenshots

_Add your project image or video link here._

---

## 👨‍🎓 Project Type

**Graduation Project** – submitted in partial fulfillment of the degree in **Computer Applications**.

---

## 👩‍💻 Main Developer

- **Shukri Abdiqadir Ali** – Lead Developer, System Designer & Coder

---

## 🤝 Team Members

- Ahmed  
- Mahad  
- Muna  

---

## 📄 License

This project is open-source and free to use for academic and research purposes.

---

> “Technology empowers people. With the right tools, every barrier becomes a bridge.” – Team Wheelchair Project
