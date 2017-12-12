# If not running interactively, don't do anything
if [[ -n "$PS1" ]]; then
  ############################################################
  #  aliases
  ############################################################
  # bash helpers
  alias sbp="source_if_exists $HOME/.bash_profile"
  alias clr='clear'
  alias df='df -kTh'
  alias du='du -kh'
  alias hideme='history -d $((HISTCMD-1)) &&'

  # safety first!
  alias rm='rm -i'
  alias mv='mv -i'
  alias cp='cp -i'

  # ls helpers
  alias ls='ls --color=auto'
  alias l='ls -CF'
  alias la='ls -a'
  alias ll='ls -lkh'
  alias lla='ll -a'
  alias lrt='ll -rt'
  alias lrta='lrt -a'
  alias lrtr='lrt -R'
  alias lrs='ll -rS'
  alias lrsa='lrs -a'
  alias lrsr='lrs -R'
  alias lr='ls -R'
  alias llr='ll -R'
  alias llra='llr -a'

  # grep helpers
  alias grep='grep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'
  alias egrep='egrep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'
  alias fgrep='fgrep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'

  # file helpers
  alias t1='tail -n1'
  alias h1='head -n1'
  alias tree='tree -I "\.git|\.svn|sandcube"'

  # git helpers
  alias g='hub_or_git'
  __git_complete g __git_main

  # homeshick helpers
  alias hr="cd $HSR"

  # ruby helpers
  alias rakeit='bundle exec rake db:drop && bundle exec rake db:create && bundle exec rake db:migrate && bundle exec rake db:seed'
  alias be='bundle exec'

  # beeline helpers
  alias beeline='beeline --color=true'

  # homebrew helpers
  alias brew-cleaner='brew update; brew cleanup'
  alias brew-cask-cleaner='brew upgrade brew-cask; brew cask cleanup'

  # Mac/Finder helpers
  alias show-files='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
  alias hide-files='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'
  # from http://www.maxum.com/Rumpus/Blog/OSXServer.html
  alias mac-server-http-disable='sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist && sudo rm -i /System/Library/LaunchDaemons/org.apache.httpd.plist'

  export GRC=`which grc 2>/dev/null`
  if [ "$TERM" != dumb ] && [ -n GRC ]
  then
    alias colourify="$GRC -es --colour=auto"
    alias mvnk="colourify -c $HOME/.grc/mvn.config mvn"
    alias kat="colourify -c $HOME/.grc/mvn.config"
  fi

  # ag helpers
  alias ag='ag --hidden'

  # vim helpers
  alias vi='vim'
  function vg() { vim -p $(ag -g $1 ${2:-./}); }
  function va() { vim -p $(ag -l "$1" ${2:-./}); }
  function vd() { vim -p $(git diff --name-only $1); }
fi
