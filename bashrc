export LANG=ja_JP.UTF-8
case ${UID} in
    0)
            LANG=C
                ;;
esac

alias ll='ls -la'
alias la='ls -a'
#export NODE_PATH=/Users/shichiku_yuki/.nvm/v0.10.22/bin
export PATH=$PATH:/Users/shichiku_yuki/Documents/project/pigg/fantasia.trunk/node_modules/boost/bin
export PATH=$PATH:/Users/shichiku_yuki/Documents/project/pigg/fantasia.trunk/bin
export PATH=$NODE_PATH:$PATH

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_40.jdk/Contents/Home


#alias vim='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'

[[ -s "$HOME/.pythonbrew/etc/bashrc" ]] && source "$HOME/.pythonbrew/etc/bashrc"

ulimit -n 4096
