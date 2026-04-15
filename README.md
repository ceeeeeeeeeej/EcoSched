# EcoSched: IoT-Enabled Smart Waste Management

EcoSched is a comprehensive mobile solution for smart waste collection scheduling, community notifications, and AI-powered waste classification, specifically designed for Tago, Surigao del Sur.

## 🤖 AI Waste Classification System

The EcoSched system features a sophisticated "Process Stage" for real-time waste classification using Deep Learning.

### 🔬 Architecture & Workflow

Our system utilizes a **MobileNet-based Convolutional Neural Network (CNN)** with transfer learning to identify waste materials with high precision.

The process is divided into two main stages:

#### 1. Training Stage
*   **Model**: MobileNetV2 architecture chosen for its efficiency on mobile devices.
*   **Transfer Learning**: Pre-trained on large-scale datasets and fine-tuned on labeled waste images.
*   **Categories**: The model is trained to recognize patterns in **Biodegradable**, **Recyclable**, and **Non-Biodegradable** waste.
*   **Deployment**: The fully trained model is deployed as a high-performance REST API using **Render** cloud hosting.

#### 2. Prediction Stage (Real-time Scan)
*   **Capture**: The mobile application captures a live image of an item.
*   **Transmission**: Data is transmitted securely to the cloud-based FastAPI server.
*   **Classification**: The MobileNet model processes the image in the cloud.
*   **Result**: The API returns the classification (e.g., "Recyclable") along with a **confidence score**.
*   **Action**: The app displays localized disposal tips and key environmental facts based on the result.

### 🚀 Multimodal AI Engine
EcoSched provides three processing modes for maximum reliability:
*   **GEMINI**: Cloud-based expert mode for complex scenes.
*   **CUSTOM AI**: Your specialized MobileNet model on Render (Preferred Process Stage).
*   **LOCAL**: On-device TFLite fallback for 100% offline functionality.

## 🛠️ Technology Stack
*   **Framework**: Flutter / Dart
*   **Backend**: Supabase (Database, Auth, Storage)
*   **AI/ML**: TensorFlow / TFLite, FastAPI (Python), Google Gemini API
*   **Hosting**: Render (AI API)
*   **IoT**: MQTT for smart bin integration

---
© 2026 EcoSched Team - Tago, Surigao del Sur.
