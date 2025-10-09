#!/bin/bash

echo "Decoding Anvil state..."

# Get the compressed hex state
curl -s http://localhost:8545 \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"method":"anvil_dumpState","params":[],"id":1,"jsonrpc":"2.0"}' \
  | jq -r '.result' \
  | cut -c 3- \
  | xxd -r -p \
  | gunzip \
  > deployed-state.json

# Verify
if jq empty deployed-state.json 2>/dev/null; then
  echo "✅ State decoded successfully!"
  
  # Show contracts
  CONTRACT_COUNT=$(jq '[.accounts | to_entries[] | select(.value.code != "0x" and .value.code != "")] | length' deployed-state.json)
  echo "📝 Found $CONTRACT_COUNT deployed contracts"
  
  if [ "$CONTRACT_COUNT" -gt 0 ]; then
    echo "📍 Contract addresses:"
    jq -r '[.accounts | to_entries[] | select(.value.code != "0x" and .value.code != "") | .key] | .[]' deployed-state.json
  fi
else
  echo "❌ Failed to decode state"
  exit 1
fi