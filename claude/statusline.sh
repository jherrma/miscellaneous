#!/usr/bin/env bash
input="$(cat)"

dir="$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
model="$(echo "$input" | jq -r '.model.display_name // empty')"
effort="$(echo "$input" | jq -r '.effort.level // "default"')"
ctx="$(echo "$input" | jq -r '.context_window.used_percentage // empty')"

branch=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
  if [ -n "$branch" ] && [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
    branch="${branch} ±"
  fi
fi

parts=()
[ -n "$model" ] && parts+=("${model} [${effort}]")
[ -n "$ctx" ] && parts+=("ctx ${ctx}%")
[ -n "$branch" ] && parts+=("$branch")

out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$p"; else out="$out | $p"; fi
done
echo "$out"
