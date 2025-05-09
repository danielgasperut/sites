# sites
Hosting my github site

# Podcast RSS Feed Generator

This project provides a flexible, scriptable way to generate and update podcast RSS feeds using a Bash script (`rssgen.sh`). It supports both direct command-line usage and a YAML-driven workflow for batch or automated feed management and testing.

## Features
- Create or update podcast RSS feeds from the command line
- Add or update episodes with required and optional fields
- Supports all major podcast metadata (iTunes, etc.)
- YAML-driven batch automation and testing
- Robust test suite for regression and CI

## Requirements
- `bash` (4.x recommended, but works with POSIX shell after recent refactor)
- [`yq`](https://github.com/mikefarah/yq) (YAML processor, install with `brew install yq` or see repo)
- `xmllint` (for some test validation, usually preinstalled on macOS/Linux)

## Usage

### 1. Direct Command-Line Usage
You can run `rssgen.sh` directly to create or update a feed:

```bash
./rssgen.sh --feed-file myfeed.xml --name "My Podcast" --desc "A show about tech" --link "https://mypodcast.com" \
  --ep-title "Episode 1" --ep-desc "The first episode" --ep-url "https://mypodcast.com/ep1.mp3" --ep-date "2024-07-01"
```

See `./rssgen.sh --help` for all options and environment variable support.

### 2. YAML-Driven Workflow

#### a. Edit the YAML Input
Edit `rssgen_input_template.yaml` to add one or more feed/episode entries. Example:

```yaml
- feed_file: test_feed.xml
  podcast_name: My Podcast
  podcast_desc: A show about tech
  podcast_link: https://mypodcast.com
  ep_title: Episode 1
  ep_desc: The first episode
  ep_url: https://mypodcast.com/ep1.mp3
  ep_date: 2024-07-01
  # ...other optional fields...
```

#### b. Run the Test/Launcher Script
To process all entries in the YAML file and validate the results:

```bash
bash test_yaml_launcher.sh
```

- Each entry will be run as a separate test.
- By default, the generated feed file is deleted after the test.
- To keep the feed file for inspection, run with:
  ```bash
  VERBOSE=1 bash test_yaml_launcher.sh
  ```

#### c. Add More Tests
- Add more entries to `rssgen_input_template.yaml` to cover more scenarios (new episodes, updates, optional fields, etc.).
- The test script will loop over all entries.

## Testing

There are two ways to test the podcast RSS feed generator:

### 1. YAML-Driven Test Suite (Batch/Regression)
This suite runs all test cases defined in `rssgen_input_template.yaml` using the launcher script:

```bash
bash test_yaml_launcher.sh
```
- Runs all YAML-defined tests and validates output.
- By default, generated feed files are deleted after each test.
- To keep feed files and see their contents, run in verbose mode:
  ```bash
  VERBOSE=1 bash test_yaml_launcher.sh
  ```

### 2. Dedicated Bash Test Suite
This suite runs a series of scripted tests for `rssgen.sh`:

```bash
bash test_rssgen.sh
```
- Runs a variety of feed and episode creation/update scenarios.
- By default, skips interactive/prompt-based tests.
- To include interactive tests, run with:
  ```bash
  bash test_rssgen.sh --with-interactive
  ```
- To see the final RSS feed output, run with:
  ```bash
  VERBOSE=1 bash test_rssgen.sh
  ```

## Project Structure
- `rssgen.sh` — Main Bash script for feed generation
- `rssgen_input_template.yaml` — YAML input for batch/test automation
- `test_yaml_launcher.sh` — Test/automation script for YAML-driven workflow

## Example YAML Entry
```yaml
- feed_file: test_feed.xml
  podcast_name: My Podcast
  podcast_desc: A show about tech
  podcast_link: https://mypodcast.com
  ep_title: Episode 1
  ep_desc: The first episode
  ep_url: https://mypodcast.com/ep1.mp3
  ep_date: 2024-07-01
  # ...other optional fields...
```

## Notes
- The script is robust to missing optional fields.
- The test script checks for expected content in the generated feed.
- For advanced batch workflows, just add more YAML entries!

---

For questions or contributions, open an issue or PR.
