# Publicar Social Ratos

Skill de Claude Code pra publicar carrosséis e posts no Instagram e TikTok direto do terminal. Setup guiado, dois métodos disponíveis.

## O que faz

- Publica carrosséis e imagens no Instagram e TikTok
- Dois métodos: **Post for Me** (recomendado) ou **Graph API** (avançado)
- Setup conversacional na primeira vez
- Dry-run antes de publicar
- TikTok sempre como draft (pra escolher música no app)

## Instalação

```bash
git clone https://github.com/duduesh/publicar-social-ratos ~/.agents/skills/publicar-instagram
```

## Como usar

```
publica o carrossel que acabei de criar
```

Ou com caminho:

```
publica conteudo/carrosseis/ia-no-varejo/instagram/
```

Na primeira vez, a skill guia o setup do método escolhido.

## Métodos

| | Post for Me | Graph API |
|---|---|---|
| **Plataformas** | Instagram, TikTok, LinkedIn | Só Instagram |
| **Setup** | 5 min (conta + API key) | ~15 min (OAuth + tokens) |
| **Token expira?** | Não | A cada 60 dias |
| **TikTok** | Sim (draft nativo) | Não |
| **Custo** | Gratuito | Gratuito |

## Estrutura

```
publicar-instagram/
├── SKILL.md
└── scripts/
    ├── publish-postforme.js
    └── publish-graph-api.js
```

## Pré-requisitos

- **Post for Me:** conta em postforme.dev + API key no `.env`
- **Graph API:** app no Meta Developer + token longo + imgbb key no `.env`
- **Node.js** pra rodar os scripts

## Licença

CC BY 4.0
