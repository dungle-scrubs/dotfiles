#!/bin/bash

# Read the global CLAUDE.md and extract all include directives
CLAUDE_ROOT="$HOME/.config/ai/claude/session-start.md.md"

if [ -f "$CLAUDE_ROOT" ]; then
	echo "Loading global configuration files..."

	# Extract all include paths and read them
	grep -o '<!-- include: [^>]* -->' "$CLAUDE_ROOT" |
		sed 's/<!-- include: \(.*\) -->/\1/' |
		while read -r include_path; do
			# Expand ~ to home directory
			expanded_path="${include_path/#\~/$HOME}"

			if [ -f "$expanded_path" ]; then
				echo "✓ Reading: $expanded_path"
				cat "$expanded_path" >/dev/null 2>&1
			fi
		done

	# Also read the root file itself
	echo "✓ Reading: $CLAUDE_ROOT"
	cat "$CLAUDE_ROOT" >/dev/null 2>&1
else
	echo "✗ session-start.md not found at: $CLAUDE_ROOT"
fi
