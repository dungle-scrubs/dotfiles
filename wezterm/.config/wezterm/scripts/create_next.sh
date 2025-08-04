#!/bin/zsh --login

if [ -n "$1" ]; then
	PROJECT_NAME="$1"
else
	PROJECT_NAME=""
fi

mkdir -p ~/dev/scratch
cd ~/dev/scratch || exit

COMMON_ARGS=(--typescript --eslint --tailwind --src-dir --app --use-pnpm --turbopack --import-alias="@/src/*")

if [ -n "$PROJECT_NAME" ]; then
	pnpm dlx create-next-app@latest $PROJECT_NAME $COMMON_ARGS
else
	pnpm dlx create-next-app@latest $COMMON_ARGS
fi

cd $PROJECT_NAME

FIRST_PANE=$(wezterm cli list | grep "$PROJECT_NAME" | head -n 1 | awk '{print $3}')

# Start the dev server immediately in a new pane
wezterm cli split-pane --bottom --percent 20 -- pnpm dev

# Put focus on the first pane
wezterm cli activate-pane --pane-id "$FIRST_PANE"

# In the main pane, open neovim
nvim .

exec zsh
