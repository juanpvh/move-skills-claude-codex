# script-ratos

Script Bash para sincronizar skills a partir de uma lista fixa de repositórios GitHub.

O fluxo do script e:

1. Clonar ou atualizar os repositórios em `temp/`
2. Publicar uma copia transformada de cada skill em `.agents/skills/<nome>`
3. Trocar referencias de `.claude` para `.agents`
4. No caso de `ads-ratos`, mover `.claude/commands/*` para `references/` e remover `.claude`

## Requisitos

- Bash
- Git
- `tar`
- `grep`
- `sed`

## Uso

Executar a partir da raiz do projeto:

```bash
bash ./sync-claude-skills.sh
```

Para publicar o estado atual do projeto no GitHub, rode:

```bash
bash ./publish-project.sh
```

Esse script:

1. inicializa o Git local se necessario
2. configura o `origin` para `https://github.com/juanpvh/move-skills-claude-codex`
3. detecta automaticamente `main` ou `master`
4. adiciona os arquivos respeitando o `.gitignore`
5. cria um commit automatico com data/hora quando houver mudancas
6. faz `push` para o GitHub

## Download e execucao direta

Se quiser baixar e executar sem clonar este repositório antes, rode na raiz do projeto de destino:

```bash
curl -fsSL https://raw.githubusercontent.com/juanpvh/script-ratos/main/sync-claude-skills.sh -o /tmp/sync-claude-skills.sh && chmod +x /tmp/sync-claude-skills.sh && SKILLS_PROJECT_ROOT="$PWD" /tmp/sync-claude-skills.sh
```

Esse comando:

1. baixa o script para `/tmp`
2. executa usando o diretório atual como raiz do projeto
3. cria ou atualiza `temp/` e `.agents/skills/` no projeto atual

## Variaveis opcionais

- `SKILLS_PROJECT_ROOT`: redefine a raiz do projeto onde `temp/` e `.agents/skills/` serao criados
- `SKILLS_TEMP_ROOT`: redefine a pasta base temporaria
- `SKILLS_CLONE_ROOT`: redefine a pasta onde os repositórios sao clonados

## Resultado esperado

- Repositorios Git ficam em `temp/`
- Skills publicadas ficam em `.agents/skills/`
- Se o commit local ja for igual ao remoto, o script nao baixa novamente
