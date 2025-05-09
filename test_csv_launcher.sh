#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

YAML_FILE="rssgen_input_template.yaml"
FEED_FILE="test_feed.yaml"
LAUNCHER="./rssgen.sh"
VERBOSE=${VERBOSE:-0}

# Remove any old test feed and default feed
rm -f "$FEED_FILE" feed.xml

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

# 1. Create a new feed with a new episode (first YAML entry)
banner "[YAML-TEST 1] Create a new feed with a new episode"

# Extract fields from the first YAML entry using yq
declare -A entry
for key in feed_file podcast_name podcast_desc podcast_link podcast_language podcast_copyright podcast_itunes_author podcast_itunes_summary podcast_itunes_explicit podcast_itunes_category podcast_itunes_image podcast_itunes_owner_name podcast_itunes_owner_email podcast_itunes_type ep_title ep_desc ep_url ep_date ep_itunes_author ep_itunes_summary ep_itunes_explicit ep_itunes_duration ep_itunes_image ep_itunes_episode ep_itunes_season ep_itunes_episodetype strict; do
  entry[$key]=$(yq e ".[0].$key // \"\"" "$YAML_FILE")
done

# Build the command
CMD=("$LAUNCHER")
for key in "${!entry[@]}"; do
  val="${entry[$key]}"
  [ -z "$val" ] && continue
  case "$key" in
    feed_file) CMD+=(--feed-file "$val"); FEED_FILE="$val";;
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
    ep_title) CMD+=(--ep-title "$val");;
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
    strict) [ "$val" = "true" ] && CMD+=(--strict);;
  esac
done

if [ "$VERBOSE" -eq 1 ]; then
  echo -e "${YELLOW}Running: ${CMD[*]}${NC}"
fi
"${CMD[@]}"

if [ -f "$FEED_FILE" ]; then
  pass "Feed file created."
  if [ "$VERBOSE" -eq 1 ]; then
    echo -e "${BLUE}--- Feed file contents ---${NC}"
    cat "$FEED_FILE"
    echo -e "${BLUE}--- End feed file ---${NC}"
  fi
else
  fail "Feed file not created."
fi

grep -q '<title>My Podcast</title>' "$FEED_FILE" && grep -q '<title>Episode 1</title>' "$FEED_FILE" && grep -q '<description>The first episode</description>' "$FEED_FILE"
if [ $? -eq 0 ]; then
  pass "Feed contains expected podcast and first episode data."
else
  fail "Feed missing expected data for first episode."
fi

# Cleanup
test -f "$FEED_FILE" && rm "$FEED_FILE"

if [ "$FAILED" -eq 0 ]; then
  echo -e "\n${GREEN}YAML LAUNCHER TEST 1 PASSED!${NC}"
else
  echo -e "\n${RED}YAML LAUNCHER TEST 1 FAILED!${NC}"
  exit 1
fi 