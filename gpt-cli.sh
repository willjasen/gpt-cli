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
PROMPT="Provide me only the command line snippets with no other additional response to: $1" # The prompt passed as the first parameter
OUTPUT_FILE="${2:-./output.txt}" # Default output file
SHOW_RESPONSE="${3:-false}"      # Default to not showing the full response

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

# Save the response to the output file
echo "$RESPONSE" > "$OUTPUT_FILE"
echo "Response saved to $OUTPUT_FILE"

# Optionally display the full response in the terminal
if [[ "$SHOW_RESPONSE" == "true" ]]; then
  echo "Full response:"
  echo "$RESPONSE"
fi

# Extract the command and execute it
COMMAND=$(echo "$RESPONSE" | sed -n '/^```/,/^```/p' | sed 's/^```.*//g')

# Fallback if no code block found
if [[ -z "$COMMAND" ]]; then
  COMMAND="$RESPONSE"
fi

# Display and confirm command execution
echo "Command generated for execution:"
echo "$COMMAND"
read -p "Do you want to execute this command? (yes/no): " CONFIRM
if [[ "$CONFIRM" == "yes" ]]; then
  echo "Executing command..."
  eval "$COMMAND"
else
  echo "Command execution skipped."
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
