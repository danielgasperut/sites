#!/bin/bash

show_help() {
  cat <<EOF
Usage: $0 [options]

This script interactively creates or updates a podcast RSS feed file.

Options:
  -h, --help         Show this help message and exit
  --prompt-all       Prompt for all optional podcast and episode fields
  --feed-file FILE   Set the RSS feed file name (overrides env FEED_FILE)
  --name NAME        Set podcast name (overrides env PODCAST_NAME)
  --desc DESC        Set podcast description (overrides env PODCAST_DESC)
  --link LINK        Set podcast link (overrides env PODCAST_LINK)
  --language LANG    Set podcast language (overrides env PODCAST_LANGUAGE)
  --copyright TEXT   Set copyright (overrides env PODCAST_COPYRIGHT)
  --itunes-author AUTHOR         Set iTunes author (overrides env PODCAST_ITUNES_AUTHOR)
  --itunes-summary SUMMARY       Set iTunes summary (overrides env PODCAST_ITUNES_SUMMARY)
  --itunes-explicit yes|no       Set iTunes explicit (overrides env PODCAST_ITUNES_EXPLICIT)
  --itunes-category CATEGORY     Set iTunes category (overrides env PODCAST_ITUNES_CATEGORY)
  --itunes-image URL             Set iTunes image URL (overrides env PODCAST_ITUNES_IMAGE)
  --itunes-owner-name NAME       Set iTunes owner name (overrides env PODCAST_ITUNES_OWNER_NAME)
  --itunes-owner-email EMAIL     Set iTunes owner email (overrides env PODCAST_ITUNES_OWNER_EMAIL)
  --itunes-type TYPE             Set iTunes type (episodic/serial) (overrides env PODCAST_ITUNES_TYPE)
  --ep-title TITLE               Set episode title
  --ep-desc DESC                 Set episode description
  --ep-url URL                   Set episode audio URL
  --ep-date DATE                 Set episode publication date (YYYY-MM-DD or leave blank for today)
  --ep-itunes-author AUTHOR      Set episode iTunes author (overrides env EP_ITUNES_AUTHOR)
  --ep-itunes-summary SUMMARY    Set episode iTunes summary (overrides env EP_ITUNES_SUMMARY)
  --ep-itunes-explicit yes|no    Set episode iTunes explicit (overrides env EP_ITUNES_EXPLICIT)
  --ep-itunes-duration DURATION  Set episode iTunes duration (overrides env EP_ITUNES_DURATION)
  --ep-itunes-image URL          Set episode iTunes image URL (overrides env EP_ITUNES_IMAGE)
  --ep-itunes-episode NUM        Set episode number (overrides env EP_ITUNES_EPISODE)
  --ep-itunes-season NUM         Set season number (overrides env EP_ITUNES_SEASON)
  --ep-itunes-episodetype TYPE   Set episode type (full/trailer/bonus) (overrides env EP_ITUNES_EPISODETYPE)
  --strict              Require confirmation to update an existing episode

You can also set these as environment variables (see option names above).

When run without options, the script will prompt you for:
  - Podcast name
  - Podcast description
  - Podcast link
  - Episode title
  - Episode description
  - Episode audio URL
  - Episode publication date (YYYY-MM-DD or leave blank for today)
  If --prompt-all is set, you will also be prompted for all optional podcast and episode fields.

The script will create the specified feed file if it does not exist, or append a new episode if it does.

Examples:
  # Create a new podcast feed with one episode
  $0 --feed-file mypodcast.xml --name "My Podcast" --desc "A show about tech" --link "https://mypodcast.com" \
     --language en-us --itunes-author "Jane Doe" --itunes-summary "A tech show" --itunes-explicit no \
     --itunes-category "Technology" --itunes-image "https://mypodcast.com/cover.jpg" \
     --itunes-owner-name "Jane Doe" --itunes-owner-email "jane@example.com" --itunes-type episodic \
     --ep-title "Episode 1" --ep-desc "The first episode" --ep-url "https://mypodcast.com/ep1.mp3" \
     --ep-date 2024-07-01 --ep-itunes-author "Jane Doe" --ep-itunes-summary "All about tech" \
     --ep-itunes-explicit no --ep-itunes-duration "00:42:00" --ep-itunes-image "https://mypodcast.com/ep1.jpg" \
     --ep-itunes-episode 1 --ep-itunes-season 1 --ep-itunes-episodetype full

  # Add a new episode to the same feed
  $0 --feed-file mypodcast.xml \
     --ep-title "Episode 2" --ep-desc "The second episode" --ep-url "https://mypodcast.com/ep2.mp3" \
     --ep-date 2024-07-08 --ep-itunes-author "Jane Doe" --ep-itunes-summary "More tech" \
     --ep-itunes-explicit no --ep-itunes-duration "00:38:00" --ep-itunes-image "https://mypodcast.com/ep2.jpg" \
     --ep-itunes-episode 2 --ep-itunes-season 1 --ep-itunes-episodetype full

  # Edit an existing episode (by title)
  $0 --feed-file mypodcast.xml \
     --ep-title "Episode 1" --ep-desc "UPDATED: The first episode, now with more info" \
     --ep-url "https://mypodcast.com/ep1-v2.mp3" --ep-date 2024-07-01 \
     --ep-itunes-author "Jane Doe" --ep-itunes-summary "Updated tech talk" \
     --ep-itunes-explicit no --ep-itunes-duration "00:45:00" --ep-itunes-image "https://mypodcast.com/ep1-v2.jpg" \
     --ep-itunes-episode 1 --ep-itunes-season 1 --ep-itunes-episodetype full
EOF
}

# Add this function near the top of the script
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\' /&apos;}"
  printf '%s' "$s"
}

# Feed file: CLI > ENV > default
FEED_FILE_DEFAULT="feed.xml"
FEED_FILE_ENV="${FEED_FILE:-}"
FEED_FILE_OPT=""

# Defaults from environment variables for podcast-level fields
PODCAST_NAME_ENV="$PODCAST_NAME"
PODCAST_DESC_ENV="$PODCAST_DESC"
PODCAST_LINK_ENV="$PODCAST_LINK"
PODCAST_LANGUAGE_ENV="$PODCAST_LANGUAGE"
PODCAST_COPYRIGHT_ENV="$PODCAST_COPYRIGHT"
PODCAST_ITUNES_AUTHOR_ENV="$PODCAST_ITUNES_AUTHOR"
PODCAST_ITUNES_SUMMARY_ENV="$PODCAST_ITUNES_SUMMARY"
PODCAST_ITUNES_EXPLICIT_ENV="$PODCAST_ITUNES_EXPLICIT"
PODCAST_ITUNES_CATEGORY_ENV="$PODCAST_ITUNES_CATEGORY"
PODCAST_ITUNES_IMAGE_ENV="$PODCAST_ITUNES_IMAGE"
PODCAST_ITUNES_OWNER_NAME_ENV="$PODCAST_ITUNES_OWNER_NAME"
PODCAST_ITUNES_OWNER_EMAIL_ENV="$PODCAST_ITUNES_OWNER_EMAIL"
PODCAST_ITUNES_TYPE_ENV="$PODCAST_ITUNES_TYPE"

# Defaults from environment variables for episode-level fields
EP_ITUNES_AUTHOR_ENV="$EP_ITUNES_AUTHOR"
EP_ITUNES_SUMMARY_ENV="$EP_ITUNES_SUMMARY"
EP_ITUNES_EXPLICIT_ENV="$EP_ITUNES_EXPLICIT"
EP_ITUNES_DURATION_ENV="$EP_ITUNES_DURATION"
EP_ITUNES_IMAGE_ENV="$EP_ITUNES_IMAGE"
EP_ITUNES_EPISODE_ENV="$EP_ITUNES_EPISODE"
EP_ITUNES_SEASON_ENV="$EP_ITUNES_SEASON"
EP_ITUNES_EPISODETYPE_ENV="$EP_ITUNES_EPISODETYPE"

PROMPT_ALL=0
# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt-all) PROMPT_ALL=1; shift;;
    --feed-file) FEED_FILE_OPT="$2"; shift 2;;
    --name) PODCAST_NAME_OPT="$2"; shift 2;;
    --desc) PODCAST_DESC_OPT="$2"; shift 2;;
    --link) PODCAST_LINK_OPT="$2"; shift 2;;
    --language) PODCAST_LANGUAGE_OPT="$2"; shift 2;;
    --copyright) PODCAST_COPYRIGHT_OPT="$2"; shift 2;;
    --itunes-author) PODCAST_ITUNES_AUTHOR_OPT="$2"; shift 2;;
    --itunes-summary) PODCAST_ITUNES_SUMMARY_OPT="$2"; shift 2;;
    --itunes-explicit) PODCAST_ITUNES_EXPLICIT_OPT="$2"; shift 2;;
    --itunes-category) PODCAST_ITUNES_CATEGORY_OPT="$2"; shift 2;;
    --itunes-image) PODCAST_ITUNES_IMAGE_OPT="$2"; shift 2;;
    --itunes-owner-name) PODCAST_ITUNES_OWNER_NAME_OPT="$2"; shift 2;;
    --itunes-owner-email) PODCAST_ITUNES_OWNER_EMAIL_OPT="$2"; shift 2;;
    --itunes-type) PODCAST_ITUNES_TYPE_OPT="$2"; shift 2;;
    --ep-title) EP_TITLE_OPT="$2"; shift 2;;
    --ep-desc) EP_DESC_OPT="$2"; shift 2;;
    --ep-url) EP_URL_OPT="$2"; shift 2;;
    --ep-date) EP_DATE_OPT="$2"; shift 2;;
    --ep-itunes-author) EP_ITUNES_AUTHOR_OPT="$2"; shift 2;;
    --ep-itunes-summary) EP_ITUNES_SUMMARY_OPT="$2"; shift 2;;
    --ep-itunes-explicit) EP_ITUNES_EXPLICIT_OPT="$2"; shift 2;;
    --ep-itunes-duration) EP_ITUNES_DURATION_OPT="$2"; shift 2;;
    --ep-itunes-image) EP_ITUNES_IMAGE_OPT="$2"; shift 2;;
    --ep-itunes-episode) EP_ITUNES_EPISODE_OPT="$2"; shift 2;;
    --ep-itunes-season) EP_ITUNES_SEASON_OPT="$2"; shift 2;;
    --ep-itunes-episodetype) EP_ITUNES_EPISODETYPE_OPT="$2"; shift 2;;
    --strict) STRICT=1; shift;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown option: $1"; show_help; exit 1;;
  esac
done

# Set FEED_FILE with correct precedence
if [ -n "$FEED_FILE_OPT" ]; then
  FEED_FILE="$FEED_FILE_OPT"
elif [ -n "$FEED_FILE_ENV" ]; then
  FEED_FILE="$FEED_FILE_ENV"
else
  FEED_FILE="$FEED_FILE_DEFAULT"
fi

# Prompt for podcast info if feed does not exist
echo "--- Podcast RSS Feed Generator ---"
if [ ! -f "$FEED_FILE" ]; then
  echo "No existing feed found. Let's create a new one."
  PODCAST_NAME="${PODCAST_NAME_OPT:-${PODCAST_NAME_ENV}}"
  PODCAST_DESC="${PODCAST_DESC_OPT:-${PODCAST_DESC_ENV}}"
  PODCAST_LINK="${PODCAST_LINK_OPT:-${PODCAST_LINK_ENV}}"
  PODCAST_LANGUAGE="${PODCAST_LANGUAGE_OPT:-${PODCAST_LANGUAGE_ENV}}"
  PODCAST_COPYRIGHT="${PODCAST_COPYRIGHT_OPT:-${PODCAST_COPYRIGHT_ENV}}"
  PODCAST_ITUNES_AUTHOR="${PODCAST_ITUNES_AUTHOR_OPT:-${PODCAST_ITUNES_AUTHOR_ENV}}"
  PODCAST_ITUNES_SUMMARY="${PODCAST_ITUNES_SUMMARY_OPT:-${PODCAST_ITUNES_SUMMARY_ENV}}"
  PODCAST_ITUNES_EXPLICIT="${PODCAST_ITUNES_EXPLICIT_OPT:-${PODCAST_ITUNES_EXPLICIT_ENV}}"
  PODCAST_ITUNES_CATEGORY="${PODCAST_ITUNES_CATEGORY_OPT:-${PODCAST_ITUNES_CATEGORY_ENV}}"
  PODCAST_ITUNES_IMAGE="${PODCAST_ITUNES_IMAGE_OPT:-${PODCAST_ITUNES_IMAGE_ENV}}"
  PODCAST_ITUNES_OWNER_NAME="${PODCAST_ITUNES_OWNER_NAME_OPT:-${PODCAST_ITUNES_OWNER_NAME_ENV}}"
  PODCAST_ITUNES_OWNER_EMAIL="${PODCAST_ITUNES_OWNER_EMAIL_OPT:-${PODCAST_ITUNES_OWNER_EMAIL_ENV}}"
  PODCAST_ITUNES_TYPE="${PODCAST_ITUNES_TYPE_OPT:-${PODCAST_ITUNES_TYPE_ENV}}"
  [ -z "$PODCAST_NAME" ] && [ -t 0 ] && read -p "Podcast Name: " PODCAST_NAME
  [ -z "$PODCAST_DESC" ] && [ -t 0 ] && read -p "Podcast Description: " PODCAST_DESC
  [ -z "$PODCAST_LINK" ] && [ -t 0 ] && read -p "Podcast Link (e.g. https://example.com): " PODCAST_LINK
  if [ "$PROMPT_ALL" -eq 1 ]; then
    [ -z "$PODCAST_LANGUAGE" ] && [ -t 0 ] && read -p "Podcast Language (e.g. en-us): " PODCAST_LANGUAGE
    [ -z "$PODCAST_COPYRIGHT" ] && [ -t 0 ] && read -p "Podcast Copyright: " PODCAST_COPYRIGHT
    [ -z "$PODCAST_ITUNES_AUTHOR" ] && [ -t 0 ] && read -p "Podcast iTunes Author: " PODCAST_ITUNES_AUTHOR
    [ -z "$PODCAST_ITUNES_SUMMARY" ] && [ -t 0 ] && read -p "Podcast iTunes Summary: " PODCAST_ITUNES_SUMMARY
    [ -z "$PODCAST_ITUNES_EXPLICIT" ] && [ -t 0 ] && read -p "Podcast iTunes Explicit (yes/no): " PODCAST_ITUNES_EXPLICIT
    [ -z "$PODCAST_ITUNES_CATEGORY" ] && [ -t 0 ] && read -p "Podcast iTunes Category: " PODCAST_ITUNES_CATEGORY
    [ -z "$PODCAST_ITUNES_IMAGE" ] && [ -t 0 ] && read -p "Podcast iTunes Image URL: " PODCAST_ITUNES_IMAGE
    [ -z "$PODCAST_ITUNES_OWNER_NAME" ] && [ -t 0 ] && read -p "Podcast iTunes Owner Name: " PODCAST_ITUNES_OWNER_NAME
    [ -z "$PODCAST_ITUNES_OWNER_EMAIL" ] && [ -t 0 ] && read -p "Podcast iTunes Owner Email: " PODCAST_ITUNES_OWNER_EMAIL
    [ -z "$PODCAST_ITUNES_TYPE" ] && [ -t 0 ] && read -p "Podcast iTunes Type (episodic/serial): " PODCAST_ITUNES_TYPE
  fi
  # Only require podcast fields when creating a new feed
  REQUIRED_MISSING=0
  if [ -z "$PODCAST_NAME" ]; then
    echo "Error: Podcast name is required." >&2
    REQUIRED_MISSING=1
  fi
  if [ -z "$PODCAST_DESC" ]; then
    echo "Error: Podcast description is required." >&2
    REQUIRED_MISSING=1
  fi
  if [ -z "$PODCAST_LINK" ]; then
    echo "Error: Podcast link is required." >&2
    REQUIRED_MISSING=1
  fi
  if [ "$REQUIRED_MISSING" -eq 1 ]; then
    show_help
    exit 1
  fi
else
  # Extract podcast info from existing feed
  PODCAST_NAME=$(grep -m1 '<title>' "$FEED_FILE" | sed 's/.*<title>\(.*\)<\/title>.*/\1/')
  PODCAST_DESC=$(grep -m1 '<description>' "$FEED_FILE" | sed 's/.*<description>'"\(.*\)"'<\/description>.*/\1/')
  PODCAST_LINK=$(grep -m1 '<link>' "$FEED_FILE" | sed 's/.*<link>\(.*\)<\/link>.*/\1/')
  echo "Existing feed found: $PODCAST_NAME"
fi

# Assign all podcast and episode fields with CLI > ENV > ENV_FALLBACK precedence
PODCAST_LINK="${PODCAST_LINK_OPT:-${PODCAST_LINK_ENV}}"
EP_URL="${EP_URL_OPT:-${EP_URL:-${EP_URL_ENV}}}"
PODCAST_LANGUAGE="${PODCAST_LANGUAGE_OPT:-${PODCAST_LANGUAGE_ENV}}"
PODCAST_COPYRIGHT="${PODCAST_COPYRIGHT_OPT:-${PODCAST_COPYRIGHT_ENV}}"
PODCAST_ITUNES_AUTHOR="${PODCAST_ITUNES_AUTHOR_OPT:-${PODCAST_ITUNES_AUTHOR_ENV}}"
PODCAST_ITUNES_SUMMARY="${PODCAST_ITUNES_SUMMARY_OPT:-${PODCAST_ITUNES_SUMMARY_ENV}}"
PODCAST_ITUNES_EXPLICIT="${PODCAST_ITUNES_EXPLICIT_OPT:-${PODCAST_ITUNES_EXPLICIT_ENV}}"
PODCAST_ITUNES_CATEGORY="${PODCAST_ITUNES_CATEGORY_OPT:-${PODCAST_ITUNES_CATEGORY_ENV}}"
PODCAST_ITUNES_IMAGE="${PODCAST_ITUNES_IMAGE_OPT:-${PODCAST_ITUNES_IMAGE_ENV}}"
PODCAST_ITUNES_OWNER_NAME="${PODCAST_ITUNES_OWNER_NAME_OPT:-${PODCAST_ITUNES_OWNER_NAME_ENV}}"
PODCAST_ITUNES_OWNER_EMAIL="${PODCAST_ITUNES_OWNER_EMAIL_OPT:-${PODCAST_ITUNES_OWNER_EMAIL_ENV}}"
PODCAST_ITUNES_TYPE="${PODCAST_ITUNES_TYPE_OPT:-${PODCAST_ITUNES_TYPE_ENV}}"
EP_TITLE="${EP_TITLE_OPT:-${EP_TITLE:-${EP_TITLE_ENV}}}"
EP_DESC="${EP_DESC_OPT:-${EP_DESC:-${EP_DESC_ENV}}}"
EP_DATE="${EP_DATE_OPT:-${EP_DATE:-${EP_DATE_ENV}}}"
EP_ITUNES_AUTHOR="${EP_ITUNES_AUTHOR_OPT:-${EP_ITUNES_AUTHOR:-${EP_ITUNES_AUTHOR_ENV}}}"
EP_ITUNES_SUMMARY="${EP_ITUNES_SUMMARY_OPT:-${EP_ITUNES_SUMMARY:-${EP_ITUNES_SUMMARY_ENV}}}"
EP_ITUNES_EXPLICIT="${EP_ITUNES_EXPLICIT_OPT:-${EP_ITUNES_EXPLICIT:-${EP_ITUNES_EXPLICIT_ENV}}}"
EP_ITUNES_DURATION="${EP_ITUNES_DURATION_OPT:-${EP_ITUNES_DURATION:-${EP_ITUNES_DURATION_ENV}}}"
EP_ITUNES_IMAGE="${EP_ITUNES_IMAGE_OPT:-${EP_ITUNES_IMAGE:-${EP_ITUNES_IMAGE_ENV}}}"
EP_ITUNES_EPISODE="${EP_ITUNES_EPISODE_OPT:-${EP_ITUNES_EPISODE:-${EP_ITUNES_EPISODE_ENV}}}"
EP_ITUNES_SEASON="${EP_ITUNES_SEASON_OPT:-${EP_ITUNES_SEASON:-${EP_ITUNES_SEASON_ENV}}}"
EP_ITUNES_EPISODETYPE="${EP_ITUNES_EPISODETYPE_OPT:-${EP_ITUNES_EPISODETYPE:-${EP_ITUNES_EPISODETYPE_ENV}}}"

# Prompt for episode info if not provided
[ -z "$EP_TITLE" ] && [ -t 0 ] && read -p "Episode Title: " EP_TITLE
[ -z "$EP_DESC" ] && [ -t 0 ] && read -p "Episode Description: " EP_DESC
[ -z "$EP_URL" ] && [ -t 0 ] && read -p "Episode Audio URL: " EP_URL
[ -z "$EP_DATE" ] && [ -t 0 ] && read -p "Episode Publication Date (YYYY-MM-DD or leave blank for today): " EP_DATE
if [ "$PROMPT_ALL" -eq 1 ]; then
  [ -z "$EP_ITUNES_AUTHOR" ] && [ -t 0 ] && read -p "Episode iTunes Author: " EP_ITUNES_AUTHOR
  [ -z "$EP_ITUNES_SUMMARY" ] && [ -t 0 ] && read -p "Episode iTunes Summary: " EP_ITUNES_SUMMARY
  [ -z "$EP_ITUNES_EXPLICIT" ] && [ -t 0 ] && read -p "Episode iTunes Explicit (yes/no): " EP_ITUNES_EXPLICIT
  [ -z "$EP_ITUNES_DURATION" ] && [ -t 0 ] && read -p "Episode iTunes Duration: " EP_ITUNES_DURATION
  [ -z "$EP_ITUNES_IMAGE" ] && [ -t 0 ] && read -p "Episode iTunes Image URL: " EP_ITUNES_IMAGE
  [ -z "$EP_ITUNES_EPISODE" ] && [ -t 0 ] && read -p "Episode Number: " EP_ITUNES_EPISODE
  [ -z "$EP_ITUNES_SEASON" ] && [ -t 0 ] && read -p "Season Number: " EP_ITUNES_SEASON
  [ -z "$EP_ITUNES_EPISODETYPE" ] && [ -t 0 ] && read -p "Episode Type (full/trailer/bonus): " EP_ITUNES_EPISODETYPE
fi

# Normalize Dropbox URLs to use dl=1 if present (after all assignments)
if [[ "$PODCAST_LINK" == *dropbox.com* && "$PODCAST_LINK" == *dl=0* ]]; then
  PODCAST_LINK="${PODCAST_LINK/dl=0/dl=1}"
fi
if [[ "$EP_URL" == *dropbox.com* && "$EP_URL" == *dl=0* ]]; then
  EP_URL="${EP_URL/dl=0/dl=1}"
fi

# Only escape podcast link and episode URL fields before writing to XML
PODCAST_LINK_ESCAPED="$(xml_escape "$PODCAST_LINK")"
EP_URL_ESCAPED="$(xml_escape "$EP_URL")"

# Generate episode item (conditionally include optional fields)
EP_GUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s)
EP_ITEM="  <item>
    <title>${EP_TITLE}</title>
    <description>${EP_DESC}</description>
    <enclosure url=\"${EP_URL_ESCAPED}\" type=\"audio/mpeg\"/>
    <guid>${EP_GUID}</guid>
    <pubDate>${EP_DATE}</pubDate>"
[ -n "$EP_ITUNES_AUTHOR" ] && EP_ITEM="${EP_ITEM}
    <itunes:author>${EP_ITUNES_AUTHOR}</itunes:author>"
[ -n "$EP_ITUNES_SUMMARY" ] && EP_ITEM="${EP_ITEM}
    <itunes:summary>${EP_ITUNES_SUMMARY}</itunes:summary>"
[ -n "$EP_ITUNES_EXPLICIT" ] && EP_ITEM="${EP_ITEM}
    <itunes:explicit>${EP_ITUNES_EXPLICIT}</itunes:explicit>"
[ -n "$EP_ITUNES_DURATION" ] && EP_ITEM="${EP_ITEM}
    <itunes:duration>${EP_ITUNES_DURATION}</itunes:duration>"
[ -n "$EP_ITUNES_IMAGE" ] && EP_ITEM="${EP_ITEM}
    <itunes:image href=\"${EP_ITUNES_IMAGE}\" />"
[ -n "$EP_ITUNES_EPISODE" ] && EP_ITEM="${EP_ITEM}
    <itunes:episode>${EP_ITUNES_EPISODE}</itunes:episode>"
[ -n "$EP_ITUNES_SEASON" ] && EP_ITEM="${EP_ITEM}
    <itunes:season>${EP_ITUNES_SEASON}</itunes:season>"
[ -n "$EP_ITUNES_EPISODETYPE" ] && EP_ITEM="${EP_ITEM}
    <itunes:episodeType>${EP_ITUNES_EPISODETYPE}</itunes:episodeType>"
EP_ITEM="${EP_ITEM}
  </item>"

# Function to update the first matching episode in-place
update_episode() {
  local file="$1"
  local title="$2"
  local new_item="$3"
  local tmpfile=$(mktemp)
  local item_start item_end
  # Find the line numbers for the first matching episode
  item_start=$(grep -n '<item>' "$file" | cut -d: -f1)
  item_end=$(grep -n '</item>' "$file" | cut -d: -f1)
  match_start=0
  match_end=0
  while read -r s && read -r e <&3; do
    # Check if this <item> block contains the title
    if sed -n "${s},${e}p" "$file" | grep -q "<title>${title}</title>"; then
      match_start=$s
      match_end=$e
      break
    fi
  done < <(echo "$item_start") 3< <(echo "$item_end")
  if [ "$match_start" -ne 0 ] && [ "$match_end" -ne 0 ]; then
    # Use ed to replace the block
    ed -s "$file" <<END_ED
${match_start},${match_end}c
$new_item
.
w
q
END_ED
  fi
}

# Default STRICT to 0 if not set
STRICT=${STRICT:-0}

# If feed does not exist, create it (conditionally include optional fields)
if [ ! -f "$FEED_FILE" ]; then
  cat > "$FEED_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
<channel>
  <title>${PODCAST_NAME}</title>
  <link>${PODCAST_LINK_ESCAPED}</link>
  <description>${PODCAST_DESC}</description>
EOF
  [ -n "$PODCAST_LANGUAGE" ] && echo "  <language>${PODCAST_LANGUAGE}</language>" >> "$FEED_FILE"
  [ -n "$PODCAST_COPYRIGHT" ] && echo "  <copyright>${PODCAST_COPYRIGHT}</copyright>" >> "$FEED_FILE"
  [ -n "$PODCAST_ITUNES_AUTHOR" ] && echo "  <itunes:author>${PODCAST_ITUNES_AUTHOR}</itunes:author>" >> "$FEED_FILE"
  [ -n "$PODCAST_ITUNES_SUMMARY" ] && echo "  <itunes:summary>${PODCAST_ITUNES_SUMMARY}</itunes:summary>" >> "$FEED_FILE"
  [ -n "$PODCAST_ITUNES_EXPLICIT" ] && echo "  <itunes:explicit>${PODCAST_ITUNES_EXPLICIT}</itunes:explicit>" >> "$FEED_FILE"
  [ -n "$PODCAST_ITUNES_CATEGORY" ] && echo "  <itunes:category text=\"${PODCAST_ITUNES_CATEGORY}\"/>" >> "$FEED_FILE"
  [ -n "$PODCAST_ITUNES_IMAGE" ] && echo "  <itunes:image href=\"${PODCAST_ITUNES_IMAGE}\" />" >> "$FEED_FILE"
  if [ -n "$PODCAST_ITUNES_OWNER_NAME" ] || [ -n "$PODCAST_ITUNES_OWNER_EMAIL" ]; then
    echo "  <itunes:owner>" >> "$FEED_FILE"
    [ -n "$PODCAST_ITUNES_OWNER_NAME" ] && echo "    <itunes:name>${PODCAST_ITUNES_OWNER_NAME}</itunes:name>" >> "$FEED_FILE"
    [ -n "$PODCAST_ITUNES_OWNER_EMAIL" ] && echo "    <itunes:email>${PODCAST_ITUNES_OWNER_EMAIL}</itunes:email>" >> "$FEED_FILE"
    echo "  </itunes:owner>" >> "$FEED_FILE"
  fi
  [ -n "$PODCAST_ITUNES_TYPE" ] && echo "  <itunes:type>${PODCAST_ITUNES_TYPE}</itunes:type>" >> "$FEED_FILE"
  printf "%b\n" "$EP_ITEM" >> "$FEED_FILE"
  echo "</channel>" >> "$FEED_FILE"
  echo "</rss>" >> "$FEED_FILE"
  echo "Feed created and episode added to $FEED_FILE."
else
  # Check for existing episode with the same title
  if grep -q "<title>${EP_TITLE}</title>" "$FEED_FILE"; then
    echo "An episode with this title already exists."
    if [ "$STRICT" = "1" ]; then
      read -p "Do you want to edit the existing episode? (y/n): " EDIT_CONFIRM
      if [[ "$EDIT_CONFIRM" =~ ^[Yy]$ ]]; then
        update_episode "$FEED_FILE" "$EP_TITLE" "$EP_ITEM"
        echo "Episode updated in $FEED_FILE."
      else
        echo "No changes made. Duplicate episodes are not allowed."
        exit 0
      fi
    else
      update_episode "$FEED_FILE" "$EP_TITLE" "$EP_ITEM"
      echo "Episode updated in $FEED_FILE."
    fi
  else
    # Insert new item before </channel> using ed for portability
    TMP_FILE=$(mktemp)
    cp "$FEED_FILE" "$TMP_FILE"
    # Find the line number of </channel>
    LINE=$(grep -n '</channel>' "$TMP_FILE" | cut -d: -f1 | head -n1)
    if [ -n "$LINE" ]; then
      ed -s "$TMP_FILE" <<END_ED
${LINE}i
$EP_ITEM
.
w
q
END_ED
      mv "$TMP_FILE" "$FEED_FILE"
      echo "Episode added to $FEED_FILE."
    else
      echo "Error: </channel> tag not found in $FEED_FILE."
      rm -f "$TMP_FILE"
      exit 1
    fi
  fi
fi 