#!/bin/bash

# RocketNotes AI - Supabase Setup Script
# This script helps set up Supabase integration for RocketNotes AI

echo "🚀 RocketNotes AI - Supabase Setup"
echo "=================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI is not installed."
    echo "Install it from: https://supabase.com/docs/guides/cli"
    echo ""
    echo "Or continue with manual setup..."
fi

echo "📋 Setup Steps:"
echo "1. Create a Supabase project at https://supabase.com"
echo "2. Copy your project URL and anon key"
echo "3. Update lib/core/config/supabase_config.dart"
echo "4. Run the SQL schema in your Supabase dashboard"
echo ""

# Create .env file template
cat > .env.template << EOF
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Optional: For development
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
EOF

echo "✅ Created .env.template file"
echo ""

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Generate Hive adapters
echo "🔧 Generating Hive adapters..."
flutter pub run build_runner build

if [ $? -eq 0 ]; then
    echo "✅ Hive adapters generated successfully"
else
    echo "❌ Failed to generate Hive adapters"
    exit 1
fi

echo ""
echo "🎉 Setup completed!"
echo ""
echo "Next steps:"
echo "1. Set up your Supabase project"
echo "2. Update the configuration files"
echo "3. Run the SQL schema"
echo "4. Start developing!"
echo ""
echo "📖 See SUPABASE_INTEGRATION_README.md for detailed instructions"
