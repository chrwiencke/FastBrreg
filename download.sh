#!/bin/bash

# Set the URL to download the file from
URL="https://data.brreg.no/enhetsregisteret/api/enheter/lastned"

# Set MongoDB connection details
MONGO_HOST="localhost"
MONGO_PORT="27017"
DB_NAME="brregorganizations"
COLLECTION_NAME="enheter"

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

# Clear existing data in MongoDB collection
echo "Clearing existing data in MongoDB..."
mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" "$DB_NAME" --eval "db.$COLLECTION_NAME.deleteMany({})"

# Import the downloaded data into MongoDB
echo "Importing data into MongoDB..."
mongoimport --host "$MONGO_HOST" --port "$MONGO_PORT" --db "$DB_NAME" --collection "$COLLECTION_NAME" --file "$EXTRACTED_FILE" --jsonArray

# Check if import was successful
if [ $? -eq 0 ]; then
  echo "Data successfully imported into MongoDB."
else
  echo "Failed to import data into MongoDB."
  exit 1
fi

# Clean up
rm "$TEMP_FILE" "$EXTRACTED_FILE"

echo "Script execution completed."
