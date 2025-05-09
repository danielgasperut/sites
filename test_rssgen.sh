#!/bin/bash

FEED_FILE="feed.xml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VERBOSE=${VERBOSE:-0}
print_feed() {
  if [ "$VERBOSE" -eq 1 ] && [ -f "$1" ]; then
    echo -e "\033[1;34m--- RSS Feed: $1 ---\033[0m"
    cat "$1"
    echo -e "\033[1;34m--- End of $1 ---\033[0m\n"
  fi
}

# Parse test script flags
WITH_PROMPTS=0
WITH_INTERACTIVE=0
WITH_RSS_VALIDATION=0
for arg in "$@"; do
  if [ "$arg" = "--help" ]; then
    echo -e "\033[1;36mUsage: $0 [--with-interactive] [--with-prompts] [--with-rss-validation] [--help]\033[0m"
    echo -e "\nOptions:"
    echo -e "  --help                 Show this help message and exit"
    echo -e "  --with-interactive     Include interactive tests (skipped by default)"
    echo -e "  --with-prompts         Include prompted tests (skipped by default)"
    echo -e "  --with-rss-validation  Validate feeds with W3C RSS validator (skipped by default)"
    echo -e "\nEnvironment variables:"
    echo -e "  VERBOSE=1              Print generated feeds for inspection"
    exit 0
  fi
  if [ "$arg" = "--with-prompts" ]; then
    WITH_PROMPTS=1
  fi
  if [ "$arg" = "--with-interactive" ]; then
    WITH_INTERACTIVE=1
  fi
  if [ "$arg" = "--with-rss-validation" ]; then
    WITH_RSS_VALIDATION=1
  fi
done

FAILED=0

# Detect non-interactive shell or CI
NONINTERACTIVE=0
if [[ ! -t 1 ]] || [ -n "$CI" ]; then
  NONINTERACTIVE=1
fi

# [TEST 1] Create a new feed and first episode
echo -e "\n\033[1;33m[TEST 1] Create a new feed and first episode\033[0m"
rm -f "$FEED_FILE"
./rssgen.sh --name "Test Podcast" --desc "A test podcast description" --link "https://example.com" \
  --ep-title "Test Episode 1" --ep-desc "This is the first test episode." \
  --ep-url "https://example.com/audio1.mp3" --ep-date "2024-06-01"
if [ $? -eq 0 ] && grep -q '<title>Test Podcast</title>' "$FEED_FILE" && grep -q '<title>Test Episode 1</title>' "$FEED_FILE"; then
  echo -e "${GREEN}PASS: Feed created and contains expected content.${NC}"
else
  echo -e "${RED}FAIL: Feed not created or missing content.${NC}"
  FAILED=1
fi
print_feed "$FEED_FILE"

# [TEST 2] Add a second episode
echo -e "\n\033[1;33m[TEST 2] Add a second episode\033[0m"
./rssgen.sh --ep-title "Test Episode 2" --ep-desc "This is the second test episode." --ep-url "https://example.com/audio2.mp3" --ep-date "2024-06-02"
grep -q '<title>Test Episode 2</title>' "$FEED_FILE"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: Second episode added successfully without podcast fields.${NC}"
else
  echo -e "${RED}FAIL: Second episode not added.${NC}"
  FAILED=1
fi
print_feed "$FEED_FILE"

# [TEST 3I] Modify the first episode (interactive)
echo -e "\n\033[1;33m[TEST 3I] Modify the first episode (interactive)\033[0m"
if [ "$WITH_INTERACTIVE" -ne 1 ]; then
  echo -e "${YELLOW}Skipping interactive test 3I (run with --with-interactive to include)${NC}"
else
  ./rssgen.sh --strict --ep-title "Test Episode 1" --ep-desc "This is the UPDATED first test episode." --ep-url "https://example.com/audio1-updated.mp3" --ep-date "2024-06-03" <<EOF
y
EOF
  COUNT=$(grep -c '<title>Test Episode 1</title>' "$FEED_FILE")
  UPDATED_DESC=$(awk '/<item>/,/<\/item>/' "$FEED_FILE" | grep -A5 '<title>Test Episode 1</title>' | grep '<description>' | sed 's/.*<description>\(.*\)<\/description>.*/\1/')
  UPDATED_URL=$(awk '/<item>/,/<\/item>/' "$FEED_FILE" | grep -A5 '<title>Test Episode 1</title>' | grep '<enclosure' | sed 's/.*url="\([^"]*\)".*/\1/')
  if [ "$COUNT" -eq 1 ] && [ "$UPDATED_DESC" = "This is the UPDATED first test episode." ] && [ "$UPDATED_URL" = "https://example.com/audio1-updated.mp3" ]; then
    echo -e "${GREEN}PASS: Modified episode (by title) has updated content and no duplicates exist (no podcast fields needed).${NC}"
  else
    echo -e "${RED}FAIL: Modified episode (by title) failed or duplicates exist.${NC}"
    FAILED=1
  fi
  print_feed "$FEED_FILE"

  # [TEST 3A] Negative: Creating new feed without podcast fields should fail
  echo -e "\n\033[1;33m[TEST 3A] Negative: Creating new feed without podcast fields\033[0m"
  NEW_FEED_NEG="neg_missing_podcast_fields.xml"
  rm -f "$NEW_FEED_NEG"
  ./rssgen.sh --feed-file "$NEW_FEED_NEG" <<EOF 2>neg.log



EOF
  if grep -q "Error: Podcast name is required." neg.log && grep -q "Error: Podcast description is required." neg.log && grep -q "Error: Podcast link is required." neg.log; then
    echo -e "${GREEN}PASS: Missing podcast fields correctly rejected when creating new feed.${NC}"
  else
    echo -e "${RED}FAIL: Missing podcast fields not rejected as expected.${NC}"
    FAILED=1
  fi
  rm -f "$NEW_FEED_NEG" neg.log
fi

# [TEST 3] Modify the first episode (non-interactive)
echo -e "\n\033[1;33m[TEST 3] Modify the first episode (non-interactive)\033[0m"
./rssgen.sh --ep-title "Test Episode 1" --ep-desc "This is the UPDATED first test episode (non-interactive)." --ep-url "https://example.com/audio1-updated-nonint.mp3" --ep-date "2024-06-04"
COUNT=$(grep -c '<title>Test Episode 1</title>' "$FEED_FILE")
UPDATED_DESC=$(awk '/<item>/,/<\/item>/' "$FEED_FILE" | grep -A5 '<title>Test Episode 1</title>' | grep '<description>' | sed 's/.*<description>\(.*\)<\/description>.*/\1/')
UPDATED_URL=$(awk '/<item>/,/<\/item>/' "$FEED_FILE" | grep -A5 '<title>Test Episode 1</title>' | grep '<enclosure' | sed 's/.*url="\([^"]*\)".*/\1/')
if [ "$COUNT" -eq 1 ] && [ "$UPDATED_DESC" = "This is the UPDATED first test episode (non-interactive)." ] && [ "$UPDATED_URL" = "https://example.com/audio1-updated-nonint.mp3" ]; then
  echo -e "${GREEN}PASS: Modified episode (by title) non-interactively has updated content and no duplicates exist (no podcast fields needed).${NC}"
else
  echo -e "${RED}FAIL: Modified episode (by title) non-interactively failed or duplicates exist.${NC}"
  FAILED=1
fi
print_feed "$FEED_FILE"

# [TEST 4] Add episode to existing feed with only episode fields
echo -e "\n\033[1;33m[TEST 4] Add episode to existing feed with only episode fields\033[0m"
EXIST_FEED="exist_only_ep_fields.xml"
rm -f "$EXIST_FEED"
./rssgen.sh --feed-file "$EXIST_FEED" --name "Exist Podcast" --desc "desc" --link "https://exist.example.com" --ep-title "Ep1" --ep-desc "desc" --ep-url "https://exist.example.com/ep1.mp3" --ep-date "2024-07-01"
xmllint --noout "$EXIST_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $EXIST_FEED is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $EXIST_FEED is NOT well-formed XML!${NC}"
  FAILED=1
fi
./rssgen.sh --feed-file "$EXIST_FEED" --ep-title "Ep2" --ep-desc "desc2" --ep-url "https://exist.example.com/ep2.mp3" --ep-date "2024-07-02"
xmllint --noout "$EXIST_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $EXIST_FEED is well-formed XML after adding episode.${NC}"
else
  echo -e "${RED}FAIL: $EXIST_FEED is NOT well-formed XML after adding episode!${NC}"
  FAILED=1
fi
grep -q '<title>Ep2</title>' "$EXIST_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: Added episode to existing feed with only episode fields.${NC}"
else
  echo -e "${RED}FAIL: Could not add episode to existing feed with only episode fields.${NC}"
  FAILED=1
fi
rm -f "$EXIST_FEED"

# [TEST 5] Show help output
echo -e "\n\033[1;33m[TEST 5] Show help output\033[0m"
HELP_OUT=$(./rssgen.sh --help 2>&1)
echo "$HELP_OUT" | grep -q 'Usage:' && echo "$HELP_OUT" | grep -q 'Show this help message' \
  && echo -e "${GREEN}PASS: Help output shown and contains expected text.${NC}" \
  || { echo -e "${RED}FAIL: Help output missing or incomplete.${NC}"; FAILED=1; }

# [TEST 6] Custom feed file via --feed-file option
echo -e "\n\033[1;33m[TEST 6] Custom feed file via --feed-file option\033[0m"
CUSTOM_FEED_CLI="custom_cli_feed.xml"
rm -f "$CUSTOM_FEED_CLI"
./rssgen.sh --feed-file "$CUSTOM_FEED_CLI" --name "Custom CLI Podcast" --desc "desc" --link "https://cli.example.com" --ep-title "CLI Ep" --ep-desc "desc" --ep-url "https://cli.example.com/ep.mp3" --ep-date "2024-06-20"
xmllint --noout "$CUSTOM_FEED_CLI"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $CUSTOM_FEED_CLI is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $CUSTOM_FEED_CLI is NOT well-formed XML!${NC}"
  FAILED=1
fi
if [ -f "$CUSTOM_FEED_CLI" ] && grep -q '<title>Custom CLI Podcast</title>' "$CUSTOM_FEED_CLI"; then
  echo -e "${GREEN}PASS: Custom feed file via --feed-file option test passed.${NC}"
else
  echo -e "${RED}FAIL: Custom feed file via --feed-file option test failed.${NC}"
  FAILED=1
fi
print_feed "$CUSTOM_FEED_CLI"
rm -f "$CUSTOM_FEED_CLI"

# [TEST 7] Custom feed file via FEED_FILE env var
echo -e "\n\033[1;33m[TEST 7] Custom feed file via FEED_FILE env var\033[0m"
CUSTOM_FEED_ENV="custom_env_feed.xml"
rm -f "$CUSTOM_FEED_ENV"
export FEED_FILE="$CUSTOM_FEED_ENV"
./rssgen.sh --name "Custom ENV Podcast" --desc "desc" --link "https://env.example.com" --ep-title "ENV Ep" --ep-desc "desc" --ep-url "https://env.example.com/ep.mp3" --ep-date "2024-06-21"
xmllint --noout "$CUSTOM_FEED_ENV"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $CUSTOM_FEED_ENV is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $CUSTOM_FEED_ENV is NOT well-formed XML!${NC}"
  FAILED=1
fi
if [ -f "$CUSTOM_FEED_ENV" ] && grep -q '<title>Custom ENV Podcast</title>' "$CUSTOM_FEED_ENV"; then
  echo -e "${GREEN}PASS: Custom feed file via FEED_FILE env var test passed.${NC}"
else
  echo -e "${RED}FAIL: Custom feed file via FEED_FILE env var test failed.${NC}"
  FAILED=1
fi
print_feed "$CUSTOM_FEED_ENV"
rm -f "$CUSTOM_FEED_ENV"
unset FEED_FILE

# [TEST 8] Print out a successful RSS feed at the end
echo -e "\n\033[1;33m[TEST 8] Print out a successful RSS feed at the end\033[0m"
if [ "$VERBOSE" -eq 1 ]; then
  echo "\nCreating a final feed and printing its contents..."
  FINAL_FEED="final_print_feed.xml"
  rm -f "$FINAL_FEED"
  ./rssgen.sh --feed-file "$FINAL_FEED" --name "Print Podcast" --desc "Print desc" --link "https://print.example.com" --ep-title "Print Ep" --ep-desc "Print desc" --ep-url "https://print.example.com/ep.mp3" --ep-date "2024-06-30"
  if [ -f "$FINAL_FEED" ]; then
    echo -e "\n\033[1;34m--- Final RSS Feed Output ---\033[0m"
    cat "$FINAL_FEED"
    echo -e "\033[1;34m--- End of RSS Feed ---\033[0m\n"
  else
    echo -e "${RED}FAIL: $FINAL_FEED was not created for print test.${NC}"
    FAILED=1
  fi
  rm -f "$FINAL_FEED"
else
  echo -e "${YELLOW}Skipping final RSS feed print test (run with VERBOSE=1 to enable)${NC}"
fi

# [TEST 9] All optional fields via command-line flags
echo -e "\n\033[1;33m[TEST 9] All optional fields via command-line flags\033[0m"
CLI_FEED="cli_optional_feed.xml"
rm -f "$CLI_FEED"
./rssgen.sh --feed-file "$CLI_FEED" --name "CLI Podcast" --desc "CLI Desc" --link "https://cli.example.com" \
  --language en-us --copyright "Copyright CLI" --itunes-author "CLI Author" --itunes-summary "CLI Summary" \
  --itunes-explicit yes --itunes-category "Technology" --itunes-image "https://cli.example.com/cover.jpg" \
  --itunes-owner-name "CLI Owner" --itunes-owner-email "owner@cli.com" --itunes-type episodic \
  --ep-title "CLI Ep 1" --ep-desc "CLI Ep Desc" --ep-url "https://cli.example.com/ep1.mp3" --ep-date "2024-07-01" \
  --ep-itunes-author "CLI Ep Author" --ep-itunes-summary "CLI Ep Summary" --ep-itunes-explicit yes \
  --ep-itunes-duration "00:30:00" --ep-itunes-image "https://cli.example.com/ep1.jpg" --ep-itunes-episode 1 \
  --ep-itunes-season 1 --ep-itunes-episodetype full
xmllint --noout "$CLI_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $CLI_FEED is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $CLI_FEED is NOT well-formed XML!${NC}"
  FAILED=1
fi
for field in '<language>en-us</language>' '<copyright>Copyright CLI</copyright>' '<itunes:author>CLI Author</itunes:author>' '<itunes:summary>CLI Summary</itunes:summary>' '<itunes:explicit>yes</itunes:explicit>' '<itunes:category text="Technology"/>' '<itunes:image href="https://cli.example.com/cover.jpg" />' '<itunes:owner>' '<itunes:name>CLI Owner</itunes:name>' '<itunes:email>owner@cli.com</itunes:email>' '<itunes:type>episodic</itunes:type>' '<itunes:author>CLI Ep Author</itunes:author>' '<itunes:summary>CLI Ep Summary</itunes:summary>' '<itunes:explicit>yes</itunes:explicit>' '<itunes:duration>00:30:00</itunes:duration>' '<itunes:image href="https://cli.example.com/ep1.jpg" />' '<itunes:episode>1</itunes:episode>' '<itunes:season>1</itunes:season>' '<itunes:episodeType>full</itunes:episodeType>'
  do
    grep -q "$field" "$CLI_FEED" || { echo -e "${RED}FAIL: $field not found in CLI feed.${NC}"; FAILED=1; }
done
echo -e "${GREEN}PASS: All optional fields via command-line flags present.${NC}"
rm -f "$CLI_FEED"

# [TEST 10] All optional fields via environment variables
echo -e "\n\033[1;33m[TEST 10] All optional fields via environment variables\033[0m"
ENV_FEED="env_optional_feed.xml"
rm -f "$ENV_FEED"
export FEED_FILE="$ENV_FEED"
export PODCAST_NAME="ENV Podcast"
export PODCAST_DESC="ENV Desc"
export PODCAST_LINK="https://env.example.com"
export PODCAST_LANGUAGE="fr-fr"
export PODCAST_COPYRIGHT="Copyright ENV"
export PODCAST_ITUNES_AUTHOR="ENV Author"
export PODCAST_ITUNES_SUMMARY="ENV Summary"
export PODCAST_ITUNES_EXPLICIT="no"
export PODCAST_ITUNES_CATEGORY="Education"
export PODCAST_ITUNES_IMAGE="https://env.example.com/cover.jpg"
export PODCAST_ITUNES_OWNER_NAME="ENV Owner"
export PODCAST_ITUNES_OWNER_EMAIL="owner@env.com"
export PODCAST_ITUNES_TYPE="serial"
export EP_TITLE="ENV Ep 1"
export EP_DESC="ENV Ep Desc"
export EP_URL="https://env.example.com/ep1.mp3"
export EP_DATE="2024-07-02"
export EP_ITUNES_AUTHOR="ENV Ep Author"
export EP_ITUNES_SUMMARY="ENV Ep Summary"
export EP_ITUNES_EXPLICIT="no"
export EP_ITUNES_DURATION="00:40:00"
export EP_ITUNES_IMAGE="https://env.example.com/ep1.jpg"
export EP_ITUNES_EPISODE="2"
export EP_ITUNES_SEASON="2"
export EP_ITUNES_EPISODETYPE="trailer"
./rssgen.sh
xmllint --noout "$ENV_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $ENV_FEED is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $ENV_FEED is NOT well-formed XML!${NC}"
  FAILED=1
fi
for field in '<language>fr-fr</language>' '<copyright>Copyright ENV</copyright>' '<itunes:author>ENV Author</itunes:author>' '<itunes:summary>ENV Summary</itunes:summary>' '<itunes:explicit>no</itunes:explicit>' '<itunes:category text="Education"/>' '<itunes:image href="https://env.example.com/cover.jpg" />' '<itunes:owner>' '<itunes:name>ENV Owner</itunes:name>' '<itunes:email>owner@env.com</itunes:email>' '<itunes:type>serial</itunes:type>' '<itunes:author>ENV Ep Author</itunes:author>' '<itunes:summary>ENV Ep Summary</itunes:summary>' '<itunes:explicit>no</itunes:explicit>' '<itunes:duration>00:40:00</itunes:duration>' '<itunes:image href="https://env.example.com/ep1.jpg" />' '<itunes:episode>2</itunes:episode>' '<itunes:season>2</itunes:season>' '<itunes:episodeType>trailer</itunes:episodeType>'
  do
    grep -q "$field" "$ENV_FEED" || { echo -e "${RED}FAIL: $field not found in ENV feed.${NC}"; FAILED=1; }
done
echo -e "${GREEN}PASS: All optional fields via environment variables present.${NC}"
rm -f "$ENV_FEED"
unset FEED_FILE PODCAST_NAME PODCAST_DESC PODCAST_LINK PODCAST_LANGUAGE PODCAST_COPYRIGHT PODCAST_ITUNES_AUTHOR PODCAST_ITUNES_SUMMARY PODCAST_ITUNES_EXPLICIT PODCAST_ITUNES_CATEGORY PODCAST_ITUNES_IMAGE PODCAST_ITUNES_OWNER_NAME PODCAST_ITUNES_OWNER_EMAIL PODCAST_ITUNES_TYPE EP_TITLE EP_DESC EP_URL EP_DATE EP_ITUNES_AUTHOR EP_ITUNES_SUMMARY EP_ITUNES_EXPLICIT EP_ITUNES_DURATION EP_ITUNES_IMAGE EP_ITUNES_EPISODE EP_ITUNES_SEASON EP_ITUNES_EPISODETYPE

# [TEST 11] All optional fields via prompts (using --prompt-all)
if [ "$WITH_PROMPTS" -eq 1 ]; then
  echo -e "\n\033[1;33m[TEST 11] All optional fields via prompts (--prompt-all)\033[0m"
  PROMPT_FEED="prompt_optional_feed.xml"
  rm -f "$PROMPT_FEED"
  ./rssgen.sh --feed-file "$PROMPT_FEED" --prompt-all <<EOF
Prompt Podcast
Prompt Desc
https://prompt.example.com
en-gb
Copyright PROMPT
Prompt Author
Prompt Summary
yes
Society & Culture
https://prompt.example.com/cover.jpg
Prompt Owner
owner@prompt.com
episodic
Prompt Ep 1
Prompt Ep Desc
https://prompt.example.com/ep1.mp3
2024-07-03
Prompt Ep Author
Prompt Ep Summary
yes
00:50:00
https://prompt.example.com/ep1.jpg
3
3
bonus
EOF
  for field in '<language>en-gb</language>' '<copyright>Copyright PROMPT</copyright>' '<itunes:author>Prompt Author</itunes:author>' '<itunes:summary>Prompt Summary</itunes:summary>' '<itunes:explicit>yes</itunes:explicit>' '<itunes:category text="Society & Culture"/>' '<itunes:image href="https://prompt.example.com/cover.jpg" />' '<itunes:owner>' '<itunes:name>Prompt Owner</itunes:name>' '<itunes:email>owner@prompt.com</itunes:email>' '<itunes:type>episodic</itunes:type>' '<itunes:author>Prompt Ep Author</itunes:author>' '<itunes:summary>Prompt Ep Summary</itunes:summary>' '<itunes:explicit>yes</itunes:explicit>' '<itunes:duration>00:50:00</itunes:duration>' '<itunes:image href="https://prompt.example.com/ep1.jpg" />' '<itunes:episode>3</itunes:episode>' '<itunes:season>3</itunes:season>' '<itunes:episodeType>bonus</itunes:episodeType>'
    do
      grep -q "$field" "$PROMPT_FEED" || { echo -e "${RED}FAIL: $field not found in PROMPT feed.${NC}"; FAILED=1; }
  done
  echo -e "${GREEN}PASS: All optional fields via prompts present.${NC}"
  rm -f "$PROMPT_FEED"
else
  echo -e "${YELLOW}Skipping prompted tests (--with-prompts not set)${NC}"
fi

# [TEST 12] Failing test: invalid option
echo -e "\n\033[1;33m[TEST 12] Failing test: invalid option\033[0m"
if ./rssgen.sh --not-a-real-flag 2>&1 | grep -q 'Unknown option'; then
  echo -e "${GREEN}PASS: Help shown for invalid option.${NC}"
else
  echo -e "${RED}FAIL: Help not shown for invalid option.${NC}"
  FAILED=1
fi

# [TEST 13] RSS validation of multi-episode feed (optional)
echo -e "\n\033[1;33m[TEST 13] RSS validation of multi-episode feed (optional)\033[0m"
RSSVAL_FEED="rssval_multiep_feed.xml"
rm -f "$RSSVAL_FEED"
# Create feed
./rssgen.sh --feed-file "$RSSVAL_FEED" --name "RSSVal Podcast" --desc "desc" --link "https://rssval.example.com" --ep-title "Ep1" --ep-desc "desc1" --ep-url "https://rssval.example.com/ep1.mp3" --ep-date "2024-07-01"
# Add episode
./rssgen.sh --feed-file "$RSSVAL_FEED" --ep-title "Ep2" --ep-desc "desc2" --ep-url "https://rssval.example.com/ep2.mp3" --ep-date "2024-07-02"
# Modify first episode
./rssgen.sh --feed-file "$RSSVAL_FEED" --ep-title "Ep1" --ep-desc "desc1-modified" --ep-url "https://rssval.example.com/ep1mod.mp3" --ep-date "2024-07-03" <<EOF
y
EOF
xmllint --noout "$RSSVAL_FEED"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}PASS: $RSSVAL_FEED is well-formed XML.${NC}"
else
  echo -e "${RED}FAIL: $RSSVAL_FEED is NOT well-formed XML!${NC}"
  FAILED=1
fi
rm -f "$RSSVAL_FEED"

# [TEST 14] URL XML escaping for podcast link and episode URL
echo -e "\n\033[1;33m[TEST 14] URL XML escaping for podcast link and episode URL\033[0m"
SPECIAL_FEED="special_char_url_feed.xml"
rm -f "$SPECIAL_FEED"
SPECIAL_LINK="https://example.com/?a=1&b=2<test>"
SPECIAL_EP_URL="https://audio.example.com/ep.mp3?x=1&y=2<foo>"
./rssgen.sh --feed-file "$SPECIAL_FEED" --name "Special Podcast" --desc "desc" --link "$SPECIAL_LINK" --ep-title "Special Ep" --ep-desc "desc" --ep-url "$SPECIAL_EP_URL" --ep-date "2024-07-10"

# Check for proper escaping in the feed
if grep -q 'https://example.com/?a=1&amp;b=2&lt;test&gt;' "$SPECIAL_FEED" && \
   grep -q 'https://audio.example.com/ep.mp3?x=1&amp;y=2&lt;foo&gt;' "$SPECIAL_FEED"; then
  echo -e "${GREEN}PASS: URLs with special XML characters are properly escaped in the feed.${NC}"
else
  echo -e "${RED}FAIL: URLs with special XML characters are NOT properly escaped in the feed!${NC}"
  FAILED=1
fi
rm -f "$SPECIAL_FEED"

# [TEST 15] Dropbox URL normalization (dl=0 to dl=1)
echo -e "\n\033[1;33m[TEST 15] Dropbox URL normalization (dl=0 to dl=1)\033[0m"
DROPBOX_FEED="dropbox_dl1_feed.xml"
rm -f "$DROPBOX_FEED"
DROPBOX_LINK="https://www.dropbox.com/s/abc123/podcast.mp3?dl=0"
DROPBOX_EP_URL="https://www.dropbox.com/s/xyz789/episode.mp3?dl=0"
./rssgen.sh --feed-file "$DROPBOX_FEED" --name "Dropbox Podcast" --desc "desc" --link "$DROPBOX_LINK" --ep-title "Dropbox Ep" --ep-desc "desc" --ep-url "$DROPBOX_EP_URL" --ep-date "2024-07-11"

# Check for dl=1 and not dl=0 in the feed
if grep -q 'https://www.dropbox.com/s/abc123/podcast.mp3?dl=1' "$DROPBOX_FEED" && \
   grep -q 'https://www.dropbox.com/s/xyz789/episode.mp3?dl=1' "$DROPBOX_FEED" && \
   ! grep -q 'dl=0' "$DROPBOX_FEED"; then
  echo -e "${GREEN}PASS: Dropbox URLs with dl=0 are normalized to dl=1 in the feed.${NC}"
else
  echo -e "${RED}FAIL: Dropbox URLs with dl=0 are NOT properly normalized to dl=1!${NC}"
  FAILED=1
fi
rm -f "$DROPBOX_FEED"

if [ "$FAILED" -eq 0 ]; then
  echo -e "\n${GREEN}ALL TESTS PASSED!${NC}"
else
  echo -e "\n${RED}SOME TESTS FAILED!${NC}"
fi
exit $FAILED 