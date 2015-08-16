## About

[Tmux-resurrect](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-resurrect) is a plugin for [Tundle](https://github.com/chilicuil/tundle) who allows to save/recover tmux sessions.

<p align="center">
<a href="https://vimeo.com/104763018" target="_blank"><img src="./img/screencast_img.png" alt="tmux-resurrect video"/></a>
</p>

It's based on [tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-resurrect](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-resurrect) to your tmux  configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-resurrect"
   ```

2. Install it:

   Hit `prefix + I` inside tmux (or run `~/.tmux/plugins/tundle/scripts/install_plugins.sh` for CLI lovers)

3. Enjoy ☺!

## Usage

- `prefix + Ctrl-s` - To save your current tmux environment
- `prefix + Ctrl-r` - To recover you last tmux environment

For custom key bindings, add to `.tmux.conf`:

    setenv -g @resurrect-save    'S'
    setenv -g @resurrect-restore 'R'

### Configuration

Configuration is not required, but enables extra features.

Only a conservative list of programs is restored by default:

`vi vim nvim emacs man less more tail top htop irssi`.

- Restore additional programs with:

        setenv -g @resurrect-processes 'ssh psql mysql sqlite3'

- Or avoid doing so with:

        setenv -g @resurrect-processes 'false'

- Programs with arguments should be double quoted:

        setenv -g @resurrect-processes 'some_program "git log"'

- Start with tilde to restore a program whose process contains target name:

        setenv -g @resurrect-processes 'irb pry "~rails server" "~rails console"'

- Use `->` to specify a command to be used when restoring a program (useful if the default restore command fails):

        setenv -g @resurrect-processes 'some_program "grunt->grunt development"'

- Restore **all** programs (be careful with this!):

        setenv -g @resurrect-processes ':all:'

#### Restoring vim and neovim sessions

- save vim/neovim sessions manually or install a vim plugin to do it automatically ([tpope/vim-obsession](https://github.com/tpope/vim-obsession) is recommended as it works both vim and neovim).

- in `.tmux.conf`:

        # for vim
        setenv -g @resurrect-strategy-vim 'session'
        # for neovim
        setenv -g @resurrect-strategy-nvim 'session'

`tmux-resurrect` will now restore vim and neovim sessions when a `Sessions.vim` file is present.

#### Resurrect save dir

By default Tmux environment is saved to a file in the `~/.tmux/resurrect` dir. To change it edit:

    setenv -g @resurrect-dir '/some/path'

#### Resurrect session files

By default tmux-resurrect keeps the latest 25 sessions around (~100KB), to change this value edit:

    setenv -g @resurrect-save-max '25'

#### Restoring bash history (experimental)

    setenv -g @resurrect-save-bash-history 'on'

Bash `history` for individual panes will now be saved and restored. Due to
technical limitations, this only works for panes which have no program running in
foreground when saving. `tmux-resurrect` will send history write command
to each such pane. To prevent these commands from being added to history themselves,
add `HISTCONTROL=ignoreboth` to your `.bashrc` (this is set by default in Ubuntu).

#### Restoring pane contents (experimental)

To enable saving and restoring tmux pane contents add this line to `.tmux.conf`:

    setenv -g @resurrect-capture-pane-contents 'on'

## Known bugs

* On tmux 1.6 - 1.8 tmux-resurrect only recover a single session due to switch-client limitated scope
* Saving on tmux 1.8 or superior and recovering on tmux 1.7 or inferior could break "advanced" layout themes

Bugfixes welcome =)

## Also

* tmux-resurrect was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-resurrect will try to run in as many platforms & shells as possible
* tmux-resurrect tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
* tmux-resurrect original design came from [Mislav Marohnić](https://github.com/mislav) in the [tmux-session script](https://github.com/mislav/dotfiles/blob/2036b5e03fb430bbcbc340689d63328abaa28876/bin/tmux-session).
