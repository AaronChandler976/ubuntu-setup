# shellcheck shell=bash
# Step (optional, --robotics): ROS 2 via the official apt repo, plus Gazebo.
# Ubuntu 26.04 -> ROS 2 Lyrical Luth, 24.04 -> Jazzy. Docs: https://docs.ros.org/

step_robotics() {
    step "ROS 2 $ROS_DISTRO"
    [[ -z $ROS_DISTRO ]] && { warn "No ROS 2 distro mapped for Ubuntu $CODENAME"; return 1; }

    apt_install locales
    sudo locale-gen en_US en_US.UTF-8 >/dev/null
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

    if ! dpkg -s ros2-apt-source >/dev/null 2>&1; then
        local ver deb
        ver=$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F '"tag_name"' | awk -F'"' '{print $4}')
        deb=$(mktemp --suffix=.deb)
        if [[ -n $ver ]] && curl -fsSL -o "$deb" "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ver}/ros2-apt-source_${ver}.${CODENAME}_all.deb"; then
            sudo dpkg -i "$deb" >/dev/null
        else
            warn "Couldn't download the ROS apt source package - follow docs.ros.org/en/$ROS_DISTRO/Installation.html"
            rm -f "$deb"; return 1
        fi
        rm -f "$deb"
        sudo apt-get update >/dev/null
    fi

    apt_install ros-dev-tools "ros-$ROS_DISTRO-desktop" || { warn "ROS 2 install failed"; return 1; }
    apt_install "ros-$ROS_DISTRO-ros-gz" || warn "Gazebo (ros-$ROS_DISTRO-ros-gz) failed - install it later"

    [[ -f /etc/ros/rosdep/sources.list.d/20-default.list ]] || sudo rosdep init >/dev/null
    rosdep update >/dev/null 2>&1 || warn "rosdep update failed (run it later)"
    bashrc_add "source /opt/ros/$ROS_DISTRO/setup.bash"
    ok "ROS 2 $ROS_DISTRO installed (new terminals have 'ros2' ready)"
}
