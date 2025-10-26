#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const ATLAS_URI = process.env.MONGO_ATLAS_URI || 'mongodb+srv://CryptoAdmin:crypto_2222@cluster0.xk72gks.mongodb.net/';
const LOCAL_URI = 'mongodb://root:crypto_2222@localhost:27017/test?authSource=admin';
const DB_NAME = 'test';
const DUMP_DIR = '/tmp/mongo_dump';
const SYNC_FLAG_FILE = '/data/db/.atlas_synced';

console.log('🚀 Starting Atlas to Local MongoDB sync...');

// Check if sync has already been performed
if (fs.existsSync(SYNC_FLAG_FILE)) {
    console.log('✅ Atlas sync already completed. Skipping...');
    process.exit(0);
}

// Function to execute shell commands
function executeCommand(command, description) {
    return new Promise((resolve, reject) => {
        console.log(`📋 ${description}...`);
        console.log(`🔧 Command: ${command}`);
        
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`❌ Error in ${description}:`, error.message);
                reject(error);
                return;
            }
            if (stderr) {
                console.warn(`⚠️  Warning in ${description}:`, stderr);
            }
            if (stdout) {
                console.log(`📄 Output: ${stdout}`);
            }
            console.log(`✅ ${description} completed successfully`);
            resolve(stdout);
        });
    });
}

// Main sync function
async function syncAtlasToLocal() {
    try {
        // Wait for local MongoDB to be ready
        console.log('⏳ Waiting for local MongoDB to be ready...');
        await new Promise(resolve => setTimeout(resolve, 10000));

        // Create dump directory
        await executeCommand(`mkdir -p ${DUMP_DIR}`, 'Creating dump directory');

        // Dump data from Atlas
        const dumpCommand = `mongodump --uri="${ATLAS_URI}" --db=${DB_NAME} --out=${DUMP_DIR}`;
        await executeCommand(dumpCommand, 'Dumping data from Atlas');

        // Check if dump was successful
        const dumpPath = path.join(DUMP_DIR, DB_NAME);
        if (!fs.existsSync(dumpPath)) {
            throw new Error('Dump directory not found. Atlas dump may have failed.');
        }

        // Restore data to local MongoDB
        const restoreCommand = `mongorestore --uri="${LOCAL_URI}" --db=${DB_NAME} --drop ${dumpPath}`;
        await executeCommand(restoreCommand, 'Restoring data to local MongoDB');

        // Create sync flag file
        fs.writeFileSync(SYNC_FLAG_FILE, new Date().toISOString());
        console.log('🏁 Atlas sync flag created');

        // Cleanup dump directory
        await executeCommand(`rm -rf ${DUMP_DIR}`, 'Cleaning up dump directory');

        console.log('🎉 Atlas to Local MongoDB sync completed successfully!');
        
        // Verify the sync
        await executeCommand(
            `mongosh "${LOCAL_URI}" --eval "db.adminCommand('listCollections').cursor.firstBatch.forEach(c => print('Collection:', c.name))"`,
            'Verifying collections in local database'
        );

    } catch (error) {
        console.error('💥 Sync failed:', error.message);
        process.exit(1);
    }
}

// Run the sync
syncAtlasToLocal();
