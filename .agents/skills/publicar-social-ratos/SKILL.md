---
name: publicar-instagram
description: >
  Publica carrosséis, imagens e vídeos no Instagram e TikTok direto do Claude Code.
  Suporta dois métodos: Post for Me (mais simples, multi-plataforma) ou
  Graph API do Instagram (direto, gratuito, sem intermediário).
  Inclui setup guiado na primeira vez pra configurar credenciais.
  Use quando o usuário mencionar "publicar", "postar no instagram", "publicar carrossel",
  "publicar no tiktok", "postar isso", ou pedir pra enviar imagens pro Instagram/TikTok.
---

# /publicar — Publicar no Instagram e TikTok

## Setup (primeira vez)

Na primeira vez, guiar o usuário pra escolher e configurar o método de publicação.

### Perguntar o método

> "Pra publicar direto do Claude Code, tu tem duas opções:
>
> **1. Post for Me** (recomendado)
> - Publica no Instagram, TikTok e LinkedIn com uma API só
> - Setup em 5 minutos, token não expira
> - $10/mês
> - Site: postforme.dev
>
> **2. Graph API do Instagram** (gratuito)
> - Publica direto pela API oficial do Instagram
> - Só Instagram (TikTok e LinkedIn não)
> - Token expira a cada 60 dias (renovável)
> - Setup mais técnico (~15 min)
> - 100% gratuito, sem criar conta em nada
>
> Qual tu prefere?"

---

### Setup Post for Me

Se escolheu Post for Me:

1. **Criar conta:**
   > "Acessa postforme.dev, cria uma conta e conecta teu Instagram (e TikTok se quiser).
   > Depois vai em Settings > API e copia a API Key. Cola aqui."

2. **Salvar a key:**
   Receber a API key e adicionar no `.env`:
   ```
   POSTFORME_API_KEY=pfm_live_xxxxx
   ```

3. **Testar conexão:**
   ```bash
   curl -s -H "Authorization: Bearer $(grep POSTFORME_API_KEY .env | cut -d= -f2)" \
     "https://app.postforme.dev/api/v1/social-accounts?platform=instagram" | head -c 200
   ```
   Se retornar conta conectada, tá pronto. Se não, guiar o usuário pra conectar a conta no dashboard.

4. **Instalar o script de publicação:**
   Copiar `scripts/publish-postforme.js` (que vem com esta skill) pra pasta `scripts/` do projeto do usuário.

5. Confirmar:
   > "Pronto! Script de publicação instalado. Tua conta tá conectada. Pra publicar, é só chamar /publicar com as imagens."

---

### Setup Graph API (Instagram Login)

Se escolheu Graph API:

1. **Guiar configuração do Meta Developer:**
   > "Vou te guiar passo a passo. Primeiro:
   > 1. Acessa developers.facebook.com e cria um app tipo 'Business'
   > 2. No app, adiciona o produto 'Instagram' (Instagram API with Instagram Login)
   > 3. Na tela de setup do Instagram, clica em 'Add all required permissions'
   > 4. Na seção 'Gerar tokens de acesso', adiciona tua conta do Instagram
   > 5. Gera o token — ele começa com IGA..."
   > 6. Cola o token aqui"

2. **Pegar Instagram User ID:**
   ```bash
   curl -s "https://graph.instagram.com/v21.0/me?fields=id,username&access_token=TOKEN_IGA" | python3 -m json.tool
   ```
   O campo `id` é o Instagram User ID. O `username` serve pra confirmar que é a conta certa.

3. **Salvar no `.env`:**
   ```
   INSTAGRAM_ACCESS_TOKEN=IGA...
   INSTAGRAM_USER_ID=26186...
   ```
   Só essas 2 variáveis. Não precisa de imgbb, catbox key, nem nada a mais.

4. **Instalar o script:**
   Copiar `scripts/publish-graph-api.js` (que vem com esta skill) pra pasta `scripts/` do projeto do usuário.

5. **Testar conexão:**
   ```bash
   curl -s "https://graph.instagram.com/v21.0/me?fields=id,username&access_token=$(grep INSTAGRAM_ACCESS_TOKEN .env | cut -d= -f2)" | python3 -m json.tool
   ```
   Se retornar `username`, tá pronto.

6. **Avisar sobre renovação:**
   > "Teu token dura 60 dias. Quando expirar, renova com:
   > `curl -s 'https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=TEU_TOKEN'`
   > Ou roda /publicar que eu te guio."

---

## Detalhes técnicos da Graph API

### Endpoints
- Base: `https://graph.instagram.com/v21.0`
- Criar container: `POST /{user_id}/media`
- Publicar: `POST /{user_id}/media_publish`
- Status: `GET /{container_id}?fields=status_code`
- Permalink: `GET /{media_id}?fields=permalink`

### Host de imagens
O Instagram não aceita upload direto de imagens — precisa de URL pública.
O script usa **catbox.moe** (gratuito, sem conta, sem API key):
```bash
curl -s -F "reqtype=fileupload" -F "fileToUpload=@imagem.png" "https://catbox.moe/user/api.php"
# retorna: https://files.catbox.moe/abc123.png
```

### Tipos de publicação suportados

**Carrossel (2-10 imagens):**
1. Upload imagens pro catbox
2. Criar container por imagem com `is_carousel_item=true`
3. Poll status até FINISHED
4. Criar carousel container com `media_type=CAROUSEL`, `children=id1,id2,...`, `caption=...`
5. Poll status até FINISHED
6. Publicar com `creation_id`

**Imagem única:**
1. Upload imagem pro catbox
2. Criar container com `image_url` e `caption` (sem is_carousel_item)
3. Poll status até FINISHED
4. Publicar com `creation_id`

**Vídeo (Reels):**
1. Upload vídeo pro catbox
2. Criar container com `media_type=REELS`, `video_url`, `caption`
3. Poll status até FINISHED (pode levar 2-3 min)
4. Publicar com `creation_id`

### Notas importantes
- `media_type` do carrossel é `CAROUSEL`, não `CAROUSEL_ALBUM` (esse era da API antiga)
- Tokens IGA já vêm de longa duração (60 dias), não precisa converter
- Poll de status a cada 3s com timeout de 60s (vídeos: 180s)

---

## Workflow de publicação (após setup)

### 1. Detectar o que publicar

Se o usuário chamou `/publicar` sem argumentos, verificar:
- Existe `conteudo/carrosseis/` com PNGs recentes? Se sim, oferecer publicar o mais recente
- Se não, perguntar: "O que tu quer publicar? Me passa o caminho das imagens ou roda /carrossel primeiro"

Se chamou com caminho (ex: `/publicar conteudo/carrosseis/ia-no-varejo/instagram/`):
- Usar os PNGs e o `carousel-text.md` (legenda) daquela pasta

### 2. Detectar o método configurado

Verificar `.env`:
- Se tem `POSTFORME_API_KEY` -> usar Post for Me
- Se tem `INSTAGRAM_ACCESS_TOKEN` -> usar Graph API
- Se tem os dois -> perguntar qual usar
- Se não tem nenhum -> rodar setup

### 3. Detectar o tipo de publicação

- 1 imagem -> post único
- 2-10 imagens -> carrossel
- 1 vídeo (--video) -> Reels
- Perguntar se não for óbvio

### 4. Preview antes de publicar

Antes de qualquer publicação, mostrar preview:

> "Vou publicar no Instagram:
> - Tipo: carrossel / imagem única / Reels
> - Imagens: slide-01.png, slide-02.png, ... slide-08.png
> - Legenda: [primeiros 200 chars]...
> - Método: Post for Me / Graph API
>
> Quer que eu faça um dry-run primeiro pra testar, ou manda direto?"

### 5. Dry-run (recomendado na primeira vez)

```bash
# Post for Me
node --env-file=.env scripts/publish-postforme.js \
  --platform "instagram" \
  --images "slide-01.png,slide-02.png,..." \
  --caption "legenda" \
  --dry-run

# Graph API — carrossel
node --env-file=.env scripts/publish-graph-api.js \
  --images "slide-01.png,slide-02.png,..." \
  --caption "legenda" \
  --dry-run

# Graph API — imagem única
node --env-file=.env scripts/publish-graph-api.js \
  --images "imagem.png" \
  --caption "legenda" \
  --dry-run

# Graph API — vídeo (Reels)
node --env-file=.env scripts/publish-graph-api.js \
  --video "video.mp4" \
  --caption "legenda" \
  --dry-run
```

Mostrar resultado do dry-run. Se OK, perguntar:
> "Dry-run passou. Quer publicar de verdade?"

### 6. Publicar

```bash
# Post for Me — Instagram
node --env-file=.env scripts/publish-postforme.js \
  --platform "instagram" \
  --images "slide-01.png,slide-02.png,..." \
  --caption "legenda"

# Post for Me — TikTok (SEMPRE como draft pro usuario escolher musica no app)
node --env-file=.env scripts/publish-postforme.js \
  --platform "tiktok" \
  --images "slide-01.png,slide-02.png,..." \
  --caption "legenda tiktok" \
  --draft

# Graph API — carrossel/imagem/video (o script detecta automaticamente)
node --env-file=.env scripts/publish-graph-api.js \
  --images "slide-01.png,slide-02.png,..." \
  --caption "legenda"
```

### 7. Confirmar

Após publicação:
> "Publicado no Instagram! [link se disponível]"

Se o usuário quiser publicar no TikTok também (e usar Post for Me), perguntar:
> "Quer publicar no TikTok também? Vai como rascunho pra tu escolher a música no app."

---

## Regras

- NUNCA publicar sem confirmação explícita do usuário
- Dry-run recomendado na primeira publicação (não obrigatório depois)
- TikTok via Post for Me: SEMPRE como draft (flag --draft)
- Se o token da Graph API expirou, guiar renovação em vez de dar erro genérico
- Legenda max: 2200 caracteres (Instagram/TikTok), 3000 (LinkedIn)
- Carrossel: 2-10 imagens (Instagram), 4-35 (TikTok)
- Imagem única: 1 imagem
- Vídeo: 1 arquivo de vídeo (Graph API publica como Reels)
- Nunca commitar `.env` no git
