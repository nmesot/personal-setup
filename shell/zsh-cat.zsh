# Cute cat for the zsh prompt + new-tab greeting. Sourced from ~/.zshrc.
# Remove the `source ~/.zsh-cat.zsh` line in ~/.zshrc to turn it off.

[[ -o interactive ]] || return

# --- prompt cat: mood follows the last command ---
zmodload zsh/datetime 2>/dev/null
_cat_last_cmd_time=$EPOCHSECONDS
_cat_preexec() { _cat_last_cmd_time=$EPOCHSECONDS }
_cat_precmd() {
  local st=$? face color
  if (( EPOCHSECONDS - _cat_last_cmd_time > 300 )); then
    face='=-.-= z'; color=244          # napped while you were away
  elif (( st != 0 )); then
    face='=x.x='; color=203            # last command failed
  else
    local faces=('=^.^=' '=^o^=' '=^-^=' '=^w^=')
    face=${faces[$(( RANDOM % 4 + 1 ))]}; color=213
  fi
  _cat_face="%F{$color}${face}%f "
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cat_preexec
add-zsh-hook precmd _cat_precmd
setopt PROMPT_SUBST
PROMPT='${_cat_face}'"$PROMPT"

# --- greeting: a cat strolls across once when a new tab opens ---
_cat_greet() {
  [[ -t 1 && -z $CLAUDECODE ]] || return
  local cols=${COLUMNS:-80} w=$(( cols < 60 ? cols - 10 : 50 )) i
  local legs=('=^.^= ~' '=^.^=~ ')
  printf '\e[?25l'                     # hide cursor
  for (( i = 0; i <= w; i++ )); do
    printf '\r\e[K%*s\e[38;5;213m%s\e[0m' $i '' "${legs[$(( i % 2 + 1 ))]}"
    sleep 0.02
  done
  printf '\r\e[K\e[38;5;213m%*s=^.^= meow\e[0m\n\e[?25h' $w ''
}
_cat_greet
