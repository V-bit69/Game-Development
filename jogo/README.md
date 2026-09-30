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
| D | Dash | M2 |
| S | Trocar o tipo de dash | M2 |
| A | Atacar | M3 |
| Q | Parry | M4 |
| E | Interagir | M7 |

## Onde fica cada coisa

| Arquivo | O que é |
|---|---|
| `scripts/valores.gd` | **Todos os números de calibragem** (velocidades, distâncias, tempos). É aqui que se ajusta o jogo |
| `scripts/jogador.gd` | Homem-gato |
| `scripts/sala.gd` | Monta uma sala a partir de um mapa em texto, com a legenda do [level design](../docs/02-level-design-demo.md) |
| `cenas/sala_teste.tscn` | Sala de teste do M1. O mapa fica no campo **Mapa** do nó `SalaTeste` |
| `testes/teste_m1.gd` | Teste automático do M1 |

No mapa em texto, cada caractere vale 96 × 96 px (2 × 2 tiles): `T` vegetação, `#` parede da ruína, `o` obstáculo, `.` chão, `:` trilha, `@` início do jogador.

## Rodar o teste automático

Na pasta `jogo/`:

```bash
C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/teste_m1.gd
```
