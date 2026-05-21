# 🌿 Offline AI Survival Assistant

> A mobile application that identifies plants and provides GPS navigation — **100% offline**, built for forest and trekking environments where internet is unavailable.

🔗 [Demo Video](https://drive.google.com/file/d/1z052xzf3amppKsCInQMN6Gb18s3RRJHJ/view?usp=drive_link)
![Platform](https://img.shields.io/badge/Platform-Android-green?style=flat-square)
![Framework](https://img.shields.io/badge/Framework-Flutter-blue?style=flat-square)
![AI Model](https://img.shields.io/badge/AI-EfficientNet%20%2B%20TFLite-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=flat-square)
![Batch](https://img.shields.io/badge/Batch-21MIS-purple?style=flat-square)

---

## 📖 Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [Project Modules](#project-modules)
- [Tech Stack](#tech-stack)
- [AI Model Details](#ai-model-details)
- [System Architecture](#system-architecture)
- [Dataset](#dataset)
- [Installation](#installation)
- [Developer](#developer)

---

## 📌 About the Project

The **Offline AI Survival Assistant** is a capstone project designed for hikers, trekkers, and forest explorers who may find themselves in areas with no internet connectivity. The app combines on-device AI with offline GPS navigation to help users:

- Identify whether a plant is **edible, medicinal, or poisonous**
- Navigate using **real-time GPS** without needing mobile data
- Access a **local plant knowledge base** — no server needed

This project was developed as part of the **Winter Semester 2025–26 Capstone Project (Batch: 21MIS)**.

---

## ✨ Features

- 🌱 **Plant Identification** — Capture a photo and instantly classify it as edible, medicinal, or poisonous
- 📴 **Fully Offline** — No internet required at any stage of the app
- 🗺️ **Offline GPS Navigation** — Pre-downloaded OpenStreetMap tiles displayed with real-time location
- 📚 **Local Knowledge Base** — Plant details (name, edibility, nutritional value) stored as a local JSON file
- 📱 **Android APK** — Deployable on any Android device

---

## 🧩 Project Modules

### 1. 📂 Dataset Module
- Collected plant images from online sources across 3 categories:
  - 🟢 Edible plants / fruits
  - 🔵 Medicinal plants
  - 🔴 Poisonous plants
- Cleaned the dataset by removing duplicate and irrelevant images
- Organized into labeled folders suitable for model training

### 2. 🤖 AI Model Module
- Deep learning model trained using **TensorFlow**
- Architecture: **EfficientNet**
- Training Accuracy: **~95%**
- Validation Accuracy: **~84%**
- Converted to **TensorFlow Lite (.tflite)** for on-device inference

### 3. 🗃️ Knowledge Base Module
- Local **JSON file** stored on the device
- Contains: plant name, edible status, nutritional value, and medicinal uses
- No server or internet needed — fully self-contained

### 4. 📱 Mobile Application Module
- Built using **Flutter**
- User captures a plant image → app runs AI prediction → displays result + plant info
- Plant information fetched from local JSON knowledge base
- Built into **Android APK** using `flutter build apk`

### 5. 🗺️ Offline Navigation Module
- Uses device **GPS chip** for real-time location (no internet needed)
- **OpenStreetMap (OSM)** tiles pre-downloaded and stored locally
- Map tiles loaded from local storage — no internet needed
- User location displayed as a live dot on the offline map

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| AI Framework | TensorFlow |
| Model Architecture | EfficientNet |
| On-device AI | TensorFlow Lite (.tflite) |
| Offline Maps | OpenStreetMap (OSM) tiles |
| Map Rendering | flutter_map |
| Location | GPS (device hardware) |
| Knowledge Base | Local JSON file |
| Build Output | Android APK |

---

## 🧠 AI Model Details

| Parameter | Value |
|---|---|
| Architecture | EfficientNet |
| Framework | TensorFlow |
| Training Accuracy | ~95% |
| Validation Accuracy | ~84% |
| Deployment Format | TensorFlow Lite (.tflite) |
| Categories | Edible / Medicinal / Poisonous |
| Input | Camera image (captured in-app) |
| Output | Plant category + confidence score |

The model was trained on a custom dataset and converted to `.tflite` format for efficient on-device inference without requiring any internet connection or cloud compute.

---

## 🏗️ System Architecture

```
User captures plant image
        ↓
Flutter App (Mobile)
        ↓
TFLite Model (On-device inference)
        ↓
Prediction Result (Edible / Medicinal / Poisonous)
        ↓
Local JSON Knowledge Base
        ↓
Display: Plant name, description, nutritional info
```

```
GPS Satellites (Radio signals — no internet)
        ↓
Phone GPS Chip (Calculates lat/lon coordinates)
        ↓
Flutter App requests map tile
        ↓
Local Storage (Pre-downloaded OSM tiles)
        ↓
Map rendered on screen with live location dot
```

---

## 📊 Dataset

The dataset used for training is organized into 3 categories:

```
dataset/
├── edible/        → Images of edible fruits and plants
├── medicinal/     → Images of medicinal plants
└── poisonous/     → Images of poisonous plants
```

- Images collected from online sources
- Dataset cleaned to remove duplicates and irrelevant images
- Labeled folders used directly for TensorFlow model training

> Note: Only sample images are included in this repository due to size constraints. Full dataset available on request.

---

## 📲 Installation

### Prerequisites
- Flutter SDK installed
- Android Studio / VS Code
- Android device or emulator

### Steps

```bash
# Clone the repository
git clone https://github.com/SANGAMI-1410/Offline-AI-Survival-Assistant.git

# Navigate to the Flutter app folder
cd Offline-AI-Survival-Assistant/forest_ai

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build APK
flutter build apk
```

---

## 👩‍💻 Developer

| Name | Role |
|---|---|
| Sangami | Developer — Individual Capstone Project |

---

## 🎓 Project Info

| Detail | Info |
|---|---|
| Project Type | Individual Capstone Project |
| Semester | Winter Semester 2025–26 |
| Batch | 21MIS |
| Domain | AI + Mobile Development |
| Platform | Android |

---

## 📄 License

This project is for academic purposes under the Winter Semester 2025–26 Capstone Program.

---

> *"Built for the wild — works where the internet doesn't."* 🌲
