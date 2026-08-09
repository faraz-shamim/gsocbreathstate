
# BreathState 2.0: GSoC 2026 Project Report

### A cross-platform application for HRV biofeedback, resonance breathing, and multimodal physiological research

## Contents

<img src="https://raw.githubusercontent.com/Mr-Imperium/asset/main/logo-1024.png" alt="Logo" width="290" align="right" style="margin-left: 15px;">

- [Executive summary](#executive-summary)
- [Motivation](#motivation)
- [From the 2025 prototype to BreathState 2.0](#from-the-2025-prototype-to-breathstate-20)
- [System architecture](#system-architecture)
- [Major contributions](#major-contributions)
- [Engineering challenges and lessons](#engineering-challenges-and-lessons)
- [Running the project](#running-the-project)
- [Future work](#future-work)
- [Acknowledgements](#acknowledgements)
- [References and useful links](#references-and-useful-links)

---

## Executive summary

BreathState is an open-source, local-first application for heart rate and breathing signal acquisition, resonance frequency estimation, and guided biofeedback. Built using Flutter and Dart, it runs cross-platform (mobile, web, and WebXR) without relying on cloud services for data storage or processing.

Building on the initial 2025 prototype—which supported basic Polar H10 tracking, audio-based breathing estimation, and local SQLite storage—my GSoC 2026 project turns BreathState into a complete research platform. 

Key upgrades include:
- Native and Web Bluetooth support for Polar H10 (HR, R–R, raw ECG, accelerometer) and Vernier GDX-RB respiration belts.
- On-device physiological analytics (25 time-domain HRV metrics, 5 spectral bands, RSA, ECG-derived respiration, and psychophysiological indices).
- Real-time biofeedback dashboard with adaptive breathing guidance.
- An auditable implementation of Fisher and Lehrer's resonance frequency protocol, alongside Hasuo et al.'s sex/height estimation formula.
- WebXR VR biofeedback sanctuary for Meta Quest devices.
- Multi-patient database (Drift) with CSV exports and clinical screening tools (PHQ-9, GAD-7, PCL-5).
- A standalone Android BLE simulator to mock Polar devices during development.

---

## Motivation

While HRV biofeedback and resonance breathing are well-supported in literature, most existing apps are closed-source, expensive, or tied to proprietary SDKs and single platforms. Researchers often have to use different tools to record heart rate and respiration, then manually align and analyze the data offline.

BreathState solves this by combining sensor streaming, signal alignment, on-device analysis, guided feedback, and raw data export into a single open-source app. Everything runs locally to protect patient privacy and ensure reproducible research data.

---

## From the 2025 prototype to BreathState 2.0

| Area | 2025 foundation | GSoC 2026 result |
| --- | --- | --- |
| Cardiac sensing | Polar heart rate and R–R intervals | Native and Web Bluetooth support for HR, R–R, raw PMD ECG, and accelerometer streams |
| Respiration | Phone microphone | Vernier GDX-RB belt on native/web, synchronized with Polar, with microphone fallback |
| HRV analysis | Primarily RMSSD | 25 time-domain measures, five-band spectral analysis, RSA, coherence, SQI, stress, autonomic, and relaxation indices |
| Resonance frequency | Stepped trials ranked mainly by RMSSD | Composite trial analysis, a locked Fisher–Lehrer assessment, measured/estimated modes, quality gates, and a Hasuo formula estimate |
| Feedback | Standard guided breathing exercises | Real-time dashboard, adaptive pacing, custom protocols, phase-aware audio, ambience, and VR biofeedback |
| Data model | Single-user SQLite records | Multi-patient Drift schema, native SQLite and web WASM storage, audit records, history, details, and CSV export |
| User workflows | General patient-facing interface | Separate clinician, patient-with-Polar, and patient-without-Polar modes |
| Immersion | Not available | Two-way Flutter/WebXR bridge and a comfort-aware Meta Quest sanctuary |

---

## System architecture

BreathState uses a layered architecture to keep UI, platform-specific sensor drivers, analysis algorithms, and persistent storage decoupled.

<p align="center">
  <img src="https://raw.githubusercontent.com/Mr-Imperium/asset/main/architecture.png" alt="Architecture Diagram" width="500">
</p>

Flutter manages presentation, patient state, and audio guidance. Platform-specific transport code is handled via conditional Dart exports: `flutter_blue_plus` and native SQLite on mobile, versus Web Bluetooth and Drift WASM on web. 

All clinical calculations and session records remain inside Flutter. The WebXR view communicates via plain JSON messages over a `BroadcastChannel`, acting as a purely visual layer rather than handling patient data or biofeedback logic directly.

---

## Major contributions

### 1. Cross-platform biosignal acquisition

#### Polar H10
I replaced reliance on proprietary Polar SDKs with a pure-Dart BLE driver that implements the standard Bluetooth Heart Rate Service and Polar Measurement Data (PMD) protocol, referencing Polar's documentation and the [`bleakheart`](https://github.com/fsmeraldi/bleakheart) project.

Features include:
- HR and R–R interval parsing from standard BLE packets.
- Raw ECG streaming (signed 24-bit little-endian parsing) and 200 Hz 3-axis accelerometer data via PMD control characteristics.
- Stream auto-recovery and bounded timeouts.
- Shared parsing logic between Native BLE and Web Bluetooth to prevent unit conversion bugs across platforms.

#### Vernier Go Direct GDX-RB
Added native and web Dart drivers for the Vernier respiration belt using its GATT service protocol:
- Auto-discovery by service UUID.
- Respiration force streaming at 10 Hz.
- Concurrent streaming with Polar H10, falling back to microphone audio if no belt is connected.
- Dual-signal resampling to a uniform 4 Hz time base for synchronized cardiorespiratory analysis.

### 2. On-device physiological analytics

I wrote a modular, pure-Dart physiological engine to analyze R–R and respiration signals locally, matching conventions from Python's NeuroKit2 where applicable.

* **Time-domain HRV:** Computes 25 metrics including MeanNN, SDNN, RMSSD, pNN50, pNN20, HTI, TINN, and rolling SDANN/SDNNI windows.
* **Frequency-domain HRV:** Implements Welch PSD (on interpolated grids) and Lomb-Scargle (for raw R-R intervals) across ULF, VLF, LF, HF, and VHF bands, outputting both absolute and normalized spectral values.
* **RSA & ECG-Derived Respiration:** Computes respiratory sinus arrhythmia via peak-to-trough and Porges–Bohrer methods. Adds an ECG-derived respiration (EDR) pipeline using Pan-Tompkins peak detection to track breathing rate from R-peak amplitude and QRS baseline shifts.
* **Psychophysiological indices:** Calculates Baevsky Stress Index, LF/HF autonomic balance, parasympathetic tone, and a normalized 0–100 relaxation score.

### 3. Real-time biofeedback and adaptive pacing

The real-time feedback loop uses a sliding window over incoming R–R intervals to monitor signal quality, coherence, and instant HRV trends. The biofeedback view features:
- Dual waveform plots for R–R intervals and respiration.
- Live SQI (Signal Quality Index) tracking.
- Adaptive pacing that gently shifts target breathing rates based on real-time coherence trends.

### 4. Precise, auditable resonance-frequency assessment

Implemented the exact 14-minute, 55-second resonance frequency testing protocol outlined by Fisher & Lehrer (2022):
- Guides users through 78 complete breaths from 6.75 BPM down to 4.25 BPM.
- Pacing changes are locked to breath boundaries rather than clock time.
- Pre-processes R–R intervals using LOWESS smoothing, removes ectopic beats, and extracts peak-to-trough cardiac excursions to identify the optimal resonance frequency.
- Supports both "Measured" mode (when using the GDX-RB belt to confirm compliance) and "Estimated" mode (when using Polar alone).

### 5. Quick RF estimation

Added a quick resonance frequency calculator based on the Hasuo et al. (2024) height and sex regression formulas, giving users a quick baseline when a full 15-minute assessment isn't practical.

### 6. Guided breathing and audio engine

Updated the breathing engine with customizable pacing controls:
- Built-in templates: Resonance, Box, Equal, and 4-7-8 breathing, along with fully custom inhale/hold/exhale ratios.
- Phase-aware audio synthesis (metronome or continuous pitch-shifted hum) paired with customizable ambient audio tracks (rain, river, birds).
- Platform integration: Uses Android foreground services and screen wake locks to prevent playback interruption during long sessions.

### 7. Multi-patient database & clinical tools

Replaced the legacy single-user database with Drift, supporting cross-platform persistence (SQLite on native, WASM/IndexedDB on web).

- **Clinical Screening:** Added PHQ-9, GAD-7, and PCL-5 forms with automated scoring, severity flagging, and historical tracking.
- **Data Export:** Reconstruction of session histories with interactive charts and full CSV export for offline analysis in tools like R or Python.

### 8. Immersive WebXR biofeedback

Developed a WebXR biofeedback environment built with Three.js that runs directly in the Meta Quest browser.
- Uses a `BroadcastChannel` bridge to sync live breathing phase, session progress, and coherence metrics from Flutter into the VR scene.
- Environment visual dynamics (such as lighting shifts and sakura tree growth) react smoothly to sustained coherence levels, avoiding distracting jump-cuts or fast visual rewards during breathing sessions.

### 9. BLE physiology simulator

To simplify testing without needing physical hardware connected constantly, I built a standalone Android BLE simulator app in Flutter that emulates a Polar H10 strap.

- Advertises standard Heart Rate and Polar PMD GATT services.
- Generates synthetic 130 Hz ECG and 200 Hz accelerometer data.
- Includes controls for heart rate, respiratory rate, RSA intensity, ectopic beats, and artificial packet loss.

---

## Engineering challenges and lessons

### Syncing asynchronous Bluetooth streams
R–R intervals arrive irregularly after each heartbeat, whereas the respiration belt streams regularly at 10 Hz. Relying on BLE packet arrival timestamps caused timing jitter. I solved this by reconstructing beat timing using sample counts from the hardware frames directly, resampling both signals onto a shared 4 Hz grid only when performing joint calculations like RSA.

### Bridging Native BLE and Web Bluetooth APIs
Web Bluetooth has very different permission workflows, connection lifecycles, and event models compared to native mobile BLE (`flutter_blue_plus`). Instead of branching application logic throughout the UI, I wrote a unified Dart interface wrapper, isolating transport-specific code into small platform adapters.

### Faithfully reproducing scientific protocols
Translating clinical assessment specifications into real-time code required strict adherence to published literature. For example, the Fisher & Lehrer (2022) protocol requires pacing adjustments to be locked precisely to breathing cycle boundaries rather than elapsed clock seconds, and pre-processing R–R data with LOWESS smoothing and ectopic beat suppression. Implementing these mathematical pipelines purely in Dart ensured cross-platform consistency and verifiable analytical output without relying on external server processing.

### WebXR performance and state isolation
Initial prototypes running WebXR rendered jittery visuals when Flutter updated the state too frequently. I decoupled the rendering loop completely: Flutter acts as the single source of truth and broadcasts low-frequency state snapshots, allowing the VR scene to interpolate animations locally at native refresh rates (90/120 Hz).

---

## Running the project

### Main application

```bash
flutter pub get
flutter run
```

For the web build:

```bash
flutter run -d chrome
```

Web Bluetooth requires a compatible browser and a secure context outside local development.

### BLE simulator

```bash
cd simulator
flutter pub get
flutter run
```

The simulator requires an Android device with BLE peripheral advertising support. Run BreathState on a second device for end-to-end testing.

### Automated validation

```bash
flutter test
node --test test/*.mjs

cd simulator
flutter analyze
flutter test
```
---

## Future work

- **Photoplethysmography (PPG) support:** Integrate camera-based or PPG wearable streams to expand accessibility for users without dedicated ECG or respiration hardware.
- **Expanded WebXR environments:** Introduce additional adaptive VR sanctuaries and custom audio-visual feedback loops.

---

## Acknowledgements

I am sincerely grateful to Dr. Suresh Krishna for his guidance throughout this project and for keeping the work connected to its scientific and human purpose. I also thank Zoran Matic, Oren Gurevitch, Alex Zhao, and Dr. Sachin Bhat, Dr. Ashok for their mentorship and feedback.

I thank INCF and Google Summer of Code for the opportunity to contribute to open neuroinformatics, and Michael Lewis for the 2025 BreathState foundation on which this work builds.

---

## References and useful links

- [Official GSoC 2026 project page](https://summerofcode.withgoogle.com/programs/2026/projects/axPxPpBS)
- [INCF GSoC 2026 project showcase](https://www.incf.org/incf-gsoc-2026-projects)
- [GSoC 2026 BreathState project discussion](https://neurostars.org/t/gsoc-2026-project-20-breathstate-contribution-a-phone-based-app-for-heart-rate-variability-biofeedback-and-resonance-breathing-protocols/35579)
- [BreathState GSoC 2025 final report](https://gist.github.com/michaelLewis04/126e29b5450704977f8c45c1d443813b)
- Fisher, L. R., & Lehrer, P. M. (2022). [A method for more accurate determination of resonance frequency of the cardiovascular system, and evaluation of a program to perform it](https://doi.org/10.1007/s10484-021-09524-0).
- Hasuo, H., Mori, K., Matsuoka, H., Sakuma, H., & Ishikawa, H. (2024). [An estimation formula for resonance frequency using sex and height for healthy individuals and patients with incurable cancers](https://doi.org/10.1007/s10484-023-09602-5).
- Lehrer, P. M., & Gevirtz, R. (2014). [Heart rate variability biofeedback: how and why does it work?](https://doi.org/10.3389/fpsyg.2014.00756).
- Pan, J., & Tompkins, W. J. (1985). [A real-time QRS detection algorithm](https://doi.org/10.1109/TBME.1985.325532).
- Charlton, P. H. et al. (2016). [An assessment of algorithms to estimate respiratory rate from the electrocardiogram and photoplethysmogram](https://doi.org/10.1088/0967-3334/37/4/610).
- [NeuroKit2](https://github.com/neuropsychology/NeuroKit)
- [bleakheart](https://github.com/fsmeraldi/bleakheart)

---
