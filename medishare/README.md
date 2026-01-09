# MediShare - Medicine Donation Platform

A Flutter application that connects medicine donors with those in need, enabling community-based medicine sharing with admin oversight and safety reporting.

## Features

✅ **User Authentication** - Login and registration with dual role support (User, Admin)
✅ **Medicine Donations** - Donate unused medicines with details (name, type, quantity, expiry)
✅ **Medicine Requests** - Request medicines and claim available donations
✅ **Location-Based Search** - Find donations within ~25km radius using Haversine formula
✅ **Admin Dashboard** - Review donations, handle safety reports, manage users
✅ **Safety Reporting** - Report expired or suspicious medicines
✅ **Notifications** - Real-time updates on donations, claims, and reports
✅ **Mock Data** - Full demo data for immediate testing (no Firebase needed yet)

## Quick Start

### Prerequisites
- Flutter 3.0+
- Dart 3.0+

### Installation

```bash
# Clone or extract the project
cd medishare

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Demo Credentials

**Admin Account** (Full access to admin panel)
- Email: `nfahad066@gmail.com`
- Password: `12345678`

**Regular User Accounts**
- Email: `john@example.com` | Password: `12345678`
- Email: `jane@example.com` | Password: `12345678`
- Email: `ahmed@example.com` | Password: `12345678`

All demo credentials are displayed in the login screen for easy reference.

## Project Structure

```
lib/
├── main.dart              # App entry point & navigation
├── models/                # Data models
│   ├── user.dart         # User model with roles
│   ├── donation.dart     # Donation lifecycle
│   ├── request.dart      # Medicine request
│   ├── report.dart       # Safety report
│   └── notification.dart # User notifications
├── services/              # Business logic & mock data
│   ├── user_service.dart
│   ├── donation_service.dart
│   ├── request_service.dart
│   ├── report_service.dart
│   └── notification_service.dart
├── pages/                 # UI screens
│   ├── landing_page.dart
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── donate_page.dart
│   ├── request_page.dart
│   ├── admin_panel.dart
│   └── list.dart
├── state/                 # State management
│   └── auth_state.dart   # Global auth state with Provider
└── widgets/               # Reusable UI components
    ├── app_navbar.dart
    └── medicine_card.dart
```

## Architecture

- **Pattern**: Clean Architecture (Models → Services → Pages)
- **State Management**: Provider with ChangeNotifier
- **Storage**: In-memory lists (mock data for testing)
- **Authentication**: Mock-based with email validation
- **Location**: Haversine distance calculation

## Mock Data Included

- **4 Users**: 1 admin + 3 regular users across Dhaka, Chittagong, Sylhet
- **5 Donations**: Various medicines at different approval statuses
- **3 Requests**: Fulfilled and pending requests
- **1 Report**: Safety report awaiting admin review
- **3 Notifications**: Donation, claim, and report notifications

See [MOCK_DATA.md](MOCK_DATA.md) for detailed mock data documentation.

## Testing Workflow

### For Admins
1. Login with `nfahad066@gmail.com / 12345678`
2. Click red Admin FAB button
3. **Donations Tab**: Review and approve pending medicines (DON_005)
4. **Reports Tab**: Handle safety reports (RPT_001)
5. **Users Tab**: Manage platform users

### For Regular Users
1. Login with any user email above
2. **Home Tab**: View notifications
3. **Browse Tab**: Search for available medicines (location-based)
4. **Donate Tab**: Add new medicine donation
5. **Request Tab**: Request or claim medicines

## Key Components

### AuthState (lib/state/auth_state.dart)
Global authentication and app state using Provider. Methods:
- `login(email, password)` - Authenticate user
- `register(...)` - Create new account
- `logout()` - Sign out
- `markNotificationAsRead(notificationId)` - Notification management

### DonationService (lib/services/donation_service.dart)
Donation CRUD and location-based search. Methods:
- `createDonation(...)` - Add new donation
- `getNearbyDonations(lat, lng)` - Search within 25km radius
- `updateDonationStatus(...)` - Admin approval/rejection
- `claimDonation(...)` - User claims medicine

### Admin Panel (lib/pages/admin_panel.dart)
3-tab dashboard for admins:
- **Donations**: Approve/reject pending medicines
- **Reports**: Review and resolve safety reports
- **Users**: View and manage all users

## Status Workflows

### Donation Statuses
- `pending` → `approved` (admin approval)
- `approved` → `claimed` (user claims medicine)
- `approved` → `expired` (auto-marked after expiry date)
- Any → `rejected` (admin rejection)

### Request Statuses
- `pending` → `fulfilled` (medicine assigned)
- `pending` → `rejected` (medicine unavailable)
- `pending` → `cancelled` (user cancels)

### Report Statuses
- `pending` (awaiting admin review)
- `resolved` (admin action taken)
- `rejected` (report dismissed)

## Known Limitations (Current)

- No real Firebase integration (using in-memory storage)
- Authentication is mock-based (no password hashing)
- Notifications are simulated (no real push notifications)
- Location data is static (not using device GPS)

## Next Steps for Production

1. Integrate Firebase Firestore for persistent storage
2. Implement Firebase Authentication with proper password hashing
3. Add real push notifications using Firebase Cloud Messaging
4. Integrate device GPS for live location tracking
5. Add image upload for medicine verification
6. Implement proper error handling and offline support
7. Add unit and widget tests
8. Deploy to Play Store and App Store

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

---

**Status**: ✅ Complete with mock data, ready for testing and Firebase integration

