#!/bin/bash

selected_file=$(fzf --preview='bat {}' --exit-0)
if [ -n "$selected_file" ] && [ -f "$selected_file" ]; then
	echo "$selected_file"
else
	exit 1
fi
