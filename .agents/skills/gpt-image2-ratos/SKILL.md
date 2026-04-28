---
name: gpt-image2-ratos
description: Gera imagens via gpt-image-2 (OpenAI) usando OAuth do plano ChatGPT do user — sem API key, sem custo direto. Lê ~/.codex/auth.json (login feito uma vez via Codex CLI) e dispara um proxy local openai-oauth que roteia pelo backend Codex. Suporta text-to-image e image-edit (referência via base64). Setup conversacional do estilo a cada uso. Latência alta (60-180s por imagem). Use quando o user paga ChatGPT Plus/Pro e não quer cobrar API. Pra iteração rápida ou usuários sem plano pago, usar image-gen-ratos (FAL) ou nanobanana-ratos (Gemini).
---

# gpt-image2-ratos

Skill de geração de imagens via **gpt-image-2** usando **OAuth do plano ChatGPT do user**. Sem API key, sem custo direto — queima limite do plano.

Pra usuários que pagam ChatGPT Plus/Pro/Business/Enterprise. Pra usuários sem plano, redirecionar pra [`/image-gen-ratos`](https://github.com/duduesh/image-gen-ratos) (FAL) ou [`/nanobanana-ratos`](https://github.com/duduesh/nanobanana-ratos) (Gemini).

## Aviso de latência (importante)

Antes de gerar, deixar claro pro user que cada imagem leva **60-180 segundos** (vs 10-15s no FAL). Isso é o overhead do proxy OAuth + Responses API + tool call de image_generation.

Se o user quer 5+ variações pra escolher, sugerir usar `image-gen-ratos` (FAL) em vez disso. Aqui a skill brilha quando é "1 imagem boa final".

## Setup (primeira vez)

A skill **não tem .env**. Toda a auth vem do `~/.codex/auth.json` que o Codex CLI cria. O fluxo de setup é:

### 1. Verificar pré-requisitos

```bash
test -f ~/.codex/auth.json && echo "OK_AUTH" || echo "NO_AUTH"
which node npx && node --version
which python3
```

### 2. Se `~/.codex/auth.json` NÃO existe

Mostrar ao user:

> Pra usar essa skill tu precisa logar no Codex CLI uma vez (vai abrir o browser). Roda isso no terminal e me avisa quando terminar:
>
> ```bash
> npx @openai/codex login
> ```
>
> Depois disso o token fica salvo em `~/.codex/auth.json` e dura meses. Tu não precisa logar de novo.
>
> Se tu não tem plano ChatGPT pago, essa skill não funciona. Usa `/image-gen-ratos` (FAL, $0.06/imagem) ou `/nanobanana-ratos` (Gemini, grátis) em vez disso.

### 3. Se `~/.codex/auth.json` JÁ existe

Seguir direto pro fluxo de geração. Não precisa de setup adicional.

## Estilo visual (conversacional, NÃO hardcoded)

Igual a `image-gen-ratos`. A skill **não força** nenhum estilo. Cada projeto/marca/canal tem o seu.

No início de cada sessão (a primeira vez que o user pedir imagem na conversa atual), perguntar:

> Como tu quer o estilo? 4 caminhos:
>
> 1. **Livre** — descreve em palavras
> 2. **Brand guide** — cola aqui o teu DNA visual ou aponta pra um arquivo
> 3. **Usar exemplo** — tem exemplos em `~/.agents/skills/gpt-image2-ratos/examples/`
> 4. **Sem estilo** — gera puro, sem calibração

Aplicar o estilo escolhido como contexto/prefixo no prompt em inglês. Não perguntar isso a cada imagem da mesma sessão — só na primeira.

## Modos de operação

### Modo direto

User cola um prompt pronto em inglês. Claude só roda.

### Modo assistido (default quando user só passa tema)

User dá um tema curto. Claude:

1. Se ainda não definiu estilo nesta sessão, pergunta
2. Sugere **3 conceitos distintos** em 2-3 linhas cada
3. Pergunta qual vai
4. Quando user escolher: escreve o prompt em **inglês** com detalhes (lighting, câmera, composição, etc)
5. Roda
6. Mostra

## Aspect ratio e quality

| Aspect | Width x Height | Pra quê |
|---|---|---|
| `1:1` (default) | 1024x1024 | Feed quadrado |
| `4:5` | 1024x1280 | Feed vertical |
| `9:16` | 1024x1792 | Stories, Reels, Shorts |
| `16:9` | 1792x1024 | Thumbnail YouTube, landscape |

**Quality** — afeta latência mais que custo (que é flat dentro do limite do plano):

| Quality | Latência tipica | Quando usar |
|---|---|---|
| `low` | ~60-90s | Rascunho |
| `medium` (default) | ~90-120s | Produção padrão |
| `high` | ~120-180s | Final final |

## Comando base (text-to-image)

```bash
PORT=10531
OUT_DIR="${OUT_DIR:-/tmp/gpt-image2-out}"
mkdir -p "$OUT_DIR"

# 1. Verificar se proxy ja esta rodando
if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/v1/models" 2>/dev/null | grep -qE "^(2|4)"; then
  echo "[skill] proxy ja UP"
  PROXY_PID=""
else
  echo "[skill] subindo proxy openai-oauth na porta $PORT..."
  npx -y openai-oauth --port "$PORT" > "$OUT_DIR/proxy.log" 2>&1 &
  PROXY_PID=$!
  # Esperar proxy ficar disponivel (max 30s)
  for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/v1/models" 2>/dev/null | grep -qE "^(2|4)"; then
      echo "[skill] proxy UP (tentativa $i)"
      break
    fi
    sleep 1
  done
fi

# 2. Montar payload (Responses API com tool image_generation)
cat > "$OUT_DIR/payload.json" <<JSON
{
  "model": "gpt-5.4-mini",
  "input": [
    {"role": "developer", "content": "You are an image generation assistant. Your sole function is to invoke the image_generation tool. Never respond with plain text."},
    {"role": "user", "content": "Generate an image: PROMPT_AQUI"}
  ],
  "tools": [
    {"type": "image_generation", "quality": "medium", "size": "1024x1024", "moderation": "low"}
  ],
  "tool_choice": "auto",
  "stream": true
}
JSON

# 3. Disparar e capturar SSE
curl -sS -N -X POST "http://127.0.0.1:$PORT/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d "@$OUT_DIR/payload.json" > "$OUT_DIR/sse.raw"

# 4. Extrair b64 do output (Python)
python3 <<'PY'
import json, base64, pathlib, sys
raw = pathlib.Path("OUT_DIR_PLACEHOLDER/sse.raw").read_text()
img_b64 = None
for block in raw.split("\n\n"):
    data = "".join(line[6:] for line in block.split("\n") if line.startswith("data: "))
    if not data or data == "[DONE]":
        continue
    try:
        e = json.loads(data)
    except json.JSONDecodeError:
        continue
    if e.get("type") == "response.output_item.done":
        item = e.get("item", {})
        if item.get("type") == "image_generation_call" and item.get("result"):
            img_b64 = item["result"]
if not img_b64:
    print("ERRO: image_generation_call.result nao encontrado", file=sys.stderr)
    sys.exit(1)
out = pathlib.Path("OUTPUT_PATH_PLACEHOLDER")
out.write_bytes(base64.b64decode(img_b64))
print(f"Salvo: {out} ({out.stat().st_size} bytes)")
PY
```

Substituir `PROMPT_AQUI`, `OUT_DIR_PLACEHOLDER` e `OUTPUT_PATH_PLACEHOLDER` antes de rodar.

**Não matar o proxy** ao final do request. Deixa rodando pra reusar nas próximas imagens da sessão. Pra parar manualmente: `lsof -ti:10531 | xargs kill`.

## Comando com imagem de referência (image edit)

Mesmo endpoint, content do user vira array com `input_image` antes do `input_text`:

```json
"input": [
  {"role": "developer", "content": "You are an image editing assistant..."},
  {"role": "user", "content": [
    {"type": "input_image", "image_url": "data:image/png;base64,BASE64_DA_IMAGEM"},
    {"type": "input_text", "text": "Edit this image: PROMPT_AQUI"}
  ]}
]
```

`tool_choice` muda pra `"required"` em modo edit pra forçar invocação da tool.

Pode passar múltiplas referências (até 16) — adicionar mais `input_image` no array.

## Princípios pra escrever o prompt

1. **Em inglês.** O modelo entende PT mas responde melhor a direção técnica em EN. Texto literal na imagem pode ser em PT.
2. **Texto em quotes.** Pra renderizar verbatim: `reads "[texto em português]"`. ~99% accuracy.
3. **Composição, não intenção.** "Medium shot, subject centered, banker lamp backlighting" > "dramatic portrait".
4. **Listar negativos.** "No emojis, no gradients, no stock photo aesthetic".
5. **Specificity vence.** "Space-black MacBook Pro 16-inch M3" > "a laptop".
6. **Referências cinematográficas (se o estilo pedir).** "In the visual style of Severance office scenes".

## Pós-geração

Mostrar a imagem ao user. Por causa da latência, perguntar **antes** de fazer outra:
- Aprovou? → pergunta onde salvar/publicar
- Quer variação? → ajusta 1 detalhe e roda de novo (avisa que vai levar mais 1-3 min)
- Quer mesma ideia em outro aspect/quality? → rerodar

Não gerar 3 variações em paralelo sem perguntar — cada uma queima quota Codex do plano dele.

## Troubleshooting

**`~/.codex/auth.json` não existe**
User não logou no Codex CLI. Mostrar: `npx @openai/codex login`.

**Proxy não sobe (timeout em 30s)**
Ver `$OUT_DIR/proxy.log`. Causas comuns:
- Porta 10531 ocupada por outro processo: `lsof -i :10531` e matar
- Rede lenta no primeiro download do `openai-oauth` (npx baixa antes de rodar)
- Token expirado e refresh falhou: rodar `npx @openai/codex login` de novo

**`401` ou `403` do proxy**
Token OAuth expirou ou foi revogado. User precisa relogar: `npx @openai/codex login`.

**`429` do proxy**
Limite Codex do plano ChatGPT esgotado. Esperar reset (geralmente a cada 5h).

**Imagem não veio (`No image data in response`)**
Modelo recusou a request (moderation, prompt ambíguo). Ver últimos eventos do SSE. Reescrever o prompt.

**Latência muito maior que 180s**
Status do plano ChatGPT pode estar com fila. Verificar [status.openai.com](https://status.openai.com).

**Imagem em PT com acentos quebrados**
Encurtar a string. Confirmar que tá em quotes: `reads "texto"`.

## Custos reais (atenção)

A skill é "free" no sentido de não cobrar API extra, mas **queima limite do plano ChatGPT**. Por doc oficial da OpenAI, image generation consome limite Codex **3-5x mais rápido** que turn de texto.

Avisar o user no setup:

> Heads up: cada imagem aqui usa parte da tua quota Codex do plano ChatGPT. Se tu também usa Codex CLI pra coding, isso compete pelo mesmo limite. No Plus ($20/mês), tu provavelmente consegue gerar ~6-30 imagens medium em cada janela de 5h, mas isso vai depender do uso normal do Codex.

## Referências

- Exemplos de estilo: `~/.agents/skills/gpt-image2-ratos/examples/`
- [Pacote openai-oauth (proxy local)](https://github.com/EvanZhouDev/openai-oauth)
- [Codex CLI Authentication (OpenAI)](https://developers.openai.com/codex/auth)
- [Codex CLI Features (image generation)](https://developers.openai.com/codex/cli/features)
- Skill complementar (FAL, paga): `/image-gen-ratos`
- Skill complementar (Gemini, grátis): `/nanobanana-ratos`
