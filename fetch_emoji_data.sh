#!/bin/bash

# Script to fetch emoji data from emojibase
# Run this script from the project root to update emoji data

set -e

EMOJI_URL="https://raw.githubusercontent.com/milesj/emojibase/master/packages/data/en/compact.raw.json"
OUTPUT_DIR="Sources/Resources"
OUTPUT_FILE="$OUTPUT_DIR/emoji_data.json"

echo "🔄 Fetching emoji data from emojibase..."

# Create resources directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Download the emoji data
if curl -s -o "$OUTPUT_FILE" "$EMOJI_URL"; then
    echo "✅ Successfully downloaded emoji data to $OUTPUT_FILE"

    # Show some stats
    EMOJI_COUNT=$(jq length "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
    echo "📊 Total emojis: $EMOJI_COUNT"

    # Show file size
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo "📏 File size: $FILE_SIZE"

    echo "🎉 Emoji data update complete!"
else
    echo "❌ Failed to download emoji data"
    exit 1
fi
