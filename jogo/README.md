# Protótipo no Godot

Projeto Godot 4 do protótipo da demo. Feito com formas simples, sem arte final.

## Como abrir

1. Abra o Godot (`C:\Godot\Godot_v4.7.2-stable_win64.exe`).
2. Clique em **Importar**, escolha o arquivo `project.godot` desta pasta e confirme.
3. Com o projeto aberto, aperte **F5** para jogar.

## Controles

| Tecla | Ação | Marco |
|---|---|---|
| Setas | Mover em 8 direções | M1 ✅ |
| D | Dash | M2 ✅ |
| S | Trocar o tipo de dash | M2 ✅ |
| A | Atacar (combo de 3 golpes) | M3 ✅ |
| Q | Parry | M4 |
| E | Interagir | M7 |
| F11 | Alternar tela cheia e janela | — |
| R | Recomeçar a sala | — |
| Esc | Fechar o jogo (provisório) | — |

## Escala

O jogo roda em **640 × 360** e é ampliado 3× num monitor 1920 × 1080, com os pixels visíveis. Todos os números do projeto estão em pixels da arte: o personagem padrão tem 50 px e aparece com 150 px na tela. A ampliação é sempre inteira, por isso o jogo abre em tela cheia. Em janela, ele fica 2× e sobra borda preta.

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `scripts/valores.gd` | **Todos os números de calibragem** (velocidades, distâncias, tempos). É aqui que se ajusta o jogo |
| `scripts/jogador.gd` | Homem-gato: movimento, dashes, stamina e combo |
| `scripts/inimigo.gd` | Base dos inimigos: vida, dano, knockback, morte |
| `cenas/alvo.tscn` | Alvo de treino parado, com o tamanho do sapo |
| `scripts/hud.gd` | HUD provisória: vida, stamina e dash equipado |
| `scripts/som.gd` | Sons provisórios, gerados por código |
| `scripts/sala.gd` | Monta uma sala a partir de um mapa em texto, com a legenda do [level design](../docs/02-level-design-demo.md) |
| `cenas/sala_teste.tscn` | Sala de teste do M1. O mapa fica no campo **Mapa** do nó `SalaTeste` |
| `testes/teste_m1.gd` a `teste_m3.gd` | Testes automáticos de cada marco |

No mapa em texto, cada caractere vale 32 × 32 px (2 × 2 tiles): `T` vegetação, `#` parede da ruína, `o` obstáculo, `.` chão, `:` trilha, `@` início do jogador, `x` alvo de treino.

## Rodar o teste automático

Na pasta `jogo/`:

```bash
C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/teste_m1.gd
```

Troque `teste_m1` pelo marco que quiser testar.
