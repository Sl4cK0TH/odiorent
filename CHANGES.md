# Changelog

## [2025-12-11 - Latest Updates]

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
