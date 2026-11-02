# shellcheck shell=bash
# Step: GitHub CLI, login, git identity, SSH key. Runs early so the rest can be hands-off.

install_gh() {
    have gh && return 0
    info "Installing GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update >/dev/null && apt_install gh
}

step_github() {
    step "GitHub + git identity + SSH key"
    have curl || apt_install curl git
    install_gh || { warn "GitHub CLI install failed"; return 1; }

    git config --global init.defaultBranch main
    git config --global pull.rebase false

    # One SSH key for GitHub, the SJSU HPC, etc.
    if [[ ! -f $HOME/.ssh/id_ed25519 ]]; then
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -N "" -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" >/dev/null
        ok "Created SSH key ~/.ssh/id_ed25519"
    fi

    if [[ $GITHUB_LOGIN == 1 ]] && ! gh auth status >/dev/null 2>&1; then
        info "Logging in to GitHub: copy the code shown, press Enter, and approve in the browser."
        gh auth login --hostname github.com --git-protocol https --web --scopes admin:public_key </dev/tty >/dev/tty 2>&1
    fi

    if gh auth status >/dev/null 2>&1; then
        gh auth setup-git
        local login id
        login=$(gh api user --jq .login)
        id=$(gh api user --jq .id)
        # The noreply address avoids GitHub's "push declined due to email privacy" error.
        [[ -z $GIT_NAME ]]  && GIT_NAME=$login
        [[ -z $GIT_EMAIL ]] && GIT_EMAIL="${id}+${login}@users.noreply.github.com"

        local pub; pub=$(awk '{print $2}' "$HOME/.ssh/id_ed25519.pub")
        if gh ssh-key list 2>/dev/null | grep -qF "$pub"; then
            ok "SSH key already on GitHub"
        elif gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname) (ubuntu)" >/dev/null 2>&1; then
            ok "SSH key added to GitHub"
        else
            warn "Couldn't upload SSH key - run: gh auth refresh -s admin:public_key && gh ssh-key add ~/.ssh/id_ed25519.pub"
        fi
    else
        warn "Not logged in to GitHub - run 'gh auth login' later"
    fi

    [[ -n $GIT_NAME ]]  && git config --global user.name  "$GIT_NAME"
    [[ -n $GIT_EMAIL ]] && git config --global user.email "$GIT_EMAIL"
    ok "git: $(git config --global user.name) <$(git config --global user.email)>"
}
