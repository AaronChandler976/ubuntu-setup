# shellcheck shell=bash
# Step: NVIDIA driver (RTX 5070 Ti needs a recent driver with the open kernel modules,
# which ubuntu-drivers picks automatically).

step_nvidia() {
    step "NVIDIA driver"
    if ! lspci | grep -qi 'vga.*nvidia\|3d.*nvidia'; then
        info "No NVIDIA GPU found - skipping"
        return 0
    fi
    if have nvidia-smi && nvidia-smi >/dev/null 2>&1; then
        ok "Driver working: $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)"
        return 0
    fi

    apt_install ubuntu-drivers-common
    info "Recommended driver: $(ubuntu-drivers devices 2>/dev/null | grep recommended || echo unknown)"
    if sudo ubuntu-drivers install; then
        ok "NVIDIA driver installed (active after reboot)"
        REBOOT_NEEDED=1
        if have mokutil && mokutil --sb-state 2>/dev/null | grep -qi enabled; then
            info "Secure Boot is on. If a blue 'MOK management' screen appears after reboot:"
            info "choose Enroll MOK > Continue > Yes, and type the password you were asked to set."
        fi
    else
        warn "ubuntu-drivers install failed - try Software & Updates > Additional Drivers"
    fi
}
