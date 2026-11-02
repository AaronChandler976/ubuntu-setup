# shellcheck shell=bash
# Step: manual checklist.

step_finish() {
    step "Manual checklist"
    cat <<'TXT'
  [ ] Reboot (activates the NVIDIA driver and the docker group)
  [ ] Check the GPU:          nvidia-smi
  [ ] Check GPU in Docker:    docker run --rm --gpus all ubuntu nvidia-smi
  [ ] Chrome: sign in + turn on sync; make it the default browser when it asks
  [ ] Claude Code: run 'claude' once and log in
  [ ] Timeshift: open it, pick RSYNC, schedule daily snapshots (your undo button before letting agents loose)
  [ ] SJSU VPN: in Chrome open https://vpn.sjsu.edu (group Student-SSO), install the Linux Cisco Secure Client .deb
  [ ] SJSU HPC (VPN on): ssh-copy-id hpc, then 'ssh hpc' / 'ssh hpc3'
      GPU session on HPC3: srun -p gpuqs --gres=gpu:1 --pty /bin/bash   (type exit when done)
  [ ] VS Code: Accounts icon > Backup and Sync Settings (sign in with GitHub)
  [ ] Sign in to Discord and Zoom
TXT
}
