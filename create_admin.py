#!/usr/bin/env python3
"""
One-time script to create an admin user in Firebase
Usage: python3 create_admin.py
"""

import firebase_admin
from firebase_admin import credentials, auth, firestore
from datetime import datetime

# Initialize Firebase Admin SDK
# You need to download your service account key from Firebase Console
# Go to: Project Settings > Service Accounts > Generate New Private Key
cred = credentials.Certificate('odiorent-5a387-firebase-adminsdk-fbsvc-15acc306ac.json')
firebase_admin.initialize_app(cred)

# Get Firestore client
db = firestore.client()

def create_admin_user():
    """Create an admin user with email: admin@odiorent.com and password: admin123"""
    
    email = "admin@odiorent.com"
    password = "admin123"
    
    try:
        # Create user in Firebase Authentication
        user = auth.create_user(
            email=email,
            password=password,
            display_name="Admin User"
        )
        
        print(f"✅ Successfully created user in Firebase Auth")
        print(f"   User ID: {user.uid}")
        print(f"   Email: {user.email}")
        
        # Create admin profile in Firestore
        admin_data = {
            'email': email,
            'role': 'admin',
            'firstName': 'Admin',
            'lastName': 'User',
            'middleName': None,
            'userName': 'admin',
            'phoneNumber': '+1234567890',
            'profilePictureUrl': None,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'lastSeen': firestore.SERVER_TIMESTAMP,
        }
        
        db.collection('users').document(user.uid).set(admin_data)
        
        print(f"✅ Successfully created admin profile in Firestore")
        print(f"\n🎉 Admin user created successfully!")
        print(f"\nLogin credentials:")
        print(f"   Email: {email}")
        print(f"   Password: {password}")
        print(f"   Username: admin")
        
    except auth.EmailAlreadyExistsError:
        print(f"❌ Error: User with email {email} already exists")
        print(f"   If you want to recreate, delete the existing user first from Firebase Console")
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")

if __name__ == "__main__":
    print("=" * 60)
    print("Creating Admin User for OdioRent")
    print("=" * 60)
    create_admin_user()
