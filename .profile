eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export PATH="$HOME/.bun/bin:$PATH"

if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

if [ -f ~/.work ]; then
  source ~/.work
fi
