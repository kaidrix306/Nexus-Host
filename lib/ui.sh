#!/usr/bin/env bash
# =====================================================================
#  NexusCloud shared UI library  -  bright colours, ASCII boxes
#  Source this from any script:  source lib/ui.sh   (or curl | source)
# =====================================================================

# ---------------------------------------------------------------------
#  BRIGHT COLOURS ONLY (no dim / grey / dark tones anywhere)
# ---------------------------------------------------------------------
NX_R=$'\e[1;91m'; NX_G=$'\e[1;92m'; NX_Y=$'\e[1;93m'; NX_B=$'\e[1;94m'
NX_M=$'\e[1;95m'; NX_C=$'\e[1;96m'; NX_W=$'\e[1;97m'; NX_N=$'\e[0m'

NX_WIDTH=55   # inner width of every box (total 57 columns)

nx_hline() { printf '%s+%s+%s\n' "${NX_C}" "$(printf '%*s' "$NX_WIDTH" '' | tr ' ' '-')" "${NX_N}"; }

nx_box() {                       # nx_box "TITLE"
    local t=" $1 " pad l r
    pad=$((NX_WIDTH - ${#t})); l=$((pad / 2)); r=$((pad - l))
    echo
    nx_hline
    printf '%s|%s%*s%s%s%s%*s%s|%s\n' "$NX_C" "$NX_N" "$l" "" "$NX_Y" "$t" "$NX_N" "$r" "" "$NX_C" "$NX_N"
    nx_hline
}

nx_row() {                       # nx_row "Label" "Value" ["Colour"]
    local colour=${3:-$NX_W}
    printf '%s|%s %s%-14.14s%s : %s%-36.36s%s %s|%s\n' \
        "$NX_C" "$NX_N" "$NX_Y" "$1" "$NX_C" "$colour" "$2" "$NX_N" "$NX_C" "$NX_N"
}

nx_banner() {                    # nx_banner "SUBTITLE"
    clear 2>/dev/null || true
    echo "${NX_C}  _   _ _____ __  __ _   _ ____${NX_N}"
    echo "${NX_B} | \\ | | ____|\\ \\/ /| | | / ___|${NX_N}"
    echo "${NX_M} |  \\| |  _|   \\  / | | | \\___ \\${NX_N}"
    echo "${NX_Y} | |\\  | |___  /  \\ | |_| |___) |${NX_N}"
    echo "${NX_G} |_| \\_|_____|/_/\\_\\ \\___/|____/${NX_N}"
    echo
    echo "${NX_W}   C L O U D${NX_N}"
    [ -n "${1:-}" ] && echo "${NX_C}   $1${NX_N}"
    nx_hline
}

nx_ok()   { printf '  %s[ OK ]%s %s\n'  "$NX_G" "$NX_N" "$*"; }
nx_warn() { printf '  %s[WARN]%s %s\n'  "$NX_Y" "$NX_N" "$*"; }
nx_info() { printf '  %s[INFO]%s %s\n'  "$NX_B" "$NX_N" "$*"; }
nx_fail() { printf '  %s[FAIL]%s %s\n'  "$NX_R" "$NX_N" "$*"; }
nx_die()  { nx_fail "$*"; exit 1; }

nx_spin() {
    local pid=$1 msg=$2 i=0 f='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s[%s]%s %s%s%s   ' "$NX_M" "${f:i%4:1}" "$NX_N" "$NX_W" "$msg" "$NX_N"
        i=$((i + 1)); sleep 0.15
    done
    printf '\r\033[K'
}

# nx_run "message" command [args...]  -> spinner, aborts script on failure
nx_run() {
    local msg=$1 pid rc log=${NX_LOG:-/dev/null}; shift
    "$@" >>"$log" 2>&1 &
    pid=$!
    nx_spin "$pid" "$msg"
    wait "$pid"; rc=$?
    if [ "$rc" -eq 0 ]; then
        nx_ok "$msg"
    else
        nx_fail "$msg"
        [ "$log" != /dev/null ] && { echo "${NX_R}  ---- last log lines ($log) ----${NX_N}"; tail -n 10 "$log"; }
        exit 1
    fi
}

# nx_run_soft "message" command [args...]  -> like nx_run, returns 1 instead of exiting
nx_run_soft() {
    local msg=$1 pid rc; shift
    "$@" >>"${NX_LOG:-/dev/null}" 2>&1 &
    pid=$!; nx_spin "$pid" "$msg"; wait "$pid"; rc=$?
    if [ "$rc" -eq 0 ]; then nx_ok "$msg"; else nx_fail "$msg"; fi
    return "$rc"
}

nx_ask() {                       # nx_ask VAR "Prompt" "default"
    local __v=$1 p=$2 d=${3:-} in
    if [ -n "$d" ]; then
        printf '  %s>%s %s%s%s %s[%s]%s: ' "$NX_M" "$NX_N" "$NX_W" "$p" "$NX_N" "$NX_Y" "$d" "$NX_N"
    else
        printf '  %s>%s %s%s%s: ' "$NX_M" "$NX_N" "$NX_W" "$p" "$NX_N"
    fi
    read -r in
    printf -v "$__v" '%s' "${in:-$d}"
}

nx_ask_secret() {                # nx_ask_secret VAR "Prompt"
    local __v=$1 p=$2 in
    printf '  %s>%s %s%s%s: ' "$NX_M" "$NX_N" "$NX_W" "$p" "$NX_N"
    read -rs in; echo
    printf -v "$__v" '%s' "$in"
}

nx_confirm() {                   # nx_confirm "Question" -> 0=yes 1=no
    local a
    while true; do
        printf '  %s?%s %s%s%s %s(y/n)%s: ' "$NX_G" "$NX_N" "$NX_W" "$1" "$NX_N" "$NX_Y" "$NX_N"
        read -r a
        case "$a" in [Yy]*) return 0 ;; [Nn]*) return 1 ;; esac
    done
}

nx_pause() { printf '\n  %sPress ENTER to continue...%s' "$NX_W" "$NX_N"; read -r _; }

nx_menu_item() { printf '   %s%s%s) %s%s%s\n' "$NX_G" "$1" "$NX_N" "$NX_W" "$2" "$NX_N"; }

nx_rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-24}"; }
