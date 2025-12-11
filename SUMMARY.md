# Project Summary - OdioRent

## 1. Project Overview

**OdioRent** is a mobile application built with Flutter that aims to modernize the property rental market in Odiongan, Romblon. The app serves as a centralized platform connecting property owners (Landlords) with potential tenants (Renters), with an administrative backend for oversight (Admins).

### User Roles

- **Renters:** Can browse, search, and view details of available rental properties. They can bookmark favorites, rate properties, request bookings, track booking status, and communicate with landlords via real-time chat.
- **Landlords:** Can list their properties for rent with images and video tours, manage their listings (create, update, delete), respond to booking requests (approve/reject/cancel), and communicate with potential renters.
- **Admins:** Can oversee the platform, approve or reject new property listings, and manage user accounts.

## 2. Technology Stack

- **Frontend:** Flutter (SDK ^3.9.2)
- **Backend-as-a-Service (BaaS):** Firebase
  - **Database:** Cloud Firestore (NoSQL, real-time)
  - **Authentication:** Firebase Auth (Email/Password)
  - **Storage:** Firebase Storage (profile images), Cloudinary (property images/videos, 25GB free tier)
  - **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Primary Language:** Dart
- **Key Packages:**
  - `cloud_firestore: ^5.6.12` - Real-time database
  - `firebase_auth: ^5.7.0` - User authentication
  - `firebase_messaging: ^15.2.10` - Push notifications
  - `cloudinary_public: ^0.21.0` - Media storage and optimization
  - `video_player: ^2.9.2` & `chewie: ^1.8.5` - Video playback
  - `video_compress: ^3.1.3` - Video compression
  - `intl: ^0.19.0` - Date formatting and localization

**Important Migration:** This project was migrated from Supabase (PostgreSQL) to Firebase on December 11, 2025. All backend services now use Firebase.

## 3. Core Features

### Property Management
- **Landlord CRUD Operations:** Full create, read, update, delete functionality for property listings
- **Anti-Duplication:** Database-level check prevents landlords from creating properties with identical names
- **Standardized Addresses:** Dropdown selection for Odiongan's Barangays plus text field for street/house number
- **Image & Video Support:** Multiple property images and one required video tour per property
- **Cloudinary Integration:** Automatic image/video compression and optimization

### Search & Discovery
- **Advanced Search:** Multi-field search across property names, addresses, descriptions, and landlord names
- **Real-time Results:** Firestore queries with instant updates as properties are added/modified
- **Bookmarks:** Renters can save favorite properties for quick access

### Ratings & Reviews
- **5-Star Rating System:** Renters can rate properties (1-5 stars) and leave text comments
- **Real-time Aggregation:** Average ratings and review counts calculated automatically
- **Display Integration:** Ratings visible on property cards and detail screens with star icons

### Virtual Tours
- **Video Tours:** Each property must include one video tour
- **Fullscreen Playback:** High-quality video player with controls (powered by Chewie)
- **Like Functionality:** Users can like videos, with real-time like counts
- **Compression:** Videos are compressed before upload to optimize storage and bandwidth

### Booking System
- **Booking Requests:** Renters submit booking requests with:
  - Editable renter name (auto-fills from profile)
  - Move-in date selection with date picker
  - Duration options: 1, 2, 3, 6, 9, 12, 18, 24, 36 months
  - Number of occupants (1-50 via text field)
- **Approval Workflow:** 
  - Landlords can approve, reject, or cancel bookings
  - All status changes require a reason/explanation
- **Status Tracking:** Six booking states:
  - `pending` - Initial request submitted
  - `approved` - Landlord approved the request
  - `active` - Tenant has moved in
  - `completed` - Rental period finished
  - `rejected` - Landlord rejected the request
  - `cancelled` - Either party cancelled
- **Availability Validation:** Automatic date overlap checking prevents double-booking
- **Financial Transparency:**
  - Monthly rent display
  - Security deposit (2 months rent)
  - Total amount calculation
  - Payment method: Over the Counter
- **Real-time Notifications:** Badge indicators show pending booking counts
- **Booking Management Screens:**
  - Renters: Create booking, view all bookings with filters, detailed booking view with cancel option
  - Landlords: View all booking requests with filters, detailed view with approve/reject actions

### Real-time Chat
- **Messaging System:** Fully functional chat with:
  - Real-time message delivery
  - Presence detection (online/offline status)
  - Typing indicators
  - Read receipts
  - Multimedia support (images, videos)
- **Firestore Streams:** Instant message updates using Firestore real-time listeners

### Authentication & Security
- **Firebase Authentication:** Secure email/password authentication
- **Role-based Access:** Different permissions and interfaces for renters, landlords, and admins
- **Firestore Security Rules:** Database-level security configured in firebase.json

### Admin Dashboard
- **Property Review:** Approve or reject new property listings before they become visible to renters
- **User Management:** Oversee user accounts and activity

## 4. Development History & Key Milestones

### Phase 1: Initial Development (Supabase Era)
- Implemented user roles and authentication
- Built property CRUD with PostgreSQL RPC function for multi-column search
- Created ratings system with `property_ratings` table and `properties_with_avg_rating` view
- Developed real-time chat with presence detection
- Resolved Row Level Security (RLS) policy issues and circular dependency bugs

### Phase 2: Firebase Migration (December 2025)
- **Migration Reason:** Better Flutter integration, simpler real-time updates, superior FCM support
- Migrated from PostgreSQL to Cloud Firestore
- Replaced Supabase Auth with Firebase Auth
- Migrated Supabase Storage to Cloudinary for images/videos
- Rewrote all database queries to use Firestore collections
- Implemented Firebase Cloud Messaging for push notifications
- Updated all screens and services for Firebase compatibility

### Phase 3: Booking System Implementation
- **Models:** Created Booking model with BookingStatus enum and Firestore serialization
- **Database:** Added 15+ booking-related methods to FirebaseDatabaseService
  - `createBooking()` with overlap validation
  - Stream methods for real-time updates
  - Convenience methods: `approveBooking()`, `rejectBooking()`, `cancelBooking()`
  - `isPropertyAvailable()` for date conflict checking
- **Renter UI:** Built CreateBookingScreen, MyBookingsScreen, BookingDetailsScreen
- **Landlord UI:** Built LandlordBookingsScreen, LandlordBookingDetailsScreen
- **Navigation:** Integrated bookings into both renter and landlord home screens with badge indicators

### Phase 4: UI/UX Refinements
- Changed booking feature color from red to green (0xFF4CAF50) for consistency
- Made renter name field editable (previously auto-filled only)
- Changed occupants from dropdown to number text field (1-50 range)
- Added 1 and 2 month duration options
- Added payment method display throughout booking flow
- Reorganized landlord navigation (moved notifications to appbar top-right)
- Implemented red badge indicators showing booking counts

## 5. Current Project State

### Completed Features
✅ User authentication (Firebase Auth)  
✅ Property CRUD with anti-duplication  
✅ Advanced multi-field search  
✅ 5-star ratings and reviews  
✅ Property bookmarks  
✅ Virtual tours with video playback  
✅ Real-time chat with presence detection  
✅ Admin property approval system  
✅ **Booking request/approval workflow**  
✅ **Real-time booking status tracking**  
✅ **Date conflict validation**  
✅ **Financial transparency with payment method**  
✅ **Badge indicators for pending bookings**  
✅ Cloudinary integration for media storage  
✅ Firebase Cloud Messaging for push notifications  

### Code Health
- `flutter analyze` reports **0 issues**
- All Firebase services configured and operational
- Cloudinary media storage functional
- Real-time Firestore streams working across all features

### Known Limitations
- Payment processing is manual ("Over the Counter" only)
- Video upload limited by Cloudinary free tier (25GB)
- No automated booking expiration/renewal system yet
- Push notifications configured but not fully integrated into booking workflow

### Firestore Collections Structure
```
users/
  - userId: { email, firstName, lastName, role, etc. }
properties/
  - propertyId: { name, address, price, landlordId, images, videoUrl, etc. }
bookings/
  - bookingId: { propertyId, renterId, landlordId, status, dates, financial, etc. }
chats/
  - chatId: { participants, lastMessage, unreadCount, etc. }
messages/
  - messageId: { chatId, senderId, content, timestamp, etc. }
ratings/
  - ratingId: { propertyId, userId, rating, comment, etc. }
bookmarks/
  - bookmarkId: { userId, propertyId, timestamp }
videoLikes/
  - likeId: { propertyId, userId, timestamp }
```

## 6. Next Steps & Future Enhancements

### Immediate Priorities
- Integrate push notifications with booking status changes
- Add booking expiration/renewal system
- Implement payment gateway integration (GCash, PayMaya, etc.)
- Add booking calendar view for landlords
- Enhance admin dashboard with analytics

### Long-term Goals
- Property verification system
- In-app payment processing
- Tenant screening and background checks
- Maintenance request tracking
- Lease agreement digital signing
- Multi-language support (Tagalog, English)
- iOS app release

## 7. Build & Deployment

### Development
- Run renter interface: `flutter run`
- Run landlord/admin interface: `flutter run lib/main_admin.dart`

### Release
- Android APK: `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

### Current Branch
- Active development branch: `firebase-migration`
- Repository: https://github.com/Sl4cK0TH/odiorent

## 8. Configuration Requirements

### Firebase Setup
1. Create Firebase project at firebase.google.com
2. Enable Authentication (Email/Password)
3. Create Firestore database (production mode)
4. Enable Firebase Storage
5. Enable Cloud Messaging
6. Download `google-services.json` → `android/app/`
7. Download `GoogleService-Info.plist` → `ios/Runner/`

### Cloudinary Setup
1. Create account at cloudinary.com
2. Get Cloud Name, API Key, API Secret
3. Create unsigned upload preset
4. Configure in `lib/services/storage_service.dart`

### Environment Variables
No `.env` file needed - all configuration in Firebase and Cloudinary dashboards.
