# Changelog

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
