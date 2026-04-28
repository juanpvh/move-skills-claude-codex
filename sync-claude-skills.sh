#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${SKILLS_PROJECT_ROOT:-$DEFAULT_PROJECT_ROOT}"

TEMP_ROOT="${SKILLS_TEMP_ROOT:-$PROJECT_ROOT/temp}"
CLONE_ROOT="${SKILLS_CLONE_ROOT:-$TEMP_ROOT}"
AGENTS_SKILLS_DIR="$PROJECT_ROOT/.agents/skills"

REPOS=(
  "https://github.com/duduesh/gpt-image2-ratos.git"
  "https://github.com/duduesh/image-gen-ratos.git"
  "https://github.com/duduesh/ads-ratos.git"
  "https://github.com/duduesh/ga4-ratos.git"
  "https://github.com/duduesh/publicar-social-ratos.git"
  "https://github.com/duduesh/carrossel-ratos.git"
  "https://github.com/duduesh/transcribe.git"
  "https://github.com/duduesh/yt-transcript.git"
  "https://github.com/duduesh/google-ads-ratos.git"
  "https://github.com/duduesh/meta-ads-ratos.git"
  "https://github.com/duduesh/nanobanana-ratos.git"
  "https://github.com/duduesh/triagem-youtube-ratos.git"
  "https://github.com/duduesh/schwartz-copy.git"
  "https://github.com/duduesh/ogilvy-copy.git"
)

cloned_count=0
updated_count=0
already_current_count=0
failed_count=0

log() {
  printf '[sync-claude-skills] %s\n' "$1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "comando obrigatorio ausente: $1"
    exit 1
  fi
}

move_ads_commands_into_references() {
  local target_dir="$1"
  local commands_dir references_dir command_file

  commands_dir="$target_dir/.claude/commands"
  references_dir="$target_dir/references"

  [[ -d "$commands_dir" ]] || return

  mkdir -p "$references_dir"

  for command_file in "$commands_dir"/*; do
    [[ -e "$command_file" ]] || continue
    mv "$command_file" "$references_dir/"
  done

  rm -rf "$target_dir/.claude"
}

publish_repo() {
  local repo_name="$1"
  local source_dir target_dir file

  source_dir="$CLONE_ROOT/$repo_name"
  target_dir="$AGENTS_SKILLS_DIR/$repo_name"

  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  if ! git -C "$source_dir" archive --format=tar HEAD | tar -xf - -C "$target_dir"; then
    log "falha ao publicar $repo_name em $target_dir"
    failed_count=$((failed_count + 1))
    return 1
  fi

  if [[ "$repo_name" == "ads-ratos" ]]; then
    move_ads_commands_into_references "$target_dir"
  fi

  while IFS= read -r -d '' file; do
    sed -i 's/\.claude/\.agents/g' "$file"
  done < <(grep -rlI --null '\.claude' "$target_dir")
}

sync_repo() {
  local repo_url="$1"
  local repo_name source_dir branch_name local_head remote_head

  repo_name="${repo_url##*/}"
  repo_name="${repo_name%.git}"
  source_dir="$CLONE_ROOT/$repo_name"

  if [[ -d "$source_dir/.git" ]]; then
    log "verificando $repo_name"
    branch_name="$(git -C "$source_dir" symbolic-ref --short HEAD)"
    local_head="$(git -C "$source_dir" rev-parse HEAD)"
    remote_head=""
    read -r remote_head _ < <(git -C "$source_dir" ls-remote --heads origin "$branch_name")

    if [[ -n "$remote_head" && "$local_head" == "$remote_head" ]]; then
      already_current_count=$((already_current_count + 1))
      log "$repo_name ja esta na ultima versao"
      publish_repo "$repo_name"
      return
    fi

    log "atualizando $repo_name"

    if git -C "$source_dir" fetch origin "$branch_name" --prune && git -C "$source_dir" merge --ff-only "origin/$branch_name"; then
      updated_count=$((updated_count + 1))
      publish_repo "$repo_name"
    else
      log "falha ao atualizar $repo_name"
      failed_count=$((failed_count + 1))
    fi
    return
  fi

  if [[ -e "$source_dir" ]]; then
    log "diretorio existente sem git, pulando: $source_dir"
    failed_count=$((failed_count + 1))
    return
  fi

  log "clonando $repo_name"
  if git clone --depth 1 "$repo_url" "$source_dir"; then
    cloned_count=$((cloned_count + 1))
    publish_repo "$repo_name"
  else
    log "falha ao clonar $repo_name"
    failed_count=$((failed_count + 1))
  fi
}

main() {
  require_command git
  require_command tar
  require_command grep
  require_command sed

  mkdir -p "$CLONE_ROOT"
  mkdir -p "$AGENTS_SKILLS_DIR"
  log "sincronizando repositorios em $CLONE_ROOT"

  for repo_url in "${REPOS[@]}"; do
    sync_repo "$repo_url"
  done

  log "resumo: clonados=$cloned_count atualizados=$updated_count ja_atuais=$already_current_count falhas=$failed_count"

  if [[ "$failed_count" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
