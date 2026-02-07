#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗████████╗██████╗  █████╗  ██████╗███████╗
#  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
#  ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║   ██║   ██████╔╝███████║██║     █████╗  
#  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║   ██║   ██╔══██╗██╔══██║██║     ██╔══╝  
#  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝   ██║   ██║  ██║██║  ██║╚██████╗███████╗
#  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
#
#  OSINT Digital Footprint Finder - Linux Shell Script
#  Find usernames across 100+ platforms, check breaches, and remove footprints
#═══════════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
TIMEOUT=10
MAX_PARALLEL=20
OUTPUT_DIR="$HOME/.shadowtrace"
RESULTS_FILE=""

# Create output directory
mkdir -p "$OUTPUT_DIR"

#═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo -e "${CYAN}"
    echo '  ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗████████╗██████╗  █████╗  ██████╗███████╗'
    echo '  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝'
    echo '  ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║   ██║   ██████╔╝███████║██║     █████╗  '
    echo '  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║   ██║   ██╔══██╗██╔══██║██║     ██╔══╝  '
    echo '  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝   ██║   ██║  ██║██║  ██║╚██████╗███████╗'
    echo '  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝'
    echo -e "${NC}"
    echo -e "${GRAY}  ═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    OSINT Digital Footprint Finder v1.0${NC}"
    echo -e "${GRAY}  ═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_menu() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}MAIN MENU${NC}                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} 🔍 Username Search     - Find across 100+ platforms     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[2]${NC} 🛡️  Email Breach Check   - Check HaveIBeenPwned          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[3]${NC} 🔐 Password Breach      - Check if password is leaked   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[4]${NC} 🌐 Google Dork Search   - Advanced Google search        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[5]${NC} 🗑️  Removal Tools        - Data broker opt-outs         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[6]${NC} 📊 View Last Results    - Show previous scan            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[0]${NC} ❌ Exit                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 9); do
            printf "\r${CYAN}[${spinstr:$i:1}]${NC} $2"
            sleep $delay
        done
    done
    printf "\r"
}

check_dependencies() {
    local deps=("curl" "jq" "grep" "parallel")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠ Missing dependencies: ${missing[*]}${NC}"
        echo -e "${GRAY}Install with: sudo apt install ${missing[*]}${NC}"
        echo -e "${GRAY}(parallel is optional but speeds up scans)${NC}"
        echo ""
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
# SITE DEFINITIONS - Social Media & Platforms
#═══════════════════════════════════════════════════════════════════════════════

declare -A SITES=(
    # Social Media
    ["Twitter"]="https://twitter.com/{}"
    ["Instagram"]="https://www.instagram.com/{}"
    ["Facebook"]="https://www.facebook.com/{}"
    ["TikTok"]="https://www.tiktok.com/@{}"
    ["YouTube"]="https://www.youtube.com/@{}"
    ["LinkedIn"]="https://www.linkedin.com/in/{}"
    ["Pinterest"]="https://www.pinterest.com/{}"
    ["Tumblr"]="https://{}.tumblr.com"
    ["Reddit"]="https://www.reddit.com/user/{}"
    ["Snapchat"]="https://www.snapchat.com/add/{}"
    ["Threads"]="https://www.threads.net/@{}"
    ["Mastodon"]="https://mastodon.social/@{}"
    ["Bluesky"]="https://bsky.app/profile/{}.bsky.social"
    
    # Gaming
    ["Steam"]="https://steamcommunity.com/id/{}"
    ["Twitch"]="https://www.twitch.tv/{}"
    ["Xbox"]="https://xboxgamertag.com/search/{}"
    ["PlayStation"]="https://psnprofiles.com/{}"
    ["Roblox"]="https://www.roblox.com/users/profile?username={}"
    ["Minecraft"]="https://namemc.com/profile/{}"
    ["Chess.com"]="https://www.chess.com/member/{}"
    ["Lichess"]="https://lichess.org/@/{}"
    ["Osu"]="https://osu.ppy.sh/users/{}"
    ["Speedrun"]="https://www.speedrun.com/user/{}"
    
    # Development
    ["GitHub"]="https://github.com/{}"
    ["GitLab"]="https://gitlab.com/{}"
    ["Bitbucket"]="https://bitbucket.org/{}"
    ["StackOverflow"]="https://stackoverflow.com/users/{}"
    ["CodePen"]="https://codepen.io/{}"
    ["Replit"]="https://replit.com/@{}"
    ["Dev.to"]="https://dev.to/{}"
    ["HackerRank"]="https://www.hackerrank.com/{}"
    ["LeetCode"]="https://leetcode.com/{}"
    ["Codewars"]="https://www.codewars.com/users/{}"
    ["Kaggle"]="https://www.kaggle.com/{}"
    ["HuggingFace"]="https://huggingface.co/{}"
    ["npm"]="https://www.npmjs.com/~{}"
    ["PyPI"]="https://pypi.org/user/{}"
    ["DockerHub"]="https://hub.docker.com/u/{}"
    
    # Design & Creative
    ["Behance"]="https://www.behance.net/{}"
    ["Dribbble"]="https://dribbble.com/{}"
    ["DeviantArt"]="https://www.deviantart.com/{}"
    ["ArtStation"]="https://www.artstation.com/{}"
    ["Flickr"]="https://www.flickr.com/people/{}"
    ["500px"]="https://500px.com/p/{}"
    ["Unsplash"]="https://unsplash.com/@{}"
    ["VSCO"]="https://vsco.co/{}"
    ["Figma"]="https://figma.com/@{}"
    
    # Music
    ["Spotify"]="https://open.spotify.com/user/{}"
    ["SoundCloud"]="https://soundcloud.com/{}"
    ["LastFM"]="https://www.last.fm/user/{}"
    ["Bandcamp"]="https://bandcamp.com/{}"
    ["Mixcloud"]="https://www.mixcloud.com/{}"
    
    # Video
    ["Vimeo"]="https://vimeo.com/{}"
    ["Dailymotion"]="https://www.dailymotion.com/{}"
    
    # Messaging
    ["Telegram"]="https://t.me/{}"
    ["Discord"]="https://discord.com/users/{}"
    ["Keybase"]="https://keybase.io/{}"
    
    # Professional
    ["AngelList"]="https://angel.co/u/{}"
    ["Crunchbase"]="https://www.crunchbase.com/person/{}"
    ["ProductHunt"]="https://www.producthunt.com/@{}"
    ["Polywork"]="https://www.polywork.com/{}"
    
    # Blog & Writing
    ["Medium"]="https://medium.com/@{}"
    ["Substack"]="https://{}.substack.com"
    ["Hashnode"]="https://hashnode.com/@{}"
    ["Wattpad"]="https://www.wattpad.com/user/{}"
    
    # Finance
    ["CashApp"]="https://cash.app/\${}"
    ["Venmo"]="https://venmo.com/{}"
    ["PayPal"]="https://paypal.me/{}"
    
    # Creator Platforms
    ["Patreon"]="https://www.patreon.com/{}"
    ["Ko-fi"]="https://ko-fi.com/{}"
    ["BuyMeACoffee"]="https://www.buymeacoffee.com/{}"
    ["Gumroad"]="https://{}.gumroad.com"
    ["OnlyFans"]="https://onlyfans.com/{}"
    
    # Entertainment
    ["Letterboxd"]="https://letterboxd.com/{}"
    ["Goodreads"]="https://www.goodreads.com/{}"
    ["MyAnimeList"]="https://myanimelist.net/profile/{}"
    ["AniList"]="https://anilist.co/user/{}"
    ["Trakt"]="https://trakt.tv/users/{}"
    
    # Other
    ["Gravatar"]="https://en.gravatar.com/{}"
    ["About.me"]="https://about.me/{}"
    ["Linktree"]="https://linktr.ee/{}"
    ["HackerNews"]="https://news.ycombinator.com/user?id={}"
    ["Quora"]="https://www.quora.com/profile/{}"
    ["Imgur"]="https://imgur.com/user/{}"
    ["Giphy"]="https://giphy.com/channel/{}"
    
    # Security
    ["HackerOne"]="https://hackerone.com/{}"
    ["Bugcrowd"]="https://bugcrowd.com/{}"
    
    # Commerce
    ["Etsy"]="https://www.etsy.com/shop/{}"
    ["eBay"]="https://www.ebay.com/usr/{}"
    ["Poshmark"]="https://poshmark.com/closet/{}"
    
    # NFT/Crypto
    ["OpenSea"]="https://opensea.io/{}"
    ["Rarible"]="https://rarible.com/{}"
)

#═══════════════════════════════════════════════════════════════════════════════
# USERNAME SEARCH FUNCTION
#═══════════════════════════════════════════════════════════════════════════════

check_site() {
    local site_name="$1"
    local url_template="$2"
    local username="$3"
    
    # Replace {} with username
    local url="${url_template//\{\}/$username}"
    
    # Make request
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time $TIMEOUT \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
        "$url" 2>/dev/null)
    
    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}[+]${NC} ${WHITE}$site_name${NC}: ${CYAN}$url${NC}"
        echo "$site_name|$url|FOUND" >> "$RESULTS_FILE"
        return 0
    else
        echo -e "${GRAY}[-] $site_name: Not found${NC}"
        return 1
    fi
}

search_username() {
    local username="$1"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  Scanning for username: ${MAGENTA}@$username${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Create results file
    RESULTS_FILE="$OUTPUT_DIR/scan_${username}_$(date +%Y%m%d_%H%M%S).txt"
    echo "# ShadowTrace Scan Results" > "$RESULTS_FILE"
    echo "# Username: $username" >> "$RESULTS_FILE"
    echo "# Date: $(date)" >> "$RESULTS_FILE"
    echo "# ==========================================" >> "$RESULTS_FILE"
    
    local found=0
    local total=${#SITES[@]}
    local current=0
    
    # Check if parallel is available
    if command -v parallel &> /dev/null; then
        # Export functions and variables for parallel
        export -f check_site
        export TIMEOUT RESULTS_FILE GREEN CYAN WHITE GRAY MAGENTA NC
        
        # Run parallel checks
        for site_name in "${!SITES[@]}"; do
            echo "${site_name}|${SITES[$site_name]}|$username"
        done | parallel -j $MAX_PARALLEL --colsep '\|' 'check_site {1} {2} {3}'
    else
        # Sequential fallback
        for site_name in "${!SITES[@]}"; do
            ((current++))
            printf "\r${GRAY}[%d/%d]${NC} Checking $site_name...     " "$current" "$total"
            
            local url_template="${SITES[$site_name]}"
            local url="${url_template//\{\}/$username}"
            
            local response
            response=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time $TIMEOUT \
                -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
                "$url" 2>/dev/null)
            
            if [[ "$response" == "200" ]]; then
                echo -e "\r${GREEN}[+]${NC} ${WHITE}$site_name${NC}: ${CYAN}$url${NC}          "
                echo "$site_name|$url|FOUND" >> "$RESULTS_FILE"
                ((found++))
            fi
        done
    fi
    
    # Count results
    found=$(grep -c "FOUND" "$RESULTS_FILE" 2>/dev/null || echo "0")
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  SCAN COMPLETE${NC}"
    echo -e "${GREEN}  Found: $found accounts${NC}"
    echo -e "${GRAY}  Results saved: $RESULTS_FILE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════════════════
# BREACH CHECK FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

check_email_breach() {
    local email="$1"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  Checking breaches for: ${MAGENTA}$email${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # HaveIBeenPwned (requires API key for full results, but we can check basic)
    echo -e "${YELLOW}[*] Checking HaveIBeenPwned...${NC}"
    
    # Use the free breach directory search
    local breaches
    breaches=$(curl -s "https://haveibeenpwned.com/unifiedsearch/$email" \
        -H "User-Agent: ShadowTrace-OSINT" 2>/dev/null)
    
    if [[ -n "$breaches" && "$breaches" != "null" ]]; then
        echo -e "${RED}[!] EMAIL FOUND IN BREACHES!${NC}"
        echo "$breaches" | jq -r '.Breaches[]?.Name // empty' 2>/dev/null | while read breach; do
            echo -e "${RED}    → $breach${NC}"
        done
    else
        echo -e "${GREEN}[✓] No breaches found in public database${NC}"
    fi
    
    # Hudson Rock Free Check
    echo ""
    echo -e "${YELLOW}[*] Checking Hudson Rock (Infostealer DB)...${NC}"
    
    local hudson
    hudson=$(curl -s "https://cavalier.hudsonrock.com/api/json/v2/osint-tools/search-by-email?email=$email" \
        -H "User-Agent: ShadowTrace-OSINT" 2>/dev/null)
    
    if echo "$hudson" | jq -e '.stealers | length > 0' &>/dev/null; then
        echo -e "${RED}[!] FOUND IN INFOSTEALER LOGS!${NC}"
        echo "$hudson" | jq -r '.stealers[]? | "    → Computer: \(.computer_name // "Unknown") | Date: \(.date_compromised // "Unknown")"' 2>/dev/null
    else
        echo -e "${GREEN}[✓] Not found in infostealer databases${NC}"
    fi
    
    echo ""
}

check_password_breach() {
    local password="$1"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  Checking password breach status${NC}"
    echo -e "${GRAY}  (Using k-anonymity - password is NOT sent to server)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # SHA1 hash the password
    local sha1
    sha1=$(echo -n "$password" | sha1sum | awk '{print toupper($1)}')
    
    # Get first 5 chars (prefix) and the rest (suffix)
    local prefix="${sha1:0:5}"
    local suffix="${sha1:5}"
    
    # Query HIBP Passwords API
    local response
    response=$(curl -s "https://api.pwnedpasswords.com/range/$prefix" 2>/dev/null)
    
    # Check if suffix exists in response
    local count
    count=$(echo "$response" | grep -i "^$suffix:" | cut -d: -f2 | tr -d '\r')
    
    if [[ -n "$count" ]]; then
        echo -e "${RED}[!] PASSWORD HAS BEEN PWNED!${NC}"
        echo -e "${RED}    Found in $count data breaches${NC}"
        echo -e "${YELLOW}    You should change this password immediately!${NC}"
    else
        echo -e "${GREEN}[✓] Password not found in known breaches${NC}"
    fi
    
    echo ""
}

#═══════════════════════════════════════════════════════════════════════════════
# GOOGLE DORK SEARCH
#═══════════════════════════════════════════════════════════════════════════════

google_dork_search() {
    local username="$1"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  Google Dork Queries for: ${MAGENTA}@$username${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${WHITE}Copy and paste these into Google:${NC}"
    echo ""
    echo -e "${YELLOW}General Search:${NC}"
    echo -e "  \"$username\" site:pastebin.com"
    echo -e "  \"$username\" (email OR contact OR @)"
    echo -e "  \"$username\" filetype:pdf"
    echo ""
    echo -e "${YELLOW}Social Media:${NC}"
    echo -e "  \"$username\" site:twitter.com"
    echo -e "  \"$username\" site:facebook.com"
    echo -e "  \"$username\" site:linkedin.com"
    echo -e "  \"$username\" site:instagram.com"
    echo ""
    echo -e "${YELLOW}Forums & Leaks:${NC}"
    echo -e "  \"$username\" site:reddit.com"
    echo -e "  \"$username\" site:github.com"
    echo -e "  \"$username\" (leak OR breach OR dump)"
    echo ""
    echo -e "${YELLOW}Personal Info:${NC}"
    echo -e "  \"$username\" (phone OR mobile OR address)"
    echo -e "  \"$username\" (DOB OR birthday OR \"born\")"
    echo ""
    echo -e "${GRAY}Tip: Use inurl: and intitle: for more targeted searches${NC}"
}

#═══════════════════════════════════════════════════════════════════════════════
# REMOVAL TOOLS
#═══════════════════════════════════════════════════════════════════════════════

show_removal_tools() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  🗑️  DATA BROKER OPT-OUT LINKS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${WHITE}People Search Sites:${NC}"
    echo -e "  ${GREEN}[Easy]${NC}   Spokeo:           https://www.spokeo.com/optout"
    echo -e "  ${GREEN}[Easy]${NC}   TruePeopleSearch: https://www.truepeoplesearch.com/removal"
    echo -e "  ${GREEN}[Easy]${NC}   FastPeopleSearch: https://www.fastpeoplesearch.com/removal"
    echo -e "  ${YELLOW}[Med]${NC}    WhitePages:       https://www.whitepages.com/suppression-requests"
    echo -e "  ${YELLOW}[Med]${NC}    BeenVerified:     https://www.beenverified.com/app/optout/search"
    echo -e "  ${YELLOW}[Med]${NC}    Intelius:         https://www.intelius.com/opt-out"
    echo -e "  ${RED}[Hard]${NC}   Radaris:          https://radaris.com/page/how-to-remove"
    echo -e "  ${RED}[Hard]${NC}   MyLife:           https://www.mylife.com/ccpa/index.pubview"
    echo ""
    
    echo -e "${WHITE}Social Media Account Deletion:${NC}"
    echo -e "  Facebook:   https://www.facebook.com/help/delete_account"
    echo -e "  Instagram:  https://www.instagram.com/accounts/remove/request/permanent/"
    echo -e "  Twitter/X:  https://twitter.com/settings/your_twitter_data/deactivate"
    echo -e "  TikTok:     https://support.tiktok.com/en/account-and-privacy/deleting-an-account"
    echo -e "  LinkedIn:   https://www.linkedin.com/help/linkedin/answer/63"
    echo -e "  Reddit:     https://www.reddit.com/settings/account"
    echo -e "  Discord:    https://support.discord.com/hc/en-us/articles/212500837"
    echo ""
    
    echo -e "${WHITE}Generate GDPR/CCPA Removal Request:${NC}"
    echo -e "${GRAY}  Run: $0 --generate-gdpr \"Your Name\" \"your@email.com\" \"Company Name\"${NC}"
    echo ""
}

generate_gdpr_request() {
    local name="$1"
    local email="$2"
    local company="$3"
    local date=$(date +%Y-%m-%d)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  📝 GDPR Article 17 - Right to Erasure Request${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    cat << EOF
Subject: GDPR Article 17 - Right to Erasure Request

Dear $company Data Protection Officer,

I am writing to request the erasure of my personal data pursuant to Article 17 
of the General Data Protection Regulation (GDPR).

PERSONAL INFORMATION:
Full Name: $name
Email Address: $email

I request that you:
1. Confirm what personal data you hold about me
2. Delete all personal data you hold about me
3. Confirm deletion has been completed within 30 days

Please note that under GDPR, you are required to respond to this request within 
one month. If you need any further information to verify my identity or locate 
my data, please contact me at the email address provided.

If you do not comply with this request, I reserve the right to lodge a complaint 
with the relevant supervisory authority.

Thank you for your prompt attention to this matter.

Sincerely,
$name

Date: $date
EOF
    
    echo ""
    echo -e "${GREEN}[✓] Copy the text above and send to the company${NC}"
}

#═══════════════════════════════════════════════════════════════════════════════
# VIEW RESULTS
#═══════════════════════════════════════════════════════════════════════════════

view_last_results() {
    local latest
    latest=$(ls -t "$OUTPUT_DIR"/scan_*.txt 2>/dev/null | head -1)
    
    if [[ -z "$latest" ]]; then
        echo -e "${YELLOW}No previous scan results found.${NC}"
        return
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  📊 Last Scan Results${NC}"
    echo -e "${GRAY}  File: $latest${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    grep "FOUND" "$latest" | while IFS='|' read -r site url status; do
        echo -e "${GREEN}[+]${NC} ${WHITE}$site${NC}: ${CYAN}$url${NC}"
    done
    
    local count
    count=$(grep -c "FOUND" "$latest" 2>/dev/null || echo "0")
    echo ""
    echo -e "${WHITE}Total found: $count${NC}"
}

#═══════════════════════════════════════════════════════════════════════════════
# MAIN MENU LOOP
#═══════════════════════════════════════════════════════════════════════════════

main() {
    # Parse command line arguments
    case "$1" in
        -u|--username)
            search_username "$2"
            exit 0
            ;;
        -e|--email)
            check_email_breach "$2"
            exit 0
            ;;
        -p|--password)
            check_password_breach "$2"
            exit 0
            ;;
        -g|--google)
            google_dork_search "$2"
            exit 0
            ;;
        --generate-gdpr)
            generate_gdpr_request "$2" "$3" "$4"
            exit 0
            ;;
        -h|--help)
            echo "ShadowTrace - OSINT Digital Footprint Finder"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -u, --username USERNAME    Search username across platforms"
            echo "  -e, --email EMAIL          Check email for breaches"
            echo "  -p, --password PASSWORD    Check if password is leaked"
            echo "  -g, --google USERNAME      Generate Google dork queries"
            echo "  --generate-gdpr NAME EMAIL COMPANY   Generate GDPR removal request"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Interactive mode: Run without arguments"
            exit 0
            ;;
    esac
    
    # Interactive mode
    clear
    print_banner
    check_dependencies
    
    while true; do
        print_menu
        read -p "$(echo -e ${CYAN}Enter choice [0-6]: ${NC})" choice
        
        case $choice in
            1)
                read -p "$(echo -e ${WHITE}Enter username to search: ${NC})" username
                search_username "$username"
                ;;
            2)
                read -p "$(echo -e ${WHITE}Enter email to check: ${NC})" email
                check_email_breach "$email"
                ;;
            3)
                read -s -p "$(echo -e ${WHITE}Enter password to check: ${NC})" password
                echo ""
                check_password_breach "$password"
                ;;
            4)
                read -p "$(echo -e ${WHITE}Enter username for dorks: ${NC})" username
                google_dork_search "$username"
                ;;
            5)
                show_removal_tools
                ;;
            6)
                view_last_results
                ;;
            0)
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Try again.${NC}"
                ;;
        esac
        
        echo ""
        read -p "$(echo -e ${GRAY}Press Enter to continue...${NC})"
        clear
        print_banner
    done
}

# Run main
main "$@"
