# Firebase Setup Instructions for Zawaj

## Prerequisites
- Firebase project created at https://console.firebase.google.com
- GoogleService-Info.plist downloaded and added to Xcode project
- Firebase SDK packages added via Swift Package Manager

## 1. Firestore Database Setup

### Enable Firestore
1. Go to Firebase Console → Build → Firestore Database
2. Click "Create database"
3. Select "Start in production mode"
4. Choose location: `us-central` (or your preferred region)
5. Click "Enable"

### Deploy Security Rules

#### Option A: Manual (Firebase Console)
1. In Firestore Database, click "Rules" tab
2. Copy contents from `firestore.rules` file
3. Paste into the rules editor
4. Click "Publish"

#### Option B: Firebase CLI (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firestore
cd /Users/ashraf/Documents/Zawaj
firebase init firestore
# Select your Firebase project
# Use default files: firestore.rules and firestore.indexes.json

# Deploy
firebase deploy --only firestore:rules,firestore:indexes
```

### Create Indexes

The following indexes are required for queries:

1. **Username lookup**:
   - Collection: `users`
   - Fields: `username` (Ascending)

2. **Partner requests by receiver**:
   - Collection: `partnerRequests`
   - Fields: `receiverUsername` (Asc), `status` (Asc), `createdAt` (Desc)

3. **Partner requests by sender**:
   - Collection: `partnerRequests`
   - Fields: `senderId` (Asc), `status` (Asc), `createdAt` (Desc)

**To create manually:**
1. In Firestore Database, click "Indexes" tab
2. Click "Add index"
3. Fill in collection and fields as listed above
4. Click "Create"

**To create via CLI:**
```bash
firebase deploy --only firestore:indexes
```

## 2. Authentication Setup

### Enable Authentication Methods

1. Go to Firebase Console → Build → Authentication
2. Click "Get started" if first time
3. Click "Sign-in method" tab
4. Enable the following providers:

#### Email/Password
1. Click "Email/Password"
2. Toggle "Enable"
3. Click "Save"

#### Phone
1. Click "Phone"
2. Toggle "Enable"
3. Add test phone numbers (optional for development):
   - Phone: +1 650-555-3434
   - Code: 123456
4. Click "Save"

#### Google Sign-In
1. Click "Google"
2. Toggle "Enable"
3. Enter support email (required): your-email@example.com
4. Click "Save"
5. Download updated `GoogleService-Info.plist`
6. Replace old file in Xcode project

#### Apple Sign-In (Requires Apple Developer Account)
1. Click "Apple"
2. Toggle "Enable"
3. Configure in Apple Developer Portal:
   - Enable "Sign In with Apple" capability
   - Add redirect URLs from Firebase Console
4. Click "Save"

## 3. Firebase Storage (Optional - for profile photos)

1. Go to Firebase Console → Build → Storage
2. Click "Get started"
3. Start in production mode
4. Choose same location as Firestore
5. Click "Done"

### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile photos
    match /users/{userId}/profile.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

## 4. Cloud Messaging (Push Notifications)

### Configure APNs
1. In Xcode, enable "Push Notifications" capability
2. In Apple Developer Portal:
   - Create APNs Key
   - Download .p8 file
3. In Firebase Console → Project Settings → Cloud Messaging:
   - Click "Upload" under "APNs Authentication Key"
   - Upload .p8 file
   - Enter Key ID and Team ID

### Test Notifications
1. Run app on device (not simulator)
2. Grant notification permissions when prompted
3. In Firebase Console → Engage → Messaging:
   - Click "Send your first message"
   - Test notification delivery

## 5. Verify Setup

### Test Firestore
```swift
// This happens automatically when completing onboarding
// Check Firebase Console → Firestore Database for new user document
```

### Test Authentication
1. Run app and sign up with email
2. Check Firebase Console → Authentication → Users
3. Verify user appears in list

### Test Phone Verification
1. Enter phone number in onboarding
2. Receive SMS code (or use test number)
3. Verify code works

### Test Google Sign-In
1. Click "Continue with Google" on login screen
2. Select Google account
3. Verify login succeeds

## 6. Production Checklist

Before launching:
- [ ] Update Firestore security rules for production
- [ ] Set up billing alerts in Google Cloud Console
- [ ] Enable App Check to prevent API abuse
- [ ] Configure rate limiting for sensitive operations
- [ ] Set up Firebase Analytics conversion tracking
- [ ] Configure data retention policies (GDPR compliance)
- [ ] Test all authentication flows on physical devices
- [ ] Monitor Firestore usage in Firebase Console

## 7. Troubleshooting

### "Permission denied" errors
- Check Firestore security rules are deployed
- Verify user is authenticated before database operations
- Check indexes are created

### Google Sign-In not working
- Verify `GoogleService-Info.plist` is latest version
- Check support email is configured in Firebase Console
- Verify `REVERSED_CLIENT_ID` URL scheme in Xcode

### Phone verification not sending SMS
- Check phone authentication is enabled in Firebase Console
- Verify billing is enabled (required for SMS)
- Use test phone numbers for development

### Build errors
- Clean build folder (Shift + Cmd + K)
- Delete DerivedData
- Verify all Firebase packages are added in SPM

## Database Structure

### users/{userId}
```json
{
  "id": "firebase-uid-string",
  "email": "user@example.com",
  "phoneNumber": "+12065551234",
  "isEmailVerified": true,
  "isPhoneVerified": true,
  "fullName": "John Doe",
  "username": "johndoe",
  "gender": "Male",
  "birthday": "1995-01-15T00:00:00Z",
  "relationshipStatus": "Single",
  "marriageTimeline": "Within 1 year",
  "topicPriorities": ["Faith", "Family", "Career"],
  "partnerId": null,
  "partnerConnectionStatus": "none",
  "notificationsEnabled": true,
  "createdAt": "2025-12-21T10:00:00Z",
  "updatedAt": "2025-12-21T10:00:00Z",
  "photoURL": null
}
```

### partnerRequests/{requestId}
```json
{
  "id": "request-uuid",
  "senderId": "sender-firebase-uid",
  "senderUsername": "johndoe",
  "receiverUsername": "janedoe",
  "status": "pending",
  "createdAt": "2025-12-21T10:00:00Z",
  "respondedAt": null
}
```

### couples/{coupleId}
```json
{
  "user1Id": "user1-firebase-uid",
  "user2Id": "user2-firebase-uid",
  "connectedAt": "2025-12-21T10:00:00Z",
  "currentQuestionId": null,
  "questionHistory": []
}
```
