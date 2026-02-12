# reload zsh config
alias reload!='RELOAD=1 source ~/.zshrc'

# Filesystem aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Helpers
alias grep='grep --color=auto'
alias df='df -h' # disk free, in Gigabytes, not bytes
alias du='du -h -c' # calculate disk usage for a folder

alias lpath='echo $PATH | tr ":" "\n"' # list the PATH separated by new lines

# Cross-platform clipboard
if [[ "$(uname)" == "Darwin" ]]; then
    : # pbcopy/pbpaste are native on macOS
elif command -v wl-copy &>/dev/null; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
elif command -v xclip &>/dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

# remove broken symlinks
alias clsym="find -L . -name . -o -type d -prune -o -type l -exec rm {} +"

# use eza if available
if command -v eza &>/dev/null; then
  alias ll="eza --icons --git --long"
  alias l="eza --icons --git --all --long"
else
  alias l="ls -lah ${colorflag}"
  alias ll="ls -lFh ${colorflag}"
fi
alias la="ls -AF ${colorflag}"
alias lld="ls -l | grep ^d"
alias rmf="rm -rf"
