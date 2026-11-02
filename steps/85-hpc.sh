# shellcheck shell=bash
# Step (optional, --sjsu-id or answer the question): SSH shortcuts for the SJSU CoE HPC.
#   ssh hpc   -> coe-hpc1.sjsu.edu (login node)
#   ssh hpc3  -> HPC3 / g17 (A100 GPUs), hopping through hpc1
# The SJSU VPN must be on (Cisco Secure Client, group Student-SSO). See README.

step_hpc() {
    step "SJSU HPC ssh shortcuts"
    local cfg="$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    touch "$cfg" && chmod 600 "$cfg"
    if grep -qE '^Host[[:space:]]+hpc$' "$cfg"; then
        ok "~/.ssh/config already has an 'hpc' entry"
    else
        cat >> "$cfg" <<EOF

Host hpc
    HostName coe-hpc1.sjsu.edu
    User $SJSU_ID

Host hpc3
    HostName g17
    User $SJSU_ID
    ProxyJump hpc
EOF
        ok "Added 'ssh hpc' and 'ssh hpc3' to ~/.ssh/config"
    fi
    info "One time, with the VPN on: ssh-copy-id hpc   (after that, no password needed)"
}
