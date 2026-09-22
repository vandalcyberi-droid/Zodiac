# ZODIAC

APK Reverse Engineering · Threat Intelligence · Security Analysis

<p align="center">
  <img src="https://img.shields.io/badge/version-8.0.0-111111?style=for-the-badge&logo=android&logoColor=white" alt="Version">
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20Termux-111111?style=for-the-badge&logo=linux&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/language-Bash-111111?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/focus-APK%20Security-111111?style=for-the-badge&logo=android&logoColor=white" alt="APK Security">
</p><p align="center">
  <b>ZODIAC</b> is a command-line toolkit for inspecting Android APKs,
  extracting security-relevant artifacts, and performing pattern-based
  threat and application-security analysis.
</p><p align="center">
  <i>One APK. One command line. A large amount of security-relevant evidence.</i>
</p>---

Table of Contents

- "Overview" (#overview)
- "What ZODIAC Does" (#what-zodiac-does)
- "Capabilities" (#capabilities)
- "Command Map" (#command-map)
- "Installation" (#installation)
- "Quick Start" (#quick-start)
- "Examples" (#examples)
- "Scan Modes" (#scan-modes)
- "Output & Reports" (#output--reports)
- "Environment Variables" (#environment-variables)
- "Dependencies" (#dependencies)
- "Detection Philosophy" (#detection-philosophy)
- "False Positives" (#false-positives)
- "Limitations" (#limitations)
- "Responsible Use" (#responsible-use)
- "Project Structure" (#project-structure)
- "Roadmap" (#roadmap)
- "License" (#license)

---

Overview

ZODIAC is a Bash-based Android APK analysis toolkit designed for researchers, mobile-security analysts, malware triage, reverse engineers, and security learners.

It combines several common APK inspection workflows behind a single command-line interface:

             ┌──────────────────────────┐
             │          APK              │
             └────────────┬─────────────┘
                          │
             ┌────────────▼─────────────┐
             │         ZODIAC            │
             │   Analysis Orchestrator   │
             └────────────┬─────────────┘
                          │
       ┌──────────────────┼──────────────────┐
       │                  │                  │
       ▼                  ▼                  ▼
   Metadata            Artifacts          Patterns
       │                  │                  │
       ├─ Manifest        ├─ URLs            ├─ Threats
       ├─ Certificate     ├─ IPs             ├─ Vulns
       ├─ Permissions     ├─ Domains         ├─ Secrets
       └─ Components      ├─ APIs            ├─ Crypto
                          ├─ Strings         └─ Native
                          └─ Paths

The goal is not to replace a full reverse-engineering environment.

Instead, ZODIAC provides a fast first-pass analysis layer that helps answer:

- What is inside this APK?
- What permissions and components does it expose?
- Which network indicators are present?
- Are there suspicious strings, endpoints, secrets, or cloud references?
- Which security-sensitive APIs and patterns appear in the application?
- Where should deeper manual analysis begin?

---

What ZODIAC Does

ZODIAC currently groups its functionality into several analysis areas.

APK Discovery

Inspect the basic structure and metadata of an APK.

info
manifest
cert
permissions

Network Intelligence

Extract network-related indicators and endpoints.

net
urls
ips
emails
domains
api
paths
strings

Secrets & Services

Search application contents for potentially sensitive artifacts.

secrets
cloud
auth
payment
comm

Threat Analysis

Look for patterns associated with malware and suspicious application behavior.

mal
vuln
bypass
track

Application Security

Inspect security-sensitive implementation patterns.

offensive
crypto
decrypt
native
components

Combined Analysis

Run broader analysis workflows.

hunt
fast
report

---

Capabilities

🔎 APK Metadata

- APK identification
- SHA-256 calculation
- Android manifest inspection
- certificate information
- permission enumeration
- component inspection

🌐 Network Analysis

Detection and extraction of:

- URLs
- IPv4 addresses
- domains
- email addresses
- API endpoints
- file/network paths
- common REST / GraphQL / gRPC indicators

🔐 Secrets Detection

Pattern-based searches for artifacts such as:

- API keys
- tokens
- passwords
- private-key indicators
- cloud credentials
- JWT-like structures
- authentication-related material

«Matches are indicators for investigation, not proof that a credential is valid or usable.»

☁ Cloud & Service Detection

The toolkit includes patterns for common ecosystems such as:

- AWS
- Google Cloud
- Azure
- Firebase
- authentication frameworks
- payment services
- communication platforms

🦠 Threat Indicators

ZODIAC can flag patterns associated with:

- command-and-control infrastructure
- reverse shells
- RAT-like functionality
- ransomware-related strings
- cryptomining indicators
- suspicious shell execution
- native execution
- persistence-related artifacts
- surveillance/monitoring terminology

🛡 Application Security Patterns

The vulnerability-oriented checks cover areas including:

- SQL-related APIs
- command execution
- path traversal indicators
- deserialization
- intent handling
- WebView configuration
- SSL/TLS handling
- exported components
- cleartext traffic
- insecure cryptographic usage
- weak randomness
- file-access patterns
- native security-sensitive APIs

🔬 Native Analysis

Patterns related to:

- JNI
- ".so" libraries
- syscalls
- "ptrace"
- memory mapping
- executable memory
- native process execution
- anti-debugging indicators

---

Command Map

Command| Purpose
"list"| List available APKs
"install <url>"| Download an APK
"info <apk>"| APK information + SHA-256
"manifest <apk>"| Inspect "AndroidManifest.xml"
"cert <apk>"| Certificate information
"permissions <apk>"| Permission analysis
"net <apk>"| Network-oriented scan
"urls <apk>"| Extract URLs
"ips <apk>"| Extract IP addresses
"emails <apk>"| Extract email addresses
"domains <apk>"| Extract domains
"api <apk>"| Search API indicators
"paths <apk>"| Extract paths
"strings <apk>"| Extract strings
"secrets <apk>"| Search for secret-like artifacts
"cloud <apk>"| Cloud-service indicators
"auth <apk>"| Authentication indicators
"payment <apk>"| Payment/crypto indicators
"comm <apk>"| Communication-service indicators
"mal <apk>"| Malware/threat pattern scan
"vuln <apk>"| Security-pattern scan
"bypass <apk>"| Bypass-related indicators
"track <apk>"| Tracking SDK/pattern detection
"offensive <apk>"| Attack-surface/security-sensitive patterns
"crypto <apk>"| Cryptography analysis
"decrypt <apk>"| Decryption-related analysis
"native <apk>"| Native/JNI analysis
"db <apk>"| Database indicators
"components <apk>"| Component/export analysis
"hunt <apk>"| Broad analysis
"fast <apk>"| Quick analysis
"report <apk>"| Generate a report
"search <apk> <regex>"| Custom pattern search
"unzip <apk>"| Extract APK
"decompile <apk>"| Decompile using available tooling
"clean"| Clear analysis cache
"prompt"| Install optional shell prompt
"version"| Display version

Aliases are available for several commands.

Run:

zodiac help

for the complete command reference.

---

Installation

1. Clone the repository

git clone https://github.com/YOUR_USERNAME/zodiac.git
cd zodiac

2. Make the script executable

chmod +x zodiac.sh

3. Run

./zodiac.sh help

You can optionally install it into your PATH through the built-in installer:

./zodiac.sh install

After installation:

zodiac version

---

Termux

ZODIAC can also be used in a Termux environment, provided the required utilities are available.

Start with:

pkg update
pkg upgrade
pkg install bash coreutils grep sed awk unzip file curl

Then:

chmod +x zodiac.sh
./zodiac.sh help

Additional Android reverse-engineering tools such as JADX or apktool can be installed separately when deeper analysis is required.

---

Quick Start

Inspect an APK

zodiac info app.apk

Inspect the manifest

zodiac manifest app.apk

Check permissions

zodiac permissions app.apk

Extract URLs

zodiac urls app.apk

Search for secrets

zodiac secrets app.apk

Run a threat-oriented scan

zodiac mal app.apk

Run vulnerability-pattern analysis

zodiac vuln app.apk

Run the broader workflow

zodiac hunt app.apk

Generate a report

zodiac report app.apk

---

Examples

Analyze a downloaded APK

zodiac install https://example.org/application.apk

Then:

zodiac info application.apk
zodiac manifest application.apk
zodiac permissions application.apk

Network-focused investigation

zodiac urls application.apk
zodiac ips application.apk
zodiac domains application.apk
zodiac api application.apk

Security-focused investigation

zodiac vuln application.apk
zodiac crypto application.apk
zodiac components application.apk
zodiac native application.apk

Custom search

zodiac search application.apk "api[_-]?key"

This is useful when a researcher wants to test a hypothesis that is not covered by the built-in detectors.

---

Scan Modes

"fast"

Designed for a quick first pass.

Use it when:

- triaging many APKs
- checking an unknown sample quickly
- deciding whether deeper analysis is worthwhile

zodiac fast sample.apk

---

"hunt"

A broader workflow intended for a more comprehensive first-pass review.

zodiac hunt sample.apk

It combines multiple analysis areas so the researcher does not need to execute every command manually.

---

Individual Modules

For focused investigations, individual commands are preferable.

For example:

zodiac crypto sample.apk

is more targeted than running the complete workflow when the research question is specifically about cryptographic implementation.

---

Detection Philosophy

ZODIAC primarily uses static pattern-based analysis.

That means a finding generally represents:

«“A security-relevant pattern was found.”»

It does not automatically mean:

«“The application is vulnerable.”»

For example, finding:

X509TrustManager

does not by itself prove broken TLS validation.

Likewise:

PendingIntent

does not by itself indicate an insecure "PendingIntent".

And:

Random()

does not automatically mean cryptographically sensitive randomness is being used incorrectly.

The tool is therefore best viewed as an evidence collection and triage system.

---

False Positives

Static analysis naturally produces false positives.

Examples include:

Detector| Why it may be benign
"X509TrustManager"| May implement correct certificate validation
"PendingIntent"| Can be securely configured
"Random()"| May be used for non-security purposes
"ptrace()"| May be used for debugging or anti-debugging
"mmap()"| Common legitimate native API
"AES"| AES itself is not a vulnerability
"BroadcastReceiver"| Normal Android functionality
"WebView"| Common application component
"Base64"| Encoding is not encryption
"TrustManager"| Presence alone does not prove trust-all behavior
"monitor" / "track"| Could describe legitimate analytics
"encrypt"| Encryption can be completely legitimate

Always investigate the surrounding code and application context before treating a match as a confirmed security issue.

---

Reports

The report workflow is intended to turn analysis output into something easier to preserve and review.

Typical workflow:

zodiac report sample.apk

For larger investigations, keep the original APK and generated report together and record the APK SHA-256.

Example:

sha256sum sample.apk

This allows the analysis to be tied to a specific file version.

---

Environment Variables

ZODIAC stores APKs and working data under the user's home directory by default.

APK directory

ZODIAC_DIR

Default:

~/zodiac/apks

Example:

export ZODIAC_DIR="$HOME/samples/apks"

Working/cache directory

ZODIAC_WORK

Default:

~/zodiac/.cache

Example:

export ZODIAC_WORK="$HOME/zodiac-work"

---

Dependencies

The core script is Bash-based and uses common Unix utilities.

Typical dependencies include:

bash
coreutils
grep
sed
awk
find
unzip
file
sha256sum
curl

Some functionality can make use of Android/reverse-engineering tooling when available, such as:

aapt / aapt2
jadx
apktool

Availability depends on the command being used and the host environment.

ZODIAC does not require every optional reverse-engineering utility for its basic static analysis workflows.

---

Recommended Workflow

For an unfamiliar APK:

                    ┌──────────────┐
                    │    APK       │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │     info     │
                    └──────┬───────┘
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
        manifest       permissions      cert
            │              │              │
            └──────────────┼──────────────┘
                           ▼
                    ┌──────────────┐
                    │     fast     │
                    └──────┬───────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
           net           secrets        mal
             │             │             │
             └─────────────┼─────────────┘
                           ▼
                    ┌──────────────┐
                    │     vuln     │
                    └──────┬───────┘
                           │
                           ▼
                 Manual / Dynamic Review

The important principle is simple:

Automated findings → evidence → manual validation.

---

Security Considerations

ZODIAC may process APKs containing sensitive information, including:

- API endpoints
- tokens
- credentials
- private-key material
- internal hostnames
- personally identifiable information
- proprietary application code

Treat analysis output accordingly.

Avoid uploading generated reports containing sensitive findings to public repositories.

---

Responsible Use

ZODIAC is intended for:

- applications you own
- applications you are authorized to analyze
- malware-analysis research
- security research environments
- educational labs
- CTFs and controlled testing environments

Do not use the toolkit to access systems, accounts, services, or data without authorization.

The presence of an analysis feature does not imply authorization to use it against third-party infrastructure.

---

Limitations

ZODIAC is deliberately lightweight and shell-based.

It is not a replacement for a full mobile-security stack.

It does not inherently provide:

- complete program-path analysis
- semantic vulnerability verification
- dynamic instrumentation
- runtime behavior monitoring
- emulator-based behavioral analysis
- complete decompilation by itself
- guaranteed malware classification
- proof that a detected secret is valid
- proof that a detected pattern is exploitable

For deeper investigations, combine its output with appropriate reverse-engineering and dynamic-analysis tools.

---

Design Goals

The project focuses on five principles:

01 · Fast

Common APK triage should require a small number of commands.

02 · Portable

The core should remain usable in ordinary Linux and Termux environments.

03 · Transparent

Detection patterns should be inspectable rather than hidden behind an opaque classification system.

04 · Modular

Researchers should be able to run one focused analysis instead of the entire toolkit.

05 · Honest Results

A pattern match should be presented as a lead for investigation—not automatically as a confirmed vulnerability.

---

Project Structure

A typical installation looks like:

zodiac/
├── zodiac.sh
├── README.md
├── LICENSE
└── ...

Runtime data is stored separately:

~/zodiac/
├── apks/
└── .cache/

This keeps downloaded samples and temporary analysis data outside the source tree.

---

Roadmap

Potential future development areas include:

- [ ] JSON output
- [ ] SARIF export
- [ ] improved APK metadata normalization
- [ ] configurable detection rules
- [ ] per-rule confidence levels
- [ ] rule suppression / allowlists
- [ ] improved component correlation
- [ ] better secret validation workflows
- [ ] YARA integration
- [ ] VirusTotal integration as an optional module
- [ ] richer HTML reports
- [ ] batch APK analysis
- [ ] analysis result diffing
- [ ] structured evidence collection
- [ ] improved Android resource analysis

The roadmap is intentionally focused on improving signal quality and reproducibility, rather than simply increasing the number of detection patterns.

---

Contributing

Contributions are welcome.

Good contributions include:

- bug fixes
- portability improvements
- improved regex rules
- reduced false positives
- new APK analysis modules
- documentation
- test cases
- performance improvements

When adding a detector, please document:

1. What it detects
2. Why the pattern is relevant
3. Known false positives
4. Expected input
5. Example output
6. Whether the finding is an indicator or a confirmed condition

A good detection rule is not simply a large regex.

A good detection rule produces useful evidence.

---

Versioning

Current release:

ZODIAC 8.0.0

The project uses semantic-style versioning for releases:

MAJOR.MINOR.PATCH

---

License

Add your chosen license to "LICENSE" before publishing the repository.

For example:

MIT License

or another license appropriate for your project.

---

Final Note

ZODIAC is designed to shorten the distance between:

APK
 ↓
Evidence
 ↓
Indicators
 ↓
Investigation

It is intentionally a triage and analysis toolkit, not a claim that static pattern matching can replace a complete security assessment.

If a detector finds something interesting, the next step is to inspect the evidence—not blindly trust the label.

---

<p align="center">
  <b>ZODIAC</b><br>
  <sub>APK Reverse Engineering · Threat Intelligence · Security Analysis</sub>
</p>