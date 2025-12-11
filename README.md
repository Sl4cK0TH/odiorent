# OdioRent - Property Rental Application

OdioRent is a Flutter-based mobile application designed to streamline the property rental process in Odiongan, Romblon. It connects renters with landlords, providing a comprehensive platform for browsing listings, managing properties, booking rentals, and facilitating communication.

## Features

### Core Features
- **User Roles:** Separate interfaces and functionalities for Renters, Landlords, and Admins
- **Property Listings:** Landlords can create, update, and delete property listings with multiple images and detailed descriptions
- **Advanced Search:** Renters can search for properties using keywords that match property names, addresses, descriptions, or landlord names
- **Property Ratings & Reviews:** Renters can rate properties (1-5 stars) and leave comments, with real-time average rating calculations
- **Virtual Tours:** Properties include video tours with like functionality and fullscreen playback (1 video required per property)
- **Bookmarks:** Renters can save favorite properties for quick access
- **Real-time Chat:** Fully functional messaging system with real-time presence detection, typing indicators, read receipts, and multimedia support
- **Admin Dashboard:** Admins can review and manage property listings (approve/reject) and user accounts

### Booking System
- **Booking Requests:** Renters can submit booking requests with customizable move-in dates and duration (1-36 months)
- **Approval Workflow:** Landlords can approve, reject, or cancel booking requests with mandatory reason explanations
- **Status Tracking:** Track booking status (pending, approved, active, completed, rejected, cancelled) with timestamps
- **Availability Validation:** Automatic date overlap checking prevents double-booking
- **Financial Summary:** Transparent breakdown of monthly rent, security deposit (2 months), and total amount
- **Payment Method:** Over-the-counter payment supported
- **Real-time Notifications:** Badge indicators show pending booking counts for both renters and landlords

### Security & Authentication
- **Secure Authentication:** Powered by Firebase Authentication for user sign-up, login, and profile management
- **Role-based Access Control:** Different permissions for renters, landlords, and admins

## Technology Stack

- **Frontend:** Flutter (SDK ^3.9.2)
- **Backend:** Firebase (Firestore, Authentication, Cloud Messaging, Storage)
- **Media Storage:** Cloudinary (images and videos with automatic compression)
- **Language:** Dart
- **State Management:** StatefulWidget with StreamBuilder for real-time updates

## Key Packages

- `cloud_firestore: ^5.6.12` - Real-time database
- `firebase_auth: ^5.7.0` - User authentication
- `firebase_messaging: ^15.2.10` - Push notifications
- `cloudinary_public: ^0.21.0` - Media storage and optimization
- `video_player: ^2.9.2` - Video playback
- `chewie: ^1.8.5` - Video player UI
- `video_compress: ^3.1.3` - Video compression before upload
- `intl: ^0.19.0` - Date formatting and localization

## Project Setup

Follow these steps to set up the development environment on a new machine.

### 1. Prerequisites

- **Flutter:** Ensure you have the Flutter SDK (^3.9.2) installed. If not, follow the official [Flutter installation guide](https://flutter.dev/docs/get-started/install)
- **Firebase Project:** You will need a Firebase project with Firestore, Authentication, and Storage enabled
- **Cloudinary Account:** Required for media storage. Sign up at [cloudinary.com](https://cloudinary.com)

### 2. Clone the Repository

Clone this project to your local machine:
```bash
git clone https://github.com/Sl4cK0TH/odiorent.git
cd odiorent
```

### 3. Firebase Configuration

#### A. Download Firebase Configuration Files
1. In your Firebase project console, add both Android and iOS apps
2. Download `google-services.json` (Android) and place it in `android/app/`
3. Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`

#### B. Initialize Firebase in Flutter
1. The Firebase configuration is already set up in `lib/firebase_options.dart`
2. Update the file with your Firebase project credentials if needed

#### C. Enable Firebase Services
1. **Authentication:** Enable Email/Password authentication in Firebase Console
2. **Firestore:** Create a Firestore database in production mode
3. **Storage:** Enable Firebase Storage for user profile images
4. **Cloud Messaging:** Enable for push notifications

### 4. Cloudinary Configuration

1. Create a Cloudinary account at [cloudinary.com](https://cloudinary.com)
2. Get your Cloud Name, API Key, and API Secret from the dashboard
3. Update `lib/services/cloudinary_service.dart` with your credentials:
   ```dart
   final cloudinary = CloudinaryPublic('your-cloud-name', 'your-upload-preset', cache: false);
   ```

### 5. Install Dependencies

Fetch the project dependencies:
```bash
flutter pub get
```

### 6. Run the Application

Run the app on your desired device (emulator or physical device):
```bash
flutter run
```

For the landlord/admin interface:
```bash
flutter run lib/main_admin.dart
```