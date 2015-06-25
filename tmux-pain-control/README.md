## About

[Tmux-pain-control](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-pain-control) is a plugin for [Tundle](https://github.com/chilicuil/tundle) providing affordable tmux window management.

<p align="center">
<img src="./screenshots/pane_splitting.gif" alt="pane splitting"/>
</p>

It's based on [tmux-plugins/tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-pain-control](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-pain-control) to your tmux  configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-pain-control"
   ```

2. Install it:

   Hit `prefix + I` (or run `here tmux free installation script` for CLI lovers)

3. Enjoy

## Usage

Notice most of the bindings emulate vim cursor movements.

### Navigation

<img align="right" src="./screenshots/pane_navigation.gif" alt="pane navigation"/>

- `prefix + h` and `prefix + C-h`<br/>
  select pane on the left
- `prefix + j` and `prefix + C-j`<br/>
  select pane below the current one
- `prefix + k` and `prefix + C-k`<br/>
  select pane above
- `prefix + l` and `prefix + C-l`<br/>
  select pane on the right

**Note**: This overrides tmux's default binding for toggling between last active windows, `prefix + l`.  [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control) gives you a better binding for that, `prefix + a` (if your prefix is `C-a`).

### Resizing panes

<img align="right" src="./screenshots/pane_resizing.gif" alt="pane resizing"/>

- `prefix + shift + h`<br/>
  resize current pane 5 cells to the left
- `prefix + shift + j`<br/>
  resize 5 cells in the up direction
- `prefix + shift + k`<br/>
  resize 5 cells in the down direction
- `prefix + shift + l`<br/>
  resize 5 cells to the right

These mappings are `repeatable`.

The amount of cells to resize can be configured with `@pane_resize` option. See
[configuration section](#configuration) for the details.

### Splitting

<img align="right" src="./screenshots/pane_splitting.gif" alt="pane splitting"/>

- `prefix + |`<br/>
  split current pane horizontally
- `prefix + -`<br/>
  split current pane vertically

Newly created pane always has the same path as the original pane.

### Swapping windows

- `prefix + <` - moves current window one position to the left
- `prefix + >` - moves current window one position to the right

### Configuration

You can set `@pane_resize` Tmux option to choose number of resize cells for the
resize bindings. "5" is the default.

Example:

    set-env -g @pane_resize "10"

## Also

* tmux-pain-control was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-pain-control will try to run in as many platforms & shells as possible
* tmux-pain-control tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
