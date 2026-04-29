#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${SKILLS_PROJECT_ROOT:-$DEFAULT_PROJECT_ROOT}"
SYNC_MODE="${SKILLS_SYNC_MODE:-both}"

TEMP_ROOT="${SKILLS_TEMP_ROOT:-$PROJECT_ROOT/temp}"
CLONE_ROOT="${SKILLS_CLONE_ROOT:-$TEMP_ROOT}"
AGENTS_SKILLS_DIR="$PROJECT_ROOT/.agents/skills"
AGENTS_PLUGINS_DIR="$PROJECT_ROOT/.agents/plugins"
PLUGINS_DIR="$PROJECT_ROOT/plugins"
STAGING_SKILLS_DIR="$TEMP_ROOT/published-skills"
PUBLISHED_SKILLS_DIR=""

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
Uso: bash ./sync-claude-skills.sh [--mode skills|plugins|both]

Modos:
  skills   publica apenas em .agents/skills
  plugins  publica apenas em plugins/ e .agents/plugins/marketplace.json
  both     publica skills e plugins

Variaveis opcionais:
  SKILLS_SYNC_MODE
  SKILLS_PROJECT_ROOT
  SKILLS_TEMP_ROOT
  SKILLS_CLONE_ROOT
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
        SYNC_MODE="$2"
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

uses_skills_output() {
  [[ "$SYNC_MODE" == "skills" || "$SYNC_MODE" == "both" ]]
}

uses_plugins_output() {
  [[ "$SYNC_MODE" == "plugins" || "$SYNC_MODE" == "both" ]]
}

configure_paths() {
  if uses_skills_output; then
    PUBLISHED_SKILLS_DIR="$AGENTS_SKILLS_DIR"
  else
    PUBLISHED_SKILLS_DIR="$STAGING_SKILLS_DIR"
  fi
}

write_plugin_manifest() {
  local plugin_name="$1"
  local plugin_json_path="$2"

  case "$plugin_name" in
    ads-ratos)
      cat >"$plugin_json_path" <<'EOF'
{
  "name": "ads-ratos",
  "version": "0.1.0",
  "description": "Suite local de skills para diagnostico, auditoria e operacao de Meta Ads, Google Ads e GA4.",
  "author": {
    "name": "RATOS IA",
    "url": "https://github.com/juanpvh/move-skills-claude-codex"
  },
  "homepage": "https://github.com/juanpvh/move-skills-claude-codex",
  "repository": "https://github.com/juanpvh/move-skills-claude-codex",
  "keywords": [
    "ads",
    "meta-ads",
    "google-ads",
    "ga4",
    "trafego-pago"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Ads Ratos",
    "shortDescription": "Diagnostico, auditoria e operacao de ads",
    "longDescription": "Empacota as skills ads-ratos, meta-ads-ratos, google-ads-ratos e ga4-ratos em um unico plugin local.",
    "developerName": "RATOS IA",
    "category": "Marketing",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/juanpvh/move-skills-claude-codex",
    "defaultPrompt": [
      "Faz um diagnostico da conta de ads.",
      "Gera um relatorio mensal com benchmarks BR.",
      "Audita Meta Ads, Google Ads e GA4 do cliente."
    ],
    "brandColor": "#1F6FEB",
    "composerIcon": "./assets/icon.svg",
    "logo": "./assets/logo.svg"
  }
}
EOF
      ;;
    imagem-ratos)
      cat >"$plugin_json_path" <<'EOF'
{
  "name": "imagem-ratos",
  "version": "0.1.0",
  "description": "Suite local de skills para geracao e edicao de imagens com diferentes provedores e estilos.",
  "author": {
    "name": "RATOS IA",
    "url": "https://github.com/juanpvh/move-skills-claude-codex"
  },
  "homepage": "https://github.com/juanpvh/move-skills-claude-codex",
  "repository": "https://github.com/juanpvh/move-skills-claude-codex",
  "keywords": [
    "imagem",
    "gpt-image",
    "gemini",
    "criativos",
    "design"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Imagem Ratos",
    "shortDescription": "Geracao de imagem com varios motores",
    "longDescription": "Empacota as skills gpt-image2-ratos, image-gen-ratos e nanobanana-ratos em um unico plugin local.",
    "developerName": "RATOS IA",
    "category": "Creativity",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/juanpvh/move-skills-claude-codex",
    "defaultPrompt": [
      "Cria um criativo de imagem para campanha.",
      "Gera uma variacao visual no estilo da marca.",
      "Faz um mockup com texto e composicao."
    ],
    "brandColor": "#F97316",
    "composerIcon": "./assets/icon.svg",
    "logo": "./assets/logo.svg"
  }
}
EOF
      ;;
    copy-ratos)
      cat >"$plugin_json_path" <<'EOF'
{
  "name": "copy-ratos",
  "version": "0.1.0",
  "description": "Suite local de skills para copy de branding e resposta direta.",
  "author": {
    "name": "RATOS IA",
    "url": "https://github.com/juanpvh/move-skills-claude-codex"
  },
  "homepage": "https://github.com/juanpvh/move-skills-claude-codex",
  "repository": "https://github.com/juanpvh/move-skills-claude-codex",
  "keywords": [
    "copy",
    "branding",
    "vendas",
    "ogilvy",
    "schwartz"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Copy Ratos",
    "shortDescription": "Copy para branding e performance",
    "longDescription": "Empacota as skills ogilvy-copy e schwartz-copy em um unico plugin local.",
    "developerName": "RATOS IA",
    "category": "Writing",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/juanpvh/move-skills-claude-codex",
    "defaultPrompt": [
      "Escreve uma landing page de alta conversao.",
      "Cria um manifesto de marca no estilo Ogilvy.",
      "Gera headlines para campanha de resposta direta."
    ],
    "brandColor": "#16A34A",
    "composerIcon": "./assets/icon.svg",
    "logo": "./assets/logo.svg"
  }
}
EOF
      ;;
    social-ratos)
      cat >"$plugin_json_path" <<'EOF'
{
  "name": "social-ratos",
  "version": "0.1.0",
  "description": "Suite local de skills para criar e publicar conteudo em Instagram e TikTok.",
  "author": {
    "name": "RATOS IA",
    "url": "https://github.com/juanpvh/move-skills-claude-codex"
  },
  "homepage": "https://github.com/juanpvh/move-skills-claude-codex",
  "repository": "https://github.com/juanpvh/move-skills-claude-codex",
  "keywords": [
    "social",
    "instagram",
    "tiktok",
    "carrossel",
    "publicacao"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "Social Ratos",
    "shortDescription": "Criacao e publicacao social",
    "longDescription": "Empacota as skills carrossel-ratos e publicar-social-ratos em um unico plugin local.",
    "developerName": "RATOS IA",
    "category": "Marketing",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/juanpvh/move-skills-claude-codex",
    "defaultPrompt": [
      "Faz um carrossel para Instagram sobre este tema.",
      "Publica este criativo no Instagram e TikTok.",
      "Transforma este roteiro em slides prontos."
    ],
    "brandColor": "#DB2777",
    "composerIcon": "./assets/icon.svg",
    "logo": "./assets/logo.svg"
  }
}
EOF
      ;;
    youtube-ratos)
      cat >"$plugin_json_path" <<'EOF'
{
  "name": "youtube-ratos",
  "version": "0.1.0",
  "description": "Suite local de skills para triagem de pautas e transcricao de videos e conteudo do YouTube.",
  "author": {
    "name": "RATOS IA",
    "url": "https://github.com/juanpvh/move-skills-claude-codex"
  },
  "homepage": "https://github.com/juanpvh/move-skills-claude-codex",
  "repository": "https://github.com/juanpvh/move-skills-claude-codex",
  "keywords": [
    "youtube",
    "transcricao",
    "transcript",
    "triagem",
    "conteudo"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "YouTube Ratos",
    "shortDescription": "Triagem e transcricao de conteudo",
    "longDescription": "Empacota as skills triagem-youtube-ratos, yt-transcript e transcribe em um unico plugin local.",
    "developerName": "RATOS IA",
    "category": "Research",
    "capabilities": [
      "Interactive",
      "Write"
    ],
    "websiteURL": "https://github.com/juanpvh/move-skills-claude-codex",
    "defaultPrompt": [
      "Transcreve este video do YouTube.",
      "Prioriza estas pautas para gravar no canal.",
      "Extrai a legenda e resume os pontos centrais."
    ],
    "brandColor": "#DC2626",
    "composerIcon": "./assets/icon.svg",
    "logo": "./assets/logo.svg"
  }
}
EOF
      ;;
    *)
      log "plugin sem manifesto mapeado: $plugin_name"
      failed_count=$((failed_count + 1))
      return 1
      ;;
  esac
}

write_marketplace_json() {
  local marketplace_path="$1"

  cat >"$marketplace_path" <<'EOF'
{
  "name": "ratos-ia",
  "interface": {
    "displayName": "RATOS IA"
  },
  "plugins": [
    {
      "name": "ads-ratos",
      "source": {
        "source": "local",
        "path": "./plugins/ads-ratos"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Marketing"
    },
    {
      "name": "imagem-ratos",
      "source": {
        "source": "local",
        "path": "./plugins/imagem-ratos"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Creativity"
    },
    {
      "name": "copy-ratos",
      "source": {
        "source": "local",
        "path": "./plugins/copy-ratos"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Writing"
    },
    {
      "name": "social-ratos",
      "source": {
        "source": "local",
        "path": "./plugins/social-ratos"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Marketing"
    },
    {
      "name": "youtube-ratos",
      "source": {
        "source": "local",
        "path": "./plugins/youtube-ratos"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Research"
    }
  ]
}
EOF
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
  target_dir="$PUBLISHED_SKILLS_DIR/$repo_name"

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

publish_plugin() {
  local plugin_name="$1"
  shift

  local plugin_root plugin_json_path plugin_skills_dir skill_name source_skill_dir

  plugin_root="$PLUGINS_DIR/$plugin_name"
  plugin_json_path="$plugin_root/.codex-plugin/plugin.json"
  plugin_skills_dir="$plugin_root/skills"

  mkdir -p "$plugin_root/.codex-plugin"
  rm -rf "$plugin_skills_dir"
  mkdir -p "$plugin_skills_dir"

  for skill_name in "$@"; do
    source_skill_dir="$AGENTS_SKILLS_DIR/$skill_name"

    if [[ ! -d "$source_skill_dir" ]]; then
      log "skill obrigatoria ausente para plugin $plugin_name: $skill_name"
      failed_count=$((failed_count + 1))
      return 1
    fi

    cp -R "$source_skill_dir" "$plugin_skills_dir/$skill_name"
  done

  write_plugin_manifest "$plugin_name" "$plugin_json_path"
  log "plugin local atualizado: $plugin_name"
}

publish_plugins() {
  mkdir -p "$AGENTS_PLUGINS_DIR"

  publish_plugin ads-ratos ads-ratos meta-ads-ratos google-ads-ratos ga4-ratos
  publish_plugin imagem-ratos gpt-image2-ratos image-gen-ratos nanobanana-ratos
  publish_plugin copy-ratos ogilvy-copy schwartz-copy
  publish_plugin social-ratos carrossel-ratos publicar-social-ratos
  publish_plugin youtube-ratos triagem-youtube-ratos yt-transcript transcribe

  write_marketplace_json "$AGENTS_PLUGINS_DIR/marketplace.json"
}

main() {
  parse_args "$@"
  validate_mode "$SYNC_MODE"
  configure_paths

  require_command git
  require_command tar
  require_command grep
  require_command sed

  mkdir -p "$CLONE_ROOT"
  rm -rf "$PUBLISHED_SKILLS_DIR"
  mkdir -p "$PUBLISHED_SKILLS_DIR"
  log "sincronizando repositorios em $CLONE_ROOT no modo $SYNC_MODE"

  for repo_url in "${REPOS[@]}"; do
    sync_repo "$repo_url"
  done

  if uses_plugins_output; then
    publish_plugins
  fi

  if ! uses_skills_output; then
    rm -rf "$STAGING_SKILLS_DIR"
  fi

  log "resumo: clonados=$cloned_count atualizados=$updated_count ja_atuais=$already_current_count falhas=$failed_count"

  if [[ "$failed_count" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
