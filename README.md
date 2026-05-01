# Dotfiles

Personal dotfiles managed with GNU Stow.

## Install

Clone this repository into your home directory, then run:

```sh
stow .
```

This symlinks the dotfiles from this repository into the parent directory,
usually `$HOME`.

To preview changes first:

```sh
stow --simulate --verbose .
```

Repository-only files such as this README and helper scripts are excluded by
`.stow-local-ignore`.
