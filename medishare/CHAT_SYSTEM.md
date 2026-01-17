# Chat System Implementation

## Overview
A real-time chat system for donors and receivers to communicate about medicine donation requests.

## Features

### 1. Chat Model (`lib/models/chat_message.dart`)
- **Fields:**
  - `id`: Unique UUID for each message
  - `requestId`: Link to the medicine request
  - `senderId`: User who sent the message
  - `senderName`: Sender's display name
  - `recipientId`: User receiving the message
  - `message`: Message content
  - `createdAt`: Timestamp of message creation
  - `isRead`: Message read status
- **Methods:** `fromJson()`, `toJson()`, `copyWith()`

### 2. Chat Service (`lib/services/chat_service.dart`)
**Key Methods:**
- `sendMessage()` - Send new message with UUID generation
- `getMessagesByRequest()` - Fetch all messages for a request
- `getConversation()` - Get messages between two users for a request
- `markMessageAsRead()` - Mark individual message as read
- `markAllMessagesAsRead()` - Mark all messages for a user as read
- `deleteMessage()` - Delete a message
- `getUnreadCount()` - Get unread message count

### 3. Chat Page (`lib/pages/chat_page.dart`)
**UI Components:**
- **Header:** Shows recipient name and request ID (truncated)
- **Messages List:** 
  - Ordered chronologically
  - Color-coded (current user = blue, other user = gray)
  - Shows timestamp (time for today, "Yesterday HH:MM", or date format)
  - Empty state when no messages
- **Input Section:**
  - Text field for message composition
  - Send button (blue circular button with send icon)
  - Auto-scroll to latest message after sending

**Features:**
- Auto-marks messages as read on page load
- Smooth scrolling to bottom after sending
- Error handling with snackbar notifications
- Responsive design with proper spacing

### 4. Database Schema (`sql/create_chat_messages_table.sql`)
**Table:** `chat_messages`

**Columns:**
- `id UUID PRIMARY KEY` - Unique message ID
- `request_id VARCHAR(255)` - Link to medicine request
- `sender_id UUID` - User who sent message
- `sender_name VARCHAR(255)` - Sender's name
- `recipient_id UUID` - Message recipient
- `message TEXT` - Message content
- `is_read BOOLEAN DEFAULT false` - Read status
- `created_at TIMESTAMP` - Creation timestamp
- `updated_at TIMESTAMP` - Last update timestamp

**Indexes:**
- `request_id` - Retrieve messages by request
- `sender_id` - Retrieve messages by sender
- `recipient_id` - Retrieve messages by recipient
- `created_at DESC` - Order messages chronologically
- `(request_id, sender_id, recipient_id)` - Composite for conversation queries

**RLS Policies:**
- SELECT: Sender, recipient, or admin can view
- INSERT: Sender must be authenticated user
- UPDATE: Sender or admin can update
- DELETE: Sender or admin can delete

### 5. Integration Points

**My Requests Page** (`lib/pages/my_requests.dart`)
- Added `import 'chat_page.dart';`
- Chat button available for all request statuses
- Button colors: Green (pending/approved), Green (fulfilled/received)
- Shows "Chat with Donor" for all statuses

**Requested To Me Page** (`lib/pages/requested_to_me.dart`)
- Added `import 'chat_page.dart';`
- Chat button available for all request statuses
- Integrated with pending, approved, and received states
- Shows "Chat" button alongside other actions

## User Flow

### Receiver Perspective
1. View "My Requests" page
2. Click "Chat" button on any request
3. Opens ChatPage with donor's name
4. Can send messages to donor at any stage
5. Messages marked as read when opened

### Donor Perspective
1. View "Requested to Me" page
2. Click "Chat" button during acceptance/delivery/completion
3. Opens ChatPage with requester's name
4. Can send messages to requester
5. Maintains conversation history per request

## Technical Details

**Message Flow:**
```
User types message → _sendMessage() → ChatService.sendMessage()
  ↓
Generate UUID → Insert to Supabase → Update UI
  ↓
Fetch updated messages → Display in ListView
  ↓
Auto-scroll to bottom
```

**Timestamp Formatting:**
- Today: "HH:MM" (e.g., "14:30")
- Yesterday: "Yesterday HH:MM"
- Earlier: "D/M HH:MM" (e.g., "15/1 10:30")

**UI Styling:**
- Current user messages: Blue background, white text, right-aligned
- Other user messages: Gray background, black text, left-aligned
- Message bubbles: 16px padding, 16px border-radius
- Read status: Displayed but not visually emphasized in UI

## Integration with Request System

Chat is integrated at multiple request statuses:
- **PENDING**: Recipients can ask questions before accepting
- **APPROVED**: Both parties can discuss delivery logistics
- **FULFILLED**: Coordination during delivery
- **RECEIVED**: Post-delivery discussion

This allows seamless communication throughout the transaction lifecycle.

## Future Enhancements

- [ ] Typing indicators
- [ ] Message reactions/emojis
- [ ] Image sharing
- [ ] Read receipts UI
- [ ] Chat notifications
- [ ] Message search within conversation
- [ ] Group chat for requests
- [ ] Message editing
- [ ] Auto-delete old messages

## Database Setup

Run this SQL to create the chat system:
```sql
-- From: sql/create_chat_messages_table.sql
```

Or manually execute the schema in Supabase:
1. Go to SQL Editor in Supabase
2. Copy and paste the SQL from `sql/create_chat_messages_table.sql`
3. Execute the query
4. Verify `chat_messages` table is created with proper indexes and RLS policies
