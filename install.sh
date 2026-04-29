#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${INSTALL_PROJECT_ROOT:-$PWD}"
REPO_URL="${INSTALL_REPO_URL:-https://github.com/juanpvh/move-skills-claude-codex}"
CLONE_DIR_NAME="${INSTALL_CLONE_DIR_NAME:-move-skills-claude-codex}"
INSTALL_MODE="${INSTALL_MODE:-skills}"
CLONE_DIR="$PROJECT_ROOT/$CLONE_DIR_NAME"
AGENTS_DIR="$PROJECT_ROOT/.agents"
AGENTS_SKILLS_DIR="$PROJECT_ROOT/.agents/skills"
AGENTS_PLUGINS_DIR="$PROJECT_ROOT/.agents/plugins"
PLUGINS_DIR="$PROJECT_ROOT/plugins"

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

usage() {
  cat <<'EOF'
Uso: bash ./install.sh [--mode skills|plugins|both]

Modos:
  skills   instala apenas .agents/skills
  plugins  instala apenas plugins/ e .agents/plugins/marketplace.json
  both     instala skills e plugins

Variaveis opcionais:
  INSTALL_MODE
  INSTALL_PROJECT_ROOT
  INSTALL_REPO_URL
  INSTALL_CLONE_DIR_NAME
EOF
}

validate_mode() {
  case "$1" in
    skills|plugins|both) ;;
    *)
      fail "modo invalido: $1. Use skills, plugins ou both."
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        [[ $# -ge 2 ]] || fail "faltou valor para --mode"
        INSTALL_MODE="$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "argumento desconhecido: $1"
        ;;
    esac
  done
}

uses_skills_install() {
  [[ "$INSTALL_MODE" == "skills" || "$INSTALL_MODE" == "both" ]]
}

uses_plugins_install() {
  [[ "$INSTALL_MODE" == "plugins" || "$INSTALL_MODE" == "both" ]]
}

validate_targets() {
  if uses_skills_install; then
    [[ ! -e "$AGENTS_SKILLS_DIR" ]] || fail "o projeto destino ja possui .agents/skills em $AGENTS_SKILLS_DIR"
  fi

  if uses_plugins_install; then
    [[ ! -e "$PLUGINS_DIR" ]] || fail "o projeto destino ja possui plugins em $PLUGINS_DIR"
    [[ ! -e "$AGENTS_PLUGINS_DIR" ]] || fail "o projeto destino ja possui .agents/plugins em $AGENTS_PLUGINS_DIR"
  fi
}

install_skills() {
  [[ -d "$CLONE_DIR/.agents/skills" ]] || fail "o repositorio clonado nao contem .agents/skills"
  mkdir -p "$AGENTS_DIR"
  log "movendo .agents/skills para a raiz do projeto"
  mv "$CLONE_DIR/.agents/skills" "$AGENTS_SKILLS_DIR"
}

install_plugins() {
  [[ -d "$CLONE_DIR/plugins" ]] || fail "o repositorio clonado nao contem plugins"
  [[ -d "$CLONE_DIR/.agents/plugins" ]] || fail "o repositorio clonado nao contem .agents/plugins"

  mkdir -p "$AGENTS_DIR"

  log "movendo plugins para a raiz do projeto"
  mv "$CLONE_DIR/plugins" "$PLUGINS_DIR"

  log "movendo .agents/plugins para a raiz do projeto"
  mv "$CLONE_DIR/.agents/plugins" "$AGENTS_PLUGINS_DIR"
}

cleanup() {
  if [[ -e "$CLONE_DIR" ]]; then
    rm -rf -- "$CLONE_DIR"
    [[ ! -e "$CLONE_DIR" ]] || return 1
  fi
}

main() {
  parse_args "$@"
  validate_mode "$INSTALL_MODE"

  require_command git

  [[ -d "$PROJECT_ROOT" ]] || fail "diretorio do projeto nao encontrado: $PROJECT_ROOT"
  [[ ! -e "$CLONE_DIR" ]] || fail "ja existe um diretorio temporario em $CLONE_DIR"
  validate_targets

  trap cleanup EXIT

  log "clonando $REPO_URL em $CLONE_DIR_NAME no modo $INSTALL_MODE"
  git clone --depth 1 "$REPO_URL" "$CLONE_DIR"

  if uses_skills_install; then
    install_skills
  fi

  if uses_plugins_install; then
    install_plugins
  fi

  trap - EXIT
  cleanup || fail "falha ao remover diretorio temporario em $CLONE_DIR"
  log "diretorio temporario removido"
  log "instalacao concluida"
}

main "$@"
