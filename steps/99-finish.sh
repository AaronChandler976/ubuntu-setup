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
  [ ] SJSU HPC: ssh-copy-id <your-id>@<hpc-login-host>   (uses ~/.ssh/id_ed25519)
  [ ] VS Code: Accounts icon > Backup and Sync Settings (sign in with GitHub)
  [ ] Sign in to Discord and Zoom
TXT
}
