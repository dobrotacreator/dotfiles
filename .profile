export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/.cargo/env"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

if [ -f ~/.work ]; then
  source ~/.work
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
