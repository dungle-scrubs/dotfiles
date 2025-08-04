#!/bin/zsh --login

if [ -n "$1" ]; then
	TAB_NAME="$1"
else
	TAB_NAME=""
fi

wezterm cli set-tab-title "$TAB_NAME"

exec zsh
