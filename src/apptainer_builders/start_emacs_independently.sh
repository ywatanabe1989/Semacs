#!/bin/bash
# Time-stamp: "2024-12-18 09:47:52 (ywatanabe)"
# File: ./Ninja/.apptainer/ninja/ninja.sandbox/opt/Ninja/src/apptainer_builders/start_emacs_independently.sh

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script ($0) must be run as root" >&2
    exit 1
fi

source "$(dirname $0)"/ENVS.sh.src

# Define shared_emacsd globally
shared_emacsd=/opt/Ninja/src/apptainer_builders/shared_emacsd

# Add at beginning of script
xhost +local:root > /dev/null 2>&1

# Generate and export CRDT password
CRDT_PASSWORD=$(openssl rand -base64 12)
export CRDT_PASSWORD


init_environment() {
    killall -9 "$NINJA_EMACS_CLIENT" 2>/dev/null || true
    killall -9 "$NINJA_EMACS_BIN" 2>/dev/null || true

    # # Global permissions
    # chown -R root:$NINJAS_GROUP /home
    # chown -R root:$NINJAS_GROUP $shared_emacsd
    # chmod -R 750 $shared_emacsd
}


start_emacs_daemon() {
    local user=$1
    local display=$2
    local user_socket_dir="/home/$user/emacs-server"
    local user_socket="$user_socket_dir/server"
    local log_file=/tmp/emacs-$user.log

    mkdir -p $user_socket_dir
    chown $user:$user $user_socket_dir
    chmod 700 $user_socket_dir

    # Cleanup existing socket
    rm -f $user_socket 2>&1 >/dev/null

    # Start daemon
    rm $log_file 2>&1 >/dev/null
    su - $user -c "DISPLAY=$display emacs --daemon=$user_socket -Q > $log_file 2>&1" &

    # Verify daemon
    sleep 2
    if ! pgrep -u $user emacs >/dev/null; then
        echo "Emacs daemon failed to start for $user"
        cat $log_file
        return 1
    fi

    # Wait for socket
    local attempt=0
    while [ ! -S "$user_socket" ] && [ $attempt -lt 10 ]; do
        echo "Waiting for socket ($attempt/10)..."
        ls -l "$user_socket"* 2>/dev/null || true
        sleep 1
        ((attempt++))
    done


    # Start client with init file
    if su - $user -c "DISPLAY=$display emacsclient -c -n -s $user_socket --eval '(load-file \"~/.emacs.d/init.el\")' > /dev/null 2>&1 &"; then
        echo "Success: $user_socket launched"
        return 0
    else
        echo "Failed: Check error log below"
        cat $log_file
        return 1
    fi

}


start_emacs_for_user() {
    local user=$1
    local display=$2

    # setup_user_directories "$user"
    start_emacs_daemon "$user" "$display"
}


main() {
    init_environment
    for i in $(seq 1 $NINJA_N_AGENTS); do
        user="ninja-$(printf "%03d" $i)"
        start_emacs_for_user "$user" ":0"
    done
}

main

# EOF
