############################################################
#  aliases
############################################################
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
alias clr='clear'
alias df='df -kTh'
alias du='du -kh'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias grep='grep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'
alias egrep='egrep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'
alias fgrep='fgrep --color=auto --exclude-dir="\.git" --exclude-dir="\.svn"'
alias t1='tail -n1'
alias h1='head -n1'
alias vi='vim'
alias g='hub_or_git'
__git_complete g __git_main
alias sbp="source_if_exists $HOME/.bash_profile"
alias hr="cd $HSR"
alias rakeit="rake db:drop && rake db:create && rake db:migrate && rake db:seed"
alias beeline="beeline --color=true"
alias tree="tree -I '\.git|\.svn|sandcube'"
alias brew_cleaner="brew update && brew upgrade brew-cask && brew cleanup && brew cask cleanup"

alias hideme='history -d $((HISTCMD-1)) &&'

export GRC=`which grc 2>/dev/null`
if [ "$TERM" != dumb ] && [ -n GRC ]
then
  alias colourify="$GRC -es --colour=auto"
  alias mvnk="colourify -c $HOME/.grc/mvn.config mvn"
  alias kat="colourify -c $HOME/.grc/mvn.config"
fi

function vg() {
  vim -p $(ag -g $1)
}

function va() {
  vim -p $(ag -l $1)
}
