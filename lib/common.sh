# shellcheck shell=bash
# Shared helpers, sourced by setup.sh.

WARNINGS=()
REBOOT_NEEDED=0

step() { printf '\n\033[1;36m%s\n  %s\n%s\033[0m\n' "$(printf '=%.0s' {1..70})" "$*" "$(printf '=%.0s' {1..70})"; }
info() { printf '  > %s\n' "$*"; }
ok()   { printf '  \033[32m[ok]\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m[!]\033[0m %s\n' "$*"; WARNINGS+=("$*"); }

have() { command -v "$1" >/dev/null 2>&1; }

# ask_yn "Question?" y|n  -> exit status 0 = yes. Returns the default when --unattended.
ask_yn() {
    local q=$1 def=$2 ans hint='[y/N]'
    [[ $def == y ]] && hint='[Y/n]'
    if [[ ${UNATTENDED:-0} == 1 ]]; then [[ $def == y ]]; return; fi
    while true; do
        read -r -p "  $q $hint " ans </dev/tty || ans=''
        ans=${ans,,}
        [[ -z $ans ]] && ans=$def
        case $ans in y|yes) return 0 ;; n|no) return 1 ;; esac
    done
}

apt_install() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# Print a list file without comments or blank lines.
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^[[:space:]]*$'; }

# Download a .deb and install it with apt (which also pulls dependencies).
install_deb() {
    local name=$1 url=$2 check_cmd=$3
    if have "$check_cmd"; then ok "$name already installed"; return 0; fi
    info "Installing $name..."
    local tmp; tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/pkg.deb" "$url" && apt_install "$tmp/pkg.deb"; then
        ok "$name installed"
    else
        warn "Could not install $name from $url"
    fi
    rm -rf "$tmp"
}

# Add a line to ~/.bashrc once.
bashrc_add() { grep -qxF "$1" "$HOME/.bashrc" 2>/dev/null || echo "$1" >> "$HOME/.bashrc"; }
