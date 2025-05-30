#!/bin/bash

# Function to generate a random password
generate_password() {
    local length=$1
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -le 0 ]; then
        echo "Please provide a valid positive integer for password length."
        exit 1
    fi

    local charset='A-Z:a-z:0-9:!@#$%^&*()_+[]{}|;:,.<>?'
    # Generate the password
    local password=$(cat /dev/urandom | tr -dc "$charset" | fold -w "$length" | head -n 1)
    echo "$password"
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <length>"
    exit 1
fi
generate_password "$1"
