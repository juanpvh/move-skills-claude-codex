# yt-transcript

Skill para Claude Code que extrai transcrições de vídeos do YouTube usando yt-dlp.

## O que faz

- Baixa apenas as legendas (sem baixar o vídeo)
- Tenta legendas manuais primeiro, depois automáticas
- Suporta inglês e português
- Converte VTT para texto limpo, sem timestamps nem tags HTML
- Opção de saída com timestamps `[MM:SS]`

## Instalação

```bash
git clone https://github.com/duduesh/yt-transcript ~/.agents/skills/yt-transcript
```

Dependência: [yt-dlp](https://github.com/yt-dlp/yt-dlp)

```bash
brew install yt-dlp
```

## Como usar

Cole o link do YouTube no chat e peça a transcrição:

```
transcreve esse vídeo: https://www.youtube.com/watch?v=XXXXXXXXXXX
```

O arquivo `XXXXXXXXXX-transcript.txt` é salvo na pasta atual.

## Licença

MIT
