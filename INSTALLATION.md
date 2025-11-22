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
- **To Verify:** Run `flutter doctor` in your terminal. This command checks your environment and displays a report of the status of your Flutter installation. Address any issues it reports.

### 1.3. IDE (Integrated Development Environment)
You need a code editor to work with the project. Visual Studio Code is recommended.
- **To Install:** Download [VS Code](https://code.visualstudio.com/).
- **Recommended Extensions:**
  - `Flutter` (provides Flutter support and developer tools).
  - `Dart` (provides language support for Dart).

## Part 2: Supabase Backend Setup

This project uses Supabase for its backend (database, authentication, etc.).

1.  **Create a Supabase Account:** Go to [supabase.com](https://supabase.com) and sign up for a free account.
2.  **Create a New Project:** From your Supabase dashboard, create a new project. Give it a name (e.g., "OdioRent") and generate a secure database password.
3.  **Run Database Schema:**
    -   Navigate to the **SQL Editor** in your Supabase project dashboard.
    -   Find the `supabase/schema.sql` file in this project's repository.
    -   Copy the entire content of the file.
    -   Paste the content into a new query in the SQL Editor and click **RUN**. This will set up all your tables, views, functions, and security policies.
4.  **Get API Credentials:**
    -   Go to your project's **Settings > API**.
    -   You will need two values: the **Project URL** and the **Project API Keys (anon public key)**. Keep this page open.

## Part 3: Local Project Setup

Now, set up the Flutter project on your local machine.

1.  **Clone the Repository:**
    ```bash
    git clone <your-repository-url>
    cd odiorent
    ```
2.  **Create the Environment File:**
    -   In the root directory of the project, create a new file named `.env`.
    -   **Important:** This file is intentionally ignored by Git (via `.gitignore`) to keep your secret keys out of version control.
    -   Add your Supabase credentials to this file as follows:
        ```
        SUPABASE_URL=https://your-project-url.supabase.co
        SUPABASE_ANON_KEY=your-public-anon-key
        ```
    -   Replace the placeholder values with the actual URL and anon key from your Supabase API settings.
3.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

## Part 4: Running and Building the Application

### 4.1. Run in Debug Mode
To run the app on a connected device or emulator for development and testing:
```bash
flutter run
```

### 4.2. Build a Release APK (for Android)
To build a release version of the app for Android:
```bash
flutter build apk --release
```
The output APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### 4.3. Troubleshooting Common Build Issues

-   **Gradle Daemon Crash:** If you see an error like `Gradle build daemon disappeared unexpectedly`, it's often due to a lack of memory. Try the following command to clean the Gradle cache:
    ```bash
    # Navigate to the android directory first
    cd android
    ./gradlew clean
    cd ..
    # Then try building again
    flutter build apk --release
    ```

-   **Java Compiler (JDK) Not Found:** If you encounter an error like `Toolchain installation does not provide the required capabilities: [JAVA_COMPILER]`, it means Gradle can't find your JDK, or the installation is incomplete.
    -   **Solution:** Explicitly set the `JAVA_HOME` environment variable to point to your JDK installation path.
    -   On Linux/macOS, find the path with `which javac` and add the following to your `~/.bashrc` or `~/.zshrc`:
        ```bash
        export JAVA_HOME="/path/to/your/jdk"
        ```
        (Remember to use the correct path and `source` the file or restart your terminal.)
