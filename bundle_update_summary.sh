#!/bin/bash
set -e

if [ -t 1 ]; then
  RESET='\033[0m'
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  RED='\033[31m'
  CYAN='\033[36m'
  BLUE='\033[34m'
else
  RESET= BOLD= DIM= GREEN= YELLOW= RED= CYAN= BLUE=
fi

LOCKFILE="Gemfile.lock"

lockfile_gem_lines() {
  grep -E '^\s{4}[^[:space:]]' "$1" | sed 's/^[[:space:]]*//' | sort
}

gem_name_from_line() {
  echo "$1" | awk '{print $1}'
}

# e.g. "ffi (1.17.0-arm64-darwin)" -> "arm64-darwin", plain versions -> "ruby"
platform_key_from_line() {
  local ver
  ver=$(echo "$1" | sed -n 's/.*(\([^)]*\)).*/\1/p')
  if [[ "$ver" =~ -(arm64-darwin|x86_64-darwin|universal-darwin|java|jruby)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "ruby"
  fi
}

if [ ! -f "$LOCKFILE" ]; then
  echo -e "${YELLOW}No Gemfile.lock found. Running bundle install first...${RESET}"
  command bundle install
  exit 0
fi

before_file=$(mktemp)
after_file=$(mktemp)
removed_file=$(mktemp)
added_file=$(mktemp)
trap 'rm -f "$before_file" "$after_file" "$removed_file" "$added_file"' EXIT

lockfile_gem_lines "$LOCKFILE" > "$before_file"

args=("$@")
if [ "${args[0]}" = "update" ]; then
  args=("${args[@]:1}")
fi

echo -e "${YELLOW}Running bundle update...${RESET}"
command bundle update "${args[@]}"

lockfile_gem_lines "$LOCKFILE" > "$after_file"

comm -23 "$before_file" "$after_file" > "$removed_file"
comm -13 "$before_file" "$after_file" > "$added_file"

upgraded=""
removed=""
added=""

while IFS= read -r old_line; do
  [ -z "$old_line" ] && continue
  name=$(gem_name_from_line "$old_line")
  platform=$(platform_key_from_line "$old_line")
  matched=""

  while IFS= read -r new_line; do
    [ -z "$new_line" ] && continue
    if [ "$(gem_name_from_line "$new_line")" = "$name" ] &&
       [ "$(platform_key_from_line "$new_line")" = "$platform" ]; then
      upgraded+="  ${GREEN}↑${RESET}  ${BOLD}${name}${RESET}  ${DIM}${old_line#"$name "}${RESET} ${YELLOW}→${RESET} ${GREEN}${new_line#"$name "}${RESET}\n"
      grep -Fxv "$new_line" "$added_file" > "${added_file}.tmp" || true
      mv "${added_file}.tmp" "$added_file"
      matched=1
      break
    fi
  done < "$added_file"

  if [ -z "$matched" ]; then
    removed+="  ${RED}🗑${RESET}  ${BOLD}${name}${RESET} ${DIM}${old_line#"$name "}${RESET}\n"
  fi
done < "$removed_file"

while IFS= read -r new_line; do
  [ -z "$new_line" ] && continue
  name=$(gem_name_from_line "$new_line")
  added+="  ${GREEN}✚${RESET}  ${BOLD}${name}${RESET} ${GREEN}${new_line#"$name "}${RESET}\n"
done < "$added_file"

echo ""
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${CYAN}  Bundle Update Summary${RESET}"
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [ -n "$upgraded" ]; then
  echo ""
  echo -e "${BOLD}${BLUE}Upgraded:${RESET}"
  echo -e "$upgraded"
fi

if [ -n "$added" ]; then
  echo -e "${BOLD}${BLUE}Added:${RESET}"
  echo -e "$added"
fi

if [ -n "$removed" ]; then
  echo -e "${BOLD}${RED}Removed:${RESET}"
  echo -e "$removed"
fi

if [ -z "$upgraded" ] && [ -z "$added" ] && [ -z "$removed" ]; then
  echo ""
  echo -e "  ${GREEN}✓${RESET} Everything already up to date. No changes."
fi

echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
