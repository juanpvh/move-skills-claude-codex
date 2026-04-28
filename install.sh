#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${INSTALL_PROJECT_ROOT:-$PWD}"
REPO_URL="${INSTALL_REPO_URL:-https://github.com/juanpvh/move-skills-claude-codex}"
CLONE_DIR_NAME="${INSTALL_CLONE_DIR_NAME:-move-skills-claude-codex}"
CLONE_DIR="$PROJECT_ROOT/$CLONE_DIR_NAME"
AGENTS_DIR="$PROJECT_ROOT/.agents"

log() {
  printf '[install] %s\n' "$1"
}

fail() {
  log "$1"
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "comando obrigatorio ausente: $1"
  fi
}

cleanup() {
  if [[ -d "$CLONE_DIR" ]]; then
    rm -rf "$CLONE_DIR"
  fi
}

main() {
  require_command git

  [[ -d "$PROJECT_ROOT" ]] || fail "diretorio do projeto nao encontrado: $PROJECT_ROOT"
  [[ ! -e "$AGENTS_DIR" ]] || fail "o projeto destino ja possui .agents em $AGENTS_DIR"
  [[ ! -e "$CLONE_DIR" ]] || fail "ja existe um diretorio temporario em $CLONE_DIR"

  trap cleanup EXIT

  log "clonando $REPO_URL em $CLONE_DIR_NAME"
  git clone --depth 1 "$REPO_URL" "$CLONE_DIR"

  [[ -d "$CLONE_DIR/.agents" ]] || fail "o repositorio clonado nao contem .agents"

  log "movendo .agents para a raiz do projeto"
  mv "$CLONE_DIR/.agents" "$AGENTS_DIR"

  log "instalacao concluida"
}

main "$@"


