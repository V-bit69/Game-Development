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
| Q | Parry | M4 ✅ |
| E | Interagir, avançar diálogo, recomeçar depois de morrer | M7 ✅ |
| F11 | Alternar tela cheia e janela | — |
| D perto do trecho escalável | Escalar a parede da ruína | M8 ✅ |
| Esc | Pausa (Continuar, Recomeçar a fase, Sair) | M9 ✅ |
| R | Recomeçar a fase (atalho de desenvolvimento) | — |

## Escala

O jogo roda em **640 × 360** e é ampliado 3× num monitor 1920 × 1080, com os pixels visíveis. Todos os números do projeto estão em pixels da arte: o personagem padrão tem 50 px e aparece com 150 px na tela. A ampliação é sempre inteira, por isso o jogo abre em tela cheia. Em janela, ele fica 2× e sobra borda preta.

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `scripts/valores.gd` | **Todos os números de calibragem** (velocidades, distâncias, tempos). É aqui que se ajusta o jogo |
| `scripts/jogador.gd` | Homem-gato: movimento, dashes, stamina e combo |
| `scripts/inimigo.gd` | Base dos inimigos: vida, dano, knockback, parry, atordoamento, entrada nos encontros, morte |
| `scripts/sapo.gd` · `scripts/sapo_lingua.gd` | Sapo comum e sapo com língua |
| `scripts/textos.gd` | **Todas as falas da floresta**, para o game design revisar |
| `scripts/dialogo.gd` | Caixa de diálogo |
| `scripts/tela.gd` | Pausa, tela de morte e atalhos de janela |
| `cenas/alvo.tscn` · `cenas/alvo_atacante.tscn` | Alvos de treino (parado e que ataca, para treinar o parry) |
| `scripts/hud.gd` | HUD provisória: vida, stamina e dash equipado |
| `scripts/som.gd` | Sons provisórios, gerados por código |
| `scripts/sala.gd` | Monta uma sala a partir de um mapa em texto, com a legenda do [level design](../docs/02-level-design-demo.md) |
| `cenas/floresta.tscn` | **Blockout da floresta** (cena principal, abre no F5). O mapa fica no campo **Mapa** do nó `Floresta` |
| `cenas/sala_teste.tscn` | Sala de teste para mecânicas, com alvos de treino. Para abrir: dois cliques nela e **F6** |
| `testes/teste_m1.gd` a `teste_m9.gd` | Testes automáticos de cada marco |
| `testes/teste_blockout.gd` | Confere o mapa da floresta: tamanho, contagem de sapos e se tudo é alcançável |

No mapa em texto, cada caractere vale 32 × 32 px (2 × 2 tiles). A legenda é a do [level design](../docs/02-level-design-demo.md): `T` vegetação, `#` parede da ruína, `o` obstáculo, `.` chão, `:` trilha, `@` início do jogador, `X` Xennar, `F` fogueira, `L` flor, `G` estátua, `t` elemento tecnológico, `K` peça da KLM-99, `s` sapo comum, `l` sapo com língua, `!` gatilho de encontro, `=` entrada da ruína, `D` trecho escalável, `v` descida e `x` alvo de treino e `a` alvo de treino que ataca.

## Rodar o teste automático

Na pasta `jogo/`:

```bash
C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/teste_m1.gd
```

Troque `teste_m1` pelo marco que quiser testar.
