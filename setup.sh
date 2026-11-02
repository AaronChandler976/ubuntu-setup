#!/usr/bin/env bash
# ubuntu-setup: set up a fresh Ubuntu (26.04 or 24.04) for AI/robotics work.
# All questions are asked first, then it runs hands-off. Safe to re-run.
#
# Usage: ./setup.sh [options]
#   --robotics            also install ROS 2 (+ Gazebo)
#   --ml-env              create the "ml" conda env with CUDA PyTorch
#   --unattended          ask nothing, use defaults
#   --skip a,b            skip steps   (e.g. --skip docker,ai)
#   --only a,b            run only these steps
#   --git-name NAME       git user.name  (default: your GitHub username)
#   --git-email EMAIL     git user.email (default: your GitHub noreply address)
#   --sjsu-id ID          add 'ssh hpc' / 'ssh hpc3' shortcuts for the SJSU CoE HPC
#
# Steps: system github nvidia apps dev docker ai robotics hpc tweaks finish

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/lib/common.sh"

ROBOTICS=0 MLENV=0 UNATTENDED=0 SKIP="" ONLY="" GIT_NAME="" GIT_EMAIL="" GITHUB_LOGIN=1 SJSU_ID=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --robotics)   ROBOTICS=1 ;;
        --ml-env)     MLENV=1 ;;
        --unattended) UNATTENDED=1 ;;
        --skip)       SKIP=$2; shift ;;
        --only)       ONLY=$2; shift ;;
        --git-name)   GIT_NAME=$2; shift ;;
        --git-email)  GIT_EMAIL=$2; shift ;;
        --sjsu-id)    SJSU_ID=$2; shift ;;
        -h|--help)    sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
    esac
    shift
done
export UNATTENDED

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo. It will ask for your password."
    exit 1
fi

source /etc/os-release
if [[ ${ID:-} != ubuntu ]]; then echo "This script is for Ubuntu (found: ${ID:-unknown})."; exit 1; fi
CODENAME=${UBUNTU_CODENAME:-$VERSION_CODENAME}
case $CODENAME in
    resolute) ROS_DISTRO=lyrical ;;   # Ubuntu 26.04 LTS
    noble)    ROS_DISTRO=jazzy ;;     # Ubuntu 24.04 LTS
    jammy)    ROS_DISTRO=humble ;;    # Ubuntu 22.04 LTS
    *)        ROS_DISTRO="" ;;
esac

LOG_DIR="$HOME/.local/state/ubuntu-setup"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

for f in "$ROOT"/steps/*.sh; do source "$f"; done

# --- Questions first ---------------------------------------------------------
echo
echo -e "  \033[1;36mubuntu-setup\033[0m  -  Ubuntu $VERSION_ID ($CODENAME)"
echo "  Log: $LOG"
echo
if [[ $ROBOTICS == 0 && -n $ROS_DISTRO ]] && ask_yn "Install ROS 2 $ROS_DISTRO + Gazebo (robotics, ~3 GB)?" n; then ROBOTICS=1; fi
if [[ $MLENV == 0 ]] && ask_yn "Create the 'ml' conda env with CUDA PyTorch (~5 GB)?" n; then MLENV=1; fi
if ! ask_yn "Log in to GitHub at the start (sets git identity + uploads an SSH key; needs your browser)?" y; then GITHUB_LOGIN=0; fi
if [[ -z $SJSU_ID && $UNATTENDED == 0 ]]; then
    read -r -p "  SJSU ID for HPC ssh shortcuts (blank to skip): " SJSU_ID </dev/tty || SJSU_ID=""
fi

ALL_STEPS=(system github nvidia apps dev docker ai robotics hpc tweaks finish)
STEPS=()
for s in "${ALL_STEPS[@]}"; do
    [[ $s == robotics && $ROBOTICS == 0 ]] && continue
    [[ $s == hpc && -z $SJSU_ID ]] && continue
    [[ -n $ONLY && ",$ONLY," != *",$s,"* ]] && continue
    [[ ",$SKIP," == *",$s,"* ]] && continue
    STEPS+=("$s")
done

echo
echo "  Steps : ${STEPS[*]}"
echo "  ROS 2 : $([[ $ROBOTICS == 1 ]] && echo "$ROS_DISTRO" || echo no)"
echo "  ml env: $([[ $MLENV == 1 ]] && echo yes || echo no)"
echo "  HPC   : ${SJSU_ID:-no}"
echo
ask_yn "Start? (you'll type your password once, then you can walk away after the GitHub login)" y || exit 0

# Ask for the sudo password once and keep it fresh while we run.
sudo -v || { echo "sudo is required."; exit 1; }
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &

START=$(date +%s)
for s in "${STEPS[@]}"; do
    "step_$s" || warn "Step '$s' reported an error (see log)"
done

step "Done in $(( ($(date +%s) - START) / 60 )) min"
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo -e "  \033[33mThings that need a look:\033[0m"
    for w in "${WARNINGS[@]}"; do echo "   - $w"; done
else
    ok "No problems reported."
fi
echo "  Full log: $LOG"

if [[ $REBOOT_NEEDED == 1 ]] && ask_yn "Reboot now to finish (NVIDIA driver / docker group)?" y; then
    sudo reboot
fi
