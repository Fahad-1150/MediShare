-- Fix RLS policy for chat_messages table
-- Run this in Supabase SQL Editor to fix the message sending error

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
