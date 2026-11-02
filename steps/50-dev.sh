# shellcheck shell=bash
# Step: Miniforge (conda), optional "ml" env with CUDA PyTorch, VS Code extensions.

# PyTorch CUDA wheel indexes to try, newest first (both support RTX 50-series).
# If one disappears, check https://pytorch.org/get-started/locally/
TORCH_INDEXES=(https://download.pytorch.org/whl/cu130 https://download.pytorch.org/whl/cu128)
CONDA_DIR="$HOME/miniforge3"

step_dev() {
    step "Dev tools: conda, VS Code extensions"

    if [[ ! -x $CONDA_DIR/bin/conda ]]; then
        info "Installing Miniforge..."
        local inst; inst=$(mktemp --suffix=.sh)
        if curl -fsSL -o "$inst" "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-$(uname -m).sh"; then
            bash "$inst" -b -p "$CONDA_DIR" && ok "Miniforge installed to $CONDA_DIR"
        else
            warn "Miniforge download failed"
        fi
        rm -f "$inst"
    else
        ok "Miniforge already installed"
    fi

    if [[ -x $CONDA_DIR/bin/conda ]]; then
        "$CONDA_DIR/bin/conda" init bash >/dev/null
        # Don't auto-activate base in every terminal (setting name changed in newer conda).
        "$CONDA_DIR/bin/conda" config --set auto_activate false >/dev/null 2>&1 \
            || "$CONDA_DIR/bin/conda" config --set auto_activate_base false >/dev/null 2>&1
        ok "conda ready (open a new terminal)"
        [[ $MLENV == 1 ]] && install_ml_env
    fi

    if have code; then
        while read -r ext; do
            code --install-extension "$ext" --force >/dev/null 2>&1 || warn "VS Code extension $ext failed"
        done < <(read_list "$ROOT/config/vscode-extensions.txt")
        ok "VS Code extensions installed"
    else
        warn "VS Code not found - skipping extensions"
    fi
}

install_ml_env() {
    local conda="$CONDA_DIR/bin/conda" py="$CONDA_DIR/envs/ml/bin/python"
    if [[ -x $py ]]; then
        ok "conda env 'ml' already exists"
    else
        info "Creating conda env 'ml' (takes a while)..."
        "$conda" env create -f "$ROOT/config/ml-env.yml" || { warn "Creating the ml env failed"; return 1; }
    fi
    local idx done_ok=0
    for idx in "${TORCH_INDEXES[@]}"; do
        info "Installing PyTorch from $idx ..."
        if "$py" -m pip install --upgrade torch torchvision torchaudio --index-url "$idx"; then done_ok=1; break; fi
    done
    [[ $done_ok == 1 ]] || { warn "PyTorch install failed - see pytorch.org/get-started/locally"; return 1; }
    local check
    check=$("$py" -c "import torch; print(torch.__version__, 'CUDA OK' if torch.cuda.is_available() else 'NO CUDA')" 2>&1)
    if [[ $check == *"CUDA OK"* ]]; then ok "PyTorch $check"
    else warn "PyTorch installed but CUDA not available yet ($check) - normal before the post-driver reboot"; fi
}
