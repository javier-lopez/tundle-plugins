## About

[Tmux-continuum](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-continuum) is a plugin for [Tundle](https://github.com/chilicuil/tundle) for continuous tmux usage.

<p align="center">
<img src="./img/tmux-continuum.gif" alt="tmux-continuum gif"/></a>
</p>

It's based on [tmux-plugins/tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) with personal sauce and relaxed dependency requirements.

## Quick start

1. Add [tmux-continuum](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-continuum) to your tmux configuration (~/.tmux.conf):

   ```sh
   setenv -g @bundle "chilicuil/tundle-plugins/tmux-continuum"
   ```

2. Install it:

   Hit `prefix + I` (or run `here tmux free installation script` for CLI lovers)

3. Enable it:

   Add `setenv -g @continuum-restore 'on'` to your tmux configuration file (~/.tmux.conf) to enable auto restoring of the latest session on tmux launch, and optionally
   `setenv -g @continuum-boot 'on'` to launch tmux in a terminal after you system login sequence.

## Usage

After installation no further step is required, tmux-continuum will periodically save your tmux environment and load the latest session when tmux is launched without parameters.

### Configuration

Configuration is not required, but modifies the plugin behavior.

- Save interval

        #options: int
        setenv -g @continuum-save-interval '15' #in minutes

- Automatic restore

        #options: on/off
        setenv -g @continuum-restore 'off'

Note: automatic restore happens **exclusively** on tmux server start. No other action (e.g. sourcing `tmux.conf`) triggers it.

- Automatic tmux launch (currently only OSX)

        #options: on/off
        setenv -g @continuum-boot 'off'

- Options

        #options: iterm/terminal/fullscreen
        setenv -g @continuum-boot ''

### FAQ

> Will a previous save be overwritten immediately after I start tmux?

No, first automatic save starts 15 minutes after tmux is started. If automatic restore is not enabled, that gives you enough time to manually restore from a previous save.

> I want to make a restore to a previous point in time, but it seems that save is now overwritten?

Here are the steps to restore to a previous point in time:

- `$ cd ~/.tmux/resurrect/`
- locate the save file you'd like to use for restore (file names have a timestamp)
- symlink the `last` file to the desired save file: `$ ln -sf <file_name> last`
- do a restore with `tmux-resurrect` key: `prefix + Ctrl-r`

You should now be restored to the time when `<file_name>` save happened.

> Will this plugin fill my hard disk?

Most likely no, this plugin depends on tmux-resurrect, the recommended tundle version saves a maximum of 25 sessions by default, while the tpm versions keep an unlimited number, each session file is in the range of 5kb, if you use the latter just make sure to clean out the old files in `~/.tmux/resurrect/` from time to time.

> How do I change the save interval to i.e. 1 hour?

The interval is always measured in minutes. So setting the interval to `60` (minutes) will do the trick. Put this in `.tmux.conf`:

    setenv -g @continuum-save-interval '60'

and then source `tmux.conf` by executing this command in the shell `$ tmux source-file ~/.tmux.conf`.

> How do I stop automatic saving?

Set the save interval to `0`. Put this in `.tmux.conf`

    setenv -g @continuum-save-interval '0'

and then source `tmux.conf` by executing this command in the shell `$ tmux source-file ~/.tmux.conf`.

> I had automatic restore turned on, how do I disable it now?

Remove `setenv -g @continuum-restore 'on'` from `tmux.conf`.

## Also

* tmux-continuum was developed against tmux 1.6 and dash 0.5 on Linux
* tmux-continuum depends in the [tmux-resurrect](https://github.com/chilicuil/tundle-plugins/tree/master/tmux-resurrect) plugin
* tmux-continuum will try to run in as many platforms & shells as possible
* tmux-continuum tries to be as [KISS](http://en.wikipedia.org/wiki/KISS_principle) as possible
