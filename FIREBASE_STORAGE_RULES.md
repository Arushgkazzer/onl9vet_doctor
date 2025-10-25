# Firebase Storage Security Rules

The Firebase Storage error you're experiencing is likely due to security rules. You need to configure your Firebase Storage rules to allow authenticated users to upload files.

## Current Issue
Error: `firebase_storage/object_not_found: No object exists at the desired reference`

## Solution

Go to your Firebase Console → Storage → Rules and update the rules to:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload and read chat files
    match /chat_files/{appointmentId}/{fileName} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read and write their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default rule - deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Alternative (More Permissive - for testing only)

If you want to test quickly, you can use this more permissive rule (NOT recommended for production):

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

## Steps to Update:

1. Go to Firebase Console
2. Select your project
3. Go to Storage
4. Click on "Rules" tab
5. Replace the existing rules with one of the above
6. Click "Publish"

After updating the rules, the file upload should work properly.
