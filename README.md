# OTP Defense: Anti-OTP Spoofing & Phishing Shield

An advanced, real-time OTP security shielding application designed to combat SMS/OTP spoofing, phishing, and transactional fraud in the Sri Lankan financial context. This project is developed in accordance with the final year project guidelines of **Plymouth University**.

---


## 🛡️ Project Overview

In recent years, SMS OTP (One-Time Password) intercept and spoofing attacks have grown exponentially, especially in developing banking corridors. Attackers masquerade as legitimate financial institutions (like Sampath Bank, ComBank, BOC) or telecoms (Dialog, Mobitel) using custom alphanumeric SMS gateways to trick victims into sharing OTP credentials or navigating to malicious clones.

**OTP Defense** is a mobile application built in Flutter that acts as a proactive security layer. It captures incoming notification payloads via a secure Android Accessibility service, runs them through an instant three-layer risk scoring engine, warns the user via heads-up alerts if a threat is detected, and securely stores legitimate OTPs in an isolated, biometric-guarded vault.

---

## ⚙️ Three-Layer Hybrid Security Architecture

To guarantee low-latency analysis without compromising safety, the application uses a **Hybrid Security Architecture**:

```mermaid
graph TD
    A[Incoming SMS Notification] --> B(Layer 1: Deterministic Scan)
    B -->|Match Local Verified Registry| C[Mark Safe / Spam]
    B -->|Unknown / Alphanumeric Sender| D(Layer 2: Heuristic Analysis)
    D -->|Fires Regex & NLP Rules| E{Uncertain Risk Score?}
    E -->|Yes: Score 30-65| F(Layer 3: Grok AI Semantic Scan)
    E -->|No: Decisive Score| G[Update Risk Level]
    F -->|Asynchronous API Evaluation| G
    G --> H[Heads-Up Local Alert Notification]
    G --> I[Anonymized Analytics Sync to Supabase]
```

### 1. Layer 1: Deterministic Scan (O(1) Local Lookup)
Instantly cross-references the Sender ID against a local, verified registry containing official transactional identifiers of Sri Lankan financial institutions, government agencies, and utility services (e.g., `SAMPATH`, `COMBANK`, `DIALOG`, `SLPost`). If a verified sender transmits a structurally valid OTP with no malicious links, it is instantly cleared.

### 2. Layer 2: Heuristic Analysis (NLP & Keyword Score Matrix)
If the sender is unknown, a local heuristic scanner scores the message content against a matrix of risk rules:
- **Private Numbers sending OTPs:** High base risk penalty.
- **Urgency NLP combination:** Urgency expressions combined with account-related action verbs.
- **Multilingual Keywords:** Support for Sinhala (e.g., `ලොගින්`, `අත්හිටුවා`) and Tamil keywords alongside English threat phrases.
- **URL Verification:** Classifies URLs to distinguish secure recognized platforms from malicious shorteners and unknown IPs.

### 3. Layer 3: Grok LLM Semantic AI Scan (Cloud Agent)
For ambiguous messages where the heuristic engine returns an uncertain score (30% to 65%), the app asynchronously queries a lightweight neural classifier powered by Groq (`gemma2-9b-it`). The AI agent interprets semantic cues (such as emotional manipulation or high-pressure phishing prompts) and blends its insights with the heuristic scan to determine the final security verdict.

---

## 💻 Tech Stack & Integrations

- **Frontend Framework:** Flutter (Dart SDK ^3.11.0)
- **State Management:** Flutter Riverpod (^3.2.1)
- **Database Back-end:** Supabase Client (^2.12.0)
  - Features dynamic verified institution tables and reports.
- **AI Engine API:** Groq Cloud SDK with Gemma-2 (Strict JSON-format outputs)
- **Security & Utilities:**
  - `local_auth` for Biometrics (Fingerprint/FaceID & Pattern Fallbacks).
  - `flutter_local_notifications` for instant Heads-Up alerts.
  - `flutter_animate` for high-performance visual transitions.
  - `shared_preferences` for encrypted/secure local flags.

---

## 🗄️ Database Schema (Supabase Real-Time Sync)

The application syncs reported alphanumeric senders and anonymized metadata to Supabase. This forms a collaborative threat intelligence shield across all installed devices:

1. **`trusted_senders`**: Preloaded lookup table of registered financial/service institutions (Dialog, ComBank, HNB, Sampath).
2. **`scam_number_hashes`**: Stores SHA-256 hashes of numbers flagged by multiple community users.
3. **`risk_rules`**: A table containing RegEx and keyword weighting vectors, allowing real-time over-the-air updates to client engines.
4. **`analytics`**: Stores anonymized, non-PII risk levels and rules triggered to compile aggregate regional dashboard statistics.

---

## ⚡ Setup & Installation Guidelines

To build and run the source code locally for verification:

### 1. Prerequisites
- Ensure the Flutter SDK is installed (`^3.11.0` or later). Check with:
  ```bash
  flutter --version
  ```
- An Android Emulator or physical device configured with Developer Mode and USB Debugging enabled.

### 2. Dependency Resolution
Navigate to the project root and run:
```bash
flutter pub get
```

### 3. Run the Application
Start the application on your active connected device:
```bash
flutter run
```


