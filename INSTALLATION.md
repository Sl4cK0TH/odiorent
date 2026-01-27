# Installation and Build Guide for OdioRent

This document provides detailed instructions on how to set up the OdioRent project on a new development machine and how to build a release version of the application.

---

## Part 1: Clone the Repository

Start by getting the source code.
*Note: This step requires Git to be installed (see Part 2).*

**Option A: Using Git (Recommended)**

**Windows / macOS / Linux:**
Open your terminal (Command Prompt, PowerShell, or Terminal) and run:
```bash
git clone https://github.com/Sl4cK0TH/odiorent.git
cd odiorent
```

**Option B: Download ZIP**
If you don't have Git yet, you can download the [ZIP file from GitHub](https://github.com/Sl4cK0TH/odiorent/archive/refs/heads/main.zip) and extract it.

---

## Part 2: Prerequisites

Ensure your development environment has the following software installed.

### 2.1. Git
Git is required for version control.

**Windows:**
1.  Download the **64-bit Git for Windows Setup** from [git-scm.com](https://git-scm.com/download/win).
2.  Run the installer and follow the prompts.
3.  Open **Command Prompt** or **PowerShell** and verify:
    ```cmd
    git --version
    ```

**macOS / Linux:**
-   **macOS:** `brew install git`
-   **Linux (Ubuntu/Debian):**
    ```bash
    sudo apt update
    sudo apt install git
    ```
-   **Verify:**
    ```bash
    git --version
    ```

### 2.2. Node.js (Required for Firebase CLI)

**Windows:**
1.  Download [Node.js LTS](https://nodejs.org/).
2.  Install (ensure "Add to PATH" is selected).
3.  Verify:
    ```cmd
    node --version
    npm --version
    ```

**macOS / Linux:**
-   **macOS:** `brew install node`
-   **Linux:**
    ```bash
    sudo apt install nodejs npm
    ```
-   **Verify:**
    ```bash
    node --version
    npm --version
    ```

### 2.3. Flutter SDK

1.  **Download:** Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install).
2.  **Add to PATH:** Add `flutter/bin` to your system PATH.
3.  **Verify (All OS):**
    ```bash
    flutter doctor
    ```

### 2.4. IDE
**Visual Studio Code** is recommended.
-   Install [VS Code](https://code.visualstudio.com/).
-   Install **Flutter** and **Dart** extensions.

---

## Part 3: Install Project Dependencies

Once you have Flutter installed and the repo cloned:

**Windows / macOS / Linux:**
```bash
cd odiorent
flutter pub get
```

---

## Part 4: Firebase Backend Setup

### 4.1. Install Firebase CLI

**Windows:**
```cmd
npm install -g firebase-tools
```

**macOS / Linux:**
```bash
sudo npm install -g firebase-tools
```

### 4.2. Login and Configure

1.  **Login:**
    ```bash
    firebase login
    ```

2.  **Install FlutterFire CLI:**
    ```bash
    dart pub global activate flutterfire_cli
    ```
    **Add to PATH:**
    -   **Windows:** Add `%LOCALAPPDATA%\Pub\Cache\bin` to PATH.
    -   **macOS/Linux:** Add `export PATH="$PATH":"$HOME/.pub-cache/bin"` to `~/.zshrc` or `~/.bashrc`.

3.  **Configure:**
    ```bash
    flutterfire configure
    ```
    -   Select project, select platforms (Android, iOS).

### 4.3. Manual Verification
-   **Android:** Ensure `android/app/google-services.json` exists.
-   **iOS:** Ensure `ios/Runner/GoogleService-Info.plist` exists.

---

## Part 5: Cloudinary Setup

1.  **Account:** Sign up at [cloudinary.com](https://cloudinary.com).
2.  **Credentials:** Get Cloud Name, API Key, API Secret from Dashboard.
3.  **Upload Preset:**
    -   Settings > Upload > Upload presets > Add upload preset.
    -   Mode: **Unsigned**.
    -   Name: e.g., `odiorent_uploads`.
4.  **Update Code:**
    -   Edit `lib/services/cloudinary_service.dart`:
    ```dart
    static const String _cloudName = 'YOUR_CLOUD_NAME';
    static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';
    ```

---

## Part 6: Building and Running

### 6.1. Run in Debug Mode

**Renter App (Mobile):**
```bash
flutter run
```

**Admin Web Panel:**
```bash
flutter run -d chrome -t lib/main_admin.dart
```

### 6.2. Build Release APK

**Windows:**
```cmd
flutter build apk --release
```

**macOS / Linux:**
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

---

## Troubleshooting

### Java/Gradle Issues

**Windows:**
```cmd
set JAVA_HOME="C:\Program Files\Java\jdk-17"
```

**macOS / Linux:**
```bash
export JAVA_HOME="/path/to/your/jdk"
```

### Release Build Fails?
```bash
flutter clean
flutter pub get
flutter build apk --release
```
