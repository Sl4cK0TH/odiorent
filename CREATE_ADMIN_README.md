# Admin User Creation

This directory contains a script to create an admin user in Firebase.

## Prerequisites

1. **Install Firebase Admin SDK:**
   ```bash
   pip3 install firebase-admin
   ```

2. **Download Service Account Key:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to **Project Settings** (gear icon) → **Service Accounts**
   - Click **Generate New Private Key**
   - Save the downloaded JSON file as `serviceAccountKey.json` in this directory

## Usage

1. Make sure `serviceAccountKey.json` is in the same directory as `create_admin.py`

2. Run the script:
   ```bash
   python3 create_admin.py
   ```

3. The script will create an admin user with:
   - **Email:** admin@odiorent.com
   - **Password:** admin123
   - **Username:** admin
   - **Role:** admin

## Security Note

⚠️ **IMPORTANT:** 
- The `serviceAccountKey.json` file is already in `.gitignore` - DO NOT commit it to git
- Change the admin password after first login
- Delete `create_admin.py` and `serviceAccountKey.json` after creating the admin user

## Login

After creating the admin account, you can login using:
- Email: `admin@odiorent.com` OR Username: `admin`
- Password: `admin123`

The app will automatically detect the admin role and redirect to the admin dashboard.
