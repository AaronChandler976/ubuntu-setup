# shellcheck shell=bash
# Step: dual-boot GRUB menu + a few desktop settings.

step_tweaks() {
    step "Dual-boot + desktop tweaks"

    # Show Windows in the GRUB menu, remember the last OS you picked, give 10 s to choose.
    apt_install os-prober
    sudo mkdir -p /etc/default/grub.d
    sudo tee /etc/default/grub.d/99-ubuntu-setup.cfg >/dev/null <<'GRUB'
GRUB_DISABLE_OS_PROBER=false
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB
    if sudo update-grub >/dev/null 2>&1; then
        if grep -qi windows /boot/grub/grub.cfg 2>/dev/null; then ok "GRUB menu includes Windows"
        else warn "GRUB didn't find Windows - you can still pick it from the BIOS boot menu (F11 on MSI)"; fi
    else
        warn "update-grub failed"
    fi

    # Hardware clock in UTC (Windows was set to UTC by win-setup, so both agree).
    if timedatectl show -p LocalRTC --value 2>/dev/null | grep -q yes; then sudo timedatectl set-local-rtc 0; fi
    ok "Clock uses UTC"

    # GNOME: dark mode, and never auto-suspend on AC (long training runs).
    if have gsettings; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null
        ok "Dark mode on, no auto-suspend on AC"
    fi
}
