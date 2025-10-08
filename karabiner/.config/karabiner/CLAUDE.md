# Karabiner Elements Configuration with Goku

## Overview

This configuration uses **Goku** (GokuRakuJoudo) to transform a human-readable EDN (Extensible Data Notation) file into the complex JSON format that Karabiner Elements requires. The EDN format allows for much more maintainable and understandable keyboard configurations.

## File Structure

### Key Files
- **`karabiner.edn`** - Source configuration file (human-readable, edit this!)
- **`karabiner.json`** - Generated output file (DO NOT EDIT - will be overwritten by goku)
- **Location**: `/Users/kevin/dotfiles/karabiner/.config/karabiner/`
- **Symlinked to**: `/Users/kevin/.config/karabiner/` (where Karabiner Elements reads from)

## How to Update Configuration

### Step 1: Edit the EDN file
```bash
cd /Users/kevin/dotfiles/karabiner/.config/karabiner
vim karabiner.edn  # or your preferred editor
```

### Step 2: Compile with Goku
**IMPORTANT**: You MUST run goku from the directory containing the EDN file:
```bash
cd /Users/kevin/dotfiles/karabiner/.config/karabiner
goku
```

### Step 3: Reload Karabiner (if changes don't apply automatically)
```bash
# Option 1: Force reload via launchctl
launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server

# Option 2: Restart Karabiner Elements from menu bar
# Click Karabiner Elements icon → Quit Karabiner Elements
# Then reopen from Applications
```

## EDN File Structure

### 1. Profiles Section
```clojure
:profiles {:Default {:default true
                     :sim 20      ; simultaneous key threshold (ms)
                     :delay 200   ; delay before layer activation
                     :alone 1000  ; max time for "alone" key press
                     :held 200}}  ; time to consider key "held"
```

### 2. Devices Section
```clojure
:devices {:voyager [{:vendor_id 12951 :product_id 6519}]}
```
Defines specific keyboard devices. Rules can be conditionally applied with `:condi :!voyager`.

### 3. Simlayers Section
```clojure
:simlayers {:mode-name {:key :trigger-key}}
```
Simlayers are activated by holding a trigger key and pressing another key within a short time window. Once activated, the layer remains active as long as the trigger key is held.

### 4. Main Rules Section
```clojure
:main [{:des "description"
        :rules [rule1 rule2 ...]}]
```

## Key Concepts

### Modifiers Syntax
- `!` = mandatory modifier
- `#` = optional modifier
- `C` = left_command (⌘)
- `T` = left_control (⌃)
- `O` = left_option (⌥)
- `S` = left_shift (⇧)
- `Q` = right_command
- `W` = right_control
- `E` = right_option
- `R` = right_shift
- `!!` = hyper (⌘⌃⌥⇧)
- `##` = optional any modifier

### Rule Structure
```clojure
[:from-key :to-key :conditions {:options}]
```

Examples:
- `[:a :b]` - Simple mapping: a → b
- `[:!Ca :!Cb]` - With modifiers: Cmd+a → Cmd+b
- `[:a :b nil {:alone :c}]` - Tap for c, hold for b
- `[:##a :!Ca]` - Any modifier+a → Cmd+a

### Simlayer Rules
When using simlayers, the syntax changes slightly:
```clojure
{:des "mode description"
 :rules [:mode-name          ; Activate this mode
         [:key :!Modifier+key] ; Mappings within the mode
         [:key2 :output2]]}
```

The `:condi` keyword can be added before the mode name for conditional activation.

## Current Configuration

### Active Simlayers
1. **spacebar-mode** - Navigation arrows (h/j/k/l → arrows)
2. **r-mode** - Delimiters and brackets
3. **e-mode** - Number pad
4. **period-mode** - Special functions with period key

### Home Row Mods (Traditional)
Using traditional home row modifiers (not simlayers) for better responsiveness:
- **A** → Shift when held, 'a' when tapped (left pinky)
- **S** → Control when held, 's' when tapped (left ring)
- **D** → Option when held, 'd' when tapped (left middle)
- **F** → Command when held, 'f' when tapped (left index)
- **J** → Command when held, 'j' when tapped (right index)
- **K** → Option when held, 'k' when tapped (right middle)
- **L** → Control when held, 'l' when tapped (right ring)
- **;** → Shift when held, ';' when tapped (right pinky)

### Special Keys
- **Caps Lock** → Escape when tapped, Control when held
- **Tab** → Tab when tapped, Meh (⌃⇧⌥) when held
- **Period** → Period when tapped, activates period-mode when held
- **Control + Y** → Backspace

### Period Mode Functionality
When period is held:
- Currently no mappings defined (can be added as needed)

## Troubleshooting

### Changes Not Taking Effect
1. Ensure you're running goku from the correct directory
2. Check for syntax errors in the EDN file (goku will report them)
3. Force reload Karabiner with launchctl command
4. Check Karabiner EventViewer to see if keys are being captured

### Common Syntax Errors
- Missing closing brackets `]` or `}`
- Wrong modifier syntax (use `!C` not `!Cmd`)
- Forgetting `:condi :!voyager` for device-specific rules
- Using `##` in mode definitions (only use in rules)

### Debugging
1. Open Karabiner EventViewer to see key events
2. Check `~/.config/karabiner/automatic_backups/` for previous configs
3. Look at generated `karabiner.json` to verify goku output

## Important Notes

1. **NEVER edit karabiner.json directly** - it will be overwritten
2. **Always run goku from the directory containing the EDN file**
3. **Traditional Home Row Mods**: Currently using traditional home row mods with timing detection for better responsiveness (delay: 150ms, held: 150ms)
4. **Simlayers**: Used only for spacebar, r, e, and period modes - these require holding the trigger key
5. **The `##` prefix** means "optional modifiers" - the key will work with or without modifiers
6. **Device-specific rules** use `:condi :!voyager` to only apply when the Voyager keyboard is not connected

## Resources
- [Goku GitHub](https://github.com/yqrashawn/GokuRakuJoudo)
- [Goku Tutorial](https://github.com/yqrashawn/GokuRakuJoudo/blob/master/tutorial.md)
- [Key Codes Reference](https://github.com/yqrashawn/GokuRakuJoudo/blob/master/src/karabiner_configurator/keys_info.clj)
- [Advanced Examples](https://gist.github.com/gsinclair/f4ab34da53034374eb6164698a0a8ace)
