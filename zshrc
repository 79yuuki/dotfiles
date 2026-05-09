[[ -o interactive ]] || return

setopt auto_cd
setopt hist_ignore_all_dups
setopt interactive_comments
setopt share_history

export LANG="${LANG:-ja_JP.UTF-8}"
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less -FRX}"
export CLICOLOR=1

path_prepend() {
  [ -d "$1" ] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_append() {
  [ -d "$1" ] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.claude/local"
path_append "$HOME/.turso"
path_append "$HOME/.antigravity/antigravity/bin"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi

if [ -f "$HOME/Development/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/Development/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/Development/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/Development/google-cloud-sdk/completion.zsh.inc"
fi

alias ll='ls -lah'
alias la='ls -A'
alias gs='git status -sb'
alias gl='git log --oneline --decorate --graph -20'
alias tm='task-master'
alias taskmaster='task-master'

ulimit -n 10240 2>/dev/null || true

if [ -f "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi
