# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source bash aliases if available
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# History configuration
HISTCONTROL=ignoreboth:erasedups  # ignore duplicates and remove duplicates from history
HISTSIZE=10000                    # increased from 1000
HISTFILESIZE=20000               # increased from 2000
HISTTIMEFORMAT="%F %T "          # add timestamps to history
shopt -s histappend              # append to history file, don't overwrite
shopt -s histverify              # verify history expansions before executing

# Shell options
shopt -s checkwinsize            # update LINES and COLUMNS after each command
shopt -s cdspell                 # correct minor spelling errors in cd commands
shopt -s dirspell                # correct minor spelling errors in directory names
shopt -s autocd                  # cd into directories by just typing the name

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Function to get git branch and status
git_prompt_info() {
    local branch
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        local status=""
        local git_status=$(git status --porcelain 2>/dev/null)
        
        # Check for various git states
        if [ -n "$git_status" ]; then
            if echo "$git_status" | grep -q "^M"; then
                status="${status}*"  # modified files
            fi
            if echo "$git_status" | grep -q "^A"; then
                status="${status}+"  # added files
            fi
            if echo "$git_status" | grep -q "^D"; then
                status="${status}-"  # deleted files
            fi
            if echo "$git_status" | grep -q "^??"; then
                status="${status}?"  # untracked files
            fi
        fi
        
        # Check if we're ahead/behind remote
        local ahead_behind
        ahead_behind=$(git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)
        if [ $? -eq 0 ]; then
            local behind=$(echo "$ahead_behind" | cut -f1)
            local ahead=$(echo "$ahead_behind" | cut -f2)
            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                status="${status}⇅"
            elif [ "$ahead" -gt 0 ]; then
                status="${status}↑"
            elif [ "$behind" -gt 0 ]; then
                status="${status}↓"
            fi
        fi
        printf " \001\033[93m\002(%s\001\033[91m\002%s\001\033[93m\002)\001\033[00m\002" "$branch" "$status"
    fi
}

# Set colored prompt based on terminal capability
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Configure prompt with git integration
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(git_prompt_info)\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(git_prompt_info)\$ '
fi
unset color_prompt force_color_prompt

# Set terminal title for xterm-compatible terminals
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable colored output for common commands
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# GPG TTY configuration for proper GPG agent functionality
export GPG_TTY=$(tty)

# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Common useful aliases (add more to ~/.bash_aliases for user-specific ones)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias h='history'
alias c='clear'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias less='less -R'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Development shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# Extract function for various archive types
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unar "$1"        ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and kill process by name
psgrep() {
    ps aux | grep -v grep | grep "$@" -i --color=auto
}

# Quick backup function
backup() {
    cp "$1"{,.bak}
}

# Show PATH in readable format
path() {
    echo $PATH | tr ':' '\n'
}