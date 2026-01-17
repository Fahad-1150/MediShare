# Fix Chat Message Sending Error

## Problem
You're getting this error when trying to send a message:
```
Error sending message: Exception: Failed to send message: PostgrestException(message: new row violates row-level security policy for table "chat_messages", code: 42501)
```

## Root Cause
The Row-Level Security (RLS) policy on the `chat_messages` table is rejecting message inserts because of a UUID type mismatch. The policy was comparing UUIDs incorrectly.

## Solution
You need to update the RLS policies in your Supabase database.

### Step-by-Step Fix

#### 1. Go to Supabase Dashboard
- Open [Supabase Console](https://app.supabase.com)
- Select your MediShare project
- Go to **SQL Editor** (left sidebar)

#### 2. Copy the Fix Script
The fix script is located at: `sql/fix_chat_rls_policy.sql`

Content to run:
```sql
-- Fix RLS policy for chat_messages table

-- First, drop the problematic policy
DROP POLICY IF EXISTS "Users can send messages" ON public.chat_messages;

-- Recreate with proper UUID conversion
CREATE POLICY "Users can send messages"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    auth.uid()::text = sender_id::text
  );

-- Also update the SELECT policy to be more explicit
DROP POLICY IF EXISTS "Users can view chat messages for their conversations" ON public.chat_messages;

CREATE POLICY "Users can view chat messages for their conversations"
  ON chat_messages
  FOR SELECT
  USING (
    auth.uid()::text = sender_id::text OR 
    auth.uid()::text = recipient_id::text OR
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

-- Update policies for UPDATE and DELETE as well
DROP POLICY IF EXISTS "Users can update their own messages" ON public.chat_messages;

CREATE POLICY "Users can update their own messages"
  ON chat_messages
  FOR UPDATE
  USING (
    auth.uid()::text = sender_id::text OR 
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

DROP POLICY IF EXISTS "Users can delete their messages" ON public.chat_messages;

CREATE POLICY "Users can delete their messages"
  ON chat_messages
  FOR DELETE
  USING (
    auth.uid()::text = sender_id::text OR 
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );
```

#### 3. Execute the Script
1. Paste the entire script into the SQL Editor
2. Click **"Run"** button (blue button at bottom)
3. Wait for it to complete (should see "Success" message)

#### 4. Test the Chat
1. Return to your Flutter app
2. Open a chat conversation
3. Type a message and try sending it
4. **It should work now!** ✅

---

## What Changed?

### Before (Broken):
```sql
WITH CHECK (auth.uid() = sender_id)
```

### After (Fixed):
```sql
WITH CHECK (auth.uid()::text = sender_id::text)
```

The fix converts both UUIDs to text strings before comparing them. This ensures they match correctly regardless of how Supabase represents them internally.

---

## Verification

After running the fix, you can verify it worked by:

1. **In Supabase Console:**
   - Go to Table Editor → `chat_messages`
   - Click "Policies" button
   - You should see 4 policies:
     - ✅ "Users can view chat messages for their conversations"
     - ✅ "Users can send messages"
     - ✅ "Users can update their own messages"
     - ✅ "Users can delete their messages"

2. **In the App:**
   - Open any chat
   - Send a message
   - It should appear immediately without errors

---

## If It Still Doesn't Work

If you're still getting errors, try this alternative approach:

```sql
-- Disable RLS entirely for testing (TEMPORARY - NOT RECOMMENDED FOR PRODUCTION)
ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;

-- Then re-enable and apply the fix
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Then run the fix script above
```

Or contact Supabase support if issues persist.

---

## Files Updated
- ✅ `sql/create_chat_messages_table.sql` - Updated with fixed policy
- ✅ `sql/fix_chat_rls_policy.sql` - New file with complete fix script
