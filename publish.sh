#!/usr/bin/env bash
# Usage: bash publish.sh <github-username>   (run inside this folder, needs gh logged in)
set -e
U="${1:?usage: bash publish.sh <github-username>}"
grep -rIl "kaidrix306" . --exclude-dir=.git | xargs sed -i "s/kaidrix306/${U}/g"
git init -q 2>/dev/null || true
git add -A && git commit -qm "NexusCloud initial release" || true
gh repo create nexuscloud --public --source=. --push
echo "Install command:"
echo "bash <(curl -fsSL https://raw.githubusercontent.com/${U}/nexuscloud/main/nexus.sh)"
