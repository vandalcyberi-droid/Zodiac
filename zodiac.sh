#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   ███████╗ ██████╗ ██████╗ ██╗ █████╗  ██████╗
#   ╚══███╔╝██╔═══██╗██╔══██╗██║██╔══██╗██╔════╝
#     ███╔╝ ██║   ██║██║  ██║██║███████║██║
#    ███╔╝  ██║   ██║██║  ██║██║██╔══██║██║
#   ███████╗╚██████╔╝██████╔╝██║██║  ██║╚██████╗
#   ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝
#                    Z O D I A C   v7.0.0
#        
# ═══════════════════════════════════════════════════════════════════

set -o pipefail

# Require Bash; fail safely on unset critical variables only where appropriate.
export LC_ALL="${LC_ALL:-C}"
VERSION="9.0.0"
APK_DIR="${ZODIAC_DIR:-$HOME/zodiac/apks}"
WORK_DIR="${ZODIAC_WORK:-$HOME/zodiac/.cache}"
mkdir -p "$APK_DIR" "$WORK_DIR" 2>/dev/null

# ─── RED / DARK THEME ───
if [ -t 1 ]; then
    DR='\033[2;31m'; R='\033[1;31m'; BR='\033[91m'
    RR='\033[38;5;196m'; OR='\033[38;5;208m'
    W='\033[1;37m'; G='\033[38;5;250m'
    DG='\033[38;5;240m'; DD='\033[38;5;238m'
    Y='\033[38;5;220m'; M='\033[38;5;200m'
    N='\033[0m'; B='\033[1m'
else
    DR=''; R=''; BR=''; RR=''; OR=''; W=''; G=''; DG=''; DD=''; Y=''; M=''; N=''; B=''
fi

info()  { echo -e "${DR}[·]${N} ${G}$*${N}"; }
ok()    { echo -e "${RR}[✓]${N} ${W}$*${N}"; }
warn()  { echo -e "${OR}[!]${N} ${Y}$*${N}"; }
err()   { echo -e "${R}[✗]${N} ${BR}$*${N}" >&2; }
have()  { command -v "$1" >/dev/null 2>&1; }

line() {
    printf "${1:-$DR}"
    for ((i=0; i<72; i++)); do printf "═"; done
    printf "${N}\n"
}

header() {
    local text="$1"
    echo ""
    printf "${DR}▐▓▒░ ${N}${BR}${B}%s${N} ${DR}" "$text"
    local pad=$((64 - ${#text}))
    [ "$pad" -lt 3 ] && pad=3
    for ((i=0; i<pad; i++)); do printf "░▒▓"; done
    printf "▌${N}\n\n"
}

banner() {
    echo ""
    printf "${RR}   ███████╗ ██████╗ ██████╗ ██╗ █████╗  ██████╗${N}\n"
    printf "${RR}   ╚══███╔╝██╔═══██╗██╔══██╗██║██╔══██╗██╔════╝${N}\n"
    printf "${RR}     ███╔╝ ██║   ██║██║  ██║██║███████║██║${N}\n"
    printf "${RR}    ███╔╝  ██║   ██║██║  ██║██║██╔══██║██║${N}\n"
    printf "${RR}   ███████╗╚██████╔╝██████╔╝██║██║  ██║╚██████╗${N}\n"
    printf "${RR}   ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝${N}\n"
    printf "${DR}            APK Reverse Engineering ${N}\n"
    printf "${DR}                       version ${VERSION}${N}\n"
    echo ""
}

find_aapt() {
    for c in aapt aapt2; do have "$c" && { echo "$c"; return; }; done
    for d in "$HOME"/android-sdk*/build-tools/*/aapt* \
             "$PREFIX"/opt/android-sdk/build-tools/*/aapt*; do
        [ -x "$d" ] && { echo "$d"; return; }
    done
}
AAPT="$(find_aapt)"

resolve_apk() {
    local n="$1"
    [ -z "$n" ] && return 1
    [ -f "$n" ] && { echo "$n"; return 0; }
    [ -f "$APK_DIR/$n" ] && { echo "$APK_DIR/$n"; return 0; }
    [ -f "$APK_DIR/$n.apk" ] && { echo "$APK_DIR/$n.apk"; return 0; }
    return 1
}

extract_all_text() {
    local apk="$1"
    local tag; tag=$(basename "$apk" .apk)
    local cache_key="${tag}"
    if have sha256sum; then cache_key="$(sha256sum "$apk" 2>/dev/null | cut -d" " -f1)"; fi
    local cache="$WORK_DIR/${cache_key}.txt"
    if [ -f "$cache" ] && [ "$cache" -nt "$apk" ]; then echo "$cache"; return 0; fi
    local tmp; tmp=$(mktemp -d) || return 1
    info "Extracting $(basename "$apk")..." >&2
    if ! unzip -o -q "$apk" -d "$tmp" 2>/dev/null; then
        rm -rf "$tmp"
        err "Invalid or unreadable APK: $apk"
        return 1
    fi
    local out="$tmp/all.txt"; : > "$out"
    if ls "$tmp"/classes*.dex >/dev/null 2>&1; then
        cat "$tmp"/classes*.dex 2>/dev/null | strings -n 4 >> "$out"
    fi
    [ -f "$tmp/resources.arsc" ] && strings -n 4 "$tmp/resources.arsc" >> "$out"
    if [ -d "$tmp/assets" ]; then
        find "$tmp/assets" -type f 2>/dev/null | while read -r f; do
            case "$f" in
                *.js|*.json|*.xml|*.txt|*.html|*.css|*.properties|*.yml|*.yaml|*.config|*.env|*.csv|*.md|*.pem|*.key|*.crt|*.cer|*.p12|*.jks|*.der|*.so)
                    echo "" >> "$out"; echo "### FILE: ${f#$tmp/}" >> "$out"
                    cat "$f" 2>/dev/null >> "$out" ;;
            esac
        done
    fi
    if [ -d "$tmp/lib" ]; then
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r f; do
            echo "" >> "$out"; echo "### LIB: ${f#$tmp/}" >> "$out"
            strings -n 5 "$f" 2>/dev/null >> "$out"
        done
    fi
    [ -n "$AAPT" ] && "$AAPT" dump xmltree "$apk" AndroidManifest.xml 2>/dev/null >> "$out"
    sort -u "$out" > "$cache"; rm -rf "$tmp"; echo "$cache"
}

_show() {
    local label="$1" file="$2" pattern="$3" limit="${4:-30}" sev="${5:-INFO}"
    local color icon
    case "$sev" in
        CRITICAL) color="$RR"; icon="▓▓" ;;
        HIGH)     color="$R";  icon="▓ " ;;
        MEDIUM)   color="$OR"; icon="▒ " ;;
        LOW)      color="$DR"; icon="░ " ;;
        *)        color="$DG"; icon="· " ;;
    esac
    local results count
    local grep_i=""
    case "$pattern" in
        \(\?i\)*) grep_i="-i"; pattern="${pattern#\(\?i\)}" ;;
    esac
    results=$(grep -aoE $grep_i "$pattern" "$file" 2>/dev/null | sort -u)
    count=0
    if [ -n "$results" ]; then count=$(printf '%s\n' "$results" | grep -c . 2>/dev/null || true); fi
    if [ -z "$results" ] || [ "$count" -eq 0 ]; then
        printf "  ${DD}%s %-32s${N} ${DG}─${N}\n" "$icon" "$label"
        return
    fi
    printf "  ${color}%s${N} ${W}%-32s${N} ${color}[%d]${N}\n" "$icon" "$label" "$count"
    echo "$results" | head -"$limit" | while IFS= read -r l; do
        [ -z "$l" ] && continue
        [ ${#l} -gt 115 ] && l="${l:0:112}..."
        printf "     ${DR}│${N} ${G}%s${N}\n" "$l"
    done
    [ "$count" -gt "$limit" ] && printf "     ${DR}└─${N} ${DD}+%d more${N}\n" $((count - limit))
}

_list() { _show "$1" "$2" "$3" "$4" "INFO"; }

# ═══════════════════════════════════════════════════════════
#  NETWORK
# ═══════════════════════════════════════════════════════════

cmd_net() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "NETWORK · $(basename "$apk")"
    _list "HTTP/HTTPS URLs"       "$f" 'https?://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 50
    _list "FTP URLs"              "$f" 's?ftp://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 10
    _list "WebSocket"             "$f" 'wss?://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 25
    _list "Intent URLs"           "$f" '(?i)(intent://|market://|tel:|sms:|mailto:)[a-zA-Z0-9._:/?#@!$&()*+,;=%-]+' 20
    _list "Deep links"            "$f" '(?i)([a-z][a-z0-9+.-]+)://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]+' 30
    _list "IPv4"                  "$f" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 40
    _list "IPv6"                  "$f" '\b([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}\b' 15
    _list "CIDR ranges"           "$f" '\b([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\b' 15
    _list "Domains"               "$f" '\b([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+(com|ir|net|org|io|co|me|app|dev|cloud|xyz|info|biz|tv|ru|cn|de|fr|uk|jp|kr|in|br|au|ca|nl|se|no|fi|pl|tr|sa|ae|il)' 60
    _list "Emails"                "$f" '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' 40
    _list "MAC addresses"         "$f" '\b([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\b' 15
    _list "Tor .onion"            "$f" '\b[a-z2-7]{16,56}\.onion\b' 10
    _list "I2P .b32.i2p"          "$f" '\b[a-z2-7]{52}\.b32\.i2p\b' 5
    _list "Proxy configs"         "$f" '(?i)(http_proxy|https_proxy|socks5?://|proxy[_-]?host)' 10
    _list "DNS servers"           "$f" '(?i)(dns|nameserver)[ :=]+[0-9.]+' 10
    _list "User agents"           "$f" '(?i)user[_-]?agent["'"'"' :=]+[^"'"'"']{10,}' 20
    _list "Port numbers"          "$f" '(:|port[=:"\s]+)([0-9]{2,5})\b' 30
    _list "FTP credentials"       "$f" '(?i)ftp://[^:]+:[^@]+@' 10
}

cmd_urls() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "URLS · $(basename "$apk")"
    _list "HTTP/HTTPS"     "$f" 'https?://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 60
    _list "FTP"            "$f" 's?ftp://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 10
    _list "WebSocket"      "$f" 'wss?://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' 25
    _list "Intent URLs"    "$f" '(?i)(intent://|market://|tel:|sms:|mailto:)[a-zA-Z0-9._:/?#@!$&()*+,;=%-]+' 20
    _list "Deep links"     "$f" '(?i)([a-z][a-z0-9+.-]+)://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]+' 30
}

cmd_ips() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "IP ADDRESSES · $(basename "$apk")"
    _list "IPv4"        "$f" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 40
    _list "IPv6"        "$f" '\b([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}\b' 15
    _list "CIDR"        "$f" '\b([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}\b' 15
}

cmd_emails() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "EMAILS · $(basename "$apk")"
    _list "Emails"  "$f" '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' 60
}

cmd_domains() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "DOMAINS · $(basename "$apk")"
    _list "Domains"     "$f" '\b([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+(com|ir|net|org|io|co|me|app|dev|cloud|xyz|info|biz|tv|ru|cn|de|fr|uk|jp|kr|in|br|au|ca|nl|se|no|fi|pl|tr|sa|ae|il)' 60
    _list "Subdomains"  "$f" '\b[a-z0-9-]+\.[a-z0-9-]+\.[a-z]{2,}\b' 40
    _list "CDN"         "$f" '(?i)(cloudfront|akamai|fastly|cloudflare|cdn)[a-z0-9.-]*\.(com|net|ir)' 15
}

cmd_api() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "API · $(basename "$apk")"
    _list "REST paths"       "$f" '/(api|v[0-9]+|rest|graphql|rpc)/[a-zA-Z0-9_/{}.-]+' 40
    _list "Base URLs"        "$f" 'https?://[a-zA-Z0-9.-]+/(api|v[0-9]+)' 20
    _list "HTTP Methods"     "$f" '\b(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS) /[a-zA-Z0-9_/{}.-]+' 30
    _list "Query params"     "$f" '[?&][a-zA-Z_][a-zA-Z0-9_]{2,}=' 40
    _list "gRPC services"    "$f" '/[a-zA-Z0-9_.]+\.[A-Z][a-zA-Z0-9_]+/[A-Z][a-zA-Z0-9_]+' 20
    _list "Swagger/OpenAPI"  "$f" '(?i)(swagger|openapi)[".:=/][^"]{3,}' 10
    _list "GraphQL ops"      "$f" '(query|mutation|subscription) [A-Z][a-zA-Z]*' 15
    _list "Content-Types"    "$f" '(application|text|multipart)/[a-zA-Z0-9.+-]+' 15
    _list "API versions"     "$f" '(?i)api[_-]?version["'"'"' :=]+[0-9.]+' 10
    _list "Rate limit"       "$f" '(?i)(rate.?limit|x-rate-limit|retry-after)' 10
    _list "CORS headers"     "$f" '(?i)(access-control-allow|origin)' 10
    _list "Cookie names"     "$f" '(?i)set-cookie:? *[a-zA-Z0-9_-]+=' 15
    _list "X-Headers"        "$f" '(?i)(x-api|x-auth|x-token|x-client|x-request|x-signature)[a-z-]*' 25
}

cmd_strings() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "STRINGS · $(basename "$apk")"
    _list "URLs"       "$f" 'https?://[^ "[:space:]\\]{6,}' 20
    _list "IPs"        "$f" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 20
    _list "Emails"     "$f" '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' 20
    _list "API Keys"   "$f" '(?i)(api[_-]?key|apikey)["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 15
    _list "JWT Tokens" "$f" 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' 15
    echo ""
    ok "Full cache: $f"
}

# ═══════════════════════════════════════════════════════════
#  SECRETS
# ═══════════════════════════════════════════════════════════

cmd_secrets() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "SECRETS · $(basename "$apk")"
    _show "Generic API Keys"      "$f" '(?i)(api[_-]?key|apikey)["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 25 "HIGH"
    _show "Bearer tokens"         "$f" '(?i)bearer[ _-]?[A-Za-z0-9_.\-]{20,}' 20 "HIGH"
    _show "Access tokens"         "$f" '(?i)access[_-]?token["'"'"' :=]+[A-Za-z0-9_.\-]{20,}' 20 "HIGH"
    _show "Refresh tokens"        "$f" '(?i)refresh[_-]?token["'"'"' :=]+[A-Za-z0-9_.\-]{20,}' 20 "HIGH"
    _show "ID tokens"             "$f" '(?i)id[_-]?token["'"'"' :=]+[A-Za-z0-9_.\-]{20,}' 15 "HIGH"
    _show "Session tokens"        "$f" '(?i)session[_-]?(id|token)["'"'"' :=]+[A-Za-z0-9_.\-]{16,}' 20 "MEDIUM"
    _show "Client secrets"        "$f" '(?i)client[_-]?secret["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 20 "CRITICAL"
    _show "App secrets"           "$f" '(?i)app[_-]?secret["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 20 "CRITICAL"
    _show "Passwords"             "$f" '(?i)(password|passwd|pwd|pass)["'"'"' :=]+[^"'"'"'[:space:]]{4,}' 50 "HIGH"
    _show "Usernames"             "$f" '(?i)(username|user[_-]?name|login)["'"'"' :=]+[^"'"'"'\s]{3,}' 30 "MEDIUM"
    _show "Private keys"          "$f" 'BEGIN (RSA |EC |DSA |OPENSSH |PGP |PRIVATE )?PRIVATE KEY' 15 "CRITICAL"
    _show "Public keys"           "$f" 'BEGIN PUBLIC KEY' 10 "LOW"
    _show "SSH keys"              "$f" 'ssh-(rsa|dss|ed25519) AAAA[A-Za-z0-9+/=]+' 10 "CRITICAL"
    _show "PGP keys"              "$f" 'BEGIN PGP (PRIVATE|PUBLIC) KEY BLOCK' 5 "HIGH"
    _show "Encryption keys"       "$f" '(?i)(encryption|secret|cipher)[_-]?key["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 20 "CRITICAL"
    _show "HMAC keys"             "$f" '(?i)hmac[_-]?(key|secret)["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 20 "HIGH"
    _show "Salt values"           "$f" '(?i)salt["'"'"' :=]+[A-Za-z0-9_\-+/=]{8,}' 20 "MEDIUM"
    _show "IV / Nonces"           "$f" '(?i)(initialization[_-]?vector|nonce|iv)["'"'"' :=]+[A-Za-z0-9_\-+/=]{8,}' 20 "HIGH"
    _show "Seed phrases"          "$f" '(?i)(mnemonic|seed[_-]?phrase)["'"'"' :=]+[a-z ]{20,}' 5 "CRITICAL"
    _show "Base64 blobs (60+)"    "$f" '[A-Za-z0-9+/]{60,}={0,2}' 25 "MEDIUM"
    _show "Hex strings (32+)"     "$f" '\b[A-Fa-f0-9]{32,}\b' 30 "MEDIUM"
    _show "Hex strings (64+)"     "$f" '\b[A-Fa-f0-9]{64,}\b' 20 "HIGH"
    _show "UUIDs"                 "$f" '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b' 20 "LOW"
    _show "Env variables"         "$f" '(?i)(DB_|API_|SECRET_|TOKEN_|KEY_|AWS_|GCP_|AZURE_)[A-Z_]+=' 30 "MEDIUM"
    _show ".env entries"          "$f" '^[A-Z_]{3,}=[^#\n]{3,}' 25 "MEDIUM"
    _show "Connection strings"    "$f" '(?i)(jdbc:|mysql://|postgres://|postgresql://|mongodb://|redis://|amqp://|kafka://)' 20 "CRITICAL"
    _show "Hardcoded creds"       "$f" '(?i)(user|login|email)["'"'"' :=]+[^"'"'"'\s]{3,}.*(pass|pwd)' 20 "HIGH"
    _show "Basic auth headers"    "$f" 'Basic [A-Za-z0-9+/=]{20,}' 15 "HIGH"
}

# ═══════════════════════════════════════════════════════════
#  CLOUD
# ═══════════════════════════════════════════════════════════

cmd_cloud() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "CLOUD · $(basename "$apk")"
    _show "AWS Access Key IDs"    "$f" 'AKIA[0-9A-Z]{16}' 15 "CRITICAL"
    _show "AWS ASIA temp"         "$f" 'ASIA[0-9A-Z]{16}' 10 "CRITICAL"
    _show "AWS Secret Keys"       "$f" '(?i)aws[_-]?secret[_-]?access[_-]?key["'"'"' :=]+[A-Za-z0-9/+=]{40}' 10 "CRITICAL"
    _show "AWS Session Tokens"    "$f" '(?i)aws[_-]?session[_-]?token["'"'"' :=]+[A-Za-z0-9/+=]{100,}' 10 "CRITICAL"
    _show "S3 Buckets"            "$f" '[a-z0-9.-]+\.s3[.-][a-z0-9-]*\.amazonaws\.com' 25 "HIGH"
    _show "S3 Path-Style"         "$f" 's3\.amazonaws\.com/[a-z0-9.-]+' 20 "HIGH"
    _show "AWS Regions"           "$f" '\b(us|eu|ap|sa|ca|me|af|il)-(east|west|north|south|central|northeast|southeast|northwest|southwest)-[0-9]\b' 15 "LOW"
    _show "Firebase RTDB"         "$f" '[a-z0-9-]+\.firebaseio\.com' 25 "HIGH"
    _show "Firebase Storage"      "$f" '[a-z0-9-]+\.appspot\.com' 25 "HIGH"
    _show "Firebase Project"      "$f" 'project[_-]?id["'"'"' :=]+[a-z0-9-]{6,}' 20 "MEDIUM"
    _show "Google API Keys"       "$f" 'AIza[0-9A-Za-z_-]{35}' 20 "CRITICAL"
    _show "OAuth Client IDs"      "$f" '[0-9]{10,}-[a-z0-9]+\.apps\.googleusercontent\.com' 20 "MEDIUM"
    _show "GCP Service Accounts"  "$f" '"type":\s*"service_account"' 5 "CRITICAL"
    _show "Azure Storage"         "$f" '[a-z0-9-]+\.(blob|queue|table|file)\.core\.windows\.net' 20 "HIGH"
    _show "Azure Conn Strings"    "$f" 'DefaultEndpointsProtocol=https;AccountName=[^;]+' 10 "CRITICAL"
    _show "Azure Tenant IDs"      "$f" '(?i)tenant[_-]?id["'"'"' :=]+[0-9a-f]{8}-[0-9a-f-]+' 10 "MEDIUM"
    _show "Heroku"                "$f" '[a-z0-9-]+\.herokuapp\.com' 10 "MEDIUM"
    _show "DigitalOcean"          "$f" '(?i)digitalocean[_.:]?\s*[A-Za-z0-9_]{30,}' 5 "HIGH"
    _show "DigitalOcean Spaces"   "$f" '[a-z0-9-]+\.[a-z0-9-]+\.digitaloceanspaces\.com' 10 "HIGH"
    _show "Cloudflare"            "$f" '[a-z0-9]+\.cloudflare[a-z-]*\.(com|net)' 10 "LOW"
    _show "Alibaba OSS"           "$f" '[a-z0-9-]+\.oss-[a-z0-9-]+\.aliyuncs\.com' 10 "HIGH"
    _show "Alibaba AccessKey"     "$f" 'LTAI[A-Za-z0-9]{12,20}' 10 "CRITICAL"
    _show "Tencent COS"           "$f" '[a-z0-9-]+\.cos\.[a-z0-9-]+\.myqcloud\.com' 10 "HIGH"
    _show "Oracle Cloud"          "$f" 'objectstorage\.[a-z0-9-]+\.oraclecloud\.com' 10 "HIGH"
}

# ═══════════════════════════════════════════════════════════
#  AUTH
# ═══════════════════════════════════════════════════════════

cmd_auth() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "AUTH · $(basename "$apk")"
    _show "JWT tokens"            "$f" 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' 25 "HIGH"
    _show "JWT secrets"           "$f" '(?i)jwt[_-]?secret["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 10 "CRITICAL"
    _show "Basic Auth"            "$f" 'Basic [A-Za-z0-9+/=]{20,}' 15 "HIGH"
    _show "OAuth URLs"            "$f" 'https?://[a-zA-Z0-9.-]+/(oauth|authorize|token|auth)[a-zA-Z0-9_/.-]*' 25 "MEDIUM"
    _show "OAuth scopes"          "$f" 'scope["'"'"' :=]+[a-zA-Z0-9_:. -]{10,}' 15 "LOW"
    _show "Session IDs"           "$f" '(?i)session[_-]?id["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 20 "MEDIUM"
    _show "Cookies"               "$f" '(?i)(JSESSIONID|PHPSESSID|ASP\.NET_SessionId|_session_id|sessionid)' 15 "MEDIUM"
    _show "SAML"                  "$f" '(?i)(saml|SAMLResponse|samlp:|SAMLRequest|saml:)' 20 "MEDIUM"
    _show "OpenID"                "$f" '(?i)(openid|id_token|access_token|oauth2)' 25 "MEDIUM"
    _show "CSRF tokens"           "$f" '(?i)(csrf|xsrf|_token|authenticity_token)["'"'"' :=]+[A-Za-z0-9_-]{16,}' 20 "MEDIUM"
    _show "API auth headers"      "$f" '(?i)(x-api-key|authorization|bearer|x-access-token|x-auth-token)["'"'"' :=]+' 25 "MEDIUM"
    _show "PKCE"                  "$f" '(?i)(code_challenge|code_verifier|pkce)' 15 "LOW"
    _show "MFA / 2FA"             "$f" '(?i)(otp|totp|two[_-]?factor|2fa|mfa|verification[_-]?code)["'"'"' :=]+' 20 "MEDIUM"
    _show "Captcha keys"          "$f" '(?i)(recaptcha|hcaptcha|site[_-]?key|secret[_-]?key)["'"'"' :=]+[A-Za-z0-9_\-]{16,}' 15 "MEDIUM"
}

# ═══════════════════════════════════════════════════════════
#  PAYMENT
# ═══════════════════════════════════════════════════════════

cmd_payment() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "PAYMENT · $(basename "$apk")"
    _show "Stripe live"         "$f" 'sk_live_[A-Za-z0-9]{20,}' 10 "CRITICAL"
    _show "Stripe test"         "$f" 'sk_test_[A-Za-z0-9]{20,}' 10 "MEDIUM"
    _show "Stripe publishable"  "$f" 'pk_(live|test)_[A-Za-z0-9]{20,}' 15 "LOW"
    _show "Stripe restricted"   "$f" 'rk_(live|test)_[A-Za-z0-9]{20,}' 10 "CRITICAL"
    _show "PayPal"              "$f" '(?i)(paypal|braintree)[a-z._-]*["'"'"' :=]+[A-Za-z0-9_\-]{10,}' 15 "MEDIUM"
    _show "Square keys"         "$f" 'sq0[a-z]{3}-[A-Za-z0-9_-]{20,}' 10 "HIGH"
    _show "Braintree"           "$f" '(?i)braintree[a-z._-]*["'"'"' :=]+[A-Za-z0-9]{16,}' 10 "HIGH"
    _show "Adyen"               "$f" '(?i)adyen[a-z._-]*["'"'"' :=]+[A-Za-z0-9]{16,}' 10 "HIGH"
    _show "Razorpay"            "$f" 'rzp_(live|test)_[A-Za-z0-9]{14,}' 10 "HIGH"
    _show "Bitcoin wallets"     "$f" '\b(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,62}\b' 25 "MEDIUM"
    _show "Ethereum wallets"    "$f" '\b0x[a-fA-F0-9]{40}\b' 25 "MEDIUM"
    _show "Monero wallets"      "$f" '\b4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}\b' 10 "MEDIUM"
    _show "Litecoin wallets"    "$f" '\b[LM3][a-km-zA-HJ-NP-Z1-9]{26,33}\b' 10 "MEDIUM"
    _show "Tron wallets"        "$f" '\bT[A-Za-z1-9]{33}\b' 10 "MEDIUM"
    _show "IBAN"                "$f" '\b[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}\b' 15 "HIGH"
    _show "SWIFT/BIC"           "$f" '\b[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?\b' 15 "MEDIUM"
    _show "Credit cards"        "$f" '\b(4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b' 10 "CRITICAL"
    _show "CVV"                 "$f" '(?i)(cvv|cvc|cvn)["'"'"' :=]+[0-9]{3,4}' 10 "CRITICAL"
    _show "Iranian Sheba"       "$f" '\bIR[0-9]{24}\b' 20 "HIGH"
    _show "Iranian cards"       "$f" '\b(6037|6104|6274|6393|6273|6219|5022)[0-9]{12,14}\b' 15 "CRITICAL"
}

# ═══════════════════════════════════════════════════════════
#  COMMUNICATION
# ═══════════════════════════════════════════════════════════

cmd_comm() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "COMMUNICATION · $(basename "$apk")"
    _show "Telegram bot tokens"  "$f" '[0-9]{8,10}:[A-Za-z0-9_-]{35}' 20 "CRITICAL"
    _show "Telegram API URLs"    "$f" 'https?://api\.telegram\.org/bot[0-9]+:[A-Za-z0-9_-]+' 15 "HIGH"
    _show "Telegram chat IDs"    "$f" '(?i)chat[_-]?id["'"'"' :=]+-?[0-9]{6,}' 20 "MEDIUM"
    _show "Discord webhooks"     "$f" 'https?://(canary\.|ptb\.)?discord(app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+' 20 "CRITICAL"
    _show "Discord bot tokens"   "$f" '[MN][A-Za-z0-9]{23}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}' 10 "CRITICAL"
    _show "Discord invite"       "$f" 'discord(app)?\.com/invite/[A-Za-z0-9]+' 10 "LOW"
    _show "Slack tokens"         "$f" 'xox[baprs]-[0-9A-Za-z-]{10,}' 15 "CRITICAL"
    _show "Slack webhooks"       "$f" 'https?://hooks\.slack\.com/services/[A-Z0-9/]+' 10 "CRITICAL"
    _show "Twilio SIDs"          "$f" 'AC[a-f0-9]{32}' 10 "HIGH"
    _show "Twilio Auth Tokens"   "$f" '(?i)twilio[_-]?auth[_-]?token["'"'"' :=]+[a-f0-9]{32}' 5 "CRITICAL"
    _show "SendGrid keys"        "$f" 'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}' 10 "CRITICAL"
    _show "Mailgun keys"         "$f" 'key-[a-f0-9]{32}' 10 "HIGH"
    _show "Mailchimp"            "$f" '[a-f0-9]{32}-us[0-9]{1,2}' 10 "HIGH"
    _show "AWS SES"              "$f" '(?i)email-smtp\.[a-z0-9-]+\.amazonaws\.com' 10 "MEDIUM"
    _show "WhatsApp URLs"        "$f" 'https?://(api\.)?whatsapp\.com/[a-zA-Z0-9_/.-]*' 15 "LOW"
    _show "Signal URLs"          "$f" 'https?://[a-z.]*signal\.org/[a-zA-Z0-9_/.-]*' 5 "LOW"
    _show "Matrix"               "$f" '(?i)(matrix\.org|_matrix|m\.room)' 10 "LOW"
    _show "Rocket.Chat"          "$f" '(?i)rocket\.chat' 5 "LOW"
    _show "Mattermost"           "$f" '(?i)mattermost' 5 "LOW"
}

# ═══════════════════════════════════════════════════════════
#  MALICIOUS
# ═══════════════════════════════════════════════════════════

cmd_mal() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "MALICIOUS · $(basename "$apk")"

    _show "Shell interpreters"    "$f" '\b(su|sh|bash|zsh|ash|busybox|toybox|dash|csh|ksh)\b' 40 "HIGH"
    _show "chmod/chown/chgrp"     "$f" '\bch(mod|own|grp)\s+[0-9a-zA-Z,+-]+' 20 "MEDIUM"
    _show "Destructive cmds"      "$f" '\b(rm\s+-rf|dd\s+if=|mkfs|fdisk|wipe|shred|srm)\b' 20 "CRITICAL"
    _show "Mount/umount"          "$f" '\b(mount|umount)\s+[^;]{0,50}' 15 "MEDIUM"
    _show "Package install"       "$f" '\b(pm\s+install|am\s+start|am\s+broadcast|am\s+force-stop|pm\s+uninstall)' 25 "HIGH"
    _show "Process control"       "$f" '\b(kill|pkill|killall|killall5|signal)\s+-?[0-9A-Z]+' 20 "MEDIUM"
    _show "Nohup/background"      "$f" '\b(nohup|setsid|disown)' 15 "MEDIUM"
    _show "Pipes to shell"        "$f" '(curl|wget)[^|]{0,50}\|\s*(sh|bash|python|perl)' 20 "CRITICAL"
    _show "Base64 pipe"           "$f" 'echo\s+[A-Za-z0-9+/=]{20,}\s*\|\s*base64\s+-d' 15 "CRITICAL"

    _show "su binary paths"       "$f" '/system/(x?bin|app)/su\b' 25 "CRITICAL"
    _show "Superuser apps"        "$f" '(?i)(superuser|supersu|magisk|kingroot|kingoroot|magiskhide|zygisk|riru)' 25 "CRITICAL"
    _show "Root managers"         "$f" '(?i)(topjohnwu|MagiskManager|supersu\.apk|RootCloak)' 10 "HIGH"
    _show "System binaries"       "$f" '/system/(bin|app|lib|etc|xbin)/[a-zA-Z0-9_/.-]+' 30 "MEDIUM"
    _show "Busybox paths"         "$f" '(?i)/busybox\b' 10 "HIGH"
    _show "Root checker apps"     "$f" '(?i)(rootbeer|safetynet|SafetyNet|RootChecker|rootcloak)' 15 "MEDIUM"
    _show "Exploits/CVEs"         "$f" '(?i)(cve-[0-9]{4}-[0-9]{4,}|dirtycow|dirtypipe|stagefright|towelroot|framaroot|pingpong)' 20 "CRITICAL"

    _show "Runtime.exec"          "$f" '(?i)Runtime\.getRuntime\(\)\.exec' 25 "CRITICAL"
    _show "ProcessBuilder"        "$f" '(?i)ProcessBuilder' 20 "CRITICAL"
    _show "Reflection API"        "$f" '(?i)(java\.lang\.reflect|Class\.forName|getDeclaredMethod|getDeclaredField|setAccessible)' 40 "HIGH"
    _show "DexClassLoader"        "$f" '(?i)(DexClassLoader|PathClassLoader|InMemoryDexClassLoader|BaseDexClassLoader|URLClassLoader)' 25 "CRITICAL"
    _show "Native lib loading"    "$f" '(?i)(System\.loadLibrary|System\.load|dlopen|dlsym|dlerror|RTLD_)' 25 "HIGH"
    _show "Shellcode"             "$f" '(?i)(shellcode|payload|stage2|stager|meterpreter)' 20 "CRITICAL"
    _show "JNI Register"          "$f" '(?i)(RegisterNatives|JNI_OnLoad|JNIEnv)' 20 "MEDIUM"
    _show "Javascript exec"       "$f" '(?i)(evaluateJavascript|WebView.*loadUrl|WebMessage)' 25 "HIGH"
    _show "SQL command exec"      "$f" '(?i)(execSQL|rawQuery|xp_cmdshell|sp_executesql)' 20 "HIGH"

    _show "Anti-Debug"            "$f" '(?i)(isDebuggerConnected|Debug\.isDebugger|android\.os\.Debug|ptrace|TracerPid|/proc/self/status)' 30 "HIGH"
    _show "Anti-VM"               "$f" '(?i)(qemu|genymotion|xen|vmware|virtualbox|bluestacks|nox|ldplayer|andyroid|memu|parallels)' 30 "HIGH"
    _show "Anti-Emulator"         "$f" '(?i)(isEmulator|checkEmulator|emulatorDetect|ro\.kernel\.qemu|ro\.hardware\.goldfish|goldfish)' 25 "HIGH"
    _show "Anti-Frida"            "$f" '(?i)(frida|frida-server|frida-gadget|gum-js-loop|gmain|linjector)' 25 "CRITICAL"
    _show "Anti-Xposed"           "$f" '(?i)(xposed|de\.robv|XposedBridge|XC_MethodHook|EdXposed)' 20 "CRITICAL"
    _show "Anti-Magisk"           "$f" '(?i)(magisk|magiskhide|zygisk|riru|Shamiko)' 20 "HIGH"
    _show "Anti-Substrate"        "$f" '(?i)(substrate|cydia|CydiaSubstrate|MSHookFunction|MSFindSymbol)' 15 "HIGH"
    _show "Anti-Hook"             "$f" '(?i)(hook|unhook|detour|trampoline|inline.?hook)' 20 "MEDIUM"
    _show "Integrity checks"      "$f" '(?i)(verifySignatures|checkSignature|signature[_-]?check|integrity[_-]?check|tamper|SafetyNet|attestation)' 25 "MEDIUM"
    _show "Emulator artifacts"    "$f" '/dev/(qemu|socket|goldfish|vbox|genyd|ttyGS)' 20 "HIGH"
    _show "Sandbox detection"     "$f" '(?i)(sandbox|vbox|anubis|cuckoo|joe.?sandbox|any\.run|virustotal|hybrid.?analysis)' 20 "HIGH"
    _show "Time checks"           "$f" '(?i)(SystemClock\.elapsedRealtime|System\.currentTimeMillis|uptime|elapsedRealtimeNanos)' 20 "LOW"
    _show "Environment checks"    "$f" '(?i)(getprop|Build\.(FINGERPRINT|MODEL|BRAND|MANUFACTURER|HARDWARE|PRODUCT|DEVICE|BOARD|BOOTLOADER))' 30 "MEDIUM"
    _show "Thread check"          "$f" '(?i)(Thread\.currentThread|Thread\.activeCount|isDaemon)' 15 "LOW"

    _show "Obfuscators"           "$f" '(?i)(StringFog|ProGuard|DexGuard|R8|Allatori|Zelix|DashO|yGuard|JObf)' 20 "HIGH"
    _show "Packers"               "$f" '(?i)(Bangcle|Qihoo|360\.jiagu|SecNeo|Libprotect|ijiami|Tencent.*Legu|ali.*protect|Naga|TenDroid)' 25 "CRITICAL"
    _show "VM obfuscation"        "$f" '(?i)(VMProtect|Themida|Code.*Virtual|Virtualize|Enigma)' 15 "HIGH"
    _show "Base64 decode"         "$f" '(?i)Base64\.(decode|encode)' 25 "MEDIUM"
    _show "XOR decryption"        "$f" '(?i)(xor|XOR|decrypt)[^a-zA-Z]{0,3}(loop|key|byte)?' 25 "MEDIUM"
    _show "Cipher usage"          "$f" '(?i)Cipher\.(getInstance|doFinal|init|update)' 30 "MEDIUM"
    _show "Dynamic strings"       "$f" '(?i)(StringBuilder|String\.format|concat|StringBuffer)' 30 "LOW"

    _show "SMS access"            "$f" '(?i)(SmsManager|sendTextMessage|sendMultipartTextMessage|content://sms|Telephony|SMS_RECEIVED)' 30 "CRITICAL"
    _show "SMS keywords"          "$f" '(?i)(sms|SMS_|readSms|smsBody|smsNumber)' 30 "HIGH"
    _show "Contacts access"       "$f" '(?i)(ContactsContract|content://contacts|READ_CONTACTS|ContactPicker)' 25 "CRITICAL"
    _show "Call logs"             "$f" '(?i)(CallLog|content://call_log|READ_CALL_LOG)' 25 "CRITICAL"
    _show "Location tracking"     "$f" '(?i)(LocationManager|getLastKnownLocation|requestLocationUpdates|FusedLocationProvider|GeofencingClient|Criteria)' 30 "HIGH"
    _show "Camera access"         "$f" '(?i)(Camera\.open|Camera2|MediaRecorder|CameraX|ImageCapture|SurfaceTexture)' 30 "HIGH"
    _show "Microphone access"     "$f" '(?i)(AudioRecord|MediaRecorder\.setAudioSource|AudioSource\.MIC|VOICE_RECOGNITION)' 25 "CRITICAL"
    _show "Clipboard access"      "$f" '(?i)(ClipboardManager|getPrimaryClip|setPrimaryClip|ClipData)' 20 "HIGH"
    _show "Screen capture"        "$f" '(?i)(MediaProjection|createScreenCaptureIntent|screenshot|ImageReader|VirtualDisplay)' 25 "HIGH"
    _show "Keylogger APIs"        "$f" '(?i)(AccessibilityService|onAccessibilityEvent|dispatchKeyEvent|OnKeyListener|InputMethod)' 30 "CRITICAL"
    _show "Account access"        "$f" '(?i)(AccountManager|getAccounts|AccountPicker|Authenticator)' 20 "HIGH"
    _show "Calendar access"       "$f" '(?i)(CalendarContract|content://calendar|READ_CALENDAR)' 20 "MEDIUM"
    _show "Sensor access"         "$f" '(?i)(SensorManager|SensorEventListener|TYPE_ACCELEROMETER|TYPE_GYROSCOPE|TYPE_MAGNETIC)' 20 "MEDIUM"
    _show "File access"           "$f" '(?i)(getExternalFilesDir|getExternalStorageDirectory|Environment\.getExternalStorage|MediaStore)' 25 "MEDIUM"
    _show "Call audio"            "$f" '(?i)(AudioSource\.VOICE_CALL|VOICE_DOWNLINK|VOICE_UPLINK|TelephonyManager)' 15 "CRITICAL"
    _show "Bluetooth access"      "$f" '(?i)(BluetoothAdapter|BluetoothDevice|BluetoothGatt)' 20 "MEDIUM"
    _show "Browser history"       "$f" '(?i)(Browser\.BOOKMARKS_URI|Browser\.HISTORY|content://browser)' 15 "HIGH"
    _show "WhatsApp data"         "$f" '(?i)(whatsapp.*\.db|msgstore|wa\.db)' 15 "HIGH"
    _show "Telegram data"         "$f" '(?i)(telegram.*\.db|cache4|tgnet)' 15 "HIGH"

    _show "BOOT_COMPLETED"        "$f" '(?i)BOOT_COMPLETED|RECEIVE_BOOT_COMPLETED|LOCKED_BOOT_COMPLETED' 20 "HIGH"
    _show "AlarmManager"          "$f" '(?i)(AlarmManager|setRepeating|setExact|setInexactRepeating|setAlarmClock)' 25 "MEDIUM"
    _show "JobScheduler"          "$f" '(?i)(JobScheduler|JobService|JobInfo|JobInfo\.Builder)' 20 "MEDIUM"
    _show "WorkManager"           "$f" '(?i)(WorkManager|PeriodicWorkRequest|OneTimeWorkRequest|WorkRequest)' 20 "MEDIUM"
    _show "Device Admin"          "$f" '(?i)(DeviceAdminReceiver|device_admin|DevicePolicyManager|BIND_DEVICE_ADMIN)' 20 "CRITICAL"
    _show "Foreground services"   "$f" '(?i)(startForegroundService|FOREGROUND_SERVICE|startForeground)' 25 "HIGH"
    _show "Auto-start"            "$f" '(?i)(autostart|auto_start|boot_receiver|StartupManager|MiuiAutoStart)' 20 "HIGH"
    _show "Sync adapters"         "$f" '(?i)(SyncAdapter|AbstractThreadedSyncAdapter|ContentResolver.*addPeriodicSync)' 15 "MEDIUM"
    _show "Account persistence"   "$f" '(?i)(AbstractAccountAuthenticator|AccountAuthenticatorActivity)' 15 "MEDIUM"

    _show "Accessibility abuse"   "$f" '(?i)(BIND_ACCESSIBILITY_SERVICE|AccessibilityServiceInfo|setServiceInfo|performAction|GLOBAL_ACTION)' 30 "CRITICAL"
    _show "Device Admin abuse"    "$f" '(?i)(BIND_DEVICE_ADMIN|addActiveAdmin|DeviceAdminInfo|DevicePolicyManager)' 25 "CRITICAL"
    _show "Notification listener" "$f" '(?i)(NotificationListenerService|BIND_NOTIFICATION_LISTENER|getActiveNotifications)' 20 "CRITICAL"
    _show "VPN service"           "$f" '(?i)(VpnService|BIND_VPN_SERVICE|VpnService\.Builder|establish\()' 20 "HIGH"
    _show "Overlay attacks"       "$f" '(?i)(SYSTEM_ALERT_WINDOW|TYPE_APPLICATION_OVERLAY|TYPE_SYSTEM_ALERT|TYPE_PHONE|TYPE_PRIORITY_PHONE)' 25 "CRITICAL"
    _show "Usage stats"           "$f" '(?i)(PACKAGE_USAGE_STATS|UsageStatsManager|UsageStats)' 20 "HIGH"
    _show "Input method"          "$f" '(?i)(InputMethodService|BIND_INPUT_METHOD|InputMethodManager)' 20 "CRITICAL"
    _show "Dream service"         "$f" '(?i)(DreamService|BIND_DREAM_SERVICE)' 10 "MEDIUM"
    _show "Condition provider"    "$f" '(?i)(ConditionProviderService|BIND_CONDITION_PROVIDER_SERVICE)' 10 "MEDIUM"

    _show "JS Bridge"             "$f" '(?i)addJavascriptInterface' 25 "CRITICAL"
    _show "JS enabled"            "$f" '(?i)setJavaScriptEnabled\s*\(\s*true' 20 "HIGH"
    _show "WebView loading"       "$f" '(?i)(loadUrl|loadDataWithBaseURL|evaluateJavascript|postWebMessage|WebMessagePort)' 30 "MEDIUM"
    _show "File access WebView"   "$f" '(?i)(setAllowFileAccess|setAllowFileAccessFromFileURLs|setAllowUniversalAccessFromFileURLs|setAllowContentAccess)' 20 "CRITICAL"
    _show "SSL errors ignored"    "$f" '(?i)(onReceivedSslError|sslErrorHandler\.proceed|SslErrorHandler)' 20 "CRITICAL"
    _show "WebView debugging"     "$f" '(?i)(setWebContentsDebuggingEnabled|WebView\.setWebContentsDebugging)' 15 "HIGH"

    _show "SSL pinning"           "$f" '(?i)(CertificatePinner|X509TrustManager|TrustManager|ssl.?pinning|pinning|OkHttp.*Pinner)' 30 "HIGH"
    _show "Trust all certs"       "$f" '(?i)(trustAllCerts|checkServerTrusted.*return|TrustAll|ALLOW_ALL)' 20 "CRITICAL"
    _show "Hostname verifier"     "$f" '(?i)(HostnameVerifier|setHostnameVerifier|ALLOW_ALL_HOSTNAME)' 20 "CRITICAL"
    _show "Cleartext allowed"     "$f" '(?i)(cleartextTrafficPermitted|usesCleartextTraffic)' 20 "HIGH"
    _show "Network security conf" "$f" '(?i)network[_-]?security[_-]?config' 15 "MEDIUM"
    _show "Proxy aware"           "$f" '(?i)(ProxySelector|Proxy\.NO_PROXY|getDefaultProxy|isProxySet)' 15 "LOW"

    _show "Cryptominer"           "$f" '(?i)(xmrig|stratum\+tcp|stratum\+ssl|monero.*mine|coinhive|cryptonight|minergate|cgminer)' 25 "CRITICAL"
    _show "Mining pools"          "$f" '(?i)(pool\.|minexmr|nanopool|supportxmr|hashvault|minexmr\.com)' 20 "CRITICAL"
    _show "Wallet address"        "$f" '\b4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}\b' 15 "HIGH"

    _show "Ransomware"            "$f" '(?i)(encrypt.*files|ransom|decrypt.*key|pay.*bitcoin|your files|locked)' 25 "CRITICAL"
    _show "File encryption"       "$f" '(?i)(encryptFile|AES.*files|\.locked|\.encrypted|\.crypto|\.crypt|\.enc)' 20 "CRITICAL"
    _show "Ransom notes"          "$f" '(?i)(readme.*decrypt|how.*decrypt|recover.*files|decrypt.*instruction)' 15 "CRITICAL"
    _show "Payment demands"       "$f" '(?i)(pay.*btc|send.*bitcoin|wallet.*address.*pay|onion.*pay)' 15 "CRITICAL"

    _show "RAT commands"          "$f" '(?i)(takeScreenshot|recordAudio|dumpSms|dumpContacts|uploadFile|downloadFile|shellCommand)' 30 "CRITICAL"
    _show "Backdoor hints"        "$f" '(?i)(backdoor|reverse.?shell|bind.?shell|remote.?shell|shell.?exec)' 20 "CRITICAL"
    _show "C2 patterns"           "$f" '(?i)(c2[_.-]?(server|host|url)|command.?control|beacon|implant|agent)' 25 "CRITICAL"
    _show "Botnet hints"          "$f" '(?i)(botnet|bot[_.-]?id|zombie|master.?server|slave)' 20 "CRITICAL"
    _show "Keylogger"             "$f" '(?i)(keylog|keystroke|captureKey|getKeyEvent|onKeyDown|onKeyUp)' 25 "CRITICAL"

    _show "Dangerous perms"       "$f" '(?i)(BIND_ACCESSIBILITY_SERVICE|SYSTEM_ALERT_WINDOW|REQUEST_INSTALL_PACKAGES|BIND_DEVICE_ADMIN|BIND_NOTIFICATION_LISTENER|BIND_VPN_SERVICE|MANAGE_EXTERNAL_STORAGE)' 30 "CRITICAL"

    _show "Spyware"               "$f" '(?i)(spyware|stalkerware|monitor|track.*user|surveillance)' 20 "CRITICAL"
    _show "Parental controls"     "$f" '(?i)(parental.?control|child.?monitor|kid.?track)' 10 "MEDIUM"
}

# ═══════════════════════════════════════════════════════════
#  VULNERABILITIES
# ═══════════════════════════════════════════════════════════

cmd_vuln() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "VULNERABILITIES · $(basename "$apk")"

    _show "SQL Injection"         "$f" '(?i)(rawQuery|execSQL|SELECT.*FROM.*WHERE.*\+|".*\+.*".*FROM|OR 1=1|UNION SELECT)' 30 "CRITICAL"
    _show "SQL raw methods"       "$f" '(?i)(rawQuery|execSQL|SQLiteDatabase\.openOrCreate)' 25 "HIGH"
    _show "Command Injection"     "$f" '(?i)(Runtime\.exec|ProcessBuilder|/system/bin/sh -c|\|.*sh)' 25 "CRITICAL"
    _show "Path Traversal"        "$f" '(\.\./|\.\.\\|%2e%2e|%252e%252e|%c0%ae)' 25 "HIGH"
    _show "File path concat"      "$f" '(?i)(File\([^)]*\+[^)]*\)|new File\(.*\+.*\))' 25 "MEDIUM"
    _show "Deserialization"       "$f" '(?i)(ObjectInputStream|readObject|Serializable|Parcel\.read|readParcelable)' 30 "HIGH"
    _show "Intent redirection"    "$f" '(?i)(getParcelableExtra|getSerializableExtra|Intent\.parseUri|getIntent\(\))' 30 "HIGH"
    _show "Implicit intents"      "$f" '(?i)new Intent\(\)|setAction\(|startActivity\(|sendBroadcast\()' 35 "MEDIUM"
    _show "Exported components"   "$f" '(?i)android:exported="true"' 35 "HIGH"
    _show "PendingIntent (review)" "$f" '(?i)(PendingIntent|getActivity|getService|getBroadcast|FLAG_MUTABLE|FLAG_IMMUTABLE)' 25 "HIGH"
    _show "WebView exploits"      "$f" '(?i)(addJavascriptInterface|setAllowFileAccess|setAllowContentAccess)' 25 "CRITICAL"
    _show "SSL issues"            "$f" '(?i)(onReceivedSslError|proceed\(\)|checkServerTrusted|ALLOW_ALL)' 25 "HIGH"
    _show "Broadcast APIs (review)" "$f" '(?i)(registerReceiver|onReceive|sendBroadcast|sendOrderedBroadcast)' 30 "MEDIUM"
    _show "Zip Slip"              "$f" '(?i)(ZipEntry|getNextEntry|ZipInputStream|ZipFile)' 20 "HIGH"
    _show "XXE"                   "$f" '(?i)(DocumentBuilderFactory|SAXParserFactory|XMLReaderFactory|XMLReader|SAXParser)' 25 "HIGH"
    _show "Concurrency APIs (review)" "$f" '(?i)(synchronized|ReentrantLock|AtomicBoolean|AtomicInteger|volatile)' 25 "LOW"
    _show "Insecure crypto"       "$f" '(?i)(\bDES\b|RC4|MD5|SHA-?1|ECB|ARCFOUR)' 30 "HIGH"
    _show "Weak randomness"       "$f" '(?i)(new Random\(\)|Math\.random|java\.util\.Random|Random\.nextInt)' 25 "MEDIUM"
    _show "Hardcoded HTTP"        "$f" 'http://[a-zA-Z0-9.-]+' 30 "HIGH"
    _show "Debug enabled"         "$f" '(?i)android:debuggable="true"' 15 "CRITICAL"
    _show "Backup enabled"        "$f" '(?i)android:allowBackup="true"' 15 "MEDIUM"
    _show "Task hijacking"        "$f" '(?i)(launchMode="singleTask"|taskAffinity|allowTaskReparenting)' 20 "MEDIUM"
    _show "StrandHogg"            "$f" '(?i)(StrandHogg|taskAffinity=""|launchMode.*singleTask)' 15 "HIGH"
    _show "Tapjacking"            "$f" '(?i)(filterTouchesWhenObscured|setFilterTouchesWhenObscured)' 15 "HIGH"
    _show "Overlay attacks"       "$f" '(?i)(TYPE_APPLICATION_OVERLAY|TYPE_SYSTEM_ALERT|SYSTEM_ALERT_WINDOW)' 20 "CRITICAL"
    _show "Insecure broadcast"    "$f" '(?i)(sendBroadcast\(.*\)|registerReceiver.*RECEIVER_EXPORTED)' 20 "MEDIUM"
    _show "Content provider"      "$f" '(?i)(ContentProvider|openFile|openAssetFile|call\(|query\()' 25 "MEDIUM"
    _show "File permissions"      "$f" '(?i)(MODE_WORLD_READABLE|MODE_WORLD_WRITEABLE|Context\.MODE_WORLD)' 15 "CRITICAL"
    _show "Dynamic code load"     "$f" '(?i)(DexClassLoader|PathClassLoader|loadClass|defineClass)' 25 "CRITICAL"
    _show "WebView JS enabled"    "$f" '(?i)setJavaScriptEnabled\s*\(\s*true' 20 "HIGH"
    _show "WebView file access"   "$f" '(?i)(setAllowFileAccess|setAllowContentAccess)' 20 "CRITICAL"
    _show "Activity exported"     "$f" '(?i)activity.*android:exported="true"' 20 "HIGH"
    _show "Service exported"      "$f" '(?i)service.*android:exported="true"' 15 "HIGH"
    _show "Receiver exported"     "$f" '(?i)receiver.*android:exported="true"' 15 "HIGH"
    _show "Provider exported"     "$f" '(?i)provider.*android:exported="true"' 15 "CRITICAL"
}

# ═══════════════════════════════════════════════════════════
#  BYPASS
# ═══════════════════════════════════════════════════════════

cmd_bypass() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "BYPASS · $(basename "$apk")"
    _show "SSL pinning bypass"    "$f" '(?i)(ssl.?pinning|pinning.?bypass|TrustManager|CertificatePinner|OkHttp.*Pinner|X509TrustManager)' 30 "HIGH"
    _show "Root detection bypass" "$f" '(?i)(root.?detect|rootbeer|safetynet|SafetyNet|attestation|isRooted|checkRoot)' 25 "HIGH"
    _show "Debug detection"       "$f" '(?i)(isDebuggerConnected|Debug\.waitForDebugger|ptrace|TracerPid)' 20 "HIGH"
    _show "Integrity bypass"      "$f" '(?i)(safetynet|integrity|tamper|verifySignatures|checkSignature|SafetyNetApi)' 25 "HIGH"
    _show "Frida detection"       "$f" '(?i)(frida|frida-server|frida-gadget|gum-js-loop|gmain|linjector)' 20 "CRITICAL"
    _show "Xposed detection"      "$f" '(?i)(xposed|de\.robv|XposedBridge|XC_MethodHook|EdXposed|LSPosed)' 20 "CRITICAL"
    _show "Magisk detection"      "$f" '(?i)(magisk|magiskhide|zygisk|riru|Shamiko|DenyList)' 20 "HIGH"
    _show "Substrate detection"   "$f" '(?i)(substrate|cydia|CydiaSubstrate|MSHookFunction)' 15 "HIGH"
    _show "Emulator bypass"       "$f" '(?i)(genymotion|nox|bluestacks|ldplayer|mumu|memu|andyroid)' 20 "MEDIUM"
    _show "Proxy detection"       "$f" '(?i)(ProxySelector|getDefaultProxy|isProxySet|proxyHost|Proxy\.NO_PROXY)' 20 "MEDIUM"
    _show "VPN detection"         "$f" '(?i)(NetworkCapabilities|TRANSPORT_VPN|VpnService|detectVpn|VpnTransportInfo)' 20 "MEDIUM"
    _show "Screen recording det"  "$f" '(?i)(FLAG_SECURE|setFlags.*SECURE|isScreenCaptured|OnScreenCapture)' 15 "MEDIUM"
    _show "Screenshot det"        "$f" '(?i)(onScreenCapture|ScreenCaptureCallback|ScreenCaptureListener)' 15 "MEDIUM"
    _show "Time tamper"           "$f" '(?i)(SystemClock|ntp|timeTamper|clockTamper|NTPClient)' 20 "MEDIUM"
    _show "Location spoof"        "$f" '(?i)(mock.?location|isFromMockProvider|setMock|Location\.setMock|FakeLocation)' 15 "MEDIUM"
    _show "App cloning"           "$f" '(?i)(clone|dual.?app|parallel.?space|VirtualApp|VirtualXposed|AppClone)' 15 "MEDIUM"
    _show "Anti-analysis"         "$f" '(?i)(anti.?analysis|anti.?debug|anti.?vm|anti.?frida|anti.?xposed)' 20 "HIGH"
}

# ═══════════════════════════════════════════════════════════
#  CRYPTO
# ═══════════════════════════════════════════════════════════

cmd_crypto() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "CRYPTOGRAPHY · $(basename "$apk")"
    _show "AES usage"              "$f" '(?i)\bAES[-_/]?(128|192|256)?\b' 30 "MEDIUM"
    _show "AES modes"             "$f" '(?i)\b(AES/(CBC|ECB|GCM|CTR|CFB|OFB|XTS))\b' 25 "MEDIUM"
    _show "AES/Padding"           "$f" '(?i)(AES/(CBC|ECB)/PKCS5Padding|AES/GCM/NoPadding|AES/CTR/NoPadding)' 20 "MEDIUM"
    _show "DES / 3DES usage"       "$f" '(?i)\b(3DES|DESede|DES)\b' 25 "HIGH"
    _show "DES modes"             "$f" '(?i)\b(DES/(CBC|ECB|CFB|OFB))\b' 20 "HIGH"
    _show "RSA usage"              "$f" '(?i)\bRSA[-_/]?(1024|2048|4096|8192)?\b' 25 "MEDIUM"
    _show "RSA padding"           "$f" '(?i)\b(RSA/(ECB|CBC|OAEP|PKCS1|None))\b' 20 "MEDIUM"
    _show "ECC / EC usage"          "$f" '(?i)\b(ECDSA|ECDH|secp256k1|Curve25519|Ed25519|secp256r1|secp384r1)\b' 25 "MEDIUM"
    _show "RC4 / ARC4"            "$f" '(?i)\b(ARC4|RC4|ARCFOUR)\b' 15 "CRITICAL"
    _show "RC2"                   "$f" '(?i)\bRC2\b' 10 "HIGH"
    _show "Blowfish"              "$f" '(?i)\bBlowfish\b' 15 "MEDIUM"
    _show "Twofish"               "$f" '(?i)\bTwofish\b' 10 "LOW"
    _show "ChaCha20"              "$f" '(?i)\bChaCha20[-_]?Poly1305?\b' 15 "LOW"
    _show "Salsa20"               "$f" '(?i)\bSalsa20\b' 10 "LOW"
    _show "MD5"                   "$f" '(?i)\bMD5\b' 25 "HIGH"
    _show "SHA family"            "$f" '(?i)\bSHA[-_]?(1|224|256|384|512|3)\b' 35 "LOW"
    _show "SHA1 (weak)"           "$f" '(?i)\bSHA-?1\b' 15 "HIGH"
    _show "bcrypt/scrypt/argon"   "$f" '(?i)\b(bcrypt|scrypt|argon2|pbkdf2|PBKDF2WithHmacSHA)\b' 20 "LOW"
    _show "HMAC"                  "$f" '(?i)\bHMAC[-_]?(MD5|SHA1|SHA256|SHA512)?\b' 25 "LOW"
    _show "Key sizes"             "$f" '(?i)\b(key[_-]?size|keySize|keyLength)["'"'"' :=]+[0-9]+' 20 "MEDIUM"
    _show "Weak key size"         "$f" '(?i)(keySize|keyLength)["'"'"' :=]+(512|768|1024)\b' 15 "CRITICAL"
    _show "IV / Nonce"            "$f" '(?i)\b(initialization[_-]?vector|nonce|ivBytes?|gcmNonce|ivParam)\b' 25 "HIGH"
    _show "Static IV"             "$f" '(?i)(iv\s*=\s*new\s+byte\[\]|fixed.?iv|static.?iv|hardcoded.?iv)' 20 "CRITICAL"
    _show "Keystore"              "$f" '(?i)(AndroidKeyStore|KeyStore\.getInstance|Keystore|KeyChain|KeyGenerator)' 25 "MEDIUM"
    _show "Keystore files"        "$f" '(?i)\.(jks|bks|p12|pkcs12|keystore|pem|der|crt|cer)\b' 25 "MEDIUM"
    _show "BouncyCastle"          "$f" '(?i)(BouncyCastle|org\.bouncycastle|BC\.getInstance)' 20 "LOW"
    _show "SpongyCastle"          "$f" '(?i)(SpongyCastle|org\.spongycastle)' 15 "MEDIUM"
    _show "Conscrypt"             "$f" '(?i)(Conscrypt|conscrypt)' 10 "LOW"
    _show "Weak random"           "$f" '(?i)(new Random\(\)|Math\.random|java\.util\.Random)' 30 "HIGH"
    _show "SecureRandom"          "$f" '(?i)(SecureRandom|securerandom)' 20 "LOW"
    _show "Cipher instance"       "$f" '(?i)Cipher\.getInstance\("[^"]+"\)' 35 "MEDIUM"
    _show "KeyGenerator"          "$f" '(?i)(KeyGenerator\.getInstance|SecretKeySpec|IvParameterSpec)' 25 "MEDIUM"
    _show "MessageDigest"         "$f" '(?i)(MessageDigest\.getInstance|Mac\.getInstance)' 25 "LOW"
    _show "Signature"             "$f" '(?i)(Signature\.getInstance|Signature\.initSign|Signature\.initVerify)' 20 "LOW"
    _show "KeyAgreement"          "$f" '(?i)(KeyAgreement|KeyPairGenerator|KeyFactory)' 25 "MEDIUM"
    _show "Crypto keywords"       "$f" '(?i)(encrypt|decrypt|cipher|keystore|jks|pkcs12|bks|salt|KDF|PBKDF)' 40 "MEDIUM"
    _show "Certificate pinning"   "$f" '(?i)(pin|pinning|CertificatePinner|sha256/|sha1/)' 25 "MEDIUM"
    _show "Hash algorithms"       "$f" '(?i)(md2|md4|md5|sha1|sha224|sha256|sha384|sha512|ripemd|whirlpool)' 30 "MEDIUM"
    _show "Key derivation"        "$f" '(?i)(PBKDF2|scrypt|bcrypt|argon2|HKDF|KDF)' 20 "MEDIUM"
    _show "Base64 usage"          "$f" '(?i)(Base64\.|android\.util\.Base64|java\.util\.Base64)' 30 "LOW"
    _show "Hex encoding"          "$f" '(?i)(Hex\.encodeHexString|Hex\.decodeHex|toHexString|fromHexString)' 25 "LOW"
    _show "Encryption flags"      "$f" '(?i)(Cipher\.ENCRYPT_MODE|Cipher\.DECRYPT_MODE)' 20 "MEDIUM"
    _show "Crypto providers"      "$f" '(?i)(Security\.addProvider|Security\.getProvider|Provider\.setProperty)' 20 "MEDIUM"
}

# ═══════════════════════════════════════════════════════════
#  OFFENSIVE
# ═══════════════════════════════════════════════════════════

cmd_offensive() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "OFFENSIVE · $(basename "$apk")"
    _show "Attack surface"        "$f" '(?i)(attack[_-]?surface|entry[_-]?point|trigger|exploit)' 20 "MEDIUM"
    _show "Injection points"      "$f" '(?i)(inject|injection|payload|exploit|craft)' 25 "HIGH"
    _show "Debug interfaces"      "$f" '(?i)(debug|adb|ddms|stetho|leakcanary|strictmode|webview.*debug)' 30 "HIGH"
    _show "Exported activities"   "$f" '(?i)activity.*exported="true"' 20 "HIGH"
    _show "Exported services"     "$f" '(?i)service.*exported="true"' 20 "HIGH"
    _show "Exported receivers"    "$f" '(?i)receiver.*exported="true"' 20 "HIGH"
    _show "Exported providers"    "$f" '(?i)provider.*exported="true"' 20 "CRITICAL"
    _show "Deep links"            "$f" '(?i)(android:scheme|android:host|android:pathPrefix|android:pathPattern)' 30 "HIGH"
    _show "Intent filters"        "$f" '(?i)<intent-filter>|<action\s+android:name|android:priority' 30 "MEDIUM"
    _show "Browsable"             "$f" '(?i)android:autoVerify|BROWSABLE|category.*BROWSABLE' 15 "MEDIUM"
    _show "App Links"             "$f" '(?i)asset[_-]?links|\.well-known|digitalassetlinks)' 10 "MEDIUM"
    _show "Custom URL schemes"    "$f" '(?i)([a-z][a-z0-9]+)://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]+' 40 "HIGH"
    _show "File providers"        "$f" '(?i)(FileProvider|content://.*file|android:authorities)' 20 "HIGH"
    _show "Root paths used"       "$f" '(?i)(/system/bin|/system/xbin|/su/bin|/sbin)' 25 "HIGH"
    _show "Setuid binaries"       "$f" '(?i)(setuid|setgid|chmod\s+4[0-9]{3}|chmod\s+6[0-9]{3})' 15 "CRITICAL"
    _show "Busybox usage"         "$f" '(?i)(busybox\s+(wget|nc|sh|telnet|mount))' 20 "HIGH"
    _show "Netcat usage"          "$f" '(?i)(nc\s+-[el]|ncat|netcat|/dev/tcp)' 20 "CRITICAL"
    _show "Socat usage"           "$f" '(?i)socat\s+' 10 "HIGH"
    _show "Reverse shells"        "$f" '(?i)(bash\s+-i\s+>&|/dev/tcp/|nc\s+-e\s+/bin/sh|mkfifo)' 20 "CRITICAL"
    _show "Curl pipes"            "$f" '(curl|wget)[^|]{0,50}\|\s*(sh|bash|python)' 20 "CRITICAL"
    _show "Cron jobs"             "$f" '(?i)(crontab|/etc/cron|/var/spool/cron)' 15 "HIGH"
    _show "Init scripts"          "$f" '(?i)(init\.d|rc\.local|/etc/init|systemd)' 15 "MEDIUM"
    _show "Hooks"                 "$f" '(?i)(LD_PRELOAD|LD_LIBRARY_PATH|__attribute__\(\(constructor\)\)|atexit)' 20 "HIGH"
    _show "Ptrace usage"          "$f" '(?i)(ptrace|PTRACE_ATTACH|PTRACE_DETACH|PTRACE_TRACEME)' 20 "HIGH"
    _show "Memory injection"      "$f" '(?i)(mmap|mprotect|munmap|PROT_EXEC|PROT_WRITE)' 25 "HIGH"
    _show "Antidebug native"      "$f" '(?i)(ptrace.*PTRACE_TRACEME|/proc/self/status|TracerPid)' 20 "HIGH"
    _show "Syscalls"              "$f" '(?i)(syscall\(|__NR_|SYS_|execve|fork\(|clone\()' 25 "MEDIUM"
    _show "Memory corruption"     "$f" '(?i)(buffer.?overflow|heap.?overflow|stack.?overflow|use.?after.?free)' 20 "CRITICAL"
    _show "Format strings"        "$f" '(?i)(printf.*%n|sprintf.*%n|snprintf.*%n)' 15 "HIGH"
}

# ═══════════════════════════════════════════════════════════
#  DECRYPTION
# ═══════════════════════════════════════════════════════════

cmd_decrypt() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "DECRYPTION · $(basename "$apk")"
    _show "Hardcoded keys"        "$f" '(?i)(secret[_-]?key|aes[_-]?key|encryption[_-]?key|private[_-]?key)["'"'"' :=]+[A-Za-z0-9+/=_-]{8,}' 30 "CRITICAL"
    _show "Hardcoded IVs"         "$f" '(?i)(iv|initialization.?vector|nonce)["'"'"' :=]+[A-Za-z0-9+/=_-]{8,}' 25 "CRITICAL"
    _show "Hardcoded salts"       "$f" '(?i)salt["'"'"' :=]+[A-Za-z0-9+/=_-]{8,}' 20 "HIGH"
    _show "Static passwords"      "$f" '(?i)(password|passwd|pwd|pass)["'"'"' :=]+"[^"]{4,}"' 30 "CRITICAL"
    _show "Decryption routines"   "$f" '(?i)(decrypt|deobfuscate|decompress|unpack|decode)' 35 "HIGH"
    _show "Key derivation"        "$f" '(?i)(deriveKey|generateKey|SecretKeySpec|PBEKeySpec|KeyGenerator)' 30 "MEDIUM"
    _show "XOR keys"              "$f" '(?i)(xor[_-]?key|XOR_KEY|xorKey|decryptXor)' 20 "HIGH"
    _show "Base64 decode"         "$f" '(?i)(Base64\.decode|android\.util\.Base64\.decode|decodeBase64)' 25 "MEDIUM"
    _show "Hex decode"            "$f" '(?i)(decodeHex|fromHex|hexToBytes|unhexlify|bytes\.fromhex)' 20 "MEDIUM"
    _show "Cipher init"           "$f" '(?i)Cipher\.init\(.*DECRYPT_MODE' 25 "MEDIUM"
    _show "Cipher init encrypt"   "$f" '(?i)Cipher\.init\(.*ENCRYPT_MODE' 25 "MEDIUM"
    _show "Decrypt calls"         "$f" '(?i)\.doFinal\(' 30 "MEDIUM"
    _show "Digest usage"          "$f" '(?i)(MessageDigest|DigestUtils|hash\(|computeHash)' 25 "LOW"
    _show "Public key import"     "$f" '(?i)(X509EncodedKeySpec|PKCS8EncodedKeySpec|KeyFactory)' 20 "MEDIUM"
    _show "Certificate loading"   "$f" '(?i)(CertificateFactory|X509Certificate|loadCertificate)' 20 "MEDIUM"
    _show "Keystore access"       "$f" '(?i)(KeyStore\.load|KeyStore\.getKey|KeyStore\.getCertificate|getEntry)' 25 "MEDIUM"
    _show "Android Keystore"      "$f" '(?i)(AndroidKeyStore|KeyGenParameterSpec|KeyProperties)' 25 "MEDIUM"
    _show "Weak crypto"           "$f" '(?i)(MD5|SHA-?1|DES|RC4|ECB)' 30 "HIGH"
    _show "ECB mode"              "$f" '(?i)AES/ECB|DES/ECB|/ECB/' 20 "CRITICAL"
    _show "Deterministic"         "$f" '(?i)(deterministic|fixed.?iv|static.?iv|reuse.?iv|no.?iv)' 20 "HIGH"
    _show "Length extension"      "$f" '(?i)(append.*hash|MD5.*append|SHA1.*append)' 10 "MEDIUM"
    _show "Padding oracle"        "$f" '(?i)(padding.?oracle|pkcs.?padding|invalid.?padding)' 10 "HIGH"
    _show "Known plaintext"       "$f" '(?i)(known.?plaintext|chosen.?plaintext|ciphertext)' 10 "MEDIUM"
    _show "Bit-flip attacks"      "$f" '(?i)(bit.?flip|bitflip|bitflipping)' 10 "MEDIUM"
    _show "CBC issues"            "$f" '(?i)(CBC.?mode|/CBC/)' 25 "MEDIUM"
    _show "Key reuse"             "$f" '(?i)(key.?reuse|same.?key|reused.?key)' 10 "HIGH"
}

# ═══════════════════════════════════════════════════════════
#  NATIVE
# ═══════════════════════════════════════════════════════════

cmd_native() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    header "NATIVE / JNI · $(basename "$apk")"
    local tmp; tmp=$(mktemp -d)
    unzip -o -q "$apk" "lib/*" -d "$tmp" 2>/dev/null
    if [ -d "$tmp/lib" ]; then
        info "Native libraries:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            local rel="${so#$tmp/}"
            local size; size=$(du -h "$so" | cut -f1)
            printf "  ${DR}│${N} ${RR}▸${N} ${W}%-52s${N} ${DG}%s${N}\n" "$rel" "$size"
        done
        echo ""
        info "JNI functions:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            strings -n 8 "$so" 2>/dev/null | grep -E '^Java_' | head -20 | while read -r jni; do
                printf "  ${DR}│${N} ${R}▸${N} ${G}%s${N}\n" "$jni"
            done
        done
        echo ""
        info "Native syscalls:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            strings -n 4 "$so" 2>/dev/null | grep -E '^(ptrace|mmap|mprotect|execve|fork|syscall|dlopen|dlsym|dlclose|__system_property_get|kill|waitpid|socket|connect|bind|listen)$' | sort -u | while read -r sc; do
                printf "  ${DR}│${N} ${OR}▸${N} ${Y}%s${N}\n" "$sc"
            done
        done
        echo ""
        info "Native crypto:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            strings -n 5 "$so" 2>/dev/null | grep -iE '(AES|RSA|SHA|MD5|HMAC|openssl|boringssl|mbedtls|sodium|EVP_|CRYPTO_)' | sort -u | head -20 | while read -r c; do
                printf "  ${DR}│${N} ${M}▸${N} ${G}%s${N}\n" "$c"
            done
        done
        echo ""
        info "Anti-debug native:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            strings -n 5 "$so" 2>/dev/null | grep -iE '(ptrace|TracerPid|/proc/self/status|/proc/self/maps|frida|magisk|xposed)' | sort -u | head -15 | while read -r c; do
                printf "  ${DR}│${N} ${RR}▸${N} ${W}%s${N}\n" "$c"
            done
        done
        echo ""
        info "External libraries linked:"
        find "$tmp/lib" -name "*.so" 2>/dev/null | while read -r so; do
            strings -n 5 "$so" 2>/dev/null | grep -E '^lib.*\.so' | sort -u | head -15 | while read -r lib; do
                printf "  ${DR}│${N} ${DG}▸${N} ${G}%s${N}\n" "$lib"
            done
        done
    else
        warn "No native libraries"
    fi
    rm -rf "$tmp"
}

# ═══════════════════════════════════════════════════════════
#  TRACKING
# ═══════════════════════════════════════════════════════════

cmd_track() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "TRACKING · $(basename "$apk")"
    _show "Google Analytics"      "$f" '(?i)(UA-[0-9]+-[0-9]+|G-[A-Z0-9]+|firebase_analytics)' 25 "MEDIUM"
    _show "Facebook SDK"          "$f" '(?i)(facebook.*app.*id|fb[_-]?app[_-]?id|com\.facebook)' 20 "MEDIUM"
    _show "Adjust"                "$f" '(?i)(adjust|adjust\.com)' 10 "LOW"
    _show "AppsFlyer"             "$f" '(?i)(appsflyer|appsflyer\.com)' 10 "LOW"
    _show "Mixpanel"              "$f" '(?i)mixpanel' 10 "LOW"
    _show "Segment"               "$f" '(?i)segment\.(io|com)' 10 "LOW"
    _show "Amplitude"             "$f" '(?i)amplitude' 10 "LOW"
    _show "Flurry"                "$f" '(?i)flurry' 10 "LOW"
    _show "Sentry"                "$f" '(?i)sentry\.io' 10 "LOW"
    _show "Crashlytics"           "$f" '(?i)crashlytics' 10 "LOW"
    _show "Branch"                "$f" '(?i)branch\.io' 10 "LOW"
    _show "Braze / Appboy"        "$f" '(?i)(braze|appboy)' 10 "LOW"
    _show "OneSignal"             "$f" '(?i)onesignal' 10 "LOW"
    _show "LeanCloud"             "$f" '(?i)leancloud' 10 "LOW"
    _show "Bugly"                 "$f" '(?i)(bugly|tencent.*bugly)' 10 "MEDIUM"
    _show "Umeng"                 "$f" '(?i)(umeng|com\.umeng)' 15 "MEDIUM"
    _show "Analytics IDs"         "$f" '(?i)(analytics|tracking)[_-]?id["'"'"' :=]+[A-Za-z0-9_-]{6,}' 20 "MEDIUM"
    _show "Advertising IDs"       "$f" '(?i)(advertising[_-]?id|ad[_-]?id|gaid|idfa)' 20 "MEDIUM"
    _show "Location SDKs"         "$f" '(?i)(geofence|geoloc|location.*sdk|beacon)' 15 "LOW"
    _show "Push SDKs"             "$f" '(?i)(fcm|gcm|pushwoosh|airship|urbanairship)' 15 "LOW"
}

# ═══════════════════════════════════════════════════════════
#  DATABASE
# ═══════════════════════════════════════════════════════════

cmd_db() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "DATABASE & STORAGE · $(basename "$apk")"
    _show "SQLite"                "$f" '(?i)(SQLiteDatabase|sqlite3|\.db|\.sqlite|\.sqlite3)' 30 "MEDIUM"
    _show "Shared Prefs"          "$f" '(?i)(SharedPreferences|getSharedPreferences|PreferenceManager)' 25 "LOW"
    _show "SQL keywords"          "$f" '(?i)\b(SELECT|INSERT|UPDATE|DELETE|CREATE TABLE|DROP TABLE|ALTER TABLE|TRUNCATE)\b' 40 "MEDIUM"
    _show "Room ORM"              "$f" '(?i)(androidx\.room|@Entity|@Dao|@Database|@Query|RoomDatabase)' 25 "LOW"
    _show "Realm"                 "$f" '(?i)(Realm|realm-java|io\.realm)' 20 "LOW"
    _show "GreenDAO"              "$f" '(?i)greendao' 15 "LOW"
    _show "DB names"              "$f" '(?i)\.(db|sqlite|realm|db3)\b' 25 "MEDIUM"
    _show "Firebase RT DB"        "$f" '(?i)(FirebaseDatabase|getReference|DatabaseReference)' 25 "MEDIUM"
    _show "Cloud Firestore"       "$f" '(?i)(FirebaseFirestore|Firestore|CollectionReference)' 25 "MEDIUM"
    _show "Connection strings"    "$f" '(?i)(jdbc:|mysql://|postgres://|mongodb://|redis://|sqlite://)' 20 "CRITICAL"
    _show "Encrypted DB"          "$f" '(?i)(SQLCipher|sqlcipher|net\.sqlcipher|encrypted.?db)' 15 "LOW"
    _show "Internal storage"      "$f" '(?i)(getFilesDir|getCacheDir|getDatabasePath|openOrCreateDatabase)' 25 "LOW"
}

# ═══════════════════════════════════════════════════════════
#  PATHS
# ═══════════════════════════════════════════════════════════

cmd_paths() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "FILE PATHS · $(basename "$apk")"
    _list "SD card paths"    "$f" '/sdcard/[a-zA-Z0-9_./-]+' 40
    _list "Storage paths"    "$f" '/storage/[a-zA-Z0-9_./-]+' 40
    _list "Data paths"       "$f" '/data/[a-zA-Z0-9_./-]+' 40
    _list "System paths"     "$f" '/system/[a-zA-Z0-9_./-]+' 40
    _list "Cache paths"      "$f" '/cache/[a-zA-Z0-9_./-]+' 20
    _list "Temp paths"       "$f" '/tmp/[a-zA-Z0-9_./-]+' 20
    _list "Proc paths"       "$f" '/proc/[a-zA-Z0-9_./-]+' 25
    _list "Dev paths"        "$f" '/dev/[a-zA-Z0-9_./-]+' 25
    _list "Mnt paths"        "$f" '/mnt/[a-zA-Z0-9_./-]+' 20
    _list "Vendor paths"     "$f" '/vendor/[a-zA-Z0-9_./-]+' 20
    _list "Android APIs"     "$f" '(?i)(getFilesDir|getCacheDir|getExternalFilesDir|getExternalCacheDir|getDir|getDatabasePath|getExternalStoragePublicDirectory)' 25
    _list "File extensions"  "$f" '\.[a-zA-Z]{2,5}\b' 50
}

# ═══════════════════════════════════════════════════════════
#  COMPONENTS
# ═══════════════════════════════════════════════════════════

cmd_components() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    [ -z "$AAPT" ] && { err "aapt not installed"; exit 1; }
    header "ANDROID COMPONENTS · $(basename "$apk")"
    local out; out=$("$AAPT" dump xmltree "$apk" AndroidManifest.xml 2>/dev/null)
    printf "${DR}▐ ${W}Activities${N}\n"
    "$AAPT" dump badging "$apk" 2>/dev/null | grep "^launchable-activity" | sed "s/launchable-activity: name='//;s/'//" | while read -r a; do
        printf "  ${DR}│${N} ${G}%s${N}\n" "$a"
    done
    echo ""
    printf "${DR}▐ ${W}Permissions count${N}\n"
    local pc; pc=$("$AAPT" dump permissions "$apk" 2>/dev/null | grep -c "uses-permission:")
    printf "  ${DR}│${N} ${R}%s${N} permissions\n\n" "$pc"
    printf "${DR}▐ ${W}Explicitly exported components${N}\n"
    # Parse aapt's tree by component blocks instead of using grep -B5,
    # which can associate an exported flag with the wrong component.
    awk '
        /^  E: (activity|activity-alias|service|receiver|provider) / { comp=$0; name=""; exported="" }
        /^    A: android:name\(/ { line=$0; sub(/^.*android:name\([^)]*\):/,"",line); gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); name=line }
        /^    A: android:exported\(/ { line=$0; sub(/^.*android:exported\([^)]*\):/,"",line); gsub(/^[[:space:]]+|[[:space:]]+$/,"",line); exported=line; if (exported ~ /0x1|true/) { print name } }
    ' <<< "$out" | head -25 | while read -r c; do
        [ -n "$c" ] && printf "  ${DR}│${N} ${RR}!${N} ${G}%s${N}\n" "$c"
    done
    echo ""
    printf "${DR}▐ ${W}Intent filters${N}\n"
    echo "$out" | sed -n 's/.*A: \(android:\(name\|scheme\|host\|pathPattern\|priority\|mimeType\)="[^"]*"\).*/\1/p' | head -40 | while read -r i; do
        printf "  ${DR}│${N} ${G}%s${N}\n" "$i"
    done
    echo ""
    printf "${DR}▐ ${W}Permissions used${N}\n"
    "$AAPT" dump permissions "$apk" 2>/dev/null | grep "uses-permission:" | sed "s/uses-permission: name='//;s/'//" | while read -r p; do
        printf "  ${DR}│${N} ${OR}%s${N}\n" "$p"
    done
}

# ═══════════════════════════════════════════════════════════
#  ADVANCED SECURITY AUDIT (STATIC / AUTHORIZED LAB)
# ═══════════════════════════════════════════════════════════

cmd_attack_surface() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk") || exit 1
    header "ATTACK SURFACE · $(basename "$apk")"
    _show "Exported activities" "$f" '(?i)(<activity[^>]*android:exported="true"|activity[^\n]*exported=true)' 40 "HIGH"
    _show "Exported services"   "$f" '(?i)(<service[^>]*android:exported="true"|service[^\n]*exported=true)' 30 "HIGH"
    _show "Exported receivers"  "$f" '(?i)(<receiver[^>]*android:exported="true"|receiver[^\n]*exported=true)' 30 "HIGH"
    _show "Exported providers"  "$f" '(?i)(<provider[^>]*android:exported="true"|provider[^\n]*exported=true)' 30 "CRITICAL"
    _show "Browsable deep links" "$f" '(?i)(android.intent.action.VIEW|android.intent.category.BROWSABLE|android:scheme=|android:host=)' 40 "HIGH"
    _show "Custom permissions"  "$f" '(?i)(<permission|android:permission=|uses-permission)' 40 "MEDIUM"
    _show "WebView surface"     "$f" '(?i)(WebView|setJavaScriptEnabled|addJavascriptInterface|setAllow(File|Content)Access)' 35 "HIGH"
    _show "IPC surface"         "$f" '(?i)(Binder|AIDL|ContentProvider|BroadcastReceiver|startService|bindService|sendBroadcast)' 40 "MEDIUM"
    _show "Dynamic loading"      "$f" '(?i)(DexClassLoader|InMemoryDexClassLoader|System\.loadLibrary|System\.load\()' 25 "HIGH"
    _show "Native libraries"     "$f" '(?i)(lib/[^ ]+\.so|JNI_OnLoad|native\s+[A-Za-z_])' 30 "MEDIUM"
    _show "Debug/test surface"   "$f" '(?i)(android:debuggable="true"|BuildConfig\.DEBUG|StrictMode|testOnly)' 25 "HIGH"
}

cmd_deeplinks() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk") || exit 1
    header "DEEPLINKS · $(basename "$apk")"
    _show "URI schemes"        "$f" '(?i)android:scheme="[^"]+"' 60 "HIGH"
    _show "URI hosts"          "$f" '(?i)android:host="[^"]+"' 60 "HIGH"
    _show "Path patterns"      "$f" '(?i)android:path(Prefix|Pattern)?="[^"]+"' 60 "MEDIUM"
    _show "VIEW intents"       "$f" '(?i)android.intent.action.VIEW' 20 "MEDIUM"
    _show "BROWSABLE intents"  "$f" '(?i)android.intent.category.BROWSABLE' 20 "HIGH"
    _show "Intent URI parsing" "$f" '(?i)(Intent\.parseUri|Uri\.parse|getData\(\)|getIntent\(\))' 35 "HIGH"
}

cmd_webview() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk") || exit 1
    header "WEBVIEW AUDIT · $(basename "$apk")"
    _show "JavaScript enabled"     "$f" '(?i)setJavaScriptEnabled\s*\(\s*true' 20 "HIGH"
    _show "JavaScript bridge"      "$f" '(?i)addJavascriptInterface' 20 "CRITICAL"
    _show "File access enabled"    "$f" '(?i)setAllowFileAccess\s*\(\s*true' 20 "HIGH"
    _show "Content access enabled" "$f" '(?i)setAllowContentAccess\s*\(\s*true' 20 "HIGH"
    _show "Universal access"       "$f" '(?i)setAllowUniversalAccessFromFileURLs\s*\(\s*true' 20 "CRITICAL"
    _show "Mixed content"          "$f" '(?i)setMixedContentMode|MIXED_CONTENT_' 20 "HIGH"
    _show "SSL error override"     "$f" '(?i)onReceivedSslError|handler\.proceed\s*\(\s*\)' 20 "CRITICAL"
    _show "WebView URL loading"    "$f" '(?i)shouldOverrideUrlLoading|loadUrl\s*\(' 30 "MEDIUM"
}

cmd_permissions_risk() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk") || exit 1
    header "PERMISSION RISK · $(basename "$apk")"
    _show "SMS"              "$f" '(?i)android\.permission\.(SEND_SMS|RECEIVE_SMS|READ_SMS)' 20 "HIGH"
    _show "Contacts"         "$f" '(?i)android\.permission\.(READ_CONTACTS|WRITE_CONTACTS)' 20 "MEDIUM"
    _show "Location"         "$f" '(?i)android\.permission\.(ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|ACCESS_BACKGROUND_LOCATION)' 20 "MEDIUM"
    _show "Microphone"       "$f" '(?i)android\.permission\.RECORD_AUDIO' 10 "HIGH"
    _show "Camera"           "$f" '(?i)android\.permission\.CAMERA' 10 "HIGH"
    _show "Storage/media"    "$f" '(?i)android\.permission\.(READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|READ_MEDIA_[A-Z_]+)' 20 "MEDIUM"
    _show "Overlay"          "$f" '(?i)android\.permission\.SYSTEM_ALERT_WINDOW' 10 "CRITICAL"
    _show "Accessibility"    "$f" '(?i)android\.permission\.BIND_ACCESSIBILITY_SERVICE' 10 "CRITICAL"
    _show "Install packages" "$f" '(?i)android\.permission\.(REQUEST_INSTALL_PACKAGES|INSTALL_PACKAGES)' 10 "HIGH"
}

cmd_audit() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    banner
    info "ADVANCED STATIC AUDIT · $(basename "$apk")"
    cmd_attack_surface "$apk"
    cmd_deeplinks "$apk"
    cmd_webview "$apk"
    cmd_permissions_risk "$apk"
    cmd_vuln "$apk"
    cmd_crypto "$apk"
    echo ""
    line "${RR}"
    ok "AUDIT COMPLETE — findings require manual verification"
    line "${RR}"
}

cmd_labcheck() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local f; f=$(extract_all_text "$apk") || exit 1
    header "LAB CHECKS · $(basename "$apk")"
    _show "Root detection"     "$f" '(?i)(isRooted|RootBeer|/system/xbin/su|/system/bin/su)' 25 "MEDIUM"
    _show "Debugger detection" "$f" '(?i)(isDebuggerConnected|waitForDebugger|TracerPid|Debug\.isDebuggerConnected)' 25 "MEDIUM"
    _show "Frida detection"    "$f" '(?i)(frida-server|frida-gadget|gum-js-loop|frida)' 25 "MEDIUM"
    _show "Xposed/LSPosed"     "$f" '(?i)(XposedBridge|LSPosed|EdXposed|de\.robv\.android\.xposed)' 25 "MEDIUM"
    _show "Integrity checks"   "$f" '(?i)(verifySignatures|PackageManager.*SIGNATURE|tamper|integrity|attestation)' 30 "MEDIUM"
    _show "Emulator detection" "$f" '(?i)(goldfish|ranchu|genymotion|bluestacks|nox|ro\.kernel\.qemu)' 25 "LOW"
    _show "TLS pinning"        "$f" '(?i)(CertificatePinner|X509TrustManager|TrustManager|ssl.?pinning)' 25 "MEDIUM"
    warn "Labcheck is detection-only; it does not disable or bypass these controls."
}

# ═══════════════════════════════════════════════════════════
#  COMBINED
# ═══════════════════════════════════════════════════════════

cmd_hunt() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    banner
    info "FULL HUNT · $(basename "$apk")"
    cmd_net "$apk"
    cmd_api "$apk"
    cmd_secrets "$apk"
    cmd_cloud "$apk"
    cmd_auth "$apk"
    cmd_payment "$apk"
    cmd_comm "$apk"
    cmd_mal "$apk"
    cmd_vuln "$apk"
    cmd_bypass "$apk"
    cmd_crypto "$apk"
    cmd_decrypt "$apk"
    cmd_offensive "$apk"
    cmd_track "$apk"
    cmd_db "$apk"
    echo ""
    line "${RR}"
    ok "HUNT COMPLETE"
    line "${RR}"
}

cmd_fast() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    banner
    info "FAST SCAN · $(basename "$apk")"
    local f; f=$(extract_all_text "$apk")
    header "QUICK FINDINGS"
    local total=0
    for pattern in \
        'https?://[a-zA-Z0-9._~:/?#@!$&()*+,;=%-]{6,}' \
        'AIza[0-9A-Za-z_-]{35}' \
        'AKIA[0-9A-Z]{16}' \
        '[0-9]{8,10}:[A-Za-z0-9_-]{35}' \
        'sk_live_[A-Za-z0-9]{20,}' \
        'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
        '[a-z0-9-]+\.firebaseio\.com' \
        'xox[baprs]-[0-9A-Za-z-]{10,}' \
        'Runtime\.getRuntime\(\)\.exec' \
        'DexClassLoader' \
        'addJavascriptInterface' \
        'isDebuggerConnected' \
        'frida' ; do
        local c
        c=$(grep -oaE "$pattern" "$f" 2>/dev/null | sort -u | wc -l)
        total=$((total + c))
    done
    if [ "$total" -gt 0 ]; then
        ok "$total interesting findings. Run 'zodiac hunt $1' for details."
    else
        warn "No obvious findings"
    fi
}

cmd_report() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    local base; base=$(basename "$apk" .apk)
    local out="$WORK_DIR/${base}_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "═══════════════════════════════════════════════════════════"
        echo "  ZODIAC REPORT"
        echo "  APK: $(basename "$apk")"
        echo "  Generated: $(date)"
        echo "  SHA256: $(sha256sum "$apk" 2>/dev/null | cut -d' ' -f1)"
        echo "═══════════════════════════════════════════════════════════"
        cmd_info "$apk"
        cmd_permissions "$apk"
        cmd_cert "$apk"
        cmd_net "$apk"
        cmd_api "$apk"
        cmd_secrets "$apk"
        cmd_cloud "$apk"
        cmd_auth "$apk"
        cmd_payment "$apk"
        cmd_comm "$apk"
        cmd_mal "$apk"
        cmd_vuln "$apk"
        cmd_bypass "$apk"
        cmd_crypto "$apk"
        cmd_decrypt "$apk"
        cmd_offensive "$apk"
        cmd_track "$apk"
        cmd_db "$apk"
        cmd_paths "$apk"
    } 2>&1 | tee "$out"
    echo ""
    ok "Report saved: $out"
}

# ═══════════════════════════════════════════════════════════
#  BASIC
# ═══════════════════════════════════════════════════════════

cmd_list() {
    header "AVAILABLE APKs"
    local n=0
    printf "  ${BR}%-4s${N} ${W}%-45s${N} ${OR}%10s${N}\n" "#" "FILE" "SIZE"
    printf "  ${DR}"; for ((i=0; i<62; i++)); do printf "─"; done; printf "${N}\n"
    for apk in "$APK_DIR"/*.apk; do
        [ -e "$apk" ] || continue
        n=$((n+1))
        printf "  ${RR}%-4d${N} ${G}%-45s${N} ${OR}%10s${N}\n" "$n" "$(basename "$apk")" "$(du -h "$apk" | cut -f1)"
    done
    echo ""
    [ "$n" -eq 0 ] && warn "No APK files" || ok "$n APK(s)"
}

cmd_download() {
    local url="$1"
    [ -z "$url" ] && { err "URL required"; return 1; }
    case "$url" in http://*|https://*) ;; *) err "Only http(s) URLs are supported"; return 1;; esac
    header "DOWNLOAD"
    info "$url"
    local fn
    fn=$(basename "${url%%\?*}")
    [[ "$fn" != *.apk ]] && fn="app_$(date +%s).apk"
    # Prevent path traversal through a crafted URL path.
    fn=${fn##*/}
    local dest="$APK_DIR/$fn"
    local rc=1
    if have curl; then
        curl -fL --progress-bar -A "Mozilla/5.0 (Android)" -o "$dest" "$url" && rc=0
    elif have wget; then
        wget -q --show-progress -O "$dest" "$url" && rc=0
    else
        err "curl or wget is required"; return 1
    fi
    if [ "$rc" -eq 0 ] && [ -s "$dest" ] && unzip -tq "$dest" >/dev/null 2>&1; then
        ok "Saved: $dest"
        return 0
    fi
    rm -f "$dest"
    err "Download failed or response is not a valid ZIP/APK"
    return 1
}

cmd_info() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found: $1"; exit 1; }
    [ -z "$AAPT" ] && { err "aapt not installed"; exit 1; }
    header "APK INFO"
    local out; out=$("$AAPT" dump badging "$apk" 2>/dev/null)
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "File"         "$(basename "$apk")"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Package"      "$(echo "$out" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "App Name"     "$(echo "$out" | sed -n "s/^application-label:'\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Version"      "$(echo "$out" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Version Code" "$(echo "$out" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Min SDK"      "$(echo "$out" | sed -n "s/.*sdkVersion:'\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Target SDK"   "$(echo "$out" | sed -n "s/.*targetSdkVersion:'\([^']*\)'.*/\1/p" | head -1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${OR}%s${N}\n" "Size"         "$(du -h "$apk" | cut -f1)"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${G}%s${N}\n" "Permissions"  "$(echo "$out" | grep -c 'uses-permission')"
    printf "  ${RR}▸${N} ${B}%-16s${N} ${DR}│${N} ${DG}%s${N}\n" "SHA256"       "$(sha256sum "$apk" | cut -d' ' -f1)"
    echo ""
}

cmd_manifest() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    [ -z "$AAPT" ] && { err "aapt not installed"; exit 1; }
    header "ANDROID MANIFEST"
    "$AAPT" dump xmltree "$apk" AndroidManifest.xml
}

cmd_cert() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    header "CERTIFICATES"
    have openssl || { err "openssl not installed"; exit 1; }
    local tmp; tmp=$(mktemp -d)
    unzip -o -q "$apk" "META-INF/*" -d "$tmp" 2>/dev/null
    local found=0
    for cert in "$tmp"/META-INF/*.RSA "$tmp"/META-INF/*.DSA "$tmp"/META-INF/*.EC; do
        [ -f "$cert" ] || continue
        found=1
        printf "  ${RR}▸${N} ${W}%s${N}\n" "$(basename "$cert")"
        openssl pkcs7 -inform DER -in "$cert" -print_certs -text -noout 2>/dev/null \
            | grep -E "Subject:|Issuer:|Not Before|Not After|Serial|Signature Algorithm" \
            | while IFS= read -r l; do printf "    ${DR}│${N} ${G}%s${N}\n" "$l"; done
        echo ""
    done
    [ "$found" -eq 0 ] && warn "No certificates"
    rm -rf "$tmp"
}

cmd_permissions() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    [ -z "$AAPT" ] && { err "aapt not installed"; exit 1; }
    header "PERMISSIONS · $(basename "$apk")"
    local CRIT='BIND_ACCESSIBILITY_SERVICE|BIND_DEVICE_ADMIN|SYSTEM_ALERT_WINDOW|REQUEST_INSTALL_PACKAGES|MANAGE_EXTERNAL_STORAGE|PACKAGE_USAGE_STATS|BIND_NOTIFICATION_LISTENER_SERVICE|BIND_VPN_SERVICE|BIND_INPUT_METHOD'
    local HIGH='READ_SMS|SEND_SMS|RECEIVE_SMS|READ_CONTACTS|WRITE_CONTACTS|READ_CALL_LOG|WRITE_CALL_LOG|CALL_PHONE|READ_PHONE_STATE|RECORD_AUDIO|CAMERA|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|READ_PHONE_NUMBERS|PROCESS_OUTGOING_CALLS|ANSWER_PHONE_CALLS'
    local total=0 crit=0 high=0
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        total=$((total+1))
        if echo "$p" | grep -qE "$CRIT"; then
            crit=$((crit+1)); printf "  ${RR}[▓▓]${N}  ${W}%s${N}\n" "$p"
        elif echo "$p" | grep -qE "$HIGH"; then
            high=$((high+1)); printf "  ${R}[▓ ]${N}  ${G}%s${N}\n" "$p"
        else
            printf "  ${DR}[░ ]${N}  ${DG}%s${N}\n" "$p"
        fi
    done < <("$AAPT" dump permissions "$apk" 2>/dev/null | grep "uses-permission:" | sed "s/uses-permission: name='//;s/'//")
    echo ""
    printf "  ${B}Total:${N} ${W}%d${N}   ${RR}Critical:${N} ${BR}%d${N}   ${R}High:${N} ${OR}%d${N}\n" "$total" "$crit" "$high"
}

cmd_search() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    local pat="$2"
    [ -z "$pat" ] && { err "Pattern required"; exit 1; }
    local f; f=$(extract_all_text "$apk")
    header "SEARCH '$pat'"
    local res; res=$(grep -aiE "$pat" "$f" | sort -u)
    local cnt; cnt=$(echo "$res" | grep -c . 2>/dev/null || echo 0)
    if [ "$cnt" -eq 0 ]; then
        warn "No matches"
    else
        ok "$cnt result(s)"
        echo ""
        echo "$res" | head -100 | while IFS= read -r l; do
            [ ${#l} -gt 130 ] && l="${l:0:127}..."
            printf "  ${DR}│${N} ${G}%s${N}\n" "$l"
        done
        [ "$cnt" -gt 100 ] && echo -e "\n  ${DD}... +$((cnt-100)) more${N}"
    fi
}

cmd_unzip() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    local out="$APK_DIR/$(basename "$apk" .apk)_extracted"
    mkdir -p "$out"
    unzip -o "$apk" -d "$out" > /dev/null
    ok "Extracted: $out"
}

cmd_decompile() {
    local apk; apk=$(resolve_apk "$1") || { err "APK not found"; exit 1; }
    local out="$APK_DIR/$(basename "$apk" .apk)_decompiled"
    mkdir -p "$out"
    if have jadx; then
        info "Using jadx..."
        jadx -d "$out/jadx" "$apk" && ok "Output: $out/jadx"
    elif have apktool; then
        info "Using apktool..."
        apktool d "$apk" -o "$out/apktool" -f && ok "Output: $out/apktool"
    else
        err "Install jadx or apktool and ensure it is in PATH"
        exit 1
    fi
}

cmd_clean() {
    header "CLEAN CACHE"
    local size; size=$(du -sh "$WORK_DIR" 2>/dev/null | cut -f1)
    info "Cache: $size"
    rm -rf "$WORK_DIR"/*
    ok "Cleared"
}

cmd_install() {
    if [ -n "$1" ]; then
        cmd_download "$1"
        return
    fi
    local target="${PREFIX:-/usr}/bin/zodiac"
    if [ -w "$(dirname "$target")" ]; then
        cp "$0" "$target" && chmod +x "$target"
        ok "Installed: $target"
    else
        err "No write access"
        echo "  cp $0 $target && chmod +x $target"
        exit 1
    fi
}

cmd_prompt() {
    header "KALI PROMPT"
    local bashrc="$HOME/.bashrc"

    sed -i '/_zodiac_ps1/,/^}/d' "$bashrc" 2>/dev/null
    sed -i '/_zodiac_prompt/,/^}/d' "$bashrc" 2>/dev/null
    sed -i '/ZODIAC KALI/d' "$bashrc" 2>/dev/null
    sed -i '/zodiac_ps1/d' "$bashrc" 2>/dev/null
    sed -i '/PROMPT_COMMAND.*zodiac/d' "$bashrc" 2>/dev/null
    sed -i '/^PS1=/d' "$bashrc" 2>/dev/null

    cat >> "$bashrc" << 'PROMPT_BLOCK'

# ZODIAC KALI PROMPT
_zodiac_ps1() {
    if [[ "$PWD" == "$HOME/zodiac"* ]]; then
        PS1='\[\033[1;31m\]┌──(\[\033[1;37m\]root㉿kali\[\033[1;31m\])-[\[\033[1;91m\]\w\[\033[1;31m\]]\n\[\033[1;31m\]└─\[\033[1;91m\]#\[\033[0m\] '
    fi
}
PROMPT_COMMAND="_zodiac_ps1"
PROMPT_BLOCK

    ok "Prompt installed (pure red)"
    info "Run: exec bash"
}

# ═══════════════════════════════════════════════════════════
#  HELP
# ═══════════════════════════════════════════════════════════

_sec() {
    local title="$1"; shift
    printf "  ${RR}▐${N} ${B}${W}%s${N}\n" "$title"
    local entry cmd desc pad
    for entry in "$@"; do
        cmd="${entry%%|*}"; desc="${entry#*|}"
        pad=$((30 - ${#cmd})); [ "$pad" -lt 2 ] && pad=2
        printf "    ${BR}%-s${N}%*s${DR}%s${N}\n" "$cmd" "$pad" "" "$desc"
    done
    echo ""
}

cmd_help() {
    banner
    printf "  ${B}${W}USAGE${N}    ${BR}zodiac${N} ${DR}<command> [args]${N}\n\n"

    _sec "◆ DISCOVERY" \
        "list, ls|List available APKs" \
        "install [url]|Download APK or install to PATH" \
        "info <apk>|APK info + SHA256" \
        "manifest <apk>|AndroidManifest.xml" \
        "cert <apk>|Signature certificate" \
        "permissions <apk>|Permission analysis"

    _sec "◆ NETWORK" \
        "net <apk>|Full network scan" \
        "urls <apk>|Only URLs" \
        "ips <apk>|Only IP addresses" \
        "emails <apk>|Only emails" \
        "domains <apk>|Only domains" \
        "api <apk>|REST, GraphQL, gRPC" \
        "paths <apk>|File paths" \
        "strings <apk>|All strings"

    _sec "◆ SECRETS & CLOUD" \
        "secrets <apk>|Keys, tokens, passwords" \
        "cloud <apk>|AWS, GCP, Azure, Firebase" \
        "auth <apk>|JWT, OAuth, SAML, MFA" \
        "payment <apk>|Stripe, PayPal, crypto" \
        "comm <apk>|Telegram, Discord, Slack"

    _sec "◆ MALICIOUS & THREAT" \
        "mal <apk>|★ Full malicious scan" \
        "vuln <apk>|★ Vulnerability patterns" \
        "bypass <apk>|★ Bypass technique detection" \
        "track <apk>|Tracking SDKs"

    _sec "◆ OFFENSIVE & DECRYPT" \
        "offensive <apk>|★ Attack-pattern detection" \
        "attack-surface <apk>|★ Exported/IPC/WebView surface" \
        "deeplinks <apk>|Deep-link security audit" \
        "webview <apk>|WebView security audit" \
        "perm-risk <apk>|Sensitive permission risk" \
        "labcheck <apk>|Lab-only control detection" \
        "crypto <apk>|★ Crypto & cipher analysis" \
        "decrypt <apk>|★ Decryption analysis" \
        "native <apk>|JNI, .so, syscalls"

    _sec "◆ SYSTEM" \
        "db <apk>|SQLite, Room, Realm" \
        "components <apk>|Exported components"

    _sec "◆ COMBINED" \
        "hunt <apk>|★★ FULL SCAN" \
        "fast <apk>|Quick scan" \
        "report <apk>|Save report to file"

    _sec "◆ UTILITIES" \
        "search <apk> <regex>|Custom regex search" \
        "unzip <apk>|Extract APK" \
        "decompile <apk>|Decompile (jadx/apktool)" \
        "clean|Clear cache" \
        "install|Install to PATH" \
        "prompt|Red Kali prompt" \
        "version|Show version"

    printf "  ${RR}▐${N} ${B}${W}EXAMPLES${N}\n"
    printf "    ${DR}\$${N} zodiac install https://example.com/app.apk\n"
    printf "    ${DR}\$${N} zodiac hunt app.apk\n"
    printf "    ${DR}\$${N} zodiac mal app.apk\n"
    printf "    ${DR}\$${N} zodiac offensive app.apk\n"
    printf "    ${DR}\$${N} zodiac audit app.apk\n"
    printf "    ${DR}\$${N} zodiac attack-surface app.apk\n"
    printf "    ${DR}\$${N} zodiac decrypt app.apk\n"
    printf "    ${DR}\$${N} zodiac crypto app.apk\n\n"

    printf "  ${RR}▐${N} ${B}${W}ENVIRONMENT${N}\n"
    printf "    ${BR}ZODIAC_DIR${N}   ${DR}APK storage (default: ~/zodiac/apks)${N}\n"
    printf "    ${BR}ZODIAC_WORK${N}  ${DR}cache dir (default: ~/zodiac/.cache)${N}\n\n"

    line "${RR}"
    printf "  ${DR}Zodiac v${VERSION} — For authorized security testing only${N}\n"
    line "${RR}"
}

# ═══════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════

main() {
    local cmd="${1:-help}"; shift || true
    case "$cmd" in
        list|ls)                cmd_list ;;
        install)                cmd_install "$@" ;;
        info|in)                cmd_info "$@" ;;
        manifest|mf)            cmd_manifest "$@" ;;
        cert|certificates)      cmd_cert "$@" ;;
        permissions|perms)      cmd_permissions "$@" ;;

        net|network)            cmd_net "$@" ;;
        urls|url)               cmd_urls "$@" ;;
        ips|ip)                 cmd_ips "$@" ;;
        emails|email)           cmd_emails "$@" ;;
        domains|dom)            cmd_domains "$@" ;;
        api|endpoints)          cmd_api "$@" ;;
        paths|files)            cmd_paths "$@" ;;
        strings|str)            cmd_strings "$@" ;;

        secrets|keys|sec)       cmd_secrets "$@" ;;
        cloud)                  cmd_cloud "$@" ;;
        auth)                   cmd_auth "$@" ;;
        payment|pay)            cmd_payment "$@" ;;
        comm|social)            cmd_comm "$@" ;;

        mal|malicious)          cmd_mal "$@" ;;
        vuln|vulns)             cmd_vuln "$@" ;;
        bypass|evasion)         cmd_bypass "$@" ;;
        track|analytics)        cmd_track "$@" ;;

        offensive)               cmd_offensive "$@" ;;
        attack-surface|surface) cmd_attack_surface "$@" ;;
        deeplinks|deep-links)   cmd_deeplinks "$@" ;;
        webview|web)            cmd_webview "$@" ;;
        perm-risk|permission-risk) cmd_permissions_risk "$@" ;;
        labcheck|lab-check)     cmd_labcheck "$@" ;;
        crypto|ciphers)         cmd_crypto "$@" ;;
        decrypt|decryption)     cmd_decrypt "$@" ;;

        native|jni|so)          cmd_native "$@" ;;
        db|database)            cmd_db "$@" ;;
        components|comp)        cmd_components "$@" ;;

        audit|assess|assessment) cmd_audit "$@" ;;
        hunt|all|full)          cmd_hunt "$@" ;;
        fast|quick)             cmd_fast "$@" ;;
        report)                 cmd_report "$@" ;;

        search|grep|find)       cmd_search "$@" ;;
        unzip|extract)          cmd_unzip "$@" ;;
        decompile|dec)          cmd_decompile "$@" ;;
        clean)                  cmd_clean ;;
        prompt)                 cmd_prompt ;;

        help|-h|--help)         cmd_help ;;
        version|-v|--version)   echo "Zodiac v$VERSION" ;;
        *)
            echo ""
            echo -e "${R}[✗]${N} ${BR}Unknown command:${N} ${W}$cmd${N}"
            echo ""
            echo -e "  ${DR}→ Run ${N}${BR}zodiac help${N}${DR} to see available commands.${N}"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"