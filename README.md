# ZTrack - OSINT Digital Footprint Finder

```text
███████╗████████╗██████╗  █████╗  ██████╗██╗  ██╗
╚══███╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
  ███╔╝    ██║   ██████╔╝███████║██║     █████╔╝ 
 ███╔╝     ██║   ██╔══██╗██╔══██║██║     ██╔═██╗ 
███████╗   ██║   ██║  ██║██║  ██║╚██████╗██║  ██╗
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
```

A powerful Linux shell script for finding usernames across 90+ platforms, checking data breaches, and removing your digital footprint.

## Features

- **Username Search**: Check 90+ platforms simultaneously
- **Breach Detection**: HaveIBeenPwned + Hudson Rock integration
- **Password Check**: Secure k-anonymity password breach lookup
- **Google Dorks**: Pre-built search queries for deeper OSINT
- **Removal Tools**: Data broker opt-out links + GDPR request generator

## Installation

```bash
# Clone or copy the script
chmod +x ztrack.sh

# Install dependencies (Debian/Ubuntu)
sudo apt install curl jq parallel

# Run
./ztrack.sh
```

## Usage

### Interactive Mode

```bash
./ztrack.sh
```

### Command Line

```bash
# Username search
./ztrack.sh -u johndoe

# Email breach check
./ztrack.sh -e john@email.com

# Password breach check (secure - uses k-anonymity)
./ztrack.sh -p "mypassword123"

# Google dork queries
./ztrack.sh -g johndoe

# Generate GDPR removal request
./ztrack.sh --generate-gdpr "John Doe" "john@email.com" "Facebook Inc"
```

## Platforms Checked

| Category | Platforms |
|----------|-----------|
| Social | Twitter, Instagram, Facebook, TikTok, Reddit, etc. |
| Gaming | Steam, Twitch, Xbox, PlayStation, Roblox, etc. |
| Dev | GitHub, GitLab, StackOverflow, HackerRank, etc. |
| Creative | Behance, Dribbble, DeviantArt, Figma, etc. |
| Music | Spotify, SoundCloud, Last.fm, Bandcamp |
| Professional | LinkedIn, AngelList, ProductHunt |

## Legal Disclaimer

This tool is for **personal digital footprint auditing** and **authorized security assessments only**.

**Do NOT use for**: Stalking, harassment, or unauthorized surveillance.
