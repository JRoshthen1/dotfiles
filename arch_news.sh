#!/bin/bash

# Arch Linux News Notifier
# Fetches latest news from Arch Linux RSS feed and shows notifications for new items

# Configuration
RSS_URL="https://archlinux.org/feeds/news/"
CACHE_FILE="$HOME/.cache/arch-news-seen"
TEMP_FILE="/tmp/arch-news-latest"

ICON_NORMAL="/usr/share/pixmaps/tabler--coffee.svg"
ICON_URGENT="/usr/share/pixmaps/charm--circle-warning.svg"

# Create cache directory if it doesn't existnClick to open:
mkdir -p "$(dirname "$CACHE_FILE")"

# Function to extract and format news items
parse_rss() {
  # Debug: show what we're working with
  if [[ "$DEBUG" == "1" ]]; then
    echo "=== DEBUG: RSS file content preview ===" >&2
    head -20 "$TEMP_FILE" >&2
    echo "=== END DEBUG ===" >&2
  fi

  if command -v xmllint >/dev/null 2>&1; then
    # Use xmllint to extract items properly
    xmllint --xpath "//item[position()<=5]" "$TEMP_FILE" 2>/dev/null |
      sed 's|<item>|\n<item>|g' |
      sed 's|</item>|</item>\n|g' |
      grep -A 20 '<item>' |
      awk -v RS='</item>' '
        /<item>/ {
            title = ""; link = ""; pubdate = ""
            
            # Extract title
            if (match($0, /<title[^>]*>([^<]*)<\/title>/, arr)) {
                title = arr[1]
                gsub(/&gt;/, ">", title)
                gsub(/&lt;/, "<", title)
                gsub(/&amp;/, "&", title)
            }
            
            # Extract link (not atom:link)
            if (match($0, /<link>([^<]*)<\/link>/, arr)) {
                link = arr[1]
            }
            
            # Extract pubDate
            if (match($0, /<pubDate>([^<]*)<\/pubDate>/, arr)) {
                pubdate = arr[1]
            }
            
            if (title && link && pubdate) {
                print pubdate "|" title "|" link
            }
        }'
  else
    # Fallback: simple grep approach
    local temp_items="/tmp/arch-items-$"

    # Extract each item block
    awk '/<item>/,/<\/item>/' "$TEMP_FILE" >"$temp_items"

    # Process with simple pattern matching
    while IFS= read -r line; do
      if [[ "$line" =~ \<title\>([^<]*)\</title\> ]]; then
        title="${BASH_REMATCH[1]}"
        title="${title//&gt;/>}"
        title="${title//&lt;/<}"
        title="${title//&amp;/&}"
      elif [[ "$line" =~ \<link\>([^<]*)\</link\> ]] && [[ ! "$line" =~ atom:link ]]; then
        link="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ \<pubDate\>([^<]*)\</pubDate\> ]]; then
        pubdate="${BASH_REMATCH[1]}"

        # When we have all three, output and reset
        if [[ -n "$title" && -n "$link" && -n "$pubdate" ]]; then
          echo "$pubdate|$title|$link"
          title=""
          link=""
          pubdate=""
        fi
      fi
    done <"$temp_items"

    rm -f "$temp_items"
  fi
}

# Function to send notification
send_notification() {
  local title="$1"
  local body="$2"
  local url="$3"

  # Determine urgency level based on content
  local urgency="normal"
  local icon=$ICON_NORMAL

  # Check for urgent intervention keywords (case insensitive)
  if echo "$title $body" | grep -qi "\(manual intervention\|action required\|breaking change\|immediate action\|urgent\|critical\|important.*update\|requires.*intervention\)"; then
    urgency="critical"
    icon=$ICON_URGENT
  fi

  # Send notification with appropriate urgency
  notify-send \
    --urgency="$urgency" \
    --app-name="Arch News" \
    --icon="$icon" \
    --expire-time=20000 \
    "$title" \
    "$body\n$url"

  # Debug output
  if [[ "$DEBUG" == "1" ]]; then
    echo "=== DEBUG: Notification sent ===" >&2
    echo "Title: $title" >&2
    echo "Urgency: $urgency" >&2
    echo "Reason: $(echo "$title $body" | grep -i "\(manual intervention\|action required\|breaking change\|immediate action\|urgent\|critical\|important.*update\|requires.*intervention\)" || echo "normal news")" >&2
    echo "=== END DEBUG ===" >&2
  fi
}

# Main execution
main() {
  # Parse command line options
  local force_show=false
  local show_latest=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    --force)
      force_show=true
      shift
      ;;
    --show-latest)
      show_latest=true
      shift
      ;;
    --clear-cache)
      rm -f "$CACHE_FILE"
      echo "Cache cleared"
      exit 0
      ;;
    --help | -h)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --force       Show notifications for latest news even if already seen"
      echo "  --show-latest Show notification for the latest news item only"
      echo "  --clear-cache Clear the seen items cache"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  # Check if required tools are available
  if ! command -v xmllint >/dev/null 2>&1; then
    echo "Error: xmllint is required (install libxml2-utils)" >&2
    exit 1
  fi

  if ! command -v notify-send >/dev/null 2>&1; then
    echo "Error: notify-send is required" >&2
    exit 1
  fi

  # Fetch RSS feed
  if ! curl -s --max-time 30 "$RSS_URL" >"$TEMP_FILE"; then
    echo "Error: Failed to fetch RSS feed" >&2
    exit 1
  fi

  # Debug: Check if file was created and has content
  if [[ "$DEBUG" == "1" ]]; then
    echo "=== DEBUG: Temp file info ===" >&2
    ls -la "$TEMP_FILE" >&2
    echo "First few lines:" >&2
    head -5 "$TEMP_FILE" >&2
    echo "=== END DEBUG ===" >&2
  fi

  # Check if file is not empty
  if [[ ! -s "$TEMP_FILE" ]]; then
    echo "Error: RSS feed is empty" >&2
    exit 1
  fi

  # Create cache file if it doesn't exist
  [[ ! -f "$CACHE_FILE" ]] && touch "$CACHE_FILE"

  # Parse RSS and check for new items
  local new_items=0
  local items_processed=0

  # Debug: show all parsed items
  if [[ "$DEBUG" == "1" ]]; then
    echo "=== DEBUG: All parsed RSS items ===" >&2
    parse_rss | nl >&2
    echo "=== END DEBUG ===" >&2
  fi

  while IFS='|' read -r pubdate title link; do
    [[ -z "$title" ]] && continue
    ((items_processed++))

    # Create a unique identifier for this news item
    local item_id=$(echo "$title$pubdate" | md5sum | cut -d' ' -f1)

    # Show latest item only if requested
    if [[ "$show_latest" == true && $items_processed -eq 1 ]]; then
      local formatted_date=$(date -d "$pubdate" "+%d.%m.%Y" 2>/dev/null || echo "Recent")
      send_notification "$title" "Published: $formatted_date" "$link"
      echo "$item_id" >>"$CACHE_FILE"
      ((new_items++))
      break
    fi

    # Check if we've already seen this item (or force showing)
    if [[ "$force_show" == true ]] || ! grep -q "$item_id" "$CACHE_FILE"; then
      # New item found - send notification
      local formatted_date=$(date -d "$pubdate" "+%d.%m.%Y" 2>/dev/null || echo "Recent")
      send_notification "$title" "Published: $formatted_date" "$link"

      # Mark as seen (only if not forcing)
      if [[ "$force_show" == false ]]; then
        echo "$item_id" >>"$CACHE_FILE"
      fi
      ((new_items++))

      # Add delay between notifications for better mako stacking
      [[ $new_items -gt 1 ]] && sleep 1.5
    fi
  done < <(parse_rss)

  # Clean up
  rm -f "$TEMP_FILE"

  # Limit cache file size (keep last 100 entries)
  if [[ -f "$CACHE_FILE" ]]; then
    tail -100 "$CACHE_FILE" >"$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
  fi

  echo "Checked Arch Linux news - $new_items new items found"
}

# Run main function
main "$@"
