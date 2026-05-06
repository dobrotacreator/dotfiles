colon_prepend_unique() {
  [ -n "$2" ] || return

  colon_var_name=$1
  colon_value=$2
  eval "colon_current=\${$colon_var_name:-}"
  colon_new=$colon_value
  colon_old_ifs=$IFS

  if [ -n "${ZSH_VERSION:-}" ]; then
    for colon_entry in "${(@ps.:.)colon_current}"; do
      [ -n "$colon_entry" ] || continue
      [ "$colon_entry" = "$colon_value" ] && continue
      case ":$colon_new:" in
        *":$colon_entry:"*) ;;
        *) colon_new="$colon_new:$colon_entry" ;;
      esac
    done
  else
    IFS=:
    for colon_entry in $colon_current; do
      [ -n "$colon_entry" ] || continue
      [ "$colon_entry" = "$colon_value" ] && continue
      case ":$colon_new:" in
        *":$colon_entry:"*) ;;
        *) colon_new="$colon_new:$colon_entry" ;;
      esac
    done
  fi

  IFS=$colon_old_ifs
  eval "export $colon_var_name=\$colon_new"
}

colon_append_unique() {
  [ -n "$2" ] || return

  colon_var_name=$1
  colon_value=$2
  eval "colon_current=\${$colon_var_name:-}"
  colon_new=
  colon_old_ifs=$IFS

  if [ -n "${ZSH_VERSION:-}" ]; then
    for colon_entry in "${(@ps.:.)colon_current}"; do
      [ -n "$colon_entry" ] || continue
      [ "$colon_entry" = "$colon_value" ] && continue
      case ":$colon_new:" in
        *":$colon_entry:"*) ;;
        *) colon_new="${colon_new:+$colon_new:}$colon_entry" ;;
      esac
    done
  else
    IFS=:
    for colon_entry in $colon_current; do
      [ -n "$colon_entry" ] || continue
      [ "$colon_entry" = "$colon_value" ] && continue
      case ":$colon_new:" in
        *":$colon_entry:"*) ;;
        *) colon_new="${colon_new:+$colon_new:}$colon_entry" ;;
      esac
    done
  fi

  IFS=$colon_old_ifs
  colon_new="${colon_new:+$colon_new:}$colon_value"
  eval "export $colon_var_name=\$colon_new"
}

path_prepend() {
  [ -d "$1" ] || return
  colon_prepend_unique PATH "$1"
}

path_append() {
  [ -d "$1" ] || return
  colon_append_unique PATH "$1"
}

if [ -x /opt/homebrew/bin/brew ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"

  path_prepend "$HOMEBREW_PREFIX/sbin"
  path_prepend "$HOMEBREW_PREFIX/bin"

  colon_prepend_unique INFOPATH "$HOMEBREW_PREFIX/share/info"
fi

path_prepend "$HOME/.local/bin"
path_append /usr/local/go/bin
path_append "$HOME/go/bin"

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
path_prepend "$HOME/.cargo/bin"

path_prepend /opt/homebrew/opt/openjdk/bin
path_prepend "$HOME/.bun/bin"

if [ -d "$HOME/.orbstack/bin" ]; then
  path_append "$HOME/.orbstack/bin"
fi

if [ -n "${ZSH_VERSION:-}" ]; then
  orbstack_completion_dir="/Applications/OrbStack.app/Contents/Resources/completions/zsh"
  if [ -d "$orbstack_completion_dir" ]; then
    eval '
      case " ${fpath[*]} " in
        *" $orbstack_completion_dir "*) ;;
        *) fpath+=("$orbstack_completion_dir") ;;
      esac
    '
  fi
  unset orbstack_completion_dir
fi

if [ -f "$HOME/.aliases" ]; then
  . "$HOME/.aliases"
fi

if [ -f "$HOME/.work" ]; then
  . "$HOME/.work"
fi

unset colon_var_name colon_value colon_current colon_new colon_old_ifs colon_entry
