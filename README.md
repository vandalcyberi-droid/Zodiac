
# Zodiac

**APK Reverse Engineering & Threat Analysis Toolkit**

Zodiac is a Bash-based APK static analysis tool built for Termux and Linux. It scans Android applications for security vulnerabilities, suspicious behavior, exposed secrets, and potential threats.

### Features

- 400+ detection patterns across 23 categories
- Vulnerability and malware indicator detection
- Permission and attack-surface analysis
- Secret, API endpoint, and network scanning
- Cryptographic and entropy analysis
- Risk scoring and severity classification
- HTML reports and MITRE ATT&CK Mobile mapping
- Batch scanning and optional VirusTotal hash lookup

### Installation

```bash
git clone https://github.com/vandalcyberi-droid/Zodiac.git
cd Zodiac
chmod +x zodiac.sh
./zodiac.sh install
```

### Usage

```bash
zodiac hunt app.apk
zodiac fast app.apk
zodiac risk app.apk
zodiac html app.apk
```

### Requirements

Bash, unzip, grep, strings, and sha256sum. Additional features may require optional dependencies.

### Disclaimer

Zodiac performs static analysis and does not exploit vulnerabilities. Analyze only applications you own or are authorized to test.

### License

MIT License — see [LICENSE](LICENSE).
