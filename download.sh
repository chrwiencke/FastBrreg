#!/bin/bash

# Set the URL to download the file from
URL="https://data.brreg.no/enhetsregisteret/api/enheter/lastned"

# Set MongoDB connection details
MONGO_HOST="localhost"
MONGO_PORT="27017"
DB_NAME="test"
COLLECTION_NAME="brregorganizations"
TEMP_COLLECTION_NAME="temp_brregorganizations"

# Temporary file to store the downloaded data
TEMP_FILE="/tmp/brreg_data.gz"
EXTRACTED_FILE="/tmp/brreg_data.json"

# Download the .gz file
echo "Downloading data from $URL..."
curl -s -o "$TEMP_FILE" "$URL"

# Check if download was successful
if [ $? -ne 0 ]; then
  echo "Failed to download data."
  exit 1
fi

# Extract the .gz file to a JSON file
echo "Extracting the .gz file..."
gunzip -c "$TEMP_FILE" > "$EXTRACTED_FILE"

# Check if extraction was successful
if [ $? -ne 0 ]; then
  echo "Failed to extract the .gz file."
  exit 1
fi

# Clear existing data in MongoDB collection (do not delete it, just make sure new data is in a temporary collection)
echo "Importing data into MongoDB (temporary collection)..."
mongoimport --host "$MONGO_HOST" --port "$MONGO_PORT" --db "$DB_NAME" --collection "$TEMP_COLLECTION_NAME" --file "$EXTRACTED_FILE" --jsonArray

# Check if import was successful
if [ $? -eq 0 ]; then
  echo "Data successfully imported into temporary collection."
else
  echo "Failed to import data into temporary collection."
  exit 1
fi

echo "Recreating indexes on the new collection..."

mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" "$DB_NAME" --eval "
  db.$TEMP_COLLECTION_NAME.createIndex({ 'organisasjonsnummer': 1 }, { name: 'organisasjonsnummer_1', unique: true });
  db.$TEMP_COLLECTION_NAME.createIndex({ 'navn': 'text' }, { name: 'name' });
"

# Swap collections to minimize downtime (atomic operation)
echo "Swapping collections in MongoDB..."
mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" "$DB_NAME" --eval "
  db.$COLLECTION_NAME.drop(); 
  db.$TEMP_COLLECTION_NAME.renameCollection('$COLLECTION_NAME');
"

# Check if the swap was successful
if [ $? -eq 0 ]; then
  echo "Temporary collection successfully swapped with the original collection."
else
  echo "Failed to swap collections."
  exit 1
fi

# Clean up
rm "$TEMP_FILE" "$EXTRACTED_FILE"

echo "Script execution completed."