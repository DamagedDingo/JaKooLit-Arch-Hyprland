#!/bin/bash
#: <<'COMMENT.HEADER'
=========================================================================================================
Author:         JaKooLit
Repository:     https://github.com/JaKooLit/
Description:    Define some colors for output messages used during installation scripts.
TODO:           
==========================================================================================================
# END
COMMENT.HEADER

# ----- Initialise Enviroment -------------------------------------------------------------------------------

# Define colors using ANSI escape codes
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ----- Check Dependencies ---------------------------------------------------------------------------------

# Ensure tput is available. Use fallback ANSI escape codes for this check.
if ! command -v tput &>/dev/null; then

    # Print error message with fallback colors
    echo -e "${RED}[ERROR]${YELLOW} 'tput'${RESET} is not installed or not supported in this terminal."
    exit 1
fi

# ----- Define Terminal Colors ---------------------------------------------------------------------------------

# Status messages: Sets and reverts terminal colors
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"

# General colors
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"

# Reset color
RESET="$(tput sgr0)"