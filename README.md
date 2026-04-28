# move-skills-claude-codex

Este repositorio tem dois fluxos diferentes:

1. `install.sh`: instala rapidamente a pasta `.agents` no projeto atual.
2. `sync-claude-skills.sh`: sincroniza skills a partir de uma lista fixa de repositorios GitHub.

## Requisitos

- Bash
- Git
- Para `sync-claude-skills.sh`: `tar`, `grep` e `sed`

## Instalacao rapida de `.agents`

Rode a partir da raiz do projeto que vai receber as skills:

```bash
curl -fsSL https://raw.githubusercontent.com/juanpvh/move-skills-claude-codex/main/install.sh -o install.sh
bash ./install.sh
rm -f install.sh
```

O `install.sh` faz este fluxo:

1. clona `https://github.com/juanpvh/move-skills-claude-codex`
2. move `.agents/` para a raiz do projeto atual
3. remove a pasta temporaria `move-skills-claude-codex`

Se o projeto ja tiver `.agents/`, o script aborta para evitar sobrescrita.

## Sincronizacao completa de skills

Execute a partir da raiz deste repositorio:

```bash
bash ./sync-claude-skills.sh
```

O fluxo do `sync-claude-skills.sh` e:

1. clonar ou atualizar os repositorios em `temp/`
2. publicar uma copia transformada de cada skill em `.agents/skills/<nome>`
3. trocar referencias de `.claude` para `.agents`
4. no caso de `ads-ratos`, mover `.claude/commands/*` para `references/` e remover `.claude`

## Download e execucao direta do sync

Se quiser baixar e executar o sincronizador sem clonar este repositorio antes, rode na raiz do projeto de destino:

```bash
curl -fsSL https://raw.githubusercontent.com/juanpvh/move-skills-claude-codex/main/sync-claude-skills.sh -o /tmp/sync-claude-skills.sh
chmod +x /tmp/sync-claude-skills.sh
SKILLS_PROJECT_ROOT="$PWD" /tmp/sync-claude-skills.sh
```

Esse fluxo:

1. baixa o script para `/tmp`
2. executa usando o diretorio atual como raiz do projeto
3. cria ou atualiza `temp/` e `.agents/skills/` no projeto atual

## Variaveis opcionais do sync

- `SKILLS_PROJECT_ROOT`: redefine a raiz do projeto onde `temp/` e `.agents/skills/` serao criados
- `SKILLS_TEMP_ROOT`: redefine a pasta base temporaria
- `SKILLS_CLONE_ROOT`: redefine a pasta onde os repositorios sao clonados

## Resultado esperado do sync

- repositorios Git ficam em `temp/`
- skills publicadas ficam em `.agents/skills/`
- se o commit local ja for igual ao remoto, o script nao baixa novamente
