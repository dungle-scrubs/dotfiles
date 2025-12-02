# Daily Scheduler for Hammerspoon

## Goal

Run actions once per day on first wake/startup (e.g., open a website at first login).

## Implementation

Add to `hammerspoon/.config/hammerspoon/init.lua`:

```lua
----------------------------------------------------------------------------------------------------
-- Daily Scheduler (runs once per day on first wake/startup)
----------------------------------------------------------------------------------------------------

local dailyScheduler = {}

-- Run a function only once per day, tracked by key
function dailyScheduler.runOncePerDay(key, fn)
    local today = os.date("%Y-%m-%d")
    local lastRun = hs.settings.get("dailyScheduler." .. key)
    if lastRun ~= today then
        hs.settings.set("dailyScheduler." .. key, today)
        fn()
    end
end

-- Define daily tasks here
local function runDailyTasks()
    dailyScheduler.runOncePerDay("morning-website", function()
        hs.urlevent.openURL("https://example.com")
    end)

    -- Add more daily tasks as needed:
    -- dailyScheduler.runOncePerDay("another-task", function()
    --     -- do something
    -- end)
end

-- Run on system wake
dailyScheduler.watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        runDailyTasks()
    end
end)
dailyScheduler.watcher:start()

-- Also run on Hammerspoon load (covers startup/login)
runDailyTasks()

-- Expose globally
_G.dailyScheduler = dailyScheduler
```

## Usage

1. Replace `https://example.com` with the desired URL
2. Add more tasks by calling `dailyScheduler.runOncePerDay("unique-key", function() ... end)`
3. Each task only runs once per calendar day, regardless of how many times the computer wakes/sleeps

## Notes

- Uses `hs.settings` to persist the last run date across restarts
- Settings are stored in Hammerspoon's preferences (survives reloads)
- The key prefix `dailyScheduler.` keeps settings organized
