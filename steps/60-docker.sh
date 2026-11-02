# shellcheck shell=bash
# Step: Docker (from Ubuntu's own packages) + NVIDIA Container Toolkit so containers can use the GPU.

step_docker() {
    step "Docker + GPU containers"
    if ! have docker; then
        apt_install docker.io docker-compose-v2 docker-buildx || { warn "Docker install failed"; return 1; }
    fi
    sudo systemctl enable --now docker >/dev/null 2>&1
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        REBOOT_NEEDED=1
        info "Added you to the 'docker' group (lets you run docker without sudo after you log in again)"
    fi
    ok "Docker $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ,)"

    if has_nvidia_gpu; then
        if ! dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
            info "Installing NVIDIA Container Toolkit..."
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
                | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
                | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
                | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
            sudo apt-get update >/dev/null
            apt_install nvidia-container-toolkit || { warn "NVIDIA Container Toolkit install failed"; return 1; }
        fi
        sudo nvidia-ctk runtime configure --runtime=docker >/dev/null && sudo systemctl restart docker
        ok "GPU containers enabled (test after reboot: docker run --rm --gpus all ubuntu nvidia-smi)"
    fi
}
