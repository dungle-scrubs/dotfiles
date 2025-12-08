#!/bin/bash

# Code Validator Hook
# Runs linting and type checking before Write/Edit operations
# Exit codes:
#   0 = success, allow tool execution
#   2 = validation failure, block tool execution

input_json=$(cat)

# Extract tool name and file path from hook input
tool_name=$(echo "$input_json" | jq -r '.tool_name')
file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // ""')

# Only validate on Write/Edit operations
if [[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]]; then
    exit 0
fi

# Change to dotfiles root for pnpm
cd /Users/kevin/dotfiles || exit 0

# Check file type and run appropriate linter
if [[ "$file_path" =~ \.lua$ ]]; then
    # Lua files - run lua linting
    output=$(lua-language-server --check hammerspoon/.config/hammerspoon --checklevel=Warning --logpath=/tmp/lua-ls-log 2>&1)
    if echo "$output" | grep -qE '\[(Error|Warning)\]'; then
        echo "error: Lua linting issues found. Fix before proceeding:"
        echo ""
        echo "$output" | grep -E '\[(Error|Warning)\]' | head -20
        echo ""
        echo "Run locally: cd /Users/kevin/dotfiles && pnpm run lint:lua"
        exit 2
    fi
elif [[ "$file_path" =~ \.(ts|tsx)$ ]]; then
    # TypeScript files - run ESLint and typecheck
    webview_dir="hammerspoon/.config/hammerspoon/Spoons/Attention.spoon/webview"

    # Check if file is in webview directory
    if [[ "$file_path" =~ Attention\.spoon/webview/ ]]; then
        # Run ESLint (with --max-warnings 0 to fail on warnings)
        lint_output=$(pnpm --dir "$webview_dir" run lint 2>&1)
        lint_exit=$?
        if [ $lint_exit -ne 0 ]; then
            echo "error: ESLint issues found. Fix before proceeding:"
            echo ""
            echo "$lint_output" | tail -30
            echo ""
            echo "Run locally: cd /Users/kevin/dotfiles && pnpm run lint:webview"
            exit 2
        fi

        # Run TypeScript type check
        ts_output=$(pnpm --dir "$webview_dir" run typecheck 2>&1)
        ts_exit=$?
        if [ $ts_exit -ne 0 ]; then
            echo "error: TypeScript errors found. Fix before proceeding:"
            echo ""
            echo "$ts_output" | tail -30
            echo ""
            echo "Run locally: cd /Users/kevin/dotfiles && pnpm run typecheck:webview"
            exit 2
        fi
    fi
fi

exit 0
