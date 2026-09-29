# [Nome provisório]

Jogo de ação e aventura top-down em pixel art. O combate é inspirado em *Hyper Light Drifter*, e a aventura e a narrativa em *Eastward*. Vários protagonistas contam uma mesma história por perspectivas diferentes.

## Documentação

| Documento | Conteúdo |
|---|---|
| [GDD](docs/GDD.md) | Visão geral do jogo. **Documento editável**, é aqui que o GDD evolui ([PDF original v0.1](docs/referencias/GDD-v0.1.pdf)) |
| [01 · Escopo da demo](docs/01-escopo-demo.md) | O que a demo mostra e o que fica de fora |
| [02 · Level design da demo](docs/02-level-design-demo.md) | Rascunho das áreas, fluxo e posicionamento |
| [03 · Roadmap](docs/03-roadmap.md) | Etapas e status atualizado |

## Protótipo web (ensaio)

[prototipo/index.html](prototipo/index.html): a demo inteira em miniatura, jogável no navegador, para validar ideias antes do protótipo oficial no Godot.

- Homem-gato com lâmina (combo de 3 golpes), dash, stamina, escudo e parry perfeito (atordoa e dá crítico)
- Área segura com a anciã (diálogo) e a fogueira, trilha, clareira com 2 levas, arma que libera o tiro, Sentinela com minions, núcleo e volta até a NPC
- Mapa maior que a tela, câmera seguindo, sons e efeitos provisórios em todo evento

Para jogar: ative o GitHub Pages (Settings → Pages → branch `main`) e abra `https://v-bit69.github.io/Game-Development/prototipo/`. Outra opção é baixar o arquivo e abrir no navegador.

> Inimigos, Sentinela, falas e arte são provisórios até a especificação de gameplay chegar.

## Como editar os documentos

Pelo site do GitHub: abra o arquivo, clique no ícone de lápis (**Edit this file**), faça a alteração e clique em **Commit changes** com uma frase curta explicando o que mudou. No GDD, registre também a mudança no **Histórico de versões**, no fim do documento.

## Referências visuais

- [Moodboard](docs/referencias/moodboard.jpg)
- [Referência de câmera e escala](docs/referencias/referencia-camera-escala.jpg)

## Tecnologia (proposta)

Godot 4 · GDScript · resolução base 640×360 · tiles de 16 px
