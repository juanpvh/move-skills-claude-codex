# move-skills-claude-codex

Este repositorio tem dois fluxos diferentes:

1. `install.sh`: instala rapidamente `skills`, `plugins` ou ambos no projeto atual.
2. `sync-claude-skills.sh`: sincroniza skills a partir de uma lista fixa de repositorios GitHub.

## Requisitos

- Bash
- Git
- Para `sync-claude-skills.sh`: `tar`, `grep` e `sed`

No Windows 11, rode os scripts via Git Bash. O `install.sh` aceita caminhos no formato `C:\...` nas variaveis `INSTALL_*` e converte esses valores automaticamente quando necessario.

## Instalacao rapida

Rode a partir da raiz do projeto que vai receber as skills:

```bash
curl -fsSL https://raw.githubusercontent.com/juanpvh/move-skills-claude-codex/main/install.sh -o install.sh
bash ./install.sh
bash ./install.sh --mode plugins
bash ./install.sh --mode both
rm -f install.sh
```

O `install.sh` faz este fluxo:

1. clona `https://github.com/juanpvh/move-skills-claude-codex`
2. move `skills`, `plugins` ou ambos conforme o modo escolhido
3. remove o clone temporario criado em `TMPDIR` (ou `/tmp` por padrao)

O script aceita `--mode skills|plugins|both`.
- default atual: `skills`
- `skills`: instala apenas `.agents/skills/`
- `plugins`: instala apenas `plugins/` e `.agents/plugins/`
- `both`: instala `.agents/skills/`, `.agents/plugins/` e `plugins/`

Se o projeto ja tiver os caminhos de destino do modo escolhido, o script aborta para evitar sobrescrita.

## Sincronizacao completa de skills

Execute a partir da raiz deste repositorio:

```bash
bash ./sync-claude-skills.sh
bash ./sync-claude-skills.sh --mode skills
bash ./sync-claude-skills.sh --mode plugins
```

O fluxo do `sync-claude-skills.sh` e:

1. clonar ou atualizar os repositorios em `temp/`
2. publicar uma copia transformada de cada skill em `.agents/skills/<nome>`
3. trocar referencias de `.claude` para `.agents`
4. no caso de `ads-ratos`, mover o diretório `.claude/commands/` completo para `.agents/skills/ads-ratos/commands/`; como o plugin copia essa skill publicada, o conteúdo também aparece em `plugins/ads-ratos/skills/ads-ratos/commands/`
5. montar plugins locais por segmento em `plugins/`
6. gerar ou atualizar `.agents/plugins/marketplace.json` com o catalogo local desses plugins

O script aceita `--mode skills|plugins|both`.
- default atual: `both`
- `skills`: atualiza apenas `.agents/skills/`
- `plugins`: atualiza apenas `plugins/` e `.agents/plugins/marketplace.json`
- `both`: atualiza os dois

Sem `SKILLS_PROJECT_ROOT`, o destino padrao e a propria raiz deste repositorio, onde o `sync-claude-skills.sh` esta localizado.

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
3. cria ou atualiza `temp/`, `.agents/skills/`, `plugins/` e `.agents/plugins/marketplace.json` no projeto atual
4. organiza grupos de skills em plugins locais por segmento

## Variaveis opcionais do sync

- `SKILLS_SYNC_MODE`: define `skills`, `plugins` ou `both`
- `SKILLS_PROJECT_ROOT`: redefine a raiz do projeto onde `temp/` e `.agents/skills/` serao criados
- `SKILLS_TEMP_ROOT`: redefine a pasta base temporaria
- `SKILLS_CLONE_ROOT`: redefine a pasta onde os repositorios sao clonados

## Variaveis opcionais do install

- `INSTALL_MODE`: define `skills`, `plugins` ou `both`
- `INSTALL_PROJECT_ROOT`: redefine a raiz do projeto de destino
- `INSTALL_REPO_URL`: redefine o repositorio a ser clonado
- `INSTALL_CLONE_DIR_NAME`: redefine o nome da pasta temporaria de clone

## Resultado esperado do sync

- repositorios Git ficam em `temp/`
- skills publicadas ficam em `.agents/skills/`
- os plugins locais ficam em `plugins/ads-ratos/`, `plugins/imagem-ratos/`, `plugins/copy-ratos/`, `plugins/social-ratos/` e `plugins/youtube-ratos/`
- o catalogo local de plugins fica em `.agents/plugins/marketplace.json`
- se o commit local ja for igual ao remoto, o script nao baixa novamente

## Grupos de plugins

- `ads-ratos`: `ads-ratos`, `meta-ads-ratos`, `google-ads-ratos`, `ga4-ratos`
- `imagem-ratos`: `gpt-image2-ratos`, `image-gen-ratos`, `nanobanana-ratos`
- `copy-ratos`: `ogilvy-copy`, `schwartz-copy`
- `social-ratos`: `carrossel-ratos`, `publicar-social-ratos`
- `youtube-ratos`: `triagem-youtube-ratos`, `yt-transcript`, `transcribe`

Cobertura atual: todas as skills existentes em `.agents/skills/` ja estao mapeadas nesses 5 plugins.
