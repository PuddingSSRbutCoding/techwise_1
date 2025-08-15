# Firebase Storage Configuration Guide

## Current Issues and Solutions

### 1. Storage 404 Errors
The logs show Firebase Storage errors with HTTP 404 codes. This typically means:

#### Possible Causes:
- Storage bucket not properly initialized in Firebase Console
- Security rules preventing access
- Incorrect storage bucket URL
- Missing files at specified paths

#### Solutions:

**A. Check Firebase Console Storage Setup:**
1. Go to Firebase Console → Your Project → Storage
2. Verify that Storage is enabled
3. Check that the bucket name matches: `techwisever1.firebasestorage.app`
4. Ensure you have proper IAM permissions

**B. Update Storage Security Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload profile images
    match /profile_images/{userId}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to upload profile images with timestamp
    match /profile_images/{userId}_{timestamp}.jpg {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow public read access to lesson content (if needed)
    match /lesson_content/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 2. App Check Warnings
The "No AppCheckProvider installed" warnings can be resolved by:

#### Option A: Add App Check (Recommended for Production)
Add to your `pubspec.yaml`:
```yaml
dependencies:
  firebase_app_check: ^0.2.1+3
```

Then initialize in your app:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

// In main() function after Firebase.initializeApp():
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug, // Use AndroidProvider.playIntegrity for production
);
```

#### Option B: Disable App Check (Development Only)
In Firebase Console → App Check → Apps, you can temporarily disable enforcement.

### 3. Upload Session Termination
This is often related to:
- Network timeouts
- Authentication issues
- File size limits
- Concurrent upload limits

## Code Improvements Made

1. **Better Error Handling**: Added specific error handling for different Firebase Storage exceptions
2. **Timeout Protection**: Added 5-minute timeout for uploads
3. **Storage Availability Check**: Check if Storage is accessible before attempting uploads
4. **Unique File Names**: Use timestamp to prevent file conflicts
5. **Proper Metadata**: Added metadata for better file tracking

## Testing Steps

1. **Test Storage Connection:**
   ```dart
   // Add this to a test page to verify Storage connectivity
   try {
     final ref = FirebaseStorage.instance.ref().child('test').child('test.txt');
     await ref.putString('test');
     print('Storage is working!');
   } catch (e) {
     print('Storage error: $e');
   }
   ```

2. **Verify Authentication:**
   Ensure users are properly authenticated before attempting uploads.

3. **Check Network Connectivity:**
   Test on different networks to rule out connectivity issues.

## Next Steps

1. **Update Firebase Console Storage Rules** (copy rules from above)
2. **Enable Storage in Firebase Console** if not already enabled
3. **Test profile image upload functionality**
4. **Monitor logs for any remaining Storage errors**
5. **Consider adding App Check for production builds**

## Debug Commands

To test the fixes:
```bash
flutter clean
flutter pub get
flutter run
```

Monitor logs for Storage-related errors and verify that profile image uploads work properly.

