#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

YAML_FILE="rssgen_input_template.yaml"
DEFAULT_FEED_FILE="test_feed.xml"
LAUNCHER="./rssgen.sh"
VERBOSE=${VERBOSE:-0}

# Remove any old test feed and default feed
rm -f "$DEFAULT_FEED_FILE" feed.xml

FAILED=0

banner() {
  echo -e "\n${BLUE}==============================="
  echo -e "$1"
  echo -e "===============================${NC}"
}

pass() {
  echo -e "${GREEN}PASS:${NC} $1"
}

fail() {
  echo -e "${RED}FAIL:${NC} $1"
  FAILED=1
}

num_entries=$(yq e 'length' "$YAML_FILE")
for ((i=0; i<num_entries; i++)); do
  # Extract fields from the i-th YAML entry using yq
  feed_file=$(yq e ".[${i}].feed_file // \"\"" "$YAML_FILE")
  podcast_name=$(yq e ".[${i}].podcast_name // \"\"" "$YAML_FILE")
  podcast_desc=$(yq e ".[${i}].podcast_desc // \"\"" "$YAML_FILE")
  podcast_link=$(yq e ".[${i}].podcast_link // \"\"" "$YAML_FILE")
  podcast_language=$(yq e ".[${i}].podcast_language // \"\"" "$YAML_FILE")
  podcast_copyright=$(yq e ".[${i}].podcast_copyright // \"\"" "$YAML_FILE")
  podcast_itunes_author=$(yq e ".[${i}].podcast_itunes_author // \"\"" "$YAML_FILE")
  podcast_itunes_summary=$(yq e ".[${i}].podcast_itunes_summary // \"\"" "$YAML_FILE")
  podcast_itunes_explicit=$(yq e ".[${i}].podcast_itunes_explicit // \"\"" "$YAML_FILE")
  podcast_itunes_category=$(yq e ".[${i}].podcast_itunes_category // \"\"" "$YAML_FILE")
  podcast_itunes_image=$(yq e ".[${i}].podcast_itunes_image // \"\"" "$YAML_FILE")
  podcast_itunes_owner_name=$(yq e ".[${i}].podcast_itunes_owner_name // \"\"" "$YAML_FILE")
  podcast_itunes_owner_email=$(yq e ".[${i}].podcast_itunes_owner_email // \"\"" "$YAML_FILE")
  podcast_itunes_type=$(yq e ".[${i}].podcast_itunes_type // \"\"" "$YAML_FILE")
  ep_title=$(yq e ".[${i}].ep_title // \"\"" "$YAML_FILE")
  ep_desc=$(yq e ".[${i}].ep_desc // \"\"" "$YAML_FILE")
  ep_url=$(yq e ".[${i}].ep_url // \"\"" "$YAML_FILE")
  ep_date=$(yq e ".[${i}].ep_date // \"\"" "$YAML_FILE")
  ep_itunes_author=$(yq e ".[${i}].ep_itunes_author // \"\"" "$YAML_FILE")
  ep_itunes_summary=$(yq e ".[${i}].ep_itunes_summary // \"\"" "$YAML_FILE")
  ep_itunes_explicit=$(yq e ".[${i}].ep_itunes_explicit // \"\"" "$YAML_FILE")
  ep_itunes_duration=$(yq e ".[${i}].ep_itunes_duration // \"\"" "$YAML_FILE")
  ep_itunes_image=$(yq e ".[${i}].ep_itunes_image // \"\"" "$YAML_FILE")
  ep_itunes_episode=$(yq e ".[${i}].ep_itunes_episode // \"\"" "$YAML_FILE")
  ep_itunes_season=$(yq e ".[${i}].ep_itunes_season // \"\"" "$YAML_FILE")
  ep_itunes_episodetype=$(yq e ".[${i}].ep_itunes_episodetype // \"\"" "$YAML_FILE")
  strict=$(yq e ".[${i}].strict // \"\"" "$YAML_FILE")

  FEED_FILE="$feed_file"
  banner "[YAML-TEST $((i+1))] $ep_title"

  # Build the command
  CMD=("$LAUNCHER")
  [ -n "$feed_file" ] && CMD+=(--feed-file "$feed_file")
  [ -n "$podcast_name" ] && CMD+=(--name "$podcast_name")
  [ -n "$podcast_desc" ] && CMD+=(--desc "$podcast_desc")
  [ -n "$podcast_link" ] && CMD+=(--link "$podcast_link")
  [ -n "$podcast_language" ] && CMD+=(--language "$podcast_language")
  [ -n "$podcast_copyright" ] && CMD+=(--copyright "$podcast_copyright")
  [ -n "$podcast_itunes_author" ] && CMD+=(--itunes-author "$podcast_itunes_author")
  [ -n "$podcast_itunes_summary" ] && CMD+=(--itunes-summary "$podcast_itunes_summary")
  [ -n "$podcast_itunes_explicit" ] && CMD+=(--itunes-explicit "$podcast_itunes_explicit")
  [ -n "$podcast_itunes_category" ] && CMD+=(--itunes-category "$podcast_itunes_category")
  [ -n "$podcast_itunes_image" ] && CMD+=(--itunes-image "$podcast_itunes_image")
  [ -n "$podcast_itunes_owner_name" ] && CMD+=(--itunes-owner-name "$podcast_itunes_owner_name")
  [ -n "$podcast_itunes_owner_email" ] && CMD+=(--itunes-owner-email "$podcast_itunes_owner_email")
  [ -n "$podcast_itunes_type" ] && CMD+=(--itunes-type "$podcast_itunes_type")
  [ -n "$ep_title" ] && CMD+=(--ep-title "$ep_title")
  [ -n "$ep_desc" ] && CMD+=(--ep-desc "$ep_desc")
  [ -n "$ep_url" ] && CMD+=(--ep-url "$ep_url")
  [ -n "$ep_date" ] && CMD+=(--ep-date "$ep_date")
  [ -n "$ep_itunes_author" ] && CMD+=(--ep-itunes-author "$ep_itunes_author")
  [ -n "$ep_itunes_summary" ] && CMD+=(--ep-itunes-summary "$ep_itunes_summary")
  [ -n "$ep_itunes_explicit" ] && CMD+=(--ep-itunes-explicit "$ep_itunes_explicit")
  [ -n "$ep_itunes_duration" ] && CMD+=(--ep-itunes-duration "$ep_itunes_duration")
  [ -n "$ep_itunes_image" ] && CMD+=(--ep-itunes-image "$ep_itunes_image")
  [ -n "$ep_itunes_episode" ] && CMD+=(--ep-itunes-episode "$ep_itunes_episode")
  [ -n "$ep_itunes_season" ] && CMD+=(--ep-itunes-season "$ep_itunes_season")
  [ -n "$ep_itunes_episodetype" ] && CMD+=(--ep-itunes-episodetype "$ep_itunes_episodetype")
  [ "$strict" = "true" ] && CMD+=(--strict)

  if [ "$VERBOSE" -eq 1 ]; then
    echo -e "${YELLOW}Running: ${CMD[*]}${NC}"
  fi
  "${CMD[@]}"

  if [ -f "$FEED_FILE" ]; then
    pass "Feed file created or updated."
    if [ "$VERBOSE" -eq 1 ]; then
      echo -e "${BLUE}--- Feed file contents ---${NC}"
      cat "$FEED_FILE"
      echo -e "${BLUE}--- End feed file ---${NC}"
    fi
  else
    fail "Feed file not created."
  fi

done

grep -q '<title>My Podcast</title>' "$DEFAULT_FEED_FILE" && grep -q '<title>Episode 1</title>' "$DEFAULT_FEED_FILE" && grep -q '<description>The first episode</description>' "$DEFAULT_FEED_FILE"
if [ $? -eq 0 ]; then
  pass "Feed contains expected podcast and first episode data."
else
  fail "Feed missing expected data for first episode."
fi

# Cleanup
if [ "$VERBOSE" -ne 1 ]; then
  test -f "$DEFAULT_FEED_FILE" && rm "$DEFAULT_FEED_FILE"
fi

if [ "$FAILED" -eq 0 ]; then
  echo -e "\n${GREEN}YAML LAUNCHER ALL TESTS PASSED!${NC}"
else
  echo -e "\n${RED}YAML LAUNCHER SOME TESTS FAILED!${NC}"
  exit 1
fi 