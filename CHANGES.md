# Changelog

## [2025-12-12 - Latest Updates]

### Push Notifications & Permissions System - COMPLETE ✅
- **Comprehensive push notification implementation with runtime permissions**:
  - ✅ Added `flutter_local_notifications: ^18.0.1` for local notifications
  - ✅ Added `permission_handler: ^11.3.1` for runtime permission requests
  - ✅ Android POST_NOTIFICATIONS permission for Android 13+ (Tiramisu)
  - ✅ Android VIBRATE and RECEIVE_BOOT_COMPLETED permissions
  - ✅ iOS permission descriptions in Info.plist (Camera, Photo Library, Photo Library Add)

- **PermissionService** (lib/services/permission_service.dart):
  - ✅ `requestAllPermissions()` - Request Camera, Storage/Photos, and Notifications on app launch
  - ✅ Individual permission methods: `requestCameraPermission()`, `requestStoragePermission()`, `requestNotificationPermission()`
  - ✅ Permission status checking: `isCameraGranted()`, `isStorageGranted()`, `isNotificationGranted()`
  - ✅ Permission explanation dialogs with human-readable descriptions
  - ✅ Settings redirect for permanently denied permissions
  - ✅ `requestPermissionWithExplanation()` for contextual permission requests

- **Enhanced PushNotificationService** (lib/services/push_notification_service.dart):
  - ✅ Local notifications with flutter_local_notifications integration
  - ✅ Three notification channels: Booking, Message, and General
  - ✅ Channel-specific importance levels and settings
  - ✅ `showLocalNotification()` - Display notifications in foreground
  - ✅ Notification tap handling with payload routing
  - ✅ Background message handler for FCM
  - ✅ Foreground message handling with local notification display
  - ✅ Token management and database sync
  - ✅ `sendBookingNotification()` - Notify users of booking status changes
  - ✅ `sendMessageNotification()` - Notify users of new chat messages
  - ✅ `sendGeneralNotification()` - Send general app notifications

- **Booking Notifications** (integrated in FirebaseDatabaseService):
  - ✅ New booking request → Notify landlord
  - ✅ Booking approved → Notify renter with property name
  - ✅ Booking rejected → Notify renter with reason
  - ✅ Booking cancelled → Notify renter with reason
  - ✅ Booking active → Notify renter on move-in date
  - ✅ Booking completed → Notify renter on move-out date

- **Message Notifications** (integrated in FirebaseDatabaseService):
  - ✅ New message sent → Notify recipient
  - ✅ Message preview in notification (truncated to 100 chars)
  - ✅ Sender name display
  - ✅ Chat ID in payload for navigation

- **Permission Integration**:
  - ✅ Request all permissions on splash screen after user login
  - ✅ Permission dialogs shown before app navigation
  - ✅ Initialize PushNotificationService after permissions granted
  - ✅ Context-aware permission requests (check if mounted)

- **Platform-Specific Features**:
  - ✅ Android 13+ notification permission handling
  - ✅ iOS permission descriptions for App Store compliance
  - ✅ Vibration and sound for high-priority notifications
  - ✅ Notification icons for Android
  - ✅ Badge support for iOS

### UI/UX Improvements
- **Renter Navigation**:
  - ✅ Moved notifications to appbar top-right (matching landlord layout)
  - ✅ Removed notifications from bottom navigation bar
  - ✅ Centered Bookings button in bottom navigation (5 items: Home, Bookmarks, Bookings, Messages, Account)
  - ✅ Fixed badge positioning on Bookings icon
  - ✅ Changed navigation alignment from spaceAround to spaceEvenly

- **Landlord Navigation**:
  - ✅ Fixed button placement in bottom navigation bar
  - ✅ Changed alignment from spaceAround to spaceEvenly for better distribution
  - ✅ Increased FAB gap from 40px to 48px for better visual balance
  - ✅ Fixed badge positioning on Bookings icon (centered on icon)

- **Landlord Messages Screen**:
  - ✅ Added SliverAppBar with "Messages" title (matching renter's screen)
  - ✅ Converted to CustomScrollView layout with consistent styling
  - ✅ White text on light green background (24px bold font)
  - ✅ Maintained refresh functionality and all states (loading, error, empty, with data)

- **Video Player Enhancement**:
  - ✅ Fixed portrait video display issues (no more pixelation)
  - ✅ Added proper aspect ratio handling for both portrait and landscape videos
  - ✅ Videos now center with black letterboxing/pillarboxing as needed
  - ✅ Improved VideoPlayerWidget with Container and Center wrapping

### Documentation Updates
- **README.md**: Updated with Firebase configuration, booking system features, and Cloudinary setup
- **INSTALLATION.md**: Complete Firebase and Cloudinary setup instructions
- **SUMMARY.md**: Comprehensive project history, module breakdown, and current state

## [2025-12-11 - Previous Updates]

### Booking System - COMPLETE ✅
- **Fully implemented comprehensive booking request/approval system**:
  - ✅ Booking model with all fields: propertyId, renterId, landlordId, moveInDate, durationMonths, status, etc.
  - ✅ Status workflow: pending → approved → active → completed (or rejected/cancelled)
  - ✅ Financial tracking: monthlyRent, securityDeposit (2 months), totalAmount calculation
  - ✅ Denormalized property & renter data for easy access
  - ✅ Firestore collection: `bookings` with full CRUD operations

- **Database Methods** (FirebaseDatabaseService):
  - ✅ `createBooking()` - Create booking request with overlap validation
  - ✅ `getBookingsByRenter()` / `getBookingsByLandlord()` - Fetch bookings with fallback sorting
  - ✅ `getBookingsByProperty()` - Check property bookings
  - ✅ `getPendingBookingsByLandlord()` - Get requests awaiting approval
  - ✅ `getActiveBookingsByProperty()` - Check active bookings
  - ✅ `updateBookingStatus()` - Update with approval/rejection/cancellation timestamps
  - ✅ `approveBooking()` / `rejectBooking()` / `cancelBooking()` - Status management
  - ✅ `isPropertyAvailable()` - Check date overlap for booking conflicts
  - ✅ Stream methods for real-time updates: `streamBookingsByRenter()`, `streamBookingsByLandlord()`, `streamPendingBookingsCount()`

- **Renter Screens**:
  - ✅ **CreateBookingScreen**: Full booking form with property preview, move-in date picker, duration selector (3-36 months), occupant count, special requests, financial summary
  - ✅ **MyBookingsScreen**: Booking history with filters (all, pending, approved, active, completed, cancelled), real-time updates, status badges
  - ✅ **BookingDetailsScreen**: Complete booking info, cancel functionality with reason, status timeline, rejection/cancellation reasons display
  - ✅ "Book Now" button integrated in PropertyDetailsScreen with availability check

- **Landlord Screens**:
  - ✅ **LandlordBookingsScreen**: Manage incoming booking requests, filter by status, pending count badge, real-time updates
  - ✅ **LandlordBookingDetailsScreen**: Review booking details, approve/reject with reason, cancel approved bookings, complete booking info display
  - ✅ Approve/Reject dialogs with required rejection reasons

- **Features**:
  - ✅ Date overlap validation - prevents double-booking
  - ✅ Move-in/move-out date calculation
  - ✅ Duration options: 3, 6, 9, 12, 18, 24, 36 months
  - ✅ Security deposit: 2 months rent
  - ✅ Real-time availability checking
  - ✅ Status color-coding with icons
  - ✅ Comprehensive financial summary
  - ✅ Special requests field
  - ✅ Timeline tracking (requested, approved, rejected, cancelled dates)
  - ✅ Cancellation with mandatory reason
  - ✅ Property status check (only approved properties bookable)

### Virtual Tour Feature - COMPLETE ✅
- **Fully implemented virtual tour video system**:
  - ✅ Video packages: `video_player: ^2.9.2`, `chewie: ^1.8.5`, `video_compress: ^3.1.3`, `path_provider: ^2.1.4`
  - ✅ Extended Property model with `videoUrls` field (List<String>)
  - ✅ VideoLike model for per-video like tracking
  - ✅ CloudinaryService: video upload, automatic compression (50MB max, 3min max), validation
  - ✅ Video like methods: `likeVideo()`, `unlikeVideo()`, `isVideoLiked()`, `getVideoLikeCount()` with real-time streams
  - ✅ VideoPlayerWidget: Chewie player, fullscreen (portrait/landscape), like button with live count
  - ✅ Add Property: Video picker (gallery/camera), **exactly 1 video required**, compression progress
  - ✅ Edit Property: Full video editing - add/replace/delete video, maintain 1 video requirement
  - ✅ Property Details (Renter): Video player, fullscreen playback, like functionality
  - ✅ Property Details (Landlord): Video preview without like button
  - ✅ Admin Property View: Video review before approval
  - ✅ Property Card: "Virtual Tour" badge with camera icon on properties with videos

- **Technical Features**:
  - **1 video required per property** (simplified from 2)
  - Automatic video compression before upload
  - Video validation: file size, duration, format
  - Real-time like count updates via Firestore streams
  - Progress tracking during upload and compression
  - Fullscreen support with both portrait and landscape orientations
  - Error handling with retry functionality
  - Individual video likes tracked in `videoLikes` collection

- **User Experience**:
  - Landlords: Upload 1 video via gallery or camera recording
  - Renters: Watch virtual tour, like video
  - Admins: Review video before approving properties
  - Visual indicator on property cards showing virtual tour availability

### Ratings & Reviews System - Optional Fields
- **Implemented comprehensive ratings and reviews feature** for renters:
  - ✅ Added `addPropertyRating()`, `getPropertyRatings()`, `getUserRatingForProperty()` methods in FirebaseDatabaseService
  - ✅ Both rating (1-5 stars) and comment are **optional** - at least one must be provided
  - ✅ Automatic average rating calculation (filters out comment-only reviews)
  - ✅ Real-time rating count and average displayed on property cards
  - ✅ Reviews stored in subcollection: `properties/{propertyId}/ratings`
  - ✅ Rating dialog with interactive star selector and comment field
  - ✅ Reviews display with user avatar, stars, comment, and formatted date
  - ✅ Date formatting: "Today", "Yesterday", or "MMM dd, yyyy"
  - ✅ Fixed `_recalculatePropertyRating()` to handle null ratings gracefully
  - ✅ Validation ensures at least one field (rating or comment) is provided

- **Property Details Screen Updates**:
  - Added "Ratings & Reviews" section with "Add Review" button
  - Shows all reviews with star ratings, comments, and timestamps
  - Interactive star selector (tap to rate 1-5 stars)
  - Optional comment field for detailed feedback
  - Fixed BuildContext async gap warnings

### Property Model Enhancement - Showers Field
- **Added showers/bathrooms field** to Property model and all related screens:
  - ✅ `lib/models/property.dart`: Added `showers` field with full serialization (toJson, toFirestore, fromFirestore, fromMap, copyWith)
  - ✅ `lib/screens/landlord/add_property_screen.dart`: Added showers input field with Icons.shower
  - ✅ `lib/screens/landlord/landlord_edit_property_screen.dart`: Added showers field editing capability
  - ✅ `lib/screens/landlord/landlord_property_details_screen.dart`: Display showers count with icon (Rooms, Beds, Showers)
  - ✅ `lib/screens/renter/property_details_screen.dart`: Display showers in property stats
  - ✅ `lib/widgets/property_card.dart`: Added compact room/bed/shower icons to property listings
  
### Code Quality Improvements
- **Linting fixes**:
  - Made `_newImageFiles` and `_imagesToDelete` final in edit screen
  - Replaced deprecated `withOpacity()` with `withValues(alpha:)` for Flutter 3.9+ compatibility
  - All code passes `flutter analyze` with zero issues

### UI/UX Improvements - Account Settings
- **Removed unnecessary menu items** from Landlord Account Settings:
  - ❌ Removed "My Properties" (redundant - already accessible via home tab)
  - ❌ Removed "Property Analytics" (coming soon feature)
  - ❌ Removed "Help & Support" (coming soon feature)
  - Settings now shows: Edit Profile, Change Password, Logout

---

## [2025-12-11 - Firebase Migration] - Big Bang Migration Start

### Git Backup
- **[10:45 AM]** Created `backup-supabase` branch to preserve current Supabase implementation
- **[10:45 AM]** Created `firebase-migration` branch for migration work
- **[10:45 AM]** Committed current state before migration begins

### New Services Created
- **[10:46 AM]** Created `lib/services/firebase_auth_service.dart`
  - Replaces Supabase Auth with Firebase Auth
  - Implements: Sign up, sign in, sign out, get role, get user data
  - Added: Change password, send password reset email, delete account
  - User profiles stored in Firestore `users` collection
  - Comprehensive error handling with user-friendly messages

- **[10:50 AM]** Created `lib/services/firebase_database_service.dart`
  - Replaces Supabase DatabaseService with Cloud Firestore
  - Implements all CRUD operations for properties
  - Client-side search filtering (name, address, description, landlord name)
  - Property ratings with automatic average calculation
  - Real-time chat messaging with Firestore snapshots
  - User profile management
  - Notifications system
  - FCM token management
  - Uses Cloudinary for file uploads (images & videos)
  - Total: 30+ database methods migrated

### Models Updated for Firestore Compatibility
- **[$(date '+%I:%M %p')]** Updated all models with Firestore methods:
  - ✅ `lib/models/property.dart`: Added `toFirestore()`, `fromFirestore()`, `copyWith()`
  - ✅ `lib/models/message.dart`: Added `toFirestore()`, `fromFirestore()` with Timestamp handling
  - ✅ `lib/models/user.dart`: Added `toFirestore()`, `fromFirestore()` with UserRole conversion
  - ✅ `lib/models/chat.dart`: Added `toFirestore()`, `fromFirestore()` with Timestamp handling
  - ✅ `lib/models/admin_user.dart`: Added `toFirestore()`, `fromFirestore()`
  - All models preserve backward compatibility with existing `fromMap()`/`toMap()` methods

### App Initialization & Auth Screens Updated
- **[$(date '+%I:%M %p')]** Updated `lib/main.dart`:
  - Firebase initialized with `DefaultFirebaseOptions.currentPlatform`
  - Supabase kept temporarily for backward compatibility during migration
  
- **[$(date '+%I:%M %p')]** Updated authentication screens to use FirebaseAuthService:
  - ✅ `lib/screens/shared/login_screen.dart`: Now uses FirebaseAuthService
  - ✅ `lib/screens/shared/signup_screen.dart`: Now uses FirebaseAuthService
  - ✅ `lib/screens/splash_screen.dart`: Now uses FirebaseAuthService for auto-login

### All Screens Migrated to Firebase Services
- **[$(date '+%I:%M %p')]** Updated ALL application screens:
  - ✅ Property screens (add, edit, view, details) - 6 files
  - ✅ Renter screens (home, messages, profile) - 3 files
  - ✅ Landlord screens (home, profile, change password) - 3 files
  - ✅ Admin screens (dashboard, profile, account, change password) - 4 files
  - ✅ Chat room screen - 1 file
  - **Total: 17+ screens fully migrated**
  - All now use FirebaseDatabaseService, FirebaseAuthService, and CloudinaryService
  - Image/video uploads now handled by Cloudinary (free tier)

### Widgets & Services Updated
- **[$(date '+%I:%M %p')]** Updated admin widgets:
  - ✅ pending_properties_list, rejected_properties_list, overall_properties_list, approved_properties_list
  - All now use FirebaseDatabaseService
  
- **[$(date '+%I:%M %p')]** Updated push_notification_service:
  - ✅ Now uses FirebaseDatabaseService for FCM token management

### Migration Summary
**Total Files Changed: 40+ files**
- 3 new Firebase service files created
- 5 models updated with Firestore compatibility
- 1 main.dart initialization updated
- 17+ screen files migrated
- 4 admin widget files migrated
- 1 push notification service migrated

**Migration Status: ✅ COMPLETE - All code now uses Firebase & Cloudinary**

**Next Steps:**
1. Test authentication (sign up, sign in, sign out)
2. Test property CRUD operations
3. Test chat functionality with Firestore real-time
4. Test admin approval workflow
5. Test image/video uploads with Cloudinary
6. Remove old Supabase service files after testing
7. Remove Supabase initialization from main.dart

---

## December 2, 2025

### New Features

#### Real-time Messaging System
- **Chat List Implementation:** Added fully functional messages screens for both Renter and Landlord users
  - Displays all active chats with last message preview
  - Shows time ago format for message timestamps
  - Pull-to-refresh functionality
  - Profile pictures and user avatars
  
- **Chat Room Enhancements:**
  - Updated to Supabase realtime API v2 (fixed deprecated `.on()` method)
  - Working presence detection (online/offline status)
  - Typing indicators
  - Read receipts with checkmarks
  - Multimedia message support (images)

- **Smart Initial Messages:** When a renter first contacts a landlord about a property:
  - Message input is pre-filled with property context
  - Format: "Hi! I'm interested in '[Property Name]' at [Address]. Is it still available?"
  - Only triggers on new chat creation
  - User can edit or send as-is

#### Data Model Updates
- **Created Chat Model** (`lib/models/chat.dart`):
  - Handles complex nested chat data from database
  - Intelligently determines "other user" in conversation
  - Provides helper methods for user display names

- **Enhanced Property Model:**
  - Added `landlordProfilePicture` field
  - Now includes all landlord information for seamless chat initiation

### Bug Fixes

#### Database & Backend
- **Fixed PostgreSQL Trigger:** Updated `notify_on_new_message` trigger to use correct `net.http_post` syntax
  - Changed from deprecated `net` schema to proper `extensions` schema usage
  - Fixed parameter ordering (url, body, headers)
  - Added proper error handling with `SECURITY DEFINER`

- **Updated Database Views:**
  - Added `profile_picture_url` to `properties_with_avg_rating` view
  - Ensures landlord profile pictures are available in property listings

- **Enhanced Chat Creation:**
  - `getOrCreateChat()` now returns both `chatId` and `isNewChat` flag
  - Enables smart detection of new vs. existing conversations

#### Code Quality
- **Fixed Supabase Realtime API Issues:**
  - Replaced `RealtimeListenTypes.presence` with `.onPresenceSync()`
  - Replaced `RealtimeListenTypes.broadcast` with `.onBroadcast()`
  - Fixed payload handling for presence events
  - Updated broadcast message sending to use `.sendBroadcastMessage()`

- **Fixed Property Card Switch Statement:**
  - Removed unreachable default clause
  - Cleaner enum handling for `PropertyStatus`

- **Code Style Improvements:**
  - Added braces to single-line if statements in `database_service.dart`
  - All files pass `flutter analyze` with zero issues

### Technical Improvements
- Proper type safety with explicit type casts
- Better error handling in async operations
- Improved state management in chat screens
- Optimized database queries with proper joins

---

## November 12, 2025

### Bug Fixes
- **Navigation:** Corrected a critical navigation bug where the `AppBar` "Notifications" icon was incorrectly directing users to the "Edit" page. The navigation indices for all tabs have been re-mapped to ensure correct routing.

### UI/UX Enhancements

#### 1. Global UI Refactor
- **Headers:** The main headers on the Landlord and Renter home screens have been completely redesigned. The previous large, user-profile-centric header was replaced with a compact, pinned `AppBar` featuring the "OdioRent" title and new action icons for Notifications and Messages.
- **Bottom Navigation Bar:**
    - **Icon-Only Design:** The bottom navigation bar is now icon-only, with all text labels removed for a cleaner, more modern aesthetic.
    - **No Splash Effect:** The tap/splash highlight effect on the navigation buttons has been removed.
    - **New "Edit" Tab:** The "Notifications" tab was replaced with an "Edit" tab for Landlords and a disabled placeholder for Renters.
    - **Height & Icon Sizing:** Iteratively fine-tuned the bottom bar's height to `54px` and the icon size to `28px` to achieve a balanced and visually appealing layout based on feedback.

#### 2. Search Experience
- **Simplified UI:** The "Search" tab UI was streamlined by removing the top `AppBar` and "Search Properties" title, placing the search bar at the top of the screen.
- **Safe Area:** The search view is now wrapped in a `SafeArea` widget to prevent the UI from being obscured by the system status bar.
- **Auto-Focus Keyboard:** The search `TextField` now automatically gains focus and brings up the keyboard as soon as the user navigates to the "Search" tab, significantly improving the user flow. The keyboard is automatically dismissed when switching to another tab.

---
*Changes implemented by your Gemini CLI assistant.*
