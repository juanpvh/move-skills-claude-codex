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
bash scripts/sync-claude-skills.sh
```

## Variaveis opcionais

- `SKILLS_TEMP_ROOT`: redefine a pasta base temporaria
- `SKILLS_CLONE_ROOT`: redefine a pasta onde os repositórios sao clonados

## Resultado esperado

- Repositorios Git ficam em `temp/`
- Skills publicadas ficam em `.agents/skills/`
- Se o commit local ja for igual ao remoto, o script nao baixa novamente
