#!/bin/bash

# Manual Atlas to Local MongoDB sync script
# Use this script to manually trigger a sync from Atlas to local MongoDB

set -e

echo "🚀 Manual Atlas to Local MongoDB sync starting..."

# Configuration
ATLAS_URI="mongodb+srv://CryptoAdmin:crypto_2222@cluster0.xk72gks.mongodb.net/"
LOCAL_URI="mongodb://root:crypto_2222@localhost:27017/crypto_immobilier?authSource=admin"
DB_NAME="crypto_immobilier"
DUMP_DIR="/tmp/mongo_dump_manual"
CONTAINER_NAME="crypto-mongo"

# Check if Docker container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ MongoDB container '$CONTAINER_NAME' is not running!"
    echo "Please start the containers first: docker compose up -d"
    exit 1
fi

echo "✅ MongoDB container is running"

# Function to execute commands in the MongoDB container
execute_in_container() {
    local command="$1"
    local description="$2"
    
    echo "📋 $description..."
    echo "🔧 Command: $command"
    
    if docker exec "$CONTAINER_NAME" bash -c "$command"; then
        echo "✅ $description completed successfully"
    else
        echo "❌ $description failed"
        exit 1
    fi
}

# Create dump directory in container
execute_in_container "mkdir -p $DUMP_DIR" "Creating dump directory"

# Install MongoDB tools in container if needed
execute_in_container "
    if ! command -v mongodump &> /dev/null; then
        apt-get update && apt-get install -y wget gnupg
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
        echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse' | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        apt-get update && apt-get install -y mongodb-database-tools
    fi
" "Installing MongoDB tools"

# Dump data from Atlas
execute_in_container "mongodump --uri='$ATLAS_URI' --db=$DB_NAME --out=$DUMP_DIR" "Dumping data from Atlas"

# Drop existing local database and restore from Atlas
execute_in_container "mongorestore --uri='$LOCAL_URI' --db=$DB_NAME --drop $DUMP_DIR/$DB_NAME" "Restoring data to local MongoDB"

# Cleanup
execute_in_container "rm -rf $DUMP_DIR" "Cleaning up dump directory"

# Verify the sync
echo "🔍 Verifying sync..."
docker exec "$CONTAINER_NAME" mongosh "$LOCAL_URI" --eval "
    db.adminCommand('listCollections').cursor.firstBatch.forEach(c => print('Collection:', c.name));
    print('Total collections:', db.adminCommand('listCollections').cursor.firstBatch.length);
"

echo "🎉 Manual Atlas to Local MongoDB sync completed successfully!"
echo "📊 You can now verify your data in the local MongoDB container"
