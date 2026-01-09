# MediShare Mock Data

This document outlines all mock/sample data included in the application for testing purposes.

## Demo Login Credentials

### Admin Account
- **Email**: `nfahad066@gmail.com`
- **Password**: `12345678`
- **Role**: Admin
- **Verified**: Yes
- **Location**: Dhaka

### Regular User Accounts
- **Email**: `fahad@gmail.com`
- **Password**: `12345678`
- **Name**: Fahad
- **Location**: Dhaka


---

## Mock Users

| User ID | Name | Email | Phone | Location | Role | Verified |
|---------|------|-------|-------|----------|------|----------|
| ADMIN_001 | Admin User | nfahad066@gmail.com | +8801234567890 | Dhaka | Admin | Yes |
| USER_001 | John Doe | john@example.com | +8801987654321 | Dhaka (23.8110, 90.4120) | User | Yes |
| USER_002 | Jane Smith | jane@example.com | +8801876543210 | Chittagong (22.3569, 91.7832) | User | Yes |
| USER_003 | Ahmed Khan | ahmed@example.com | +8801765432109 | Sylhet (24.8949, 91.8687) | User | Yes |

---

## Mock Donations

| ID | Medicine | Type | Quantity | Donor | Location | Status | Expiry Date |
|----|----------|------|----------|-------|----------|--------|-------------|
| DON_001 | Paracetamol | Tablet | 50 | John Doe | Dhaka | Approved | 2025-12-31 |
| DON_002 | Amoxicillin | Capsule | 30 | Jane Smith | Chittagong | Approved | 2026-03-15 |
| DON_003 | Ibuprofen | Tablet | 20 | John Doe | Dhaka | Approved | 2025-08-10 |
| DON_004 | Vitamin C | Tablet | 60 | Ahmed Khan | Sylhet | Approved | 2026-06-30 |
| DON_005 | Antihistamine | Tablet | 15 | Jane Smith | Chittagong | Pending | 2026-01-20 |

### Donation Details
- **DON_001**: 50 Paracetamol tablets, approved 2 days ago, near Dhaka city center
- **DON_002**: 30 Amoxicillin capsules, approved 1 day ago, Chittagong location
- **DON_003**: 20 Ibuprofen tablets, pain reliever, approved 3 days ago
- **DON_004**: 60 Vitamin C tablets, multivitamin supplement, just approved
- **DON_005**: 15 Antihistamine tablets, allergy medicine, awaiting admin approval

---

## Mock Requests

| ID | Medicine | Type | Quantity | Requester | Location | Status | Assigned Donation |
|----|----------|------|----------|-----------|----------|--------|-------------------|
| REQ_001 | Paracetamol | Tablet | 20 | Jane Smith | Chittagong | Fulfilled | DON_001 |
| REQ_002 | Amoxicillin | Capsule | 10 | Ahmed Khan | Sylhet | Fulfilled | DON_002 |
| REQ_003 | Vitamin D | Tablet | 30 | John Doe | Dhaka | Pending | — |

### Request Details
- **REQ_001**: 20 Paracetamol for fever relief, fulfilled 1 day ago
- **REQ_002**: 10 Amoxicillin for infection treatment, fulfilled today
- **REQ_003**: 30 Vitamin D for deficiency supplement, awaiting fulfillment

---

## Mock Reports

| ID | Donation | Reason | Reporter | Status | Created |
|----|----------|--------|----------|--------|---------|
| RPT_001 | DON_005 | Expired Medicine | John Doe | Pending | 2 hours ago |

### Report Details
- **RPT_001**: Safety report on Antihistamine donation (DON_005) - medication appears expired based on visual inspection. Awaiting admin review.

---

## Mock Notifications

| ID | Recipient | Type | Title | Status | Created |
|----|-----------|------|-------|--------|---------|
| NOT_001 | John Doe | Donation Approved | New Donation Available | Unread | 1 hour ago |
| NOT_002 | Jane Smith | Donation Claimed | Your Donation Claimed | Unread | 30 minutes ago |
| NOT_003 | Admin User | Report Resolved | New Safety Report | Unread | 15 minutes ago |

### Notification Details
- **NOT_001**: John notified of available Paracetamol donation
- **NOT_002**: Jane notified that her Paracetamol was claimed
- **NOT_003**: Admin notified of new safety report on medicine

---

## Testing Workflow

### Quick Admin Test
1. Login with admin credentials (nfahad066@gmail.com / 12345678)
2. View Admin Panel (red FAB button)
3. **Donations Tab**: See 5 donations (4 approved, 1 pending for approval)
4. **Reports Tab**: See 1 safety report awaiting action
5. **Users Tab**: Manage all 4 user accounts

### Quick User Test
1. Login with user credentials (john@example.com / 12345678)
2. **Home Tab**: View 3 unread notifications
3. **Browse Tab**: Search and browse 4 approved donations nearby
4. **Donate Tab**: Add new medicine donation
5. **Request Tab**: Create or view medicine requests

### Location-Based Search Test
- Dhaka users should see donations from John Doe (DON_001, DON_003)
- Chittagong users should see Jane's donations (DON_002, DON_005)
- Sylhet users should see Ahmed's donation (DON_004)
- Search radius: ~25 km from user location

---

## Data Initialization

All mock data is initialized in the following services at startup:

- **UserService**: `_initializeMockUsers()` method
- **DonationService**: `_initializeMockDonations()` method
- **RequestService**: `_initializeMockRequests()` method
- **ReportService**: `_initializeMockReports()` method
- **NotificationService**: `_initializeMockNotifications()` method

These methods are called during service instantiation to populate in-memory data structures for testing.

---

## Notes

- All passwords in mock data are: `12345678`
- Location coordinates use real Dhaka, Chittagong, and Sylhet city centers
- Medicine types and names are realistic examples
- Status workflows demonstrate complete lifecycle (pending → approved → claimed/fulfilled)
- Timestamps use relative durations from current time for realistic display

