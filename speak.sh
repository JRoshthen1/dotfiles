#!/bin/bash
# Chunked TTS processor - Divides text into chunks, processes and plays them sequentially

EXEC_PATH="$HOME/kokoros/target/release/koko"
MODEL_PATH="$HOME/kokoros/checkpoints/kokoro-v1.0.onnx"
VOICE_DATA="$HOME/kokoros/voices-v1.0.bin"
SPEED=1.1
VOICE_STYLE="af_heart"
# Style mixing supported for Kokoros: "af_sky.4+af_nicole.5"
# https://github.com/hexgrad/kokoro/tree/main/kokoro.js/voices

# Chunking parameters
MIN_CHUNK_SIZE=80
MAX_CHUNK_SIZE=200
MIN_SENTENCES=2

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

clipboard_content=$(xclip -o)
filtered_content=$(echo "$clipboard_content" | sed -E '
  s/-(\r|\n)//g
  s/\r|\n/ /g
  s/ +/ /g
  s/^ *//g
  s/ *$//g
  s/--/ — /g
  s/ - / — /g
  s/\.\.\./…/g
  s/([0-9]),([0-9])/\1\2/g
  s/([.,;:])([^ ])/\1 \2/g
')

TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Save the cleaned text to a file
echo "$filtered_content" > "$TEMP_DIR/full_text.txt"

# Smart chunking: Split text into optimal chunks
cat "$TEMP_DIR/full_text.txt" | 
  sed -E 's/([.!?]) +/\1\n/g' |
  awk -v min_size="$MIN_CHUNK_SIZE" -v max_size="$MAX_CHUNK_SIZE" -v min_sentences="$MIN_SENTENCES" '
  BEGIN {
    chunk = "";
    sentence_count = 0;
  }
  
  NF > 0 {
    sentence = $0;
    
    if (length(chunk) > 0) {
      test_chunk = chunk " " sentence;
    } else {
      test_chunk = sentence;
    }
    
    should_output = 0;
    
    # If adding this sentence would exceed max size, output current chunk first
    if (length(test_chunk) > max_size && length(chunk) > 0) {
      should_output = 1;
    }
    # If we have minimum sentences and minimum size, we can output
    else if (sentence_count >= min_sentences && length(chunk) >= min_size) {
      if (length(sentence) > (max_size - min_size)) {
        should_output = 1;
      }
      else if (length(test_chunk) >= min_size * 1.5) {
        chunk = test_chunk;
        sentence_count++;
        should_output = 1;
      }
    }
    
    if (should_output && length(chunk) > 0) {
      print chunk;
      chunk = "";
      sentence_count = 0;
      
      if (length(test_chunk) > max_size) {
        chunk = sentence;
        sentence_count = 1;
      }
    }
    else {
      chunk = test_chunk;
      sentence_count++;
    }
  }
  
  END {
    if (length(chunk) > 0) {
      print chunk;
    }
  }' > "$TEMP_DIR/chunks.txt"

process_chunk() {
  local chunk="$1"
  local output_file="$2"
  echo "Processing: ${chunk:0:40}..."
  echo "$chunk" > "$TEMP_DIR/current_chunk.txt"
  
  "$EXEC_PATH" \
    --model "$MODEL_PATH" \
    --data "$VOICE_DATA" \
    --speed "$SPEED" \
    --style "$VOICE_STYLE" \
    text "$(cat "$TEMP_DIR/current_chunk.txt")" \
    --output "$output_file"
    
  if [ ! -f "$output_file" ]; then
    echo "Error: Failed to create audio file for chunk. Skipping..."
    return 1
  fi
  
  return 0
}

# Process the first chunk immediately
FIRST_CHUNK=$(head -n 1 "$TEMP_DIR/chunks.txt")
FIRST_OUTPUT="$TEMP_DIR/chunk_0.wav"
process_chunk "$FIRST_CHUNK" "$FIRST_OUTPUT"

if [ -f "$FIRST_OUTPUT" ]; then
  aplay "$FIRST_OUTPUT" &
  PLAY_PID=$!
else
  echo "Failed to process first chunk. Continuing with next chunks..."
  PLAY_PID=0
fi

# Process remaining chunks
CHUNK_NUM=1
while read -r chunk; do
  if [ $CHUNK_NUM -eq 1 ]; then
    CHUNK_NUM=$((CHUNK_NUM + 1))
    continue
  fi
  
  OUTPUT_FILE="$TEMP_DIR/chunk_$CHUNK_NUM.wav"
  
  process_chunk "$chunk" "$OUTPUT_FILE"
  
  if [ $PLAY_PID -ne 0 ]; then
    wait $PLAY_PID || true
  fi
  
  if [ -f "$OUTPUT_FILE" ]; then
    aplay "$OUTPUT_FILE" &
    PLAY_PID=$!
  else
    echo "Skipping playback of chunk $CHUNK_NUM (file not created)"
    PLAY_PID=0
  fi
  
  CHUNK_NUM=$((CHUNK_NUM + 1))
done < "$TEMP_DIR/chunks.txt"

if [ $PLAY_PID -ne 0 ]; then
  wait $PLAY_PID || true
fi

echo "Processing complete!"
rm -rf "$TEMP_DIR"