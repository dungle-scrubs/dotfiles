# Kanata Configuration

## Overview

Kanata is a cross-platform keyboard remapper. This config implements home row mods and symbol/numpad layers, migrated from Karabiner/Goku.

## File Structure

```
.config/kanata/
└── kanata.kbd    # Main config
```

## Layers

### Base Layer

Standard QWERTY with tap-hold keys:

| Key | Tap | Hold |
|-----|-----|------|
| Caps Lock | Escape | Meh (Ctrl+Opt+Shift) |
| Tab | Tab | Hyper (Ctrl+Opt+Shift+Cmd) |
| Right Cmd | F13 (SuperWhisper) | Right Cmd |
| Space | Space | Navigation layer |
| E | E | Numpad layer |
| R | R | Symbols layer |

### Home Row Mods

Left hand (ASDF → Shift/Ctrl/Opt/Cmd):

| Key | Tap | Hold |
|-----|-----|------|
| A | a | Left Shift |
| S | s | Left Ctrl |
| D | d | Left Opt |
| F | f | Left Cmd |

Right hand (JKL; → Cmd/Opt/Ctrl/Shift):

| Key | Tap | Hold |
|-----|-----|------|
| J | j | Right Cmd |
| K | k | Right Opt |
| L | l | Right Ctrl |
| ; | ; | Right Shift |

### Symbols Layer (Hold R)

```
Y  U  I  O  P  [         ^  $  *  &  +  #
H  J  K  L  ;  '    →    @  (  {  }  )  |
N  M  ,  .  /            %  [  ]  <  >
Space                    =
```

| Position | Output |
|----------|--------|
| Y | `^` (caret) |
| U | `$` (dollar) |
| I | `*` (asterisk) |
| O | `&` (ampersand) |
| P | `+` (plus) |
| [ | `#` (hash) |
| H | `@` (at) |
| J | `(` (open paren) |
| K | `{` (open brace) |
| L | `}` (close brace) |
| ; | `)` (close paren) |
| ' | `\|` (pipe) |
| N | `%` (percent) |
| M | `[` (open bracket) |
| , | `]` (close bracket) |
| . | `<` (less than) |
| / | `>` (greater than) |
| Space | `=` (equals) |

### Numpad Layer (Hold E)

```
Y  U  I  O  P         ⌫  7  8  9  +
H  J  K  L  ;  '  →   .  4  5  6  -  ↵
N  M  ,  .  /         0  1  2  3  ↵
```

| Position | Output |
|----------|--------|
| Y | Backspace |
| U/I/O | 7/8/9 |
| P | `+` |
| H | `.` |
| J/K/L | 4/5/6 |
| ; | `-` |
| ' | Enter |
| N | 0 |
| M/,/. | 1/2/3 |
| / | Enter |

### Navigation Layer (Hold Space)

| Key | Output |
|-----|--------|
| H | Left arrow |
| J | Down arrow |
| K | Up arrow |
| L | Right arrow |

## Configuration Details

### Timing

All tap-hold keys use 200ms for both tap and hold thresholds:

```lisp
(tap-hold-release 200 200 <tap> <hold>)
```

`tap-hold-release` is used for home row mods to prevent accidental triggers during fast typing (releases the hold only when both keys are released).

### Process Unmapped Keys

```lisp
(defcfg
  process-unmapped-keys yes
)
```

Ensures non-remapped keys pass through normally.

## Common Tasks

### Change Timing

Modify the `200 200` values in tap-hold definitions:
- First value: tap timeout (ms before hold activates)
- Second value: hold timeout (ms to register as hold)

### Add a New Layer

1. Create `deflayer`:
```lisp
(deflayer myLayer
  ...keys...
)
```

2. Add trigger alias:
```lisp
key (tap-hold 200 200 <tap> (layer-while-held myLayer))
```

3. Add to base layer

## Running Kanata

```bash
# Start with config
sudo kanata -c ~/.config/kanata/kanata.kbd

# Or with debug output
sudo kanata -c ~/.config/kanata/kanata.kbd -d
```

**Note**: Requires sudo on macOS for keyboard access (or can be run as a launch daemon).

## Known Issue: macOS Option Key Special Characters

### Problem

On macOS, pressing Ctrl+Alt+Shift+key (Meh+key) produces special characters instead of passing through as a keyboard shortcut. For example:
- Meh+H → `Ô` instead of Ctrl+Alt+Shift+H
- Meh+L → `Ò` instead of Ctrl+Alt+Shift+L

This happens because macOS's input method layer transforms Option (Alt) + key combinations into special characters **after** Kanata sends the key events. This is OS-level behavior that Kanata cannot bypass.

### Why This Happens

1. Kanata sends Ctrl+Alt+Shift+H to macOS
2. macOS input method intercepts Option+H and transforms it to `Ô`
3. Apps receive `Ô` with Ctrl+Shift modifiers, not the intended shortcut

### Solutions

#### Option 1: Use Karabiner-Elements for Meh Key

Karabiner intercepts keys at a lower level (virtual HID) and can send raw keycodes that bypass macOS input method transformation. Use Karabiner for Meh/Hyper keys while keeping Kanata for other remapping.

#### Option 2: Switch Keyboard Input Source

Use "Unicode Hex Input" keyboard layout (System Settings → Keyboard → Input Sources). This layout has no Option-key special character mappings.

**Downside**: Changes how you input unicode characters (requires hex codes).

#### Option 3: Create Custom Keyboard Layout

Use [Ukelele](https://software.sil.org/ukelele/) to create a custom keyboard layout that removes Option-key character mappings.

#### Option 4: Map to Function Keys (Workaround)

In Kanata, map Meh+key to unused function keys (F13-F20), then bind those in your apps:

```lisp
(deflayer meh
  ...
  _    _    _    _    _    _    f17  _    _    f18  _    _    _
  ...
)
```

Then in WezTerm/other apps, bind F17/F18 instead of Ctrl+Alt+Shift+H/L.

**Downside**: Loses semantic meaning of "Meh+H"; requires app-specific rebinding.

#### Option 5: Use Ctrl+Cmd+Shift Instead of Ctrl+Alt+Shift

Avoid the Option key entirely by redefining Meh as Ctrl+Cmd+Shift:

```lisp
cap (tap-hold 150 150 esc (multi lctl lmet lsft))
```

**Downside**: Non-standard Meh definition; may conflict with other shortcuts.
