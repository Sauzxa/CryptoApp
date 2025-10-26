#!/bin/bash

# MongoDB initialization script for Docker container
# This script runs when the MongoDB container starts for the first time

set -e

echo "🚀 MongoDB initialization script starting..."

# Wait for MongoDB to be ready
echo "⏳ Waiting for MongoDB to start..."
until mongosh --host localhost --port 27017 --eval "print('MongoDB is ready')" > /dev/null 2>&1; do
    echo "Waiting for MongoDB..."
    sleep 2
done

echo "✅ MongoDB is ready!"

# Check if Atlas sync is needed
SYNC_FLAG_FILE="/data/db/.atlas_synced"

if [ ! -f "$SYNC_FLAG_FILE" ]; then
    echo "🔄 Starting Atlas synchronization..."
    
    # Install Node.js and required tools if not present
    if ! command -v node &> /dev/null; then
        echo "📦 Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install MongoDB tools if not present
    if ! command -v mongodump &> /dev/null; then
        echo "📦 Installing MongoDB tools..."
        apt-get update
        apt-get install -y wget gnupg
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        apt-get update
        apt-get install -y mongodb-database-tools
    fi
    
    # Set environment variables for the sync script
    export MONGO_ATLAS_URI="mongodb+srv://CryptoAdmin:crypto_2222@cluster0.xk72gks.mongodb.net/"
    
    # Run the Atlas sync script
    node /docker-entrypoint-initdb.d/atlas-sync.js
    
    echo "✅ Atlas synchronization completed!"
else
    echo "✅ Atlas sync already completed, skipping..."
fi

echo "🏁 MongoDB initialization completed!"
