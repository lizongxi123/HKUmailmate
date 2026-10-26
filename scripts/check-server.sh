#!/usr/bin/env bash
# Read-only inspection for the Ubuntu development server.
# Run: bash scripts/check-server.sh
# Does not read credentials, install packages or modify system configuration.
set -u

section() {
  printf '\n## %s\n' "$1"
}

inspect() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1 || printf 'Inspection unavailable or not permitted: %s\n' "$1"
  else
    printf 'Not installed: %s\n' "$1"
  fi
}

section 'System and current user'
inspect date -u
inspect uname -sr
if [ -r /etc/os-release ]; then
  cat /etc/os-release
fi
inspect id
printf 'Working directory: %s\n' "$PWD"
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  printf 'Noninteractive sudo: available\n'
else
  printf 'Noninteractive sudo: unavailable (no password requested)\n'
fi

section 'Capacity'
inspect uptime
inspect nproc
inspect free -h
inspect df -h / /home

section 'Development tools'
inspect git --version
inspect python3 --version
inspect node --version
inspect npm --version
inspect docker --version
if command -v docker >/dev/null 2>&1; then
  inspect docker compose version
fi

section 'Listening TCP ports (no process arguments)'
inspect ss -lnt

section 'Active services (no environment or configuration dump)'
inspect systemctl list-units --type=service --state=running --no-pager --no-legend

section 'Containers accessible to current user'
if command -v docker >/dev/null 2>&1; then
  inspect docker ps --format '{{.Names}} {{.Image}} {{.Ports}}'
fi

section 'Development directory metadata'
for path in /home /srv /srv/HKUmailmate "$HOME" "$HOME/HKUmailmate"; do
  if [ -e "$path" ]; then
    ls -ld "$path"
  fi
done

section 'SSH metadata only'
for path in "$HOME/.ssh" "$HOME/.ssh/authorized_keys"; do
  if [ -e "$path" ]; then
    ls -ld "$path"
  fi
done

section 'Repository state in current directory'
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  git rev-parse --show-toplevel
  git status --short --branch
else
  printf 'No Git working tree in current directory.\n'
fi

printf '\nInspection complete. No configuration changes performed.\n'
