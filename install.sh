#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

echo "⚡ NEXUS HOST — FULL TERMINAL UI UPDATE"

[[ -f nexus.sh && -f README.md && -d .git ]] || {
    echo "ERROR: Run inside your Nexus Host Git repository."
    exit 1
}

REMOTE="$(git remote get-url origin)"
[[ "$REMOTE" == *"kaidrix306/Nexus-Host"* ]] || {
    echo "ERROR: Unexpected Git remote: $REMOTE"
    exit 1
}

cp nexus.sh nexus.sh.backup
cp README.md README.backup.md

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# New thick-logo banner
cat > "$TMP/banner" <<'BANNER'
banner() {
    clear 2>/dev/null || true
    printf '\033[1;96m'
    cat <<'ART'
███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║╔══╝   ██╔██╗ ██║   ██║╚════██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
ART
    printf '\033[0m\n'
    printf '  \033[1;95m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
    printf '  \033[1;96m       N E X U S   H O S T\033[0m\n'
    printf '  \033[1;93m     SERVER INSTALLATION & MANAGEMENT\033[0m\n'
    printf '  \033[1;92m       By Kaidrix • NexusCloud Team\033[0m\n'
    printf '  \033[1;95m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
}
BANNER

# New selectable menu. Installer actions are preserved.
cat > "$TMP/menu" <<'MENU'
menu() {
    local choice ram disk uptime_text

    while true; do
        banner

        ram="$(free -m 2>/dev/null | awk '/Mem:/ {if ($2>0) printf "%d%%", $3/$2*100}')"
        disk="$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')"
        uptime_text="$(uptime -p 2>/dev/null | sed 's/^up //')"

        printf '\n \033[1;96m╔════════════════════════════╦════════════════════════════╗\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;95m      CORE INSTALLER       \033[0m\033[1;96m║\033[0m \033[1;94m     MANAGERS & EXTRAS     \033[0m\033[1;96m║\033[0m\n'
        printf ' \033[1;96m╠════════════════════════════╬════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[1]\033[0m Install Panel            \033[1;96m║\033[0m \033[1;93m[7]\033[0m Panel Manager           \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[2]\033[0m Install Wings            \033[1;96m║\033[0m \033[1;93m[8]\033[0m Wings Manager           \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[3]\033[0m Panel + Wings            \033[1;96m║\033[0m \033[1;93m[9]\033[0m Toolbox                 \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[4]\033[0m Link Wings to Panel      \033[1;96m║\033[0m \033[1;93m[10]\033[0m Themes & Extensions    \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[5]\033[0m System Status            \033[1;96m║\033[0m \033[1;93m[11]\033[0m VM Manager             \033[1;96m║\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;93m[6]\033[0m Open Master Hub          \033[1;96m║\033[0m \033[1;93m[12]\033[0m Extras                 \033[1;96m║\033[0m\n'
        printf ' \033[1;96m╠════════════════════════════╩════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;92mRAM:\033[0m %-5s  \033[1;92mDISK:\033[0m %-5s  \033[1;92mUP:\033[0m %-19.19s \033[1;96m║\033[0m\n' \
            "${ram:-N/A}" "${disk:-N/A}" "${uptime_text:-unknown}"
        printf ' \033[1;96m╠════════════════════════════════════════════════════════╣\033[0m\n'
        printf ' \033[1;96m║\033[0m \033[1;91m[0] Exit\033[0m      \033[1;95mChoose an option from 0 to 12\033[0m             \033[1;96m║\033[0m\n'
        printf ' \033[1;96m╚════════════════════════════════════════════════════════╝\033[0m\n\n'
        printf ' \033[1;95m➜\033[0m \033[1;97mYour choice:\033[0m '
        read -r choice || choice=0

        case "$choice" in
            1) install_panel; pause ;;
            2) install_wings; pause ;;
            3) install_panel; install_wings; pause ;;
            4) link_wings; pause ;;
            5) show_status; pause ;;
            6) launch_hub_feature "menu/UI.sh"; pause ;;
            7) launch_hub_feature "panel/1.sh"; pause ;;
            8) launch_hub_feature "wings/run.sh"; pause ;;
            9) launch_hub_feature "toolbox/run.sh"; pause ;;
            10) launch_hub_feature "thame/run.sh"; pause ;;
            11) launch_hub_feature "setup vm/menu.sh"; pause ;;
            12) launch_hub_feature "Extras/run.sh"; pause ;;
            0|exit|quit)
                printf '\033[1;96mGoodbye from Nexus Host!\033[0m\n'
                exit 0
                ;;
            *)
                printf '\033[1;91mInvalid option. Choose 0–12.\033[0m\n'
                sleep 1
                ;;
        esac
    done
}
MENU

# Replace complete Bash functions, counting braces without Python.
replace_function() {
    local target="$1" replacement="$2" source="$3" output="$4"

    awk -v target="$target" -v replacement="$replacement" '
    BEGIN {
        while ((getline line < replacement) > 0) newfunc = newfunc line "\n"
        close(replacement)
        signature = "^" target "[[:space:]]*\\(\\)[[:space:]]*\\{"
    }
    function brace_delta(s, t, opens, closes) {
        t = s
        opens = gsub(/\{/, "{", t)
        t = s
        closes = gsub(/\}/, "}", t)
        return opens - closes
    }
    $0 ~ signature {
        if (done) {
            print
            next
        }
        print newfunc
        depth = brace_delta($0)
        skipping = (depth > 0)
        done = 1
        next
    }
    skipping {
        depth += brace_delta($0)
        if (depth <= 0) skipping = 0
        next
    }
    { print }
    END {
        if (!done) {
            print "ERROR: function " target "() not found." > "/dev/stderr"
            exit 2
        }
        if (skipping) {
            print "ERROR: incomplete function " target "()." > "/dev/stderr"
            exit 3
        }
    }' "$source" > "$output"
}

replace_function banner "$TMP/banner" nexus.sh "$TMP/step1"
replace_function menu "$TMP/menu" "$TMP/step1" "$TMP/step2"
mv "$TMP/step2" nexus.sh

echo "Checking script syntax..."
if ! bash -n nexus.sh; then
    echo "ERROR: Syntax check failed. Restoring backups."
    cp nexus.sh.backup nexus.sh
    cp README.backup.md README.md
    exit 1
fi

git diff --check

git config user.name >/dev/null 2>&1 ||
    git config user.name "Kaidrix"
git config user.email >/dev/null 2>&1 ||
    git config user.email "kaidrix306@users.noreply.github.com"

git add nexus.sh README.md
if ! git diff --cached --quiet; then
    git commit -m "Update Nexus Host terminal UI"
else
    echo "No changes to commit."
fi

echo "Pushing changes to GitHub..."
git push origin HEAD:master

echo
echo "SUCCESS: UI updated and pushed!"
echo "https://github.com/kaidrix306/Nexus-Host"
echo "Backups: nexus.sh.backup and README.backup.md"
