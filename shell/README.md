# Shell + terminal

## Cat prompt and greeting (`zsh-cat.zsh`)

- Prompt cat in front of the zsh prompt: happy face after a successful
  command, `=x.x=` after a failure, `=-.-= z` after 5 idle minutes.
- New-tab greeting: a cat strolls across one line and says meow (skipped
  inside Claude Code's shells).

Install:

```sh
cp shell/zsh-cat.zsh ~/.zsh-cat.zsh
echo 'source ~/.zsh-cat.zsh' >> ~/.zshrc
```

## Terminal.app font

Profile "Clear Dark", SF Mono at size 15:

```sh
osascript -e 'tell application "Terminal" to set font size of settings set "Clear Dark" to 15'
```
