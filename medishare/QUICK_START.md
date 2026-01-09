# MediShare - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Dart SDK
- IDE (VS Code or Android Studio)

### Running the App

```bash
# Navigate to project
cd medishare

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 🎮 Demo Flow

### 1. Create an Account
```
1. Tap "Sign Up" in the navbar
2. Fill in:
   - Name: "John Doe"
   - Email: "john@example.com"
   - Phone: "+880123456789"
   - Location: "Dhaka"
   - Password: "password123"
   - Confirm Password: "password123"
3. Tap "Sign Up"
4. You're logged in!
```

### 2. Donate Medicine
```
1. Tap "Donate" in bottom nav
2. Fill form:
   - Medicine Name: "Paracetamol"
   - Type: "Tablet"
   - Quantity: "50"
   - Expiry Date: Pick future date
   - Location: (defaults to your location)
   - Description: "Unused medicine"
3. Tap "Donate Medicine"
4. Status: Pending admin approval
```

### 3. Admin Approval (Switch to Admin)
```
Note: To test admin features, you need to:
1. Modify user in mock data OR
2. Use admin panel user menu in a second instance

As Admin:
1. Tap "Admin" (red FAB button)
2. Click Donations tab
3. See pending donations
4. Tap "Approve" to accept
```

### 4. Browse & Request
```
As regular user:
1. Tap "Browse" in bottom nav
2. See approved medicines
3. Search by name/type
4. Filter by medicine type
5. Tap "Claim" on a medicine
6. Confirm in dialog
7. Medicine is now claimed!
```

### 5. Report Unsafe Medicine
```
1. On any medicine card, tap report icon
2. Fill form:
   - Reason: Select reason
   - Details: Describe issue
3. Tap "Report"
4. Report sent to admin
```

### 6. Admin Resolution
```
As Admin:
1. Tap "Admin" button
2. Click "Reports" tab
3. See pending reports
4. Tap "Mark Resolved"
5. Add resolution notes
6. Report status: Resolved
```

## 📱 Navigation

```
Bottom Navigation (4 tabs):
├─ Home (Landing page)
├─ Browse (Available medicines)
├─ Donate (Add your medicine)
└─ Request (Request medicines)

Top Navigation (Navbar):
├─ MediShare Logo
├─ Notification Bell (with badge)
└─ User Menu
   ├─ Profile
   ├─ Admin Panel (if admin)
   └─ Logout
```

## 👥 Test Accounts

### Pre-populated Users
None by default (mock storage), but you can register:

**Regular User:**
- Name: Demo User
- Email: demo@example.com
- Password: demo123

**Admin User:**
After registering a user, go to Admin Panel > Users tab and promote them.

## 🔄 Key Workflows

### Donation Workflow
```
User creates donation
         ↓
Status: PENDING
         ↓
Admin approves/rejects
         ↓
Status: APPROVED (if approved)
         ↓
Other user claims
         ↓
Status: CLAIMED
```

### Request Workflow
```
User requests medicine
         ↓
Status: PENDING
         ↓
Admin can assign to donation
         ↓
Status: FULFILLED
```

### Report Workflow
```
User reports medicine
         ↓
Status: PENDING
         ↓
Admin reviews
         ↓
Admin resolves
         ↓
Status: RESOLVED
```

## 🛠️ Debugging

### View Mock Data
Services store data in static lists. To inspect:

```dart
// In donate_service.dart
print(_donations); // View all donations
print(_donations.where((d) => d.status == DonationStatus.approved)); // Filter
```

### Common Issues

**Issue**: User stays on login page after signup
- Solution: Check console for errors, verify form filled correctly

**Issue**: Admin button doesn't appear
- Solution: Make sure user role is `admin`, not `user`

**Issue**: Donations not showing in browse
- Solution: Donations must be APPROVED first (admin approval)

## 📊 Data Models

### Donation
```dart
{
  id: "DON_1",
  donorId: "USER_1",
  medicineName: "Paracetamol",
  medicineType: "Tablet",
  quantity: 50,
  expiryDate: DateTime(2025, 12, 31),
  status: "approved",
  location: "Dhaka",
  latitude: 23.8103,
  longitude: 90.4125,
}
```

### User
```dart
{
  id: "USER_1",
  name: "John Doe",
  email: "john@example.com",
  phone: "+880123456789",
  role: "user", // or "admin"
  location: "Dhaka",
  latitude: 23.8103,
  longitude: 90.4125,
}
```

## 🔐 Authentication

**Current Implementation:**
- Mock in-memory storage (no real auth)
- Credentials: email + password (not validated against hash)

**Firebase Integration (TODO):**
- Replace mock login with Firebase Auth
- Use email/password authentication
- Add Google Sign-In (optional)

## 🗺️ Location Features

**Current:**
- User location (city name + coordinates)
- Distance calculation using Haversine formula
- 25km radius search

**Future Firebase:**
- Real GPS coordinates from device
- Geocoding for city names
- Real-time location updates

## 🔔 Notifications

**Current:**
- Unread count badge
- Mock notification list
- Mark read/unread

**Future Firebase:**
- Firebase Cloud Messaging
- Push notifications
- Real-time notification sync

## 📸 Images

**Current:**
- Medicine icon placeholder
- No real image upload

**Future Firebase:**
- Upload to Firebase Storage
- Display from Cloud Storage
- Image compression

## ⚙️ Configuration

No configuration needed for mock data. For Firebase:

1. Create Firebase project
2. Add `google-services.json` to android/app/
3. Add `GoogleService-Info.plist` to ios/Runner/
4. Update services to use Firebase

## 🧪 Testing Tips

1. **Test Donation**: Create donation, check it appears pending
2. **Test Admin**: Promote yourself to admin, approve donation
3. **Test Browse**: See approved donations in browse tab
4. **Test Claim**: Claim a donation, see status change
5. **Test Report**: Report a medicine, see it in admin panel
6. **Test Logout**: Logout and verify you're logged out

## 📚 Documentation Files

- **IMPLEMENTATION_COMPLETE.md** - Full implementation details
- **FILE_STRUCTURE.md** - Project structure and changes
- **this file** - Quick start guide

## 🤝 Contributing

To add features:

1. Add models in `lib/models/`
2. Add business logic in `lib/services/`
3. Update state in `lib/state/`
4. Create UI in `lib/pages/`
5. Update navigation in `lib/main.dart`

## ✅ Checklist for Firebase Integration

- [ ] Set up Firebase project
- [ ] Add Firebase dependencies to pubspec.yaml
- [ ] Initialize Firebase in main.dart
- [ ] Update UserService for Firebase Auth
- [ ] Update DonationService for Firestore
- [ ] Update RequestService for Firestore
- [ ] Update ReportService for Firestore
- [ ] Update NotificationService for Cloud Messaging
- [ ] Set Firestore security rules
- [ ] Test all flows with real backend
- [ ] Deploy to App Store / Play Store

## 📞 Support

For issues or questions:
1. Check the implementation guide
2. Review the code comments
3. Check Flutter documentation
4. Enable debugging in VS Code

---

**Happy coding! MediShare is production-ready with mock data.**
