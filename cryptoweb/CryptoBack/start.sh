#!/bin/bash

echo "🚀 Starting Crypto Backend with database initialization..."

# Wait for MongoDB to be available
echo "⏳ Waiting for MongoDB to be ready..."
while ! nc -z mongo 27017; do
  sleep 1
done
echo "✅ MongoDB is ready!"

# Run database initialization
echo "🔧 Running database initialization..."
if [ -f "./scripts/init-mongo.sh" ]; then
    ./scripts/init-mongo.sh
else
    echo "⚠️ init-mongo.sh not found, skipping database initialization"
fi

# Start the main application
echo "🎯 Starting Node.js application..."
exec npm start
