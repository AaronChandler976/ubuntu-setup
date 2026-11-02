# shellcheck shell=bash
# Step: desktop apps. Official .deb packages add their own apt repos, so they update with apt.

step_apps() {
    step "Apps"
    install_deb "Google Chrome" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" google-chrome

    # VS Code: pre-answer "add Microsoft's apt repo?" so it updates with apt.
    echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
    install_deb "VS Code" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" code

    install_deb "Discord" "https://discord.com/api/download?platform=linux&format=deb" discord
    install_deb "Zoom" "https://zoom.us/client/latest/zoom_amd64.deb" zoom

    if [[ -f $ROOT/config/snap-packages.txt ]]; then
        while read -r snap_line; do
            # shellcheck disable=SC2086
            sudo snap install $snap_line || warn "snap install $snap_line failed"
        done < <(read_list "$ROOT/config/snap-packages.txt")
    fi
    info "Notion has no official Linux app - use notion.so in Chrome (menu > Cast, save and share > Install page as app)."
}
