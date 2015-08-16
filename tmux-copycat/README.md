## About

[tmux-copycat](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-copycat) is a plugin for [Tundle](https://github.com/chilicuil/tundle) that enhances tmux search.

<p align="center">
<a href="https://vimeo.com/101867689" target="_blank"><img src="./img/screencast_img.png" alt="tmux-copycat video"/></a>
</p>

It's based on [tmux-plugins/tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-copycat](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-copycat) to your tmux configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-copycat"
   ```

2. Install it:

   Hit `prefix + I` inside tmux (or run `~/.tmux/plugins/tundle/scripts/install_plugins.sh` for CLI lovers)

3. Enjoy ☺!

## Usage

#### Search

* `prefix + /` - Search strings (regex works too)

Example search entries:

* `foo` - searches for string `foo`
* `[0-9]+` - regex search for numbers

Notes:

* Awk is used for searching.
* Searches are case insensitive.

#### Predefined searches

* `prefix + ctrl-f` - simple *f*ile search
* `prefix + ctrl-u` - *u*rl search (http, ftp and git urls)
* `prefix + alt-i` - *i*p address search
* `prefix + ctrl-d` - number search (mnemonic d, as digit)
* `prefix + alt-h` - jumping over SHA-1 hashes (best used after `git log` command)
* `prefix + ctrl-g` - jumping over *g*it status files (best used after `git status` command)

These above shortcuts enable "copycat mode" and jump to the first match.

#### "Copycat mode" bindings

While in copy mode the following mappings are available

* `n` - jumps to the next match
* `N` - jumps to the previous match

To copy a highlighted match:

* `Enter` - if you're using Tmux `vi` mode
* `ctrl-w` or `alt-w` - if you're using Tmux `emacs` mode

Copying a highlighted match will take you "out" of copycat mode. Paste with
`prefix + ]` (this is Tmux default paste).

Copying highlighted matches can be enhanced with

* [tundle/tmux yank](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-yank).

### Configuration

Configuration is not required, but modifies the plugin behavior.

* Default search keybinding

        #options: any key
        setenv -g @copycat_search '/'

* Next match

        #options: any key
        setenv -g @copycat_next 'n'

* Previous match

        #options: any key
        setenv -g @copycat_prev 'N'

* Cyclic matches

        #options: y/n
        setenv -g @copycat_cyclic 'y'

Other options are defined in [./scripts/vars.sh](./scripts/vars.sh)

### Limitations

* this plugin tries hard to consistently enable "marketed" features. It uses some
  hacks to go beyond the APIs Tmux provides. Because of this, it might have some
  "rough edges" and there's nothing that can be done.

  Examples: non-perfect file and url matching and selection. That said, usage
  should be fine in +90% cases.

* tmux `vi` copy mode works faster than `emacs`. If you don't have a preference
  yet consider enabling `vi` copy mode by default, eg: `.tmux.conf`

      set -g mode-keys vi

* remapping `Escape` key in copy mode will break the plugin. If you have this
  in your `.tmux.conf`, please consider removing it:

      bind -t vi-copy Escape cancel

* optional (but recommended) install `gawk` via your package manager of choice
for better UTF-8 character support.

## Also

* tmux-copycat was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-copycat will try to run in as many platforms & shells as possible
* tmux-copycat tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
