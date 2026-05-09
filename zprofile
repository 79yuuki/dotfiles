if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -f "$HOME/.zprofile.local" ]; then
  . "$HOME/.zprofile.local"
fi
