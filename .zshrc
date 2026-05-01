[[ -r ~/.profile ]] && emulate sh -c 'source ~/.profile'

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

load_zinit() {
  if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || {
      print -u2 "zinit is not installed; skipping zsh plugins"
      return
    }
  fi

  if [ ! -r "${ZINIT_HOME}/zinit.zsh" ]; then
    print -u2 "zinit.zsh not found; skipping zsh plugins"
    return
  fi

  source "${ZINIT_HOME}/zinit.zsh"
  zinit ice depth=1
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting
}

load_zinit

autoload -Uz compinit
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"
compinit -d "$ZSH_CACHE_DIR/.zcompdump"
if (( $+functions[zinit] )); then
  zinit cdreplay -q
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

autoload -Uz vcs_info
precmd_functions+=(vcs_info)
setopt prompt_subst
zstyle ':vcs_info:*' formats ' %F{white}[%b]%f%c%u '
zstyle ':vcs_info:*' actionformats ' %F{yellow}[%b|%a]%f%c%u '
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{green}●%f'
zstyle ':vcs_info:*' unstagedstr '%F{red}✗%f'
zstyle ':vcs_info:*' actionstr '%F{magenta}▰%f'
NEWLINE=$'\n'
PROMPT='╭%F{cyan}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_}${NEWLINE}╰$ '

HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
bindkey "^[^P" history-beginning-search-backward
bindkey "^[^N" history-beginning-search-forward

zle_highlight+=(paste:none)
