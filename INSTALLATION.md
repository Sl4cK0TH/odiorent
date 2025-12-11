# Installation and Build Guide for OdioRent

This document provides detailed instructions on how to set up the OdioRent project on a new development machine and how to build a release version of the Android application.

## Part 1: Prerequisites

Before you begin, ensure your development environment has the following software installed.

### 1.1. Git
Git is required for cloning the project repository.
- **To Install:** Download it from the [official Git website](https://git-scm.com/downloads).
- **To Verify:** Open a terminal and run `git --version`.

### 1.2. Flutter SDK
Flutter is the UI toolkit used for this application.
- **To Install:** Follow the official [Flutter installation guide](https://flutter.dev/docs/get-started/install) for your specific operating system (Windows, macOS, or Linux). This guide will also help you set up Dart.
- **Recommended Version:** Flutter SDK ^3.9.2
- **To Verify:** Run `flutter doctor` in your terminal. This command checks your environment and displays a report of the status of your Flutter installation. Address any issues it reports.

### 1.3. IDE (Integrated Development Environment)
You need a code editor to work with the project. Visual Studio Code is recommended.
- **To Install:** Download [VS Code](https://code.visualstudio.com/).
- **Recommended Extensions:**
  - `Flutter` (provides Flutter support and developer tools).
  - `Dart` (provides language support for Dart).

## Part 2: Firebase Backend Setup

This project uses Firebase for its backend (database, authentication, storage, and push notifications).

### 2.1. Create a Firebase Project

1.  **Create a Firebase Account:** Go to [firebase.google.com](https://firebase.google.com) and sign in with your Google account.
2.  **Create a New Project:** 
    - Click "Add project" or "Create a project"
    - Give it a name (e.g., "OdioRent")
    - Choose whether to enable Google Analytics (optional)
    - Click "Create project"

### 2.2. Enable Firebase Services

#### Authentication
1. In the Firebase Console, go to **Build > Authentication**
2. Click "Get Started"
3. Enable **Email/Password** sign-in method
4. Click "Save"

#### Firestore Database
1. Go to **Build > Firestore Database**
2. Click "Create database"
3. Choose **Production mode** (security rules are already configured in the app)
4. Select a Cloud Firestore location (choose closest to your target users)
5. Click "Enable"

#### Storage
1. Go to **Build > Storage**
2. Click "Get Started"
3. Choose **Production mode**
4. Select a storage location
5. Click "Done"

#### Cloud Messaging (Push Notifications)
1. Go to **Build > Cloud Messaging**
2. Click "Get Started" if prompted
3. The service will be automatically enabled

### 2.3. Configure Firebase for Android

1. In the Firebase Console, click the **Android icon** to add an Android app
2. Register your app with the package name: `com.example.odiorent` (or your custom package name)
3. Download the `google-services.json` file
4. Place it in the `android/app/` directory of your Flutter project

### 2.4. Configure Firebase for iOS

1. In the Firebase Console, click the **iOS icon** to add an iOS app
2. Register your app with the bundle ID (found in `ios/Runner/Info.plist`)
3. Download the `GoogleService-Info.plist` file
4. Place it in the `ios/Runner/` directory of your Flutter project

### 2.5. Firebase Configuration File

The Firebase configuration is located in `lib/firebase_options.dart`. This file is already included in the project. If you need to regenerate it:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run configuration
flutterfire configure
```

## Part 3: Cloudinary Setup

This project uses Cloudinary for image and video storage.

1.  **Create a Cloudinary Account:** Go to [cloudinary.com](https://cloudinary.com) and sign up for a free account.
2.  **Get API Credentials:**
    - Go to your Cloudinary Dashboard
    - Find your **Cloud Name**, **API Key**, and **API Secret**
3.  **Configure in Project:**
    - Open `lib/services/storage_service.dart`
    - Update the CloudinaryPublic constructor with your credentials:
      ```dart
      final cloudinary = CloudinaryPublic('your-cloud-name', 'your-upload-preset', cache: false);
      ```
4.  **Create Upload Preset:**
    - In Cloudinary Dashboard, go to **Settings > Upload**
    - Scroll to "Upload presets"
    - Click "Add upload preset"
    - Set Signing Mode to "Unsigned"
    - Configure folder, transformations, etc. as needed
    - Copy the preset name and use it in the code above

## Part 4: Local Project Setup

Now, set up the Flutter project on your local machine.

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/Sl4cK0TH/odiorent.git
    cd odiorent
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Verify Configuration:**
    - Ensure `google-services.json` is in `android/app/`
    - Ensure `GoogleService-Info.plist` is in `ios/Runner/`
    - Ensure Cloudinary credentials are configured in `lib/services/storage_service.dart`

## Part 5: Running and Building the Application

### 5.1. Run in Debug Mode

To run the app on a connected device or emulator for development and testing:

**Renter Interface:**
```bash
flutter run
```

**Landlord/Admin Interface:**
```bash
flutter run lib/main_admin.dart
```

### 5.2. Build a Release APK (for Android)

To build a release version of the app for Android:

```bash
flutter build apk --release
```

The output APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### 5.3. Build an App Bundle (Recommended for Google Play)

```bash
flutter build appbundle --release
```

The output bundle will be at `build/app/outputs/bundle/release/app-release.aab`.

### 5.4. Troubleshooting Common Build Issues

#### Gradle Daemon Crash
If you see an error like `Gradle build daemon disappeared unexpectedly`, it's often due to a lack of memory. Try the following:

```bash
# Navigate to the android directory
cd android
./gradlew clean
cd ..

# Clean Flutter build cache
flutter clean

# Try building again
flutter build apk --release
```

#### Java Compiler (JDK) Not Found
If you encounter an error like `Toolchain installation does not provide the required capabilities: [JAVA_COMPILER]`:

**Solution:** Explicitly set the `JAVA_HOME` environment variable to point to your JDK installation path.

**Linux/macOS:**
```bash
export JAVA_HOME=/path/to/your/jdk
```

**Windows:**
```cmd
set JAVA_HOME=C:\path\to\your\jdk
```

#### Firebase Configuration Issues
If you encounter Firebase-related errors:
- Verify `google-services.json` and `GoogleService-Info.plist` are in the correct directories
- Run `flutterfire configure` to regenerate configuration
- Ensure all Firebase services are enabled in the Firebase Console

#### Cloudinary Upload Failures
If image/video uploads fail:
- Verify your Cloud Name and Upload Preset are correct
- Check that the upload preset is set to "Unsigned" mode
- Ensure your Cloudinary account has sufficient storage (free tier: 25GB)
    -   On Linux/macOS, find the path with `which javac` and add the following to your `~/.bashrc` or `~/.zshrc`:
        ```bash
        export JAVA_HOME="/path/to/your/jdk"
        ```
        (Remember to use the correct path and `source` the file or restart your terminal.)
