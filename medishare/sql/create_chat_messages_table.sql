-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY,
  request_id VARCHAR(255) NOT NULL,
  sender_id UUID NOT NULL,
  sender_name VARCHAR(255) NOT NULL,
  recipient_id UUID NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES users_profile(id) ON DELETE CASCADE,
  CONSTRAINT fk_recipient FOREIGN KEY (recipient_id) REFERENCES users_profile(id) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX idx_chat_request_id ON chat_messages(request_id);
CREATE INDEX idx_chat_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_recipient_id ON chat_messages(recipient_id);
CREATE INDEX idx_chat_created_at ON chat_messages(created_at DESC);
CREATE INDEX idx_chat_request_sender_recipient ON chat_messages(request_id, sender_id, recipient_id);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Anyone involved in the chat (sender or recipient) can view messages
CREATE POLICY "Users can view chat messages for their conversations"
  ON chat_messages
  FOR SELECT
  USING (
    auth.uid() = sender_id OR 
    auth.uid() = recipient_id OR
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

-- Anyone can send messages (insert their own messages)
CREATE POLICY "Users can send messages"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    auth.uid()::text = sender_id::text
  );

-- Users can update their own messages
CREATE POLICY "Users can update their own messages"
  ON chat_messages
  FOR UPDATE
  USING (
    auth.uid() = sender_id OR 
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

-- Users can delete their own messages, admins can delete any
CREATE POLICY "Users can delete their messages"
  ON chat_messages
  FOR DELETE
  USING (
    auth.uid() = sender_id OR 
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );
