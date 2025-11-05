# 🏠 OdioRent

A comprehensive Flutter-based rental property management application that connects renters, landlords, and administrators in one seamless platform.

## 📱 Features

### For Renters
- 🔍 Browse and search available properties
- 💬 Real-time chat with landlords about properties
- 🏘️ View detailed property information (price, location, beds, rooms)
- 📸 Browse property image galleries
- 🔔 Receive notifications (coming soon)

### For Landlords
- ➕ Add and manage properties
- 🏠 View all listed properties
- 🔎 Search through your properties
- 💬 Respond to renter inquiries via real-time chat
- 📊 Property analytics (coming soon)
- 🔔 Get notifications about property inquiries

### For Admins
- 👥 View and manage all users
- 🏘️ Monitor all properties on the platform
- ✅ Approve or reject property listings
- 📊 Platform-wide analytics dashboard

## 🎨 Design

- **Theme:** Modern green palette (#4CAF50, #66BB6A)
- **UI/UX:** Clean, intuitive interface with smooth animations
- **Responsive:** Works on Android, iOS, Web, and Desktop platforms

## 🚀 Installation Guide

### Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   # Check Flutter version
   flutter --version
   ```
   If not installed, download from [flutter.dev](https://flutter.dev/docs/get-started/install)

2. **Dart SDK** (included with Flutter)

3. **Git**
   ```bash
   git --version
   ```

4. **Android Studio** (for Android development) or **Xcode** (for iOS development)

5. **VS Code** or **Android Studio** (recommended IDEs)

### Step 1: Clone the Repository

```bash
git clone https://github.com/Sl4cK0TH/odiorent.git
cd odiorent
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This will install all required packages listed in `pubspec.yaml`.

### Step 3: Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)

2. Create the following tables in your Supabase database:

   **profiles table:**
   ```sql
   CREATE TABLE profiles (
     id UUID REFERENCES auth.users PRIMARY KEY,
     email TEXT UNIQUE NOT NULL,
     role TEXT NOT NULL CHECK (role IN ('renter', 'landlord', 'admin')),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

   **properties table:**
   ```sql
   CREATE TABLE properties (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     landlord_id UUID REFERENCES auth.users NOT NULL,
     name TEXT NOT NULL,
     description TEXT,
     address TEXT NOT NULL,
     price DECIMAL(10,2) NOT NULL,
     beds INTEGER NOT NULL,
     rooms INTEGER NOT NULL,
     image_urls TEXT[] DEFAULT '{}',
     status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

   **chats table:**
   ```sql
   CREATE TABLE chats (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     renter_id UUID REFERENCES auth.users NOT NULL,
     landlord_id UUID REFERENCES auth.users NOT NULL,
     property_id UUID REFERENCES properties NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     UNIQUE(renter_id, landlord_id, property_id)
   );
   ```

   **messages table:**
   ```sql
   CREATE TABLE messages (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     chat_id UUID REFERENCES chats NOT NULL,
     sender_id UUID REFERENCES auth.users NOT NULL,
     sender_email TEXT NOT NULL,
     content TEXT NOT NULL,
     timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

3. Create a storage bucket named `property-images` for property photos

4. Set up Row Level Security (RLS) policies for your tables

5. Get your Supabase credentials:
   - Project URL
   - Anon/Public Key

6. Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

### Step 4: Run the Application

#### For Android/iOS Emulator:
```bash
# List available devices
flutter devices

# Run on connected device
flutter run
```

#### For Web:
```bash
flutter run -d chrome
```

#### For Linux Desktop:
```bash
flutter run -d linux
```

#### For Production Build:
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Step 5: Create Admin Account (First Time Setup)

1. Run the app and sign up with an account
2. Go to your Supabase dashboard → Authentication → Users
3. Find your user and manually update the role in the `profiles` table to `'admin'`
4. Restart the app and log in - you'll now have admin access

## 📦 Dependencies

Key packages used in this project:

- `supabase_flutter: ^2.10.3` - Backend & Authentication
- `image_picker: ^1.1.2` - Property image uploads
- `cached_network_image: ^3.4.1` - Efficient image loading
- `path_provider: ^2.1.5` - File system access
- `shared_preferences: ^2.3.3` - Local data persistence
- `app_links: ^6.3.3` - Deep linking support

## 🗂️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── message.dart
│   ├── property.dart
│   └── user.dart
├── screens/                  # UI screens
│   ├── admin/               # Admin screens
│   ├── landlord/            # Landlord screens
│   ├── renter/              # Renter screens
│   ├── shared/              # Shared screens (auth, chat)
│   └── splash_screen.dart
├── services/                # Backend services
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── storage_service.dart
└── widgets/                 # Reusable widgets
    ├── custom_button.dart
    ├── property_card.dart
    └── ...
```

## 🔐 User Roles

The application supports three user roles:

1. **Renter** - Browse properties and chat with landlords
2. **Landlord** - List and manage properties, respond to renters
3. **Admin** - Manage users and approve properties

## 🛠️ Development

### Running Tests
```bash
flutter test
```

### Code Formatting
```bash
flutter format .
```

### Analyze Code
```bash
flutter analyze
```

## 📝 Environment Setup

### Android
- Minimum SDK: 21
- Target SDK: 34

### iOS
- Minimum iOS Version: 12.0

### Web
- Compatible with modern browsers (Chrome, Firefox, Safari, Edge)

## 🐛 Troubleshooting

### Common Issues

1. **"Supabase not initialized"**
   - Make sure you've added your Supabase credentials in `main.dart`

2. **"Image picker not working"**
   - Ensure you've added camera/gallery permissions in `AndroidManifest.xml` (Android) or `Info.plist` (iOS)

3. **"Build failed"**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **"Database error"**
   - Verify all tables are created in Supabase
   - Check RLS policies are configured correctly

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

**Sl4cK0TH**
- GitHub: [@Sl4cK0TH](https://github.com/Sl4cK0TH)
- Email: davidbelle772@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- All contributors and users of OdioRent

## 📱 Screenshots

_Coming soon..._

## 🗺️ Roadmap

- [x] User authentication (Renter, Landlord, Admin)
- [x] Property listing and management
- [x] Real-time chat between renters and landlords
- [x] Admin dashboard with property approval
- [ ] Push notifications
- [ ] Property analytics
- [ ] Payment integration
- [ ] Reviews and ratings
- [ ] Favorite properties
- [ ] Advanced search filters
- [ ] Map view for properties

---

Made with ❤️ using Flutter
