# Project Summary - OdioRent

## 1. Project Overview

**OdioRent** is a mobile application built with Flutter that aims to modernize the property rental market in Odiongan, Romblon. The app serves as a centralized platform connecting property owners (Landlords) with potential tenants (Renters), with an administrative backend for oversight (Admins).

- **Renters:** Can browse, search, and view details of available rental properties. They can also rate properties and contact landlords.
- **Landlords:** Can list their properties for rent, manage their listings (create, update, delete), and communicate with potential renters.
- **Admins:** Can oversee the platform, approve or reject new property listings, and manage users.

## 2. Technology Stack

- **Frontend:** Flutter
- **Backend-as-a-Service (BaaS):** Supabase
  - **Database:** PostgreSQL
  - **Authentication:** Supabase Auth
  - **Storage:** Supabase Storage
- **Primary Language:** Dart

## 3. Development History & Key Decisions

This summary outlines the major development tasks and challenges encountered.

### Task: Landlord CRUD and App Optimization
The initial goal was to implement and optimize the full CRUD (Create, Read, Update, Delete) lifecycle for landlords and resolve various bugs.

- **Property Creation & Anti-Duplication:**
  - The "Add Property" screen was implemented, allowing landlords to upload images and property details.
  - An anti-duplication check was added to the `DatabaseService` to prevent a landlord from creating two properties with the exact same name.
  - The address input was refactored from a single text field to a dropdown for Odiongan's Barangays plus a text field for the specific street/house number, ensuring standardized address data.

- **Property Search Functionality:**
  - **Requirement:** Allow renters to search for properties using keywords matching the property's name, address, description, or the landlord's name.
  - **Evolution:**
    1.  Initial implementation was client-side, which was inefficient.
    2.  Refactored to use a server-side search. An attempt to use Supabase's `or()` filter across joined tables failed due to client library limitations.
    3.  The final, successful solution involved creating a **PostgreSQL RPC function (`search_properties`)**. This function performs the multi-column `ILIKE` search efficiently on the database server.

- **Ratings System (New Feature):**
  - **Requirement:** Replace the internal "Status" field (e.g., 'approved') with a user-facing 5-star rating system.
  - **Implementation:**
    1.  **Database:** A new `property_ratings` table was created to store individual ratings. A `properties_with_avg_rating` database VIEW was also created to efficiently calculate the average rating and count for each property.
    2.  **Backend:** A new `addPropertyRating` method was added to `DatabaseService`. All data-fetching methods were updated to query the new view instead of the base `properties` table.
    3.  **UI:** The `PropertyCard` and `PropertyDetailsScreen` were updated to display ratings with star icons. A "Rate" button and dialog were added to the details screen for users to submit ratings.

### Challenge: Row Level Security (RLS) & Build Failures

A significant portion of the development time was spent diagnosing and fixing critical backend and build issues.

- **RLS Policies & Login Failures:**
  - **Problem:** After enabling RLS, users were unable to log in, and data fetching began to fail.
  - **Diagnosis:** The policies on the `profiles` and `notifications` tables were either too restrictive or created circular dependencies. For instance, a policy designed to let users see landlord details for *approved* properties was blocking the initial property list from being loaded at all.
  - **Solution:** The RLS policies were iteratively refined. A key failure was an **"infinite recursion"** error caused by a policy on `profiles` that referenced the `properties` table, creating a loop. The final solution involved:
    - A simple policy allowing any authenticated user to read from the `profiles` table (`USING (true)`).
    - Relying on the more specific RLS policies on the `properties` table to control which rows (and therefore which linked landlord profiles) are ultimately visible to the user.
    - A specific policy on `notifications` to allow users to create notifications *for* admins.

- **Android Build Failures:**
  - **Problem 1:** `Gradle build daemon disappeared unexpectedly`. This was likely due to the build process running out of memory.
  - **Solution 1:** The standard solution of cleaning the build caches (`flutter clean`, `./gradlew clean`) was applied.
  - **Problem 2:** `Toolchain installation does not provide the required capabilities: [JAVA_COMPILER]`.
  - **Solution 2:** This indicated that although `javac` was installed, Gradle couldn't find it at the expected path. The issue was resolved by explicitly setting the `JAVA_HOME` environment variable to point to the correct JDK installation directory.

## 4. Current Project State

- **Completed Features:** All items from the recent task list have been addressed. The search, anti-duplication, address dropdown, and ratings features are implemented. The critical RLS and build errors are resolved.
- **Code Health:** `flutter analyze` now reports no issues.
- **Known Issues/TODOs:**
  - The "bug on some fields from Landlords Account Settings" was not reproducible due to a lack of specific details. A code review was performed, but no obvious errors were found. This requires more information from the tester.
  - The "Book Now" feature is a placeholder and needs to be implemented.
  - The currency symbol "₱" has been confirmed in major areas, but a full app-wide audit may be beneficial.

## 5. Next Steps

- Obtain specific details on the Landlord Account Settings bug.
- Plan and implement the property booking and scheduling functionality.
- Continue to refine and improve the UI/UX across the application.
- Conduct a full audit for currency symbol consistency.
