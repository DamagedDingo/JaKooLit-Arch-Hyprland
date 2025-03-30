#!/bin/bash
#: <<'COMMENT.HEADER'
=========================================================================================================
Author:         JaKooLit
Repository:     https://github.com/JaKooLit/
Description:    Logging utility for KooL Arch-Hyprland installer scripts.
TODO:           - Add logging
==========================================================================================================
# END
COMMENT.HEADER

# ----- BEGIN -------------------------------------------------------------------------------

execute_script() {

    local script_path="$1"
    local script_name=$(basename "$script_path")

    if [ -f "$script_path" ]; then

        chmod +x "$script_path"

        if [ -x "$script_path" ]; then
            env "$script_path"
            echo "Successfully executed script: '$script_name'."
        else
            echo "Failed to make script '$script_name' executable."
        fi

    else
        echo "Script '$script_name' not found."
    fi

    sleep 1

}
