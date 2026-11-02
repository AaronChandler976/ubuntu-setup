# shellcheck shell=bash
# Step: system updates + base packages from config/apt-packages.txt

step_system() {
    step "System update + base packages"
    sudo DEBIAN_FRONTEND=noninteractive apt-get update
    apt_install software-properties-common
    sudo add-apt-repository -y universe >/dev/null
    sudo DEBIAN_FRONTEND=noninteractive apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade

    mapfile -t pkgs < <(read_list "$ROOT/config/apt-packages.txt")
    if ! apt_install "${pkgs[@]}"; then
        # One bad name makes apt refuse the whole list; retry one at a time to find it.
        for p in "${pkgs[@]}"; do apt_install "$p" >/dev/null 2>&1 || warn "apt package '$p' failed to install"; done
    fi
    sudo snap refresh >/dev/null 2>&1 || true
    ok "System up to date"
}
