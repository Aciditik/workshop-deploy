#!/bin/bash

echo "=== Production Database Reset ==="
echo "This will reset the production database to clean state"
echo "Similar to your local environment"
echo ""

TOURNAMENT_ID="4e3e6a45-b1f0-4662-844a-f33bd407006d"
API_URL="https://cdf-tournament.onrender.com"

echo "⚠️  WARNING: This will DELETE the corrupted tournament data"
echo "Tournament ID: $TOURNAMENT_ID"
echo ""

read -p "Do you want to continue? (y/N) " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

echo "Please enter your admin credentials:"
echo "Email: "
read EMAIL
echo "Password: "
read -s PASSWORD

echo ""
echo "Authenticating..."

# Login to get token
LOGIN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  "$API_URL/api/auth/login")

TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('token', ''))
except:
    pass
")

if [ -z "$TOKEN" ]; then
    echo "❌ Login failed. Please check your credentials."
    exit 1
fi

echo "✅ Authenticated successfully!"

# Delete the corrupted tournament
echo "🗑️  Deleting corrupted tournament..."
DELETE_RESPONSE=$(curl -s -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "$API_URL/api/tournaments/$TOURNAMENT_ID")

echo "Delete response: $DELETE_RESPONSE"

echo ""
echo "✅ Production database reset complete!"
echo ""
echo "📝 Next steps:"
echo "1. Go to your admin interface: https://cdf-tournament.onrender.com"
echo "2. Create a new tournament with the same name"
echo "3. Add your players"
echo "4. Start the tournament fresh"
echo ""
echo "🎯 This will work exactly like your local environment!"
