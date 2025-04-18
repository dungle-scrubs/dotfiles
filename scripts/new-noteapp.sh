#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New NoteApp note
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author dungle-scrubs
# @raycast.authorURL https://raycast.com/dungle-scrubs

# AppleScript to open a new instance of NoteApp
osascript <<EOD
tell application "NoteApp"
    activate
    tell application "System Events"
        tell process "NoteApp"
            click menu item "New" of menu "File" of menu bar 1
        end tell
    end tell
end tell
EOD