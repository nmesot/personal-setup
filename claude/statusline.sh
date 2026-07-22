#!/usr/bin/env bash
input="$(cat)"

# ANSI 256-color palette
RESET='\033[0m'
MODEL_C='\033[38;5;45m'    # bright turquoise
COST_C='\033[38;5;220m'   # gold
DUR_C='\033[38;5;244m'      # gray
ADDED_C='\033[38;5;82m'   # vivid green
REMOVED_C='\033[38;5;203m' # coral red
DIR_C='\033[38;5;75m'     # sky blue
BRANCH_CLEAN_C='\033[38;5;114m'
BRANCH_DIRTY_C='\033[38;5;214m'
SEP_C='\033[38;5;238m'
CTX_GREEN='\033[38;5;83m'
CTX_YELLOW='\033[38;5;220m'
CTX_RED='\033[38;5;203m'
CTX_EMPTY='\033[38;5;238m'
TOKIN_C='\033[38;5;111m'  # light blue
TOKOUT_C='\033[38;5;180m' # light tan
SEP="${SEP_C} │ ${RESET}"

model=$(echo "$input" | jq -r '.model.display_name // "?"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
in_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
cur_out_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# total_output_tokens only reflects the most recent response, not the
# whole session, so accumulate it ourselves keyed by session_id.
out_tokens="$cur_out_tokens"
if [ -n "$session_id" ]; then
  state_file="/tmp/claude-statusline-tokens-${session_id}.json"
  last_in=-1
  last_out=-1
  cum_out=0
  if [ -f "$state_file" ]; then
    last_in=$(jq -r '.last_in // -1' "$state_file" 2>/dev/null) || last_in=-1
    last_out=$(jq -r '.last_out // -1' "$state_file" 2>/dev/null) || last_out=-1
    cum_out=$(jq -r '.cum_out // 0' "$state_file" 2>/dev/null) || cum_out=0
  fi
  if [ "$in_tokens" != "$last_in" ] || [ "$cur_out_tokens" != "$last_out" ]; then
    cum_out=$(( cum_out + cur_out_tokens ))
  fi
  jq -n --argjson last_in "$in_tokens" --argjson last_out "$cur_out_tokens" --argjson cum_out "$cum_out" \
    '{last_in: $last_in, last_out: $last_out, cum_out: $cum_out}' > "$state_file" 2>/dev/null
  out_tokens="$cum_out"
fi

format_tokens() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN{printf "%.1fM", n/1000000}'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN{printf "%.1fk", n/1000}'
  else
    printf '%s' "$n"
  fi
}

in_tokens_display=$(format_tokens "$in_tokens")
out_tokens_display=$(format_tokens "$out_tokens")

dir_display="${dir/#$HOME/~}"

branch=""
dirty=""
if git --no-optional-locks -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)
  if [ -n "$branch" ] && [ -n "$(git --no-optional-locks -C "$dir" status --porcelain 2>/dev/null)" ]; then
    dirty="*"
  fi
fi

cost_display=$(printf '%.2f' "$cost")

secs=$(( duration_ms / 1000 ))
mins=$(( secs / 60 ))
hrs=$(( mins / 60 ))
mins=$(( mins % 60 ))
if [ "$hrs" -gt 0 ]; then
  dur_display="${hrs}h${mins}m"
else
  dur_display="${mins}m"
fi

# context usage as a mini progress bar, colored by fill level
bar_width=10
if [ -n "$ctx_pct" ]; then
  filled=$(awk -v p="$ctx_pct" -v w="$bar_width" 'BEGIN{v=int((p/100)*w+0.5); if(v>w)v=w; print v}')
  empty=$(( bar_width - filled ))
  if awk -v p="$ctx_pct" 'BEGIN{exit !(p<50)}'; then
    bar_color="${CTX_GREEN}"
  elif awk -v p="$ctx_pct" 'BEGIN{exit !(p<80)}'; then
    bar_color="${CTX_YELLOW}"
  else
    bar_color="${CTX_RED}"
  fi
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  empty_bar=""
  for ((i=0; i<empty; i++)); do empty_bar="${empty_bar}░"; done
  ctx_display="${bar_color}${bar}${CTX_EMPTY}${empty_bar}${RESET} ${bar_color}${ctx_pct}%${RESET}"
else
  empty_bar=""
  for ((i=0; i<bar_width; i++)); do empty_bar="${empty_bar}░"; done
  ctx_display="${CTX_EMPTY}${empty_bar}${RESET} ${CTX_GREEN}0%${RESET}"
fi

git_display=""
if [ -n "$branch" ]; then
  branch_color="${BRANCH_CLEAN_C}"
  [ -n "$dirty" ] && branch_color="${BRANCH_DIRTY_C}"
  git_display="${SEP_C} on ${RESET}${branch_color}${branch}${dirty}${RESET}"
fi

printf "${MODEL_C}%s${RESET}${SEP}${COST_C}\$%s${RESET}${SEP}%b${SEP}${TOKIN_C}↑%s${RESET}/${TOKOUT_C}↓%s${RESET}${SEP}${DUR_C}%s${RESET}${SEP}${ADDED_C}+%s${RESET}/${REMOVED_C}-%s${RESET}${SEP}${DIR_C}%s${RESET}%b\n" \
  "$model" "$cost_display" "$ctx_display" "$in_tokens_display" "$out_tokens_display" "$dur_display" "$added" "$removed" "$dir_display" "$git_display"
