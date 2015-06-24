## About

[Tmux-sensible](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-sensible) is a plugin for [Tundle](https://github.com/chilicuil/tundle) providing basic tmux settings.

It's based on [tmux-plugins/tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-sensible](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-sensible) to your tmux  configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-sensible"
   ```

2. Install it:

   Hit `prefix + I` (or run `here tmux free installation script` for CLI lovers)

3. Enjoy

## Usage

Upon installation no further steps are required, tmux-sensible is just about common tmux options, some of them are (full details in [sensible.tmux](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-sensible)):

### Options

    # utf8 is on
    set -g utf8 on
    set -g status-utf8 on

    # address vim mode switching delay (http://superuser.com/a/252717/65504)
    set -s escape-time 0

    # increase scrollback buffer size
    set -g history-limit 50000

    # tmux messages are displayed for 4 seconds
    set -g display-time 4000

    # refresh 'status-left' and 'status-right' more often
    set -g status-interval 5

    # set only on OS X where it's required
    set -g default-command "reattach-to-user-namespace -l $SHELL"

    # upgrade $TERM
    set -g default-terminal "screen-256color"

    # emacs key bindings in tmux command prompt (prefix + :) are better than
    # vi keys, even for vim users
    set -g status-keys emacs

    # focus events enabled for terminals that support them
    set -g focus-events on

    # super useful when using "grouped sessions" and multi-monitor setup
    setw -g aggressive-resize on

### Key bindings

    # easier and faster switching between next/prev window
    bind C-p previous-window
    bind C-n next-window

Above bindings enhance the default `prefix + p` and `prefix + n` bindings by
allowing you to hold `Ctrl` and repeat `a + p`/`a + n` (if your prefix is
`C-a`), which is a lot quicker.

    # source .tmux.conf as suggested in `man tmux`
    bind R source-file '~/.tmux.conf'

"Adaptable" key bindings that build upon your `prefix` value:

    # if prefix is 'C-a'
    bind C-a send-prefix
    bind a last-window

If prefix is `C-b`, above keys will be `C-b` and `b`.<br/>
If prefix is `C-z`, above keys will be `C-z` and `z`... you get the idea.

## Also

* tmux-sensible was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-sensible will try to run in as many platforms & shells as possible
* tmux-sensible tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible

### License

[MIT](LICENSE.md)
