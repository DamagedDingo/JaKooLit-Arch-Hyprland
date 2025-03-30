#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Global Functions for Scripts #

set -e

# Show progress function
show_progress() {
  local pid=$1
  local package_name=$2
  local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○"
    "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●")
  local i=0

  tput civis
  printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ..." "$package_name"

  while ps -p $pid &>/dev/null; do
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
    i=$(((i + 1) % 10))
    sleep 0.3
  done

  printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ... Done!%-20s \n" "$package_name" ""
  tput cnorm
}

# Unified function to install packages
install_package() {
  local packages=("$@")

  for pkg in "${packages[@]}"; do
    # Check if package is already installed
    if pacman -Q "$pkg" &>/dev/null; then
      echo -e "${INFO} ${MAGENTA}$pkg${RESET} is already installed. Skipping..."
      continue
    fi

    # Try installing with pacman
    echo -e "${NOTE} Attempting to install ${YELLOW}$pkg${RESET} with pacman..."
    (
      stdbuf -oL sudo pacman -S --noconfirm "$pkg" 2>&1
    ) >>"$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$pkg"

    # Check if pacman succeeded
    if pacman -Q "$pkg" &>/dev/null; then
      echo -e "${OK} Package ${YELLOW}$pkg${RESET} has been successfully installed!"
      continue
    fi

    # Check for yay or paru
    local aur_helper=$(command -v yay || command -v paru)
    if [[ -z "$aur_helper" ]]; then
      echo -e "${INFO} No AUR helper found. Attempting to install paru..."
      (
        stdbuf -oL sudo pacman -S --needed --noconfirm base-devel git 2>&1
      ) >>"$LOG" 2>&1 &
      PID=$!
      show_progress $PID "base-devel and git"

      git clone https://aur.archlinux.org/paru.git >>"$LOG" 2>&1
      cd paru
      (
        stdbuf -oL makepkg -si --noconfirm 2>&1
      ) >>"$LOG" 2>&1 &
      PID=$!
      show_progress $PID "paru"
      cd ..

      aur_helper=$(command -v paru)
      if [[ -z "$aur_helper" ]]; then
        echo -e "${ERROR} Failed to install paru. Cannot proceed with AUR installation."
        return 1
      fi
    fi

    # Try installing with AUR helper
    echo -e "${NOTE} Attempting to install ${YELLOW}$pkg${RESET} with $aur_helper..."
    (
      stdbuf -oL $aur_helper -S --noconfirm "$pkg" 2>&1
    ) >>"$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$pkg"

    # Check if AUR helper succeeded
    if $aur_helper -Q "$pkg" &>/dev/null; then
      echo -e "${OK} Package ${YELLOW}$pkg${RESET} has been successfully installed!"
    else
      echo -e "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Please check the $LOG. You may need to install manually."
      return 1
    fi
  done

  return 0
}

# Function for removing packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if pacman -Qi "$pkg" &>/dev/null; then
    echo -e "${NOTE} removing $pkg ..."
    sudo pacman -R --noconfirm "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"

    if ! pacman -Qi "$pkg" &>/dev/null; then
      echo -e "\e[1A\e[K${OK} $pkg removed."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg Removal failed. No actions required."
      return 1
    fi
  else
    echo -e "${INFO} Package $pkg not installed, skipping."
  fi
  return 0
}
