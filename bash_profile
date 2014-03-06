if [ -f ~/.bashrc ] ; then
    . ~/.bashrc
fi

#if [[ -s /Users/shichiku_yuki/.nvm/nvm.sh ]] ; then
#    source /Users/shichiku_yuki/.nvm/nvm.sh ; 
#fi

source ~/.nvm/nvm.sh
nvm use v0.10.25
npm_dir=${NVM_PATH}_modules
export NODE_PATH=$npm_dir

##
# Your previous /Users/shichiku_yuki/.bash_profile file was backed up as /Users/shichiku_yuki/.bash_profile.macports-saved_2013-07-04_at_13:16:31
##

# MacPorts Installer addition on 2013-07-04_at_13:16:31: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

export PATH=/usr/local/bin:$PATH
