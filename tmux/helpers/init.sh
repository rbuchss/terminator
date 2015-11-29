# to add scripts use this format #(~/.tmux/helpers/battery-health.sh)
export TMUX_DIVIDER_RIGHT='#[fg=colour39, bg=colour234]⮂#[fg=colour234,bg=colour39]⮂#[fg=colour10,bg=colour234]'
export TMUX_DIVIDER_LEFT='#[fg=colour234,bg=colour39]⮀#[fg=colour39,bg=colour234,nobold]⮀'
export TMUX_STATUS_RIGHT="$TMUX_DIVIDER_RIGHT %a %b %d %R#[default] "
export TMUX_STATUS_LEFT="#[fg=colour10,bg=colour234] #S #[fg=colour39,bg=colour234]#h $TMUX_DIVIDER_LEFT "
export TMUX_STATUS=' #I #W '
export TMUX_STATUS_CURRENT='#[fg=colour234,bg=colour39,noreverse,bright,nobold] #I ⮁ #W #[fg=colour39,bg=colour234,nobold]'
