#!/bin/bash
if [ -z "$1" ]; then
    read -p "Enter an email to scramble: " clean_email
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo 'Usage: scramble_email.sh [emailtoscramble]
       
$ scramble_email.sh "address@email.com"
    outputs: address at email dot com

$ echo "address@email.com" | scramble_email.sh
    outputs: address at email dot com

$ xargs -I {} -a email_list.txt scramble_email.sh {} > scrambled_emails.txt
    input a txt file with emails and scramble them into a new txt file
'
exit
else
    clean_email="$1"
fi

email_pattern="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z.]{2,8}$"

if [[ $clean_email =~ $email_pattern ]]; then
    scrambled_email="${clean_email//./' dot '}"
    scrambled_email="${scrambled_email//@/' at '}"
    echo $scrambled_email
else
echo "Invalid email address. Please enter a valid email."
fi
