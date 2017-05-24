## About

[Tmux-yank](https://github.com/javier-lopez/tundle-plugins/tree/master/tmux-yank) is a plugin for [Tundle](https://github.com/javier-lopez/tundle) who enables copying to the system clipboard under Linux and OS X in tmux.

<p align="center">
<a href="https://vimeo.com/102039099" target="_blank"><img src="./img/screencast_img.png" alt="tmux-yank video"/></a>
</p>

It's based on [tmux-plugins/tmux-yank](https://github.com/tmux-plugins/tmux-yank) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-yank](https://github.com/javier-lopez/tundle-plugins/tree/master/tmux-yank) to your tmux  configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "javier-lopez/tundle-plugins/tmux-yank"
   ```

2. Install it:

   Hit `prefix + I` inside tmux (or run `~/.tmux/plugins/tundle/scripts/install_plugins.sh` for CLI lovers)

3. Enjoy ☺!

## Usage

### Key bindings

- `prefix + y` - copies current line in the command line to the clipboard.

**copy mode** bindings:

- `y` - copy selection to the system clipboard
- `Y` (shift-y) - "put" selection - equivalent to copying a selection, pasting it to the command line, and sync to the system clipboard
- `Alt-y` - "put" selection - equivalent to copying a selection, pasting it to the command line

For custom key bindings, add to `.tmux.conf`:

    setenv -g @yank-line        'y'
    setenv -g @copy_mode_yank   'y'
    setenv -g @yank_put_default 'Y'
    setenv -g @put_default      'M-y'

### Configuration

Configuration is not required, but modifies the plugin behavior.

- Default shell mode

        #options: emacs|vi
        setenv -g @shell_mode 'emacs'

- System yank selection (xclip)

        #options: primary|secondary|clipboard
        setenv -g @yank-selection 'clipboard'

- Verbose messages

        #options: y|n
        setenv -g @verbose 'y'

### External clipboard supported programs

#### OS X

- [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard)

  brew `$ brew install reattach-to-user-namespace` or
  macports `$ sudo port install tmux-pasteboard`.

  *Note*: Beginning with OSX Yosemite (10.10), `pbcopy` is reported to work
  correctly with `tmux`, we believe `reattach-to-user-namespace` is not
  needed anymore. Please install it in case the plugin doesn't work for you.

#### Linux

- `xclip` OR `xsel` command

You most likely already have one of them, but if not:

  - Debian / Ubuntu: `$ sudo apt-get install xclip` or `$ sudo apt-get install xsel`
  - Red hat / CentOS: `$ yum install xclip` or `$ yum install xsel`

### Notes

**Mouse Support**

When making a selection using tmux `mode-mouse on` or `mode-mouse copy-mode`,
you cannot rely on the default 'release mouse after selection to copy' behavior.
Instead, press `y` before releasing mouse.

## Also

* tmux-yank was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-yank will try to run in as many platforms & shells as possible
* tmux-yank tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
