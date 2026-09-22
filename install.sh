#!/usr/bin/env bash
set -e

# Zodiac installer for Termux
# Installs zodiac.sh as the `zodiac` command.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$REPO_DIR/zodiac.sh"
TARGET="${PREFIX:-$HOME/.local}/bin/zodiac"

if [ ! -f "$SOURCE" ]; then
    echo "[✗] zodiac.sh not found in: $REPO_DIR"
    exit 1
fi

echo "[*] Checking Termux dependencies..."

if command -v pkg >/dev/null 2>&1; then
    pkg update -y
    pkg install -y bash coreutils findutils grep sed gawk unzip zip openssl curl
else
    echo "[!] Termux 'pkg' was not found."
    echo "    Continuing without automatic dependency installation..."
fi

mkdir -p "$(dirname "$TARGET")"

cp "$SOURCE" "$TARGET"
chmod 755 "$TARGET"

echo ""
echo "[✓] Zodiac installed successfully."
echo "[✓] Command: $TARGET"
echo ""
echo "Run:"
echo "  zodiac"
echo ""
echo "Examples:"
echo "  zodiac help"
echo "  zodiac version"
echo "  zodiac list"
echo "  zodiac hunt app.apk"

# Make sure the install directory is in PATH for the current shell.
case ":${PATH}:" in
    *":$(dirname "$TARGET"):"*) ;;
    *)
        echo ""
        echo "[!] Add this to ~/.bashrc if 'zodiac' is not found:"
        echo "    export PATH=\"$(dirname "$TARGET"):\$PATH\""
        ;;
esac
