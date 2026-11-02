# ubuntu-setup

The Ubuntu half of my dual-boot desktop: one command turns a fresh Ubuntu (26.04 LTS, or
24.04) into an AI/robotics workstation. It installs the NVIDIA driver, Docker with GPU
containers, conda + CUDA PyTorch, VS Code, Chrome, GitHub login + SSH key, Claude Code with a
sandbox for running agents safely, optional ROS 2 + Gazebo, and dual-boot GRUB settings.

Companion repo: [win-setup](https://github.com/AaronChandler976/win-setup).

---

## Part 1: Install Ubuntu on the new SSD (one time, ~45 min)

### Before you open the case (in Windows)

1. **Run win-setup first.** It turns off Fast Startup and hibernation, and puts the Windows clock
   in UTC. Ubuntu needs both.
2. **BitLocker:** if Windows says the drive is encrypted, save the recovery key from
   https://account.microsoft.com/devices/recoverykey before changing anything.
3. **Make a USB installer** (8 GB+ stick; it gets erased):
   - Download the **Ubuntu 26.04 LTS Desktop** ISO from https://ubuntu.com/download/desktop
   - `winget install Rufus.Rufus`, open Rufus, pick the USB + ISO, click Start (keep the defaults).

### Install the drive

4. Shut down, turn off the PSU switch, and unplug. Touch the case to discharge static.
5. Put the Samsung 990 2 TB in a free M.2 slot. **Not M2_2**. Your build notes say to
   keep SSDs out of that slot. Use the slot's heatsink, remove the film from the thermal pad, and tighten
   the latch/screw.

### Install Ubuntu

6. Boot and press **F11** repeatedly for the MSI boot menu, then choose the **USB** (UEFI) entry.
   (Optional: in BIOS, **Del** key, check that both SSDs are listed.) Leave Secure Boot on.
7. In the installer: language > **Install Ubuntu** > Interactive installation > Default selection.
8. Check **"Install third-party software for graphics and Wi-Fi hardware"**.
   If it asks for a **Secure Boot password**, set one and remember it. You'll type it once after the reboot.
9. **Disk setup, the step that matters:**
   - Choose **Erase disk and install Ubuntu**, then pick the disk that says **2 TB** (or 2.0 TB).
     **Do not pick the 1 TB drive. That's Windows.**
   - If the installer doesn't let you pick a disk, choose **Manual installation**. Select the 2 TB disk,
     create a **1 GB "EFI System Partition"** and use the rest as **ext4** mounted at `/`. Set
     "Device for boot loader installation" to the **2 TB disk**.
   - This way each OS has its own drive and its own bootloader, so neither install can break the other.
10. Finish the installer (name, password, timezone), reboot, and remove the USB when told.
11. If a blue **"Perform MOK management"** screen appears, choose Enroll MOK > Continue > Yes, enter
    the Secure Boot password from step 8, then Reboot.
12. In BIOS (**Del**) > Settings > Boot, set **ubuntu** as Boot Option #1. From then on you get the
    GRUB menu at power-on and can choose Ubuntu or Windows. (Until the setup below runs, Windows
    may not be listed yet. Use **F11** to reach it.)

---

## Part 2: Run the setup (~30–60 min)

Open **Terminal** (Ctrl+Alt+T) and paste:

```bash
wget -qO- https://raw.githubusercontent.com/AaronChandler976/ubuntu-setup/main/install.sh | bash
```

With options:

```bash
wget -qO- https://raw.githubusercontent.com/AaronChandler976/ubuntu-setup/main/install.sh | bash -s -- --ml-env --robotics
```

It asks a few questions, then your password once, then a **GitHub login** (copy the code,
approve in the browser). After that it runs on its own, and at the end it offers a reboot.

| Option | What it does |
|---|---|
| `--robotics` | ROS 2 (Lyrical on 26.04, Jazzy on 24.04) + Gazebo |
| `--ml-env` | `ml` conda env with CUDA PyTorch |
| `--unattended` | No questions, defaults only |
| `--skip a,b` / `--only a,b` | Skip / run only some steps |
| `--git-name`, `--git-email` | Override git identity (default: GitHub username + private noreply email) |

Safe to re-run. Logs: `~/.local/state/ubuntu-setup/`.

### What each step does

| Step | File | What it does |
|---|---|---|
| system | `steps/10-system.sh` | `apt full-upgrade` + packages in `config/apt-packages.txt` (build tools, nvtop, Timeshift, ...) |
| github | `steps/20-github.sh` | GitHub CLI, login, git identity with your **noreply email** (avoids "push declined due to email privacy"), SSH key created + uploaded |
| nvidia | `steps/30-nvidia.sh` | Recommended NVIDIA driver via `ubuntu-drivers` |
| apps | `steps/40-apps.sh` | Chrome, VS Code, Discord, Zoom (official .debs that update with apt) + `config/snap-packages.txt` |
| dev | `steps/50-dev.sh` | Miniforge (conda), optional `ml` env, VS Code extensions |
| docker | `steps/60-docker.sh` | Docker + NVIDIA Container Toolkit (GPU in containers) |
| ai | `steps/70-ai.sh` | Claude Code, devcontainer CLI, `agent-sandbox` |
| robotics | `steps/80-robotics.sh` | ROS 2 + Gazebo + rosdep (only with `--robotics` / "yes") |
| tweaks | `steps/90-tweaks.sh` | GRUB shows Windows and remembers your last choice, UTC clock, dark mode, no auto-suspend |
| finish | `steps/99-finish.sh` | Manual checklist |

### After the reboot

```bash
nvidia-smi                                     # GPU + driver
docker run --rm --gpus all ubuntu nvidia-smi   # GPU inside Docker
conda activate ml && python -c "import torch; print(torch.cuda.is_available())"
claude                                         # log in to Claude Code once
```

Then open **Timeshift** and turn on daily snapshots, so you can roll back anything.

---

## Using AI agents on this machine

- **Normal work:** `cd` into a project (e.g. `~/SJSU/FALL_2026/CMPE_249/CMPE_249_HW1`, as a git repo)
  and run `claude`. It asks before running commands. Commit often.
- **Hands-off work:** run `agent-sandbox` in the project folder. It starts a Docker dev
  container from Anthropic's reference config and runs Claude Code there with permission prompts off.
  The agent sees only that folder, can only reach an allowlist (GitHub, npm, Anthropic API),
  and never sees your SSH keys or browser logins. Commit before you start, so `git` can undo anything.
  (That container has no GPU. For GPU jobs, run them yourself or add `--gpus all` to its config.)

## Customizing

Add or remove packages in `config/*.txt`, edit steps in `steps/`, commit, and push.

> **Never commit secrets.** This repo is public.
