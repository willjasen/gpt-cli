#!/bin/bash

# Check if the API key is set
if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY environment variable is not set."
  echo "Set your API key using: export OPENAI_API_KEY='your_api_key'"
  exit 1
fi

# Check if a prompt is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 'Your prompt here' [output_file] [show_full_response (true/false)]"
  exit 1
fi

# Start stopwatch
START_TIME=$(date +%s)

# Configuration variables
MODEL="gpt-4"               # Define the model to use
PROMPT="$1"                 # The prompt passed as the first parameter
OUTPUT_FILE="${2:-./output.txt}" # Default output file
SHOW_RESPONSE="${3:-false}" # Default to not showing the full response

# Rename existing file if necessary
if [[ -f "$OUTPUT_FILE" ]]; then
  BASENAME=$(basename "$OUTPUT_FILE")
  DIRNAME=$(dirname "$OUTPUT_FILE")
  EXT="${BASENAME##*.}"    # Extract the file extension
  FILENAME="${BASENAME%.*}" # Extract the file name without extension

  COUNTER=1
  NEW_FILE="$DIRNAME/.$FILENAME.$EXT.$COUNTER"
  while [[ -f "$NEW_FILE" ]]; do
    COUNTER=$((COUNTER + 1))
    NEW_FILE="$DIRNAME/.$FILENAME.$EXT.$COUNTER"
  done

  mv "$OUTPUT_FILE" "$NEW_FILE"
  echo "Existing file renamed to $(basename "$NEW_FILE")"
fi

# Send request to OpenAI API
API_RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
    \"temperature\": 0.7
  }")

# Extract relevant data from the API response
RESPONSE=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content')
USAGE=$(echo "$API_RESPONSE" | jq -r '.usage.total_tokens')

# Attempt to extract a code block; fallback to entire response if not found
CODE=$(echo "$RESPONSE" | sed -n '/^```/,/^```/p' | sed 's/^```.*//g')
if [[ -z "$CODE" ]]; then
  CODE="$RESPONSE" # Fallback to the full response if no code block is found
fi

# Save the code to the output file
if [[ -n "$CODE" ]]; then
  echo "$CODE" > "$OUTPUT_FILE"
  echo "Response saved to $OUTPUT_FILE"
else
  echo "Failed to extract meaningful content. Please refine your prompt."
fi

# Optionally display the full explanation in the terminal
if [[ "$SHOW_RESPONSE" == "true" ]]; then
  echo "Full response:"
  echo "$RESPONSE"
fi

# End stopwatch and calculate elapsed time
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Script execution time: ${ELAPSED_TIME} seconds"

# Output token usage
if [[ -n "$USAGE" ]]; then
  echo "Total tokens used: $USAGE"
else
  echo "Token usage information not available."
fi
