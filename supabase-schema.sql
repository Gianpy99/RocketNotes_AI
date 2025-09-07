-- Supabase Database Schema for RocketNotes AI
-- Run this in your Supabase SQL editor

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create custom types
CREATE TYPE note_mode AS ENUM ('personal', 'work');
CREATE TYPE relationship_type AS ENUM ('parent', 'child', 'spouse', 'grandparent', 'sibling', 'other');

-- Users table (extends auth.users)
CREATE TABLE user_profiles (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT NOT NULL,
  email TEXT NOT NULL,
  is_anonymous BOOLEAN DEFAULT FALSE,
  last_sync_time TIMESTAMPTZ DEFAULT NOW(),
  sync_settings JSONB DEFAULT '{}',
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  cloud_sync_enabled BOOLEAN DEFAULT TRUE,
  cloud_provider TEXT DEFAULT 'supabase'
);

-- Notes table
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  mode note_mode DEFAULT 'personal',
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id TEXT, -- For family-shared notes
  shared_notebook_id TEXT, -- For notebook sharing
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  tags TEXT[] DEFAULT '{}',
  ai_summary TEXT,
  attachments TEXT[] DEFAULT '{}',
  nfc_tag_id TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_shared BOOLEAN DEFAULT FALSE,
  sharing_permissions TEXT[] DEFAULT '{}'
);

-- Family members table
CREATE TABLE family_members (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  avatar_path TEXT,
  relationship relationship_type DEFAULT 'other',
  birth_date DATE,
  phone_number TEXT,
  is_emergency_contact BOOLEAN DEFAULT FALSE,
  permissions TEXT[] DEFAULT '{read,write}',
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shared notebooks table
CREATE TABLE shared_notebooks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notebook members table
CREATE TABLE notebook_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  notebook_id TEXT REFERENCES shared_notebooks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  permissions TEXT[] DEFAULT '{read}',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(notebook_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_mode ON notes(mode);
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_tags ON notes USING GIN(tags);
CREATE INDEX idx_family_members_user_id ON family_members(user_id);
CREATE INDEX idx_shared_notebooks_owner_id ON shared_notebooks(owner_id);
CREATE INDEX idx_notebook_members_notebook_id ON notebook_members(notebook_id);
CREATE INDEX idx_notebook_members_user_id ON notebook_members(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notebook_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for notes
CREATE POLICY "Users can view their own notes" ON notes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view shared notes" ON notes
  FOR SELECT USING (is_shared = TRUE);

CREATE POLICY "Users can insert their own notes" ON notes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes" ON notes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes" ON notes
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for family_members
CREATE POLICY "Users can view their own family members" ON family_members
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own family members" ON family_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own family members" ON family_members
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own family members" ON family_members
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for shared_notebooks
CREATE POLICY "Users can view public notebooks" ON shared_notebooks
  FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can view their own notebooks" ON shared_notebooks
  FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert their own notebooks" ON shared_notebooks
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own notebooks" ON shared_notebooks
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own notebooks" ON shared_notebooks
  FOR DELETE USING (auth.uid() = owner_id);

-- RLS Policies for notebook_members
CREATE POLICY "Users can view notebook memberships" ON notebook_members
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM shared_notebooks
      WHERE id = notebook_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Notebook owners can manage members" ON notebook_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM shared_notebooks
      WHERE id = notebook_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can join notebooks" ON notebook_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create functions for real-time updates
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER handle_updated_at_user_profiles
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_notes
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_family_members
  BEFORE UPDATE ON family_members
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_updated_at_shared_notebooks
  BEFORE UPDATE ON shared_notebooks
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Create function to handle user profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_profiles (user_id, display_name, email, is_anonymous)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NEW.email,
    FALSE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic user profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
