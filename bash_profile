if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

if [ -f "$HOME/.bash_profile.local" ]; then
  . "$HOME/.bash_profile.local"
fi
