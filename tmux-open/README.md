## About

[Tmux-open](https://github.com/javier-lopez/tundle-plugins/tree/master/tmux-open) is a plugin for [Tundle](https://github.com/javier-lopez/tundle) to open eficientily files in tmux copy-mode works under Linux and OS X.

<p align="center">
<a href="http://vimeo.com/102455265" target="_blank"><img src="./img/screencast_img.png" alt="tmux-open video"/></a>
</p>

It's based on [tmux-plugins/tmux-open](https://github.com/tmux-plugins/tmux-open) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-open](https://github.com/javier-lopez/tundle-plugins/tree/master/tmux-open) to your tmux configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "javier-lopez/tundle-plugins/tmux-open"
   ```

2. Install it:

   Hit `prefix + I` inside tmux (or run `~/.tmux/plugins/tundle/scripts/install_plugins.sh` for CLI lovers)

3. Enjoy ☺!

## Usage

**copy/copycat modes ** bindings:

- `o` - open the selection in the appropiated program (determinated by `open` and `xdg-open`, personalizable)
- `Ctrl-o` - open the selection with the default terminal `$EDITOR`

### Examples

In copy mode:

- highlight `file.pdf` and press `o` - file will open in the default PDF viewer.
- highlight `file.doc` and press `o` - file will open in system default `.doc` file viewer.
- highlight `http://example.com` and press `o` - link will be opened in the default browser.
- highlight `file.txt` and press `Ctrl-o` - file will open in `$EDITOR`.

For custom key bindings, add to `~/.tmux.conf`:

    setenv -g @open         'o'
    setenv -g @open-editor  'C-o'

### Configuration

Configuration is not required, but modifies the plugin behavior.

- Default launcher application

        #options: open|xdg-open|etc
        setenv -g @open-command 'xdg-open'

- Default editor

        #options: $EDITOR|vim|vi|nano|etc
        setenv -g @open-command 'vim'

- Verbose messages

        #options: y|n
        setenv -g @verbose 'y'

- User defined search engines

        #options: 'https://www.google.com/search?q='|'http://www.bing.com/search?q='|etc
        setenv -g @open-s 'https://www.google.com/search?q='

## Also

* tmux-open was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-open will try to run in as many platforms & shells as possible
* tmux-open tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
