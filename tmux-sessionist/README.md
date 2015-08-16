## About

[Tmux-sessionist](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-sessionist) is a plugin for [Tundle](https://github.com/chilicuil/tundle) who helps to manage tmux sessions.

<p align="center">
<img src="http://javier.io/assets/img/tmux-sessionist.gif" alt="tmux-sessionist gif"/>
</p>

It's based on [tmux-plugins/tmux-sessionist](https://github.com/tmux-plugins/tmux-sessionist) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-sessionist](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-sessionist) to your tmux  configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-sessionist"
   ```

2. Install it:

   Hit `prefix + I` inside tmux (or run `~/.tmux/plugins/tundle/scripts/install_plugins.sh` for CLI lovers)

3. Enjoy ☺!

## Usage

### Key bindings

- `prefix + g` - Switch sessions by name. Faster than the built-in `prefix + s` prompt for long session lists.
- `prefix + C` (shift + c) - Create new sessions by name
- `prefix + X` (shift + x) - Kill current session without detaching tmux.
- `prefix + S` (shift + s) - Switch to the last session. The same as built-in `prefix + L` that everyone seems to override with some other binding.
- `prefix + @` - Promote current pane into a new session. Analogous to how `prefix + !` breaks current pane to a new window.

### Configuration

Configuration is not required, but modifies the plugin behavior.

- New session binding

        #options: char
        setenv -g @sessionist-new 'C'

- Close current session binding

        #options: char
        setenv -g @sessionist-kill-session 'X'

- List session binding

        #options: char
        setenv -g @sessionist-goto 'g'

- Last used (alternate) session binding

        #options: char
        setenv -g @sessionist-alternate 'S'

- Use current pane directory in new sessions

        #options: y/n
        setenv -g @sessionist-new-last-directory 'y'

- Promote pane to session binding

        #options: char
        setenv -g @sessionist-promote-pane '@'

## Also

* tmux-sessionist was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-sessionist will try to run in as many platforms & shells as possible
* tmux-sessionist tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
