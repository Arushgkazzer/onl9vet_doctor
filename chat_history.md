# ONL9vet Doctor App - Chat History

## Dependency Issues and Resolutions

### Initial Dependency Conflicts
- Executed `flutter clean` to remove build artifacts and temporary files
- Executed `flutter pub get` which failed due to version conflicts between:
  - `firebase_core 3.9.0` and `cloud_firestore ^4.13.6` (requires `firebase_core ^2.24.2`)

### First Resolution Attempt
- Updated `pubspec.yaml` with compatible versions:
  - `firebase_core: '2.32.0'`
  - `cloud_firestore: '4.17.5'`
  - `firebase_auth: '4.16.0'`
  - `google_sign_in: '6.2.2'`
- Ran `flutter clean` and `flutter pub get` successfully

### User-Requested Version Reversion
- Reverted to specific versions as requested:
  - `firebase_core: '3.9.0'`
  - `firebase_auth: '5.3.4'`
  - `cloud_firestore: '5.6.0'` (for compatibility)
- Ran `flutter clean` and `flutter pub get` successfully

## Authentication Issues

### "Access Denied - Not a Doctor Account" Error
- Issue: User added an account in Firebase Authentication but received "access denied" when signing in
- Root cause: Adding a user in Firebase Authentication doesn't automatically create a Firestore document with 'doctor' role
- The app checks for 'doctor' role in Firestore before allowing access

### Solutions for Creating Doctor Role Account
1. **Firebase Console Method**:
   - Find the user ID in Firebase Authentication
   - Manually create a document in Firestore 'users' collection with that ID
   - Add a 'role' field with value 'doctor'

2. **App Signup Method**:
   - Use the app's `signUpWithEmailAndPassword` feature which automatically assigns the doctor role

3. **Helper Utility**:
   - Created `UserIdHelper` class to display the current user's Firebase ID within the app
   - File location: `lib/utils/user_id_helper.dart`

## Firestore Index Issue
- Error in pending appointment screen: "the query requires an index"
- The query filtering by 'status' and ordering by 'appointment_time' needs a composite index
- Solution: Create an index in Firebase Console with:
  - Collection ID: `appointments`
  - Fields to index: 
    - `status` (Ascending)
    - `appointment_time` (Ascending)
  - Query scope: Collection