# OdioRent - Property Rental Application

OdioRent is a Flutter-based mobile application designed to streamline the property rental process in Odiongan, Romblon. It connects renters with landlords, providing a platform for browsing listings, managing properties, and facilitating communication.

## Features

- **User Roles:** Separate interfaces and functionalities for Renters, Landlords, and Admins.
- **Property Listings:** Landlords can create, update, and delete property listings with images and detailed descriptions.
- **Advanced Search:** Renters can search for properties using keywords that match property names, addresses, descriptions, or landlord names.
- **Property Ratings:** Renters can rate properties and view average ratings, helping them make informed decisions.
- **Admin Dashboard:** Admins can review and manage property listings (approve/reject).
- **Secure Authentication:** Powered by Supabase for user sign-up, login, and profile management.
- **Real-time Chat:** (In-progress) Functionality for renters and landlords to communicate directly.

## Technology Stack

- **Frontend:** Flutter
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Language:** Dart, SQL (PostgreSQL)

## Project Setup

Follow these steps to set up the development environment on a new machine.

### 1. Prerequisites

- **Flutter:** Ensure you have the Flutter SDK installed. If not, follow the official [Flutter installation guide](https://flutter.dev/docs/get-started/install).
- **Supabase Account:** You will need a Supabase project. If you don't have one, create an account and a new project at [supabase.com](https://supabase.com).

### 2. Clone the Repository

Clone this project to your local machine:
```bash
git clone <your-repository-url>
cd odiorent
```

### 3. Supabase Configuration

#### A. Run the Database Schema
1.  In your Supabase project dashboard, navigate to the **SQL Editor**.
2.  Open the `supabase/schema.sql` file from this repository.
3.  Copy its entire content and paste it into the Supabase SQL Editor.
4.  Run the script. This will create all the necessary tables, views, functions, and Row Level Security (RLS) policies.

#### B. Connect the Flutter App to Supabase
1.  Create a file named `.env` in the root directory of your Flutter project. This file is listed in `.gitignore` and will not be committed to version control.
2.  Add your Supabase URL and Anon Key to the `.env` file like this:
    ```
    SUPABASE_URL=https://your-project-url.supabase.co
    SUPABASE_ANON_KEY=your-public-anon-key
    ```
3.  You can find these keys in your Supabase project's **Settings > API**.

### 4. Run the Application

1.  Fetch the project dependencies:
    ```bash
    flutter pub get
    ```
2.  Run the app on your desired device (emulator or physical device):
    ```bash
    flutter run
    ```