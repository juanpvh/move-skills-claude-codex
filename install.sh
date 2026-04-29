#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${INSTALL_PROJECT_ROOT:-$PWD}"
REPO_URL="${INSTALL_REPO_URL:-https://github.com/juanpvh/move-skills-claude-codex}"
CLONE_DIR_NAME="${INSTALL_CLONE_DIR_NAME:-move-skills-claude-codex}"
INSTALL_MODE="${INSTALL_MODE:-skills}"
CLONE_DIR=""
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

is_windows_shell() {
  case "$(uname -s 2>/dev/null || printf '')" in
    CYGWIN*|MINGW*|MSYS*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_windows_path() {
  [[ "$1" =~ ^[A-Za-z]:[\\/] || "$1" =~ ^\\\\ ]]
}

normalize_path() {
  local raw_path="$1"

  if [[ -z "$raw_path" ]]; then
    printf '%s' "$raw_path"
    return 0
  fi

  if is_windows_path "$raw_path" && command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$raw_path"
    return 0
  fi

  printf '%s' "$raw_path"
}

normalize_repo_url() {
  local raw_value="$1"

  if is_windows_path "$raw_value"; then
    normalize_path "$raw_value"
    return 0
  fi

  printf '%s' "$raw_value"
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

resolve_temp_root() {
  local candidate

  for candidate in "${TMPDIR:-}" "${TEMP:-}" "${TMP:-}"; do
    if [[ -n "$candidate" ]]; then
      normalize_path "$candidate"
      return 0
    fi
  done

  if is_windows_shell && command -v cygpath >/dev/null 2>&1 && [[ -n "${LOCALAPPDATA:-}" ]]; then
    cygpath -u "${LOCALAPPDATA}\\Temp"
    return 0
  fi

  printf '%s' "/tmp"
}

create_clone_dir() {
  local tmp_root
  local suffix

  tmp_root="$(resolve_temp_root)"
  mkdir -p "$tmp_root"

  if command -v mktemp >/dev/null 2>&1; then
    CLONE_DIR="$(mktemp -d "$tmp_root/${CLONE_DIR_NAME}.XXXXXX")" || fail "falha ao criar diretorio temporario de clone"
    return 0
  fi

  suffix="$(date +%Y%m%d%H%M%S).$$"
  CLONE_DIR="$tmp_root/${CLONE_DIR_NAME}.$suffix"
  mkdir -p "$CLONE_DIR" || fail "falha ao criar diretorio temporario de clone"
}

move_dir() {
  local source_dir="$1"
  local target_dir="$2"

  mkdir -p "$(dirname "$target_dir")"
  mv "$source_dir" "$target_dir"
}

remove_tree() {
  local target_dir="$1"
  local attempt=0
  local windows_target_dir

  [[ -e "$target_dir" ]] || return 0

  while [[ -e "$target_dir" && "$attempt" -lt 3 ]]; do
    rm -rf -- "$target_dir" 2>/dev/null || true
    if [[ -e "$target_dir" ]] && is_windows_shell && command -v powershell.exe >/dev/null 2>&1; then
      windows_target_dir="$target_dir"
      if command -v cygpath >/dev/null 2>&1; then
        windows_target_dir="$(cygpath -w "$target_dir")"
      fi
      powershell.exe -NoProfile -Command "Remove-Item -LiteralPath '$windows_target_dir' -Recurse -Force" >/dev/null 2>&1 || true
    fi
    [[ ! -e "$target_dir" ]] && return 0
    sleep 1
    attempt=$((attempt + 1))
  done

  [[ ! -e "$target_dir" ]]
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
  log "movendo .agents/skills para a raiz do projeto"
  move_dir "$CLONE_DIR/.agents/skills" "$AGENTS_SKILLS_DIR"
}

install_plugins() {
  [[ -d "$CLONE_DIR/plugins" ]] || fail "o repositorio clonado nao contem plugins"
  [[ -d "$CLONE_DIR/.agents/plugins" ]] || fail "o repositorio clonado nao contem .agents/plugins"

  mkdir -p "$AGENTS_DIR"

  log "movendo plugins para a raiz do projeto"
  move_dir "$CLONE_DIR/plugins" "$PLUGINS_DIR"

  log "movendo .agents/plugins para a raiz do projeto"
  move_dir "$CLONE_DIR/.agents/plugins" "$AGENTS_PLUGINS_DIR"
}

cleanup() {
  [[ -n "$CLONE_DIR" ]] || return 0
  remove_tree "$CLONE_DIR"
}

main() {
  parse_args "$@"
  validate_mode "$INSTALL_MODE"

  require_command git

  PROJECT_ROOT="$(normalize_path "$PROJECT_ROOT")"
  REPO_URL="$(normalize_repo_url "$REPO_URL")"

  [[ -d "$PROJECT_ROOT" ]] || fail "diretorio do projeto nao encontrado: $PROJECT_ROOT"
  validate_targets
  create_clone_dir

  trap cleanup EXIT

  log "clonando $REPO_URL em $CLONE_DIR no modo $INSTALL_MODE"
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
