export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

alias ls='ls --color'
alias c='clear'
alias la='ls -a'
alias ll='ls -l'
alias lla='ls -la'
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias gpo='git push origin'
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'
alias gr='git branch -r'
alias gplo='git pull origin'
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias gco='git checkout '
alias gl='git log'
alias gr='git remote'
alias grs='git remote show'
alias glo='git log --pretty="oneline"'
alias glol='git log --graph --oneline --decorate'

eval "$(/opt/homebrew/bin/brew shellenv)"
