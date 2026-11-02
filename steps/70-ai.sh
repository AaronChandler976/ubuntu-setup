# shellcheck shell=bash
# Step: Claude Code + the devcontainer CLI + 'agent-sandbox' helper for running agents in a container.

step_ai() {
    step "AI agents: Claude Code + sandbox tools"
    if have claude || [[ -x $HOME/.local/bin/claude ]]; then
        ok "Claude Code already installed"
    else
        info "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash && ok "Claude Code installed (run 'claude' to log in)" \
            || warn "Claude Code install failed - see https://docs.claude.com/en/docs/claude-code/setup"
    fi

    if ! have devcontainer; then
        sudo npm install -g @devcontainers/cli >/dev/null 2>&1 && ok "devcontainer CLI installed" \
            || warn "devcontainer CLI install failed (sudo npm install -g @devcontainers/cli)"
    fi

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$ROOT/bin/agent-sandbox" "$HOME/.local/bin/agent-sandbox"
    bashrc_add 'export PATH="$HOME/.local/bin:$PATH"'
    ok "Installed 'agent-sandbox' (run it inside a project folder)"
}
