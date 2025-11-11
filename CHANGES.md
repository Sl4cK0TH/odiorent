# Changelog - November 12, 2025

This document summarizes the key improvements and bug fixes implemented during our session.

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
