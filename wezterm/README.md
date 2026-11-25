# WezTerm

SF Mono 15 (borrowed from Terminal.app's bundle), Catppuccin Mocha, and an
animated pixel cat in the top-right corner (it animates while the window is
focused, and stays visible behind full-screen apps like Claude Code).

Install:

```sh
brew install --cask wezterm
ln -s ~/workspace/personal-setup/wezterm/wezterm.lua ~/.wezterm.lua
```

`cat.gif` is drawn by `make_cat.py` (no dependencies):
`python3 wezterm/make_cat.py wezterm/cat.gif`.
