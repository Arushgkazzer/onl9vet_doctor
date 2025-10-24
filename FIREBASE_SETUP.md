# Firebase Setup Guide for Onl9vet Doctor App

## Overview
This app has been migrated from Supabase to Firebase Firestore for real-time appointment management. The app now listens to Firebase collections for new appointments and allows doctors to accept/reject them in real-time.

## Firebase Configuration Required

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable Firestore Database
4. Enable Authentication (optional, for user management)

### 2. Update Firebase Configuration
Update `lib/config/firebase_config.dart` with your Firebase project details:

```dart
class FirebaseConfig {
  static const String projectId = 'your-firebase-project-id';
  static const String apiKey = 'your-firebase-api-key';
  static const String appId = 'your-firebase-app-id';
  static const String messagingSenderId = 'your-messaging-sender-id';
  
  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
  );
}
```

### 3. Firestore Collections Structure

#### appointments Collection
Each appointment document should have these fields:
```json
{
  "user_id": "string",
  "user_name": "string", 
  "user_email": "string",
  "user_phone": "string",
  "species": "string",
  "breed": "string", 
  "age": "string",
  "sex": "string",
  "body_weight": "string",
  "purpose": "string",
  "history": "string",
  "symptom": "string",
  "appointment_time": "timestamp",
  "status": "pending", // pending, accepted, rejected, confirmed, cancelled
  "payment_status": "completed",
  "priority": "normal", // normal, urgent, emergency
  "pet_name": "string", // Format: "Species - Breed"
  "assigned_doctor": "string", // Doctor ID (set when accepted)
  "assigned_doctor_name": "string", // Doctor name (set when accepted)
  "doctor_response": "string", // Doctor's response message
  "accepted_at": "timestamp", // Set when accepted
  "rejected_at": "timestamp", // Set when rejected
  "created_at": "timestamp"
}
```

#### doctor_notifications Collection
For real-time notifications:
```json
{
  "appointment_id": "string",
  "doctor_id": "string", 
  "message": "string",
  "read": false,
  "created_at": "timestamp"
}
```

#### users Collection
For doctor profiles:
```json
{
  "id": "string",
  "name": "string",
  "email": "string", 
  "phone": "string",
  "role": "doctor",
  "availability_status": "available", // available, busy, offline
  "created_at": "timestamp"
}
```

### 4. Firestore Security Rules

Set up these security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow doctors to read all appointments
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow doctors to read notifications
    match /doctor_notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow doctors to read/write their profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Real-Time Features Implemented

### 1. Real-Time Appointment Listeners
- **All Appointments**: Stream that listens to all appointments
- **Pending Appointments**: Stream that filters for status='pending'
- **My Appointments**: Stream for appointments assigned to current doctor
- **Notifications**: Stream for unread doctor notifications

### 2. Doctor Actions
- **Accept Appointment**: Updates status to 'accepted', assigns doctor, sets timestamp
- **Reject Appointment**: Updates status to 'rejected', assigns doctor, sets timestamp
- **Real-time Updates**: All changes are reflected immediately across all connected devices

### 3. UI Features
- **Priority Indicators**: Visual badges for urgent/emergency appointments
- **Status Colors**: Color-coded status indicators
- **Notification Badge**: Shows count of unread notifications
- **Accept/Reject Buttons**: Quick action buttons for pending appointments

## Testing the Integration

### 1. Test Real-Time Updates
1. Open the app on multiple devices/simulators
2. Create a new appointment in your patient app
3. Verify it appears immediately in the doctor app's pending appointments
4. Accept/reject the appointment and verify status updates in real-time

### 2. Test Notification System
1. Create appointments with different priorities
2. Verify notification badges appear
3. Test accept/reject functionality
4. Verify notifications are marked as read

## Migration Notes

### Changes Made:
1. **Removed Supabase**: All Supabase dependencies and code removed
2. **Added Firebase**: Firebase Core, Firestore, and Auth added
3. **Real-Time Streams**: Implemented Firestore streams for real-time updates
4. **New Screens**: Added dedicated pending appointments screen
5. **Enhanced UI**: Added priority indicators and notification badges

### Files Modified:
- `pubspec.yaml`: Updated dependencies
- `lib/main.dart`: Firebase initialization
- `lib/services/firebase_appointment_service.dart`: New Firebase service
- `lib/screens/appointments_screen.dart`: Updated for Firebase
- `lib/screens/pending_appointments_screen.dart`: New real-time screen
- `lib/screens/main_navigation_screen.dart`: Added pending appointments tab

## Next Steps

1. **Configure Firebase Project**: Set up your Firebase project with the collections above
2. **Update Configuration**: Add your Firebase credentials to `firebase_config.dart`
3. **Test Integration**: Verify real-time functionality works with your patient app
4. **Deploy**: Build and deploy the updated doctor app

The app is now ready to receive real-time appointments from your patient app and allow doctors to respond immediately!

