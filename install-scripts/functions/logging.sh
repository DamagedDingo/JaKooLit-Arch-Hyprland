#!/bin/bash
#: <<'COMMENT.HEADER'
=========================================================================================================
Author:         JaKooLit
Repository:     https://github.com/JaKooLit/
Description:    Logging utility for KooL Arch-Hyprland installer scripts.
Todo:           Change to only generating the Log name and set the path in main scirpt instead.
                - Then it can also create logs in the current directory if needed.
==========================================================================================================
# END
COMMENT.HEADER

# ----- Begin -------------------------------------------------------------------------------

# Function to generate log file name
generate_log_file() {
    local script_name
    local base_name
    local date_stamp
    local log_file
    local revision=2
    local log_dir

    # Resolve the directory of this script (logging.sh)
    log_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../install-logs"

    # Ensure the Install-Logs directory exists
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi

    # Get the name of the calling script
    script_name=$(basename "${BASH_SOURCE[1]}" .sh) # Name of the script calling this function
    base_name=$(echo "$script_name" | sed -E 's/(^|-)([a-z])/\U\2/g') # Convert to Capitalized format
    date_stamp=$(date +%Y%m%d) # Current date in YYYYMMDD format

    # Generate initial log file name
    log_file="$log_dir/JaKooLit-Install-Logs-${base_name}-${date_stamp}.log"

    # Check if the log file already exists and handle revisions. 
    # The only reason I could think why the old file name had seconds in the previous code was when your testing and rerunning the script.. i'd prefer to overwrite but heres a quick workaround that shouldn't be seen by end users. 
    while [ -e "$log_file" ]; do
        log_file="$log_dir/JaKooLit-Install-Logs-${base_name}-${date_stamp}.rev$(printf "%03d" $revision).log"
        revision=$((revision + 1))
    done

    echo "$log_file"
}
