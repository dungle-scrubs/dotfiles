<!-- https://apple.stackexchange.com/a/388623 -->

# What should be used in ZSH on a Mac
I posted a more narrowly scoped question on Unix & Linux and got some clarification on how these files "work." Here's the summary of that answer and what I've learned in my research as to what, in my opinion should be used in a ZSH environment on a Mac.

## `.zprofile`
`.zlogin` and `.zprofile` are basically the same thing - they set the environment for login shells1; they just get loaded at different times (see below). `.zprofile` is based on the Bash's `.bash_profile` while `.zlogin` is a derivative of CSH's `.login`. Since Bash was the default shell for everything up to Mojave, stick with `.zprofile`.

## `.zshrc`
This sets the environment for interactive shells2. This gets loaded after `.zprofile`. It's typically a place where you "set it and forget it" type of parameters like `$PATH`, `$PROMPT`, aliases, and functions you would like to have in both login and interactive shells.

## `.zshenv` (Optional)
This is read first and read every time. This is where you set environment variables. I say this is optional because is geared more toward advanced users where having your `$PATH`, `$PAGER`, or 	`$EDITOR` variables may be important for things like scripts that get called by launchd. Those run under a non-interactive shell 3 so anything in `.zprofile` or `.zshrc` won't get loaded. Personally, I don't use this one because I set the `PATH` variable in my script itself to ensure portability.

## `.zlogout` (Optional)
But very useful! This is read when you log out of a session and is very good for cleaning things up when you leave (like resetting the Terminal Window Title)

For an excellent, in-depth explanation of what these files do, see What should/shouldn't go in `.zshenv`, `.zshrc`, `.zlogin`, `.zprofile`, on Unix/Linux.


# Some Caveats
Apple does things a little differently so it's best to be aware of this. Specifically, Terminal initially opens both a login and interactive shell even though you don't authenticate (enter login credentials). However, any subsequent shells that are opened are only interactive.

You can test this out by putting an alias or setting a variable in `.zprofile`, then opening Terminal and seeing if that variable/alias exists. Then open another shell (type `zsh`); that variable won't be accessible anymore.

SSH sessions are login and interactive so they'll behave just like your initial Terminal session and read both `.zprofile` and `.zshrc`

# Order of Operations
This is the order in which these files get read. Keep in mind that it reads first from the system-wide file (i.e. `/etc/zshenv`) then from the file in your home directory (`~/.zshenv`) as it goes through the following order.

`.zshenv` → `.zprofile` → `.zshrc` → `.zlogin` → `.zlogout`
- j