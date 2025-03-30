#!/bin/bash
#: <<'EOF'
=========================================================================================================
Author:       JaKooLit
Repository:   https://github.com/JaKooLit/
Description:  
    - Downloads and installs the SDDM theme "sequoia_2" from JaKooLits repository.
    - Customises the configuration files and primes it to be able to update the wallpaper.
==========================================================================================================
EOF

# ---------------------------------------------------------------------------------------------------------
# 🔸 User Configuration Zone:
# --------------------------------------------------------------------------------------------------------

# Source URL for the theme.
source_theme="https://codeberg.org/JaKooLit/sddm-sequoia"

# New name for the SDDM theme.
theme_name="sequoia_2" # New name for the SDDM theme.


# --------------------------------------------------------------------------------------------------------
# ⚠️ Beginning System Configuration Zone: 
# --------------------------------------------------------------------------------------------------------
# The code below contains critical logic for the script's functionality.
# Editing this section without understanding its purpose may cause the script to fail.
# ---------------------------------------------------------------------------------------------------------


# ----- Variables -----------------------------------------------------------------------------------------

# Set the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/functions/global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# ----- Logging ------------------------------------------------------------------------------------------

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm_theme.log"

# ----- Theme Installation --------------------------------------------------------------------------------

# SDDM-themes
printf "${INFO} Installing ${SKY_BLUE}Additional SDDM Theme${RESET}\n"

# Check if /usr/share/sddm/themes/$theme_name exists and remove if it does
if [ -d "/usr/share/sddm/themes/$theme_name" ]; then
  sudo rm -rf "/usr/share/sddm/themes/$theme_name"
  echo -e "\e[1A\e[K${OK} - Removed existing $theme_name directory." 2>&1 | tee -a "$LOG"
fi

# Check if $theme_name directory exists in the current directory and remove if it does
if [ -d "$theme_name" ]; then
  rm -rf "$theme_name"
  echo -e "\e[1A\e[K${OK} - Removed existing $theme_name directory from the current location." 2>&1 | tee -a "$LOG"
fi

# Clone the repository
if git clone --depth=1 "$source_theme" "$theme_name"; then
  if [ ! -d "$theme_name" ]; then
    echo "${ERROR} Failed to clone the repository." | tee -a "$LOG"
  fi

  # Create themes directory if it doesn't exist
  if [ ! -d "/usr/share/sddm/themes" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    echo "${OK} - Directory '/usr/share/sddm/themes' created." | tee -a "$LOG"
  fi

  # Move cloned theme to the themes directory
  sudo mv "$theme_name" "/usr/share/sddm/themes/$theme_name" 2>&1 | tee -a "$LOG"

# ----- SDDM Configuration --------------------------------------------------------------------------------

  # Initialising the SDDM theme
  sddm_conf_dir="/etc/sddm.conf.d"
  BACKUP_SUFFIX=".bak"
  
  echo -e "${NOTE} Initialising the login screen and applying the new theme." | tee -a "$LOG"

  if [ -d "$sddm_conf_dir" ]; then
    echo "Backing up files in $sddm_conf_dir" | tee -a "$LOG"
    for file in "$sddm_conf_dir"/*; do
      if [ -f "$file" ]; then
        if [[ "$file" == *$BACKUP_SUFFIX ]]; then
          echo "Skipping backup file: $file" | tee -a "$LOG"
          continue
        fi
        # Backup each original file
        sudo cp "$file" "$file$BACKUP_SUFFIX" 2>&1 | tee -a "$LOG"
        echo "Backup created for $file" | tee -a "$LOG"
        
        # Edit existing "Current=" 
        if grep -q '^[[:space:]]*Current=' "$file"; then
          sudo sed -i "s/^[[:space:]]*Current=.*/Current=$theme_name/" "$file" 2>&1 | tee -a "$LOG"
          echo "Updated theme in $file" | tee -a "$LOG"
        fi
      fi
    done
  else
    echo "$CAT - $sddm_conf_dir not found, creating..." | tee -a "$LOG"
    sudo mkdir -p "$sddm_conf_dir" 2>&1 | tee -a "$LOG"
  fi

  # Check if the theme.conf.user file exists, if not create it
  if [ ! -f "$sddm_conf_dir/theme.conf.user" ]; then
    echo -e "[Theme]\nCurrent = $theme_name" | sudo tee "$sddm_conf_dir/theme.conf.user" > /dev/null
    
    # Check if the file was created successfully
    if [ -f "$sddm_conf_dir/theme.conf.user" ]; then
      echo "Created and configured $sddm_conf_dir/theme.conf.user with theme $theme_name" | tee -a "$LOG"
    else
      echo "Failed to create $sddm_conf_dir/theme.conf.user" | tee -a "$LOG"
    fi
  else
    echo "$sddm_conf_dir/theme.conf.user already exists, skipping creation." | tee -a "$LOG"
  fi

# ----- Wallpaper Configuration --------------------------------------------------------------------------

  # Replace the themes default wallpaper with JaKooLit's initial wallpaper.
  sudo cp -r assets/sddm.png "/usr/share/sddm/themes/$theme_name/backgrounds/.wallpaper_current" 2>&1 | tee -a "$LOG"
  sudo sed -i 's|^wallpaper=".*"|wallpaper="backgrounds/.wallpaper_current"|' "/usr/share/sddm/themes/$theme_name/theme.conf" 2>&1 | tee -a "$LOG"

  echo "${OK} - ${MAGENTA}Additional SDDM Theme${RESET} successfully installed." | tee -a "$LOG"

else

  echo "${ERROR} - Failed to clone the sddm theme repository. Please check your internet connection." | tee -a "$LOG" >&2
fi

# ----- Finalization -------------------------------------------------------------------------------------

printf "\n%.0s" {1..2}