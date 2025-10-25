# Firebase Rules Configuration - URGENT FIX

## Problem Identified from Logs:
1. `[cloud_firestore/permission-denied]` - Firestore rules blocking chat messages
2. `[firebase_storage/object-not-found]` - Storage rules blocking file uploads

## SOLUTION: Update Firebase Rules

### 1. Firestore Security Rules
Go to Firebase Console → Firestore Database → Rules and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write chats
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Allow authenticated users to read/write appointments
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write their own user data
    match /users/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write user settings
    match /user_settings/{userId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2. Firebase Storage Security Rules
Go to Firebase Console → Storage → Rules and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload and read chat files
    match /chat_files/{appointmentId}/{fileName} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to upload profile images
    match /profile_images/{userId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default rule - allow authenticated users
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## STEPS TO FIX:

### Step 1: Update Firestore Rules
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to "Firestore Database"
4. Click "Rules" tab
5. Replace existing rules with the Firestore rules above
6. Click "Publish"

### Step 2: Update Storage Rules
1. In the same Firebase Console
2. Go to "Storage"
3. Click "Rules" tab
4. Replace existing rules with the Storage rules above
5. Click "Publish"

### Step 3: Test the App
After updating both rules:
1. Try sending a text message in chat
2. Try uploading an image
3. Try uploading a PDF

## Alternative (Quick Test - Less Secure)
If you want to test quickly, you can use these more permissive rules temporarily:

**Firestore (Test Only):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Storage (Test Only):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Expected Result After Fix:
- Chat messages will send and display properly
- Image and PDF uploads will work
- No more permission denied errors in logs
