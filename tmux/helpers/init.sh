#!/bin/bash
# to add scripts use this format #(~/.tmux/helpers/battery-health.sh)
export TmuxHostColor="colour${HostColorNum}"
export TmuxBgColor="colour234"
export TmuxSessionColor="colour10"
export TmuxMessageColor="colour16"
export TmuxMenuColor="colour39"

export TMUX_DIVIDER_RIGHT="#[fg=${TmuxMenuColor},bg=${TmuxBgColor}]⮂#[fg=${TmuxBgColor},bg=${TmuxMenuColor}]⮂#[fg=${TmuxSessionColor},bg=${TmuxBgColor}]"
export TMUX_DIVIDER_LEFT="#[fg=${TmuxBgColor},bg=${TmuxMenuColor}]⮀#[fg=${TmuxMenuColor},bg=${TmuxBgColor},nobold]⮀"
export TMUX_PREFIX_STAT='#{?client_prefix,#[reverse]<Prefix>#[noreverse] , }'
export TMUX_STATUS_RIGHT="#[fg=${TmuxSessionColor},bg=${TmuxBgColor}]${TMUX_PREFIX_STAT}${TMUX_DIVIDER_RIGHT} %a %b %d %R #[default]"
export TMUX_STATUS_LEFT="#[fg=${TmuxSessionColor},bg=${TmuxBgColor}] #S #[fg=${TmuxHostColor},bg=${TmuxBgColor}]#h $TMUX_DIVIDER_LEFT "
export TMUX_STATUS=' #I #W '
export TMUX_STATUS_CURRENT="#[fg=${TmuxMessageColor},bg=${TmuxMenuColor},noreverse,bright,nobold] #I #W #[fg=${TmuxMenuColor},bg=${TmuxBgColor},nobold]"
