# Zodiac

**APK Reverse Engineering & Threat Analysis Toolkit**

A pure-Bash APK analysis tool that runs natively on Termux and Linux. No Python, no heavy dependencies — just `bash`, `unzip`, and the standard Unix toolchain.

Zodiac scans an APK against **400+ detection patterns** across **23 categories** and produces structured findings with severity levels, risk scoring, and exportable reports.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Detection Categories](#detection-categories)
- [Advanced Features](#advanced-features)
- [Environment Variables](#environment-variables)
- [Examples](#examples)
- [Requirements](#requirements)
- [Legal](#legal)

---

## Features

- **Pure Bash** — no Python, no Node, no JVM required for the core scanner
- **Termux-native** — built for Android terminal workflows
- **400+ regex patterns** covering network, secrets, malware, crypto, vulnerabilities, and more
- **Severity classification** — CRITICAL / HIGH / MEDIUM / LOW / INFO
- **Risk scoring** — 0–100 score with verdict
- **Entropy analysis** — detect packed or encrypted sections
- **HTML reports** — dark-themed, self-contained
- **MITRE ATT&CK Mobile mapping** — auto-map findings to techniques
- **JWT decoder** — decode tokens found in the APK
- **Batch mode** — scan an entire folder
- **Caching** — extraction is cached by SHA256
- **No hidden network calls** — all analysis is local (VirusTotal is opt-in)

---

## Installation

### Termux

```bash
pkg update && pkg upgrade
pkg install -y git unzip aapt openssl curl

git clone https://github.com/Vandal/zodiac.git ~/zodiac
cd ~/zodiac
chmod +x zodiac.sh
./zodiac.sh install
```

### Linux

```bash
sudo apt install -y unzip aapt openssl curl git
git clone https://github.com/Vandal/zodiac.git ~/zodiac
cd ~/zodiac
chmod +x zodiac.sh
sudo ./zodiac.sh install
```

### Verify

```bash
zodiac version
zodiac help
```

---

## Quick Start

```bash
# Download an APK
zodiac install https://f-droid.org/F-Droid.apk

# Full scan
zodiac hunt F-Droid.apk

# Quick scan
zodiac fast F-Droid.apk

# Save a full report
zodiac report F-Droid.apk
```

---

## Commands

### Discovery

| Command | Description |
|---|---|
| `zodiac list` | List available APKs |
| `zodiac install <url>` | Download an APK |
| `zodiac info <apk>` | Package info + SHA256 |
| `zodiac manifest <apk>` | AndroidManifest.xml tree |
| `zodiac cert <apk>` | Signature certificate |
| `zodiac permissions <apk>` | Permission risk analysis |

### Network

| Command | Description |
|---|---|
| `zodiac net <apk>` | Full network scan |
| `zodiac urls <apk>` | URLs only |
| `zodiac ips <apk>` | IP addresses only |
| `zodiac emails <apk>` | Emails only |
| `zodiac domains <apk>` | Domains only |
| `zodiac api <apk>` | REST / GraphQL / gRPC endpoints |
| `zodiac paths <apk>` | File paths |
| `zodiac strings <apk>` | Extracted strings |

### Secrets & Cloud

| Command | Description |
|---|---|
| `zodiac secrets <apk>` | Keys, tokens, passwords |
| `zodiac cloud <apk>` | AWS / GCP / Azure / Firebase |
| `zodiac auth <apk>` | JWT / OAuth / SAML / MFA |
| `zodiac payment <apk>` | Stripe / PayPal / crypto |
| `zodiac comm <apk>` | Telegram / Discord / Slack |

### Malicious & Threat

| Command | Description |
|---|---|
| `zodiac mal <apk>` | Full malicious scan |
| `zodiac vuln <apk>` | Vulnerability patterns |
| `zodiac bypass <apk>` | Bypass technique detection |
| `zodiac track <apk>` | Tracking SDKs |

### Offensive & Crypto

| Command | Description |
|---|---|
| `zodiac offensive <apk>` | Attack pattern detection |
| `zodiac attack-surface <apk>` | Exported components / IPC / WebView |
| `zodiac deeplinks <apk>` | Deep-link audit |
| `zodiac webview <apk>` | WebView audit |
| `zodiac perm-risk <apk>` | Sensitive permission risk |
| `zodiac labcheck <apk>` | Lab-only control detection |
| `zodiac crypto <apk>` | Crypto & cipher analysis |
| `zodiac decrypt <apk>` | Decryption analysis |
| `zodiac native <apk>` | JNI / .so / syscalls |

### System

| Command | Description |
|---|---|
| `zodiac db <apk>` | SQLite / Room / Realm |
| `zodiac components <apk>` | Exported components |

### Advanced

| Command | Description |
|---|---|
| `zodiac entropy <apk>` | Entropy analysis |
| `zodiac risk <apk>` | Risk score 0–100 |
| `zodiac html <apk>` | HTML report |
| `zodiac jwt <apk>` | Decode JWT tokens |
| `zodiac whois <apk>` | WHOIS + DNS + alive check |
| `zodiac dns <apk>` | DNS lookup |
| `zodiac mitre <apk>` | MITRE ATT&CK Mobile mapping |
| `zodiac batch [dir]` | Analyze an entire folder |
| `zodiac vt <apk>` | VirusTotal hash lookup |

### Combined

| Command | Description |
|---|---|
| `zodiac hunt <apk>` | Full scan (all categories) |
| `zodiac fast <apk>` | Quick scan |
| `zodiac report <apk>` | Save full report to file |
| `zodiac audit <apk>` | Advanced static audit |

### Utilities

| Command | Description |
|---|---|
| `zodiac search <apk> <regex>` | Custom regex search |
| `zodiac unzip <apk>` | Extract APK |
| `zodiac decompile <apk>` | Decompile with jadx or apktool |
| `zodiac clean` | Clear cache |
| `zodiac prompt` | Install Kali-style prompt |
| `zodiac version` | Show version |

---

## Detection Categories

Zodiac searches APK contents across the following categories:

**Network**
HTTP/HTTPS, FTP, WebSocket, Intent URLs, Deep links, IPv4, IPv6, CIDR, Domains, Emails, MAC addresses, Tor .onion, I2P, Proxy configs, DNS servers, User agents, Port numbers, FTP credentials

**API**
REST paths, Base URLs, HTTP methods, Query params, gRPC services, Swagger/OpenAPI, GraphQL operations, Content-Types, API versions, Rate limits, CORS headers, Cookie names, X-Headers

**Secrets**
API keys, Bearer tokens, Access/Refresh/ID/Session tokens, Client/App secrets, Passwords, Usernames, Private/Public/SSH/PGP keys, Encryption keys, HMAC keys, Salt, IV/Nonce, Seed phrases, Base64 blobs, Hex strings, UUIDs, Env variables, .env entries, Connection strings, Hardcoded credentials, Basic Auth headers

**Cloud**
AWS Access/Secret/Session keys, S3 buckets, Regions, Firebase RTDB/Storage/Project, Google API keys, OAuth Client IDs, GCP service accounts, Azure Storage/Connection strings/Tenant IDs, Heroku, DigitalOcean, Cloudflare, Alibaba OSS/AccessKey, Tencent COS, Oracle Cloud

**Auth**
JWT tokens, JWT secrets, Basic Auth, OAuth URLs/scopes, Session IDs, Cookies, SAML, OpenID, CSRF tokens, API auth headers, PKCE, MFA/2FA, Captcha keys

**Payment**
Stripe (live/test/publishable/restricted), PayPal, Square, Braintree, Adyen, Razorpay, Bitcoin/Ethereum/Monero/Litecoin/Tron wallets, IBAN, SWIFT/BIC, Credit cards, CVV, Iranian Sheba, Iranian card numbers

**Communication**
Telegram bot tokens/URLs/chat IDs, Discord webhooks/bot tokens/invites, Slack tokens/webhooks, Twilio SIDs/Auth tokens, SendGrid, Mailgun, Mailchimp, AWS SES, WhatsApp, Signal, Matrix, Rocket.Chat, Mattermost

**Malicious**
Shell interpreters, chmod/chown, destructive commands, package install, process control, pipes to shell, Base64 pipes, su binary paths, Superuser apps, root managers, exploits/CVEs, Runtime.exec, ProcessBuilder, Reflection API, DexClassLoader, native lib loading, shellcode, JNI, JavaScript exec, SQL command exec, anti-debug, anti-VM, anti-emulator, anti-Frida, anti-Xposed, anti-Magisk, anti-Substrate, anti-hook, integrity checks, emulator artifacts, sandbox detection, time checks, environment checks, obfuscators, packers, VM obfuscation, Base64 decode, XOR decryption, cipher usage, SMS access, contacts, call logs, location tracking, camera, microphone, clipboard, screen capture, keylogger APIs, account access, calendar, sensors, file access, call audio, Bluetooth, browser history, WhatsApp/Telegram data, BOOT_COMPLETED, AlarmManager, JobScheduler, WorkManager, Device Admin, foreground services, auto-start, sync adapters, accessibility abuse, device admin abuse, notification listener, VPN service, overlay attacks, usage stats, input method, JS Bridge, JS enabled, WebView loading, file access WebView, SSL errors ignored, SSL pinning, trust all certs, hostname verifier, cleartext allowed, cryptominer, mining pools, wallet addresses, ransomware, file encryption, ransom notes, payment demands, RAT commands, backdoor hints, C2 patterns, botnet hints, keylogger

**Vulnerabilities**
SQL injection, raw SQL methods, command injection, path traversal, file path concat, deserialization, intent redirection, implicit intents, exported components, PendingIntent, WebView exploits, SSL issues, broadcast receivers, Zip Slip, XXE, race conditions, insecure crypto, weak randomness, hardcoded HTTP, debug enabled, backup enabled, task hijacking, StrandHogg, tapjacking, overlay attacks, insecure broadcast, content provider, file permissions, dynamic code load, WebView JS enabled, WebView file access, exported activity/service/receiver/provider

**Bypass**
SSL pinning bypass, root detection bypass, debug detection, integrity bypass, Frida detection, Xposed detection, Magisk detection, Substrate detection, emulator bypass, proxy detection, VPN detection, screen recording detection, screenshot detection, time tamper, location spoof, app cloning, anti-analysis

**Crypto**
AES (modes + padding), DES/3DES, RSA (padding), ECC/EC, RC4/ARC4, RC2, Blowfish, Twofish, ChaCha20, Salsa20, MD5, SHA family, SHA1, bcrypt/scrypt/argon2/pbkdf2, HMAC, key sizes, weak key sizes, IV/Nonce, static IV, Keystore, Keystore files, BouncyCastle, SpongyCastle, Conscrypt, weak random, SecureRandom, cipher instances, KeyGenerator, MessageDigest, Signature, KeyAgreement, certificate pinning, hash algorithms, key derivation, Base64/Hex encoding, encryption flags, crypto providers

**Offensive**
Attack surface, injection points, debug interfaces, exported activities/services/receivers/providers, deep links, intent filters, browsable, app links, custom URL schemes, file providers, root paths, setuid binaries, busybox usage, netcat usage, socat usage, reverse shells, curl pipes, cron jobs, init scripts, hooks (LD_PRELOAD), ptrace usage, memory injection, antidebug native, syscalls, memory corruption, format strings

**Decryption**
Hardcoded keys/IVs/salts, static passwords, decryption routines, key derivation, XOR keys, Base64/Hex decode, cipher init DECRYPT/ENCRYPT mode, `.doFinal` calls, MessageDigest, public key import, certificate loading, Keystore access, Android Keystore, weak crypto, ECB mode, deterministic, length extension, padding oracle, known plaintext, bit-flip attacks, CBC issues, key reuse

**Native**
Native libraries (.so), JNI functions, native syscalls, native crypto, anti-debug native, linked external libraries

**Tracking**
Google Analytics, Facebook SDK, Adjust, AppsFlyer, Mixpanel, Segment, Amplitude, Flurry, Sentry, Crashlytics, Branch, Braze/Appboy, OneSignal, LeanCloud, Bugly, Umeng, analytics IDs, advertising IDs, location SDKs, push SDKs

**Database**
SQLite, Shared Preferences, SQL keywords, Room ORM, Realm, GreenDAO, DB names, Firebase RTDB, Cloud Firestore, connection strings, encrypted DBs (SQLCipher), internal storage

**Paths**
/sdcard, /storage, /data, /system, /cache, /tmp, /proc, /dev, /mnt, /vendor, Android storage APIs, file extensions

**Components**
Activities, permissions count, exported components, intent filters, permissions used

---

## Advanced Features

### Entropy Analysis

```bash
zodiac entropy app.apk
```

Computes Shannon entropy per file inside the APK. Values ≥ 7.5 typically indicate encrypted or packed data.

### Risk Score

```bash
zodiac risk app.apk
```

Produces a 0–100 score based on weighted indicators with a verdict.

### HTML Report

```bash
zodiac html app.apk
```

Generates a self-contained dark-themed HTML report — open with `termux-open`.

### MITRE ATT&CK Mobile Mapping

```bash
zodiac mitre app.apk
```

Maps findings to ATT&CK Mobile techniques across Initial Access, Persistence, Privilege Escalation, Defense Evasion, Credential Access, Discovery, Collection, C2, Exfiltration, and Impact.

### Batch Mode

```bash
zodiac batch ~/apks/
```

Analyzes all APKs in a directory and writes per-file results to a timestamped output folder.

### VirusTotal (Opt-in)

```bash
export VT_API_KEY="your_api_key"
zodiac vt app.apk
```

Queries VirusTotal by SHA256. No file is uploaded — hash lookup only.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `ZODIAC_DIR` | `~/zodiac/apks` | APK storage directory |
| `ZODIAC_WORK` | `~/zodiac/.cache` | Cache directory |
| `VT_API_KEY` | — | VirusTotal API key |

---

## Examples

```bash
# Basic workflow
zodiac install https://example.com/app.apk
zodiac info app.apk
zodiac permissions app.apk
zodiac hunt app.apk

# Focused analysis
zodiac secrets app.apk
zodiac mal app.apk
zodiac crypto app.apk
zodiac attack-surface app.apk

# Advanced
zodiac risk app.apk
zodiac entropy app.apk
zodiac mitre app.apk
zodiac html app.apk

# Custom search
zodiac search app.apk 'firebase'
zodiac search app.apk 'api_key.*'
zodiac search app.apk 'https?://[a-z]+\.example\.com'
```

---

## Requirements

**Core**
- `bash` 4.0+
- `unzip`
- `strings` (binutils)
- `grep`
- `sha256sum` (coreutils)

**Optional**
- `aapt` (Android SDK) — for manifest and permission parsing
- `openssl` — for certificate inspection
- `curl` — for downloads and VirusTotal
- `jadx` or `apktool` — for decompilation
- `whois` — for domain lookups
- `xxd` or `hexdump` — for hex view

Termux install:

```bash
pkg install -y unzip binutils coreutils openssl curl aapt whois
```

---

## Legal

Zodiac is a **static analysis tool**. It reads APK files and reports findings. It does not:

- Modify, repackage, or resign APKs
- Inject code or payloads
- Exploit vulnerabilities
- Bypass security controls at runtime
- Communicate with external services unless you explicitly enable VirusTotal

**Use only on APKs you own or have explicit written permission to analyze.** Unauthorized analysis of applications may violate local laws and terms of service. The authors are not responsible for misuse.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request

---

## Author

**Vandal**

- GitHub: [@Vandal](https://github.com/Vandal)