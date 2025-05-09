#!/usr/bin/env bash

CSV_FILE="${CSV_FILE:-rssgen_input_template.csv}"
SCRIPT="./rssgen.sh"

# Read the header to get column names
IFS=',' read -r -a HEADERS < "$CSV_FILE"

# Function to trim whitespace
trim() {
  local var="$1"
  var="${var##*[![:space:]]}"
  var="${var%%*[![:space:]]}"
  echo -n "$var"
}

# Function to get episode XML block by title
get_episode_block() {
  local feed_file="$1"
  local ep_title="$2"
  awk -v title="$ep_title" '/<item>/ {in_item=1; item="<item>"; next} in_item {item=item"\n"$0} /<\/item>/ {item=item"\n</item>"; in_item=0; if(item ~ "<title>"title"</title>") print item}' "$feed_file"
}

# Read each row (skip header)
tail -n +2 "$CSV_FILE" | while IFS=',' read -r -a FIELDS; do
  CMD=("$SCRIPT")
  # Use parallel arrays for keys/values
  row_keys=()
  row_vals=()
  FEED_FILE_VAL=""
  EP_TITLE_VAL=""
  for i in "${!HEADERS[@]}"; do
    key="${HEADERS[$i]}"
    val="${FIELDS[$i]}"
    val="$(trim "$val")"
    row_keys+=("$key")
    row_vals+=("$val")
    [ -z "$val" ] && continue
    flag_name="${key%_optional}"
    case "$flag_name" in
      feed_file) CMD+=(--feed-file "$val"); FEED_FILE_VAL="$val";;
      podcast_name) CMD+=(--name "$val");;
      podcast_desc) CMD+=(--desc "$val");;
      podcast_link) CMD+=(--link "$val");;
      podcast_language) CMD+=(--language "$val");;
      podcast_copyright) CMD+=(--copyright "$val");;
      podcast_itunes_author) CMD+=(--itunes-author "$val");;
      podcast_itunes_summary) CMD+=(--itunes-summary "$val");;
      podcast_itunes_explicit) CMD+=(--itunes-explicit "$val");;
      podcast_itunes_category) CMD+=(--itunes-category "$val");;
      podcast_itunes_image) CMD+=(--itunes-image "$val");;
      podcast_itunes_owner_name) CMD+=(--itunes-owner-name "$val");;
      podcast_itunes_owner_email) CMD+=(--itunes-owner-email "$val");;
      podcast_itunes_type) CMD+=(--itunes-type "$val");;
      ep_title) CMD+=(--ep-title "$val"); EP_TITLE_VAL="$val";;
      ep_desc) CMD+=(--ep-desc "$val");;
      ep_url) CMD+=(--ep-url "$val");;
      ep_date) CMD+=(--ep-date "$val");;
      ep_itunes_author) CMD+=(--ep-itunes-author "$val");;
      ep_itunes_summary) CMD+=(--ep-itunes-summary "$val");;
      ep_itunes_explicit) CMD+=(--ep-itunes-explicit "$val");;
      ep_itunes_duration) CMD+=(--ep-itunes-duration "$val");;
      ep_itunes_image) CMD+=(--ep-itunes-image "$val");;
      ep_itunes_episode) CMD+=(--ep-itunes-episode "$val");;
      ep_itunes_season) CMD+=(--ep-itunes-season "$val");;
      ep_itunes_episodetype) CMD+=(--ep-itunes-episodetype "$val");;
      strict) [ "$val" = "1" ] && CMD+=(--strict);;
    esac
  done

  # If feed file and episode title are set, check for existing episode
  if [ -n "$FEED_FILE_VAL" ] && [ -n "$EP_TITLE_VAL" ] && [ -f "$FEED_FILE_VAL" ]; then
    EP_BLOCK="$(get_episode_block "$FEED_FILE_VAL" "$EP_TITLE_VAL")"
    if [ -n "$EP_BLOCK" ]; then
      MATCHED=1
      # Map CSV keys to XML tags/attributes
      for i in "${!row_keys[@]}"; do
        key="${row_keys[$i]}"
        val="${row_vals[$i]}"
        [ -z "$val" ] && continue
        flag_name="${key%_optional}"
        case "$flag_name" in
          ep_title)
            tag="<title>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_desc)
            tag="<description>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_url)
            tag="enclosure url="
            grep -q "$tag\"$val\"" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_date)
            tag="<pubDate>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_author)
            tag="<itunes:author>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_summary)
            tag="<itunes:summary>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_explicit)
            tag="<itunes:explicit>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_duration)
            tag="<itunes:duration>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_image)
            tag="<itunes:image href="
            grep -q "$tag\"$val\"" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_episode)
            tag="<itunes:episode>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_season)
            tag="<itunes:season>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
          ep_itunes_episodetype)
            tag="<itunes:episodeType>"
            grep -q "$tag$val" <<< "$EP_BLOCK" || MATCHED=0
            ;;
        esac
      done
      if [ "$MATCHED" -eq 1 ]; then
        echo "Skipping: Episode '$EP_TITLE_VAL' in '$FEED_FILE_VAL' is unchanged."
        continue
      fi
    fi
  fi

  echo "Running: ${CMD[*]}"
  "${CMD[@]}"
  echo

done 