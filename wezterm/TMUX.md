# WezTerm Remote Shell Capabilities (tmux Alternative)

WezTerm has built-in remote session support through its **domain system**, eliminating the need for tmux in many workflows.

## Remote Connection Options

### 1. SSH Domains (Simplest)

Built-in SSH client that spawns remote shells without needing a local ssh binary:

```lua
config.ssh_domains = {
  {
    name = "server",
    remote_address = "user@hostname",
    -- multiplexing = "WezTerm",  -- enables persistent sessions
  },
}
```

### 2. Multiplexer Domains (tmux-like Persistence)

WezTerm can run its own mux server on remote machines. Sessions persist across disconnects:

```lua
config.unix_domains = {
  { name = "unix" },  -- local socket-based mux
}

-- Remote mux requires wezterm-mux-server running on the remote
config.tls_clients = {
  {
    name = "remote-mux",
    remote_address = "hostname:8080",
  },
}
```

### 3. Serial Domains

For connecting to serial ports (embedded dev, network gear):

```lua
config.serial_ports = {
  { port = "/dev/ttyUSB0" },
}
```

## Comparison: WezTerm Mux vs tmux

| Feature | tmux | WezTerm Mux |
|---------|------|-------------|
| Requires remote install | Yes | Yes (wezterm-mux-server) |
| Session persistence | Yes | Yes |
| Native GPU rendering | No | Yes (local terminal) |
| Nested multiplexing | Common issue | Handled natively |
| Config location | Remote `.tmux.conf` | Local `wezterm.lua` |

## Quick Start: Persistent SSH Sessions

The easiest path to tmux-like behavior is adding `multiplexing = "WezTerm"` to SSH domains:

```lua
config.ssh_domains = {
  {
    name = "devbox",
    remote_address = "user@devbox.example.com",
    multiplexing = "WezTerm",  -- auto-starts mux server, reconnects to sessions
  },
}
```

This automatically:
1. Starts a mux server on the remote if not running
2. Reconnects to existing sessions on connection
3. Keeps sessions alive when you disconnect

## Connecting to Domains

Use the launcher menu or keybinds:

```lua
-- Add to keybinds
{ key = "d", mods = "LEADER", action = act.ShowLauncherArgs { flags = "DOMAINS" } },
```

Or connect via CLI:

```bash
wezterm connect devbox
```
