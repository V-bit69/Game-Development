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
| D | Dash (ofensivo ou rolamento) | M2 ✅ |
| S | Trocar o tipo de dash | M2 ✅ |
| A | Atacar (combo de 3 golpes) | M3 ✅ |
| Q | Parry | M4 ✅ |
| E | Interagir, avançar diálogo, recomeçar depois de morrer | M7 ✅ |
| F11 | Alternar tela cheia e janela | — |
| D perto do trecho escalável | Escalar a parede da ruína (com o dash ofensivo) | M8 ✅ |
| Esc | Pausa (Continuar, Recomeçar a fase, Sair) | M9 ✅ |
| R | Recomeçar a fase (atalho de desenvolvimento) | — |

## Combate (game design v1.4.1)

- **Golpe** (A): 0,308 s, em duas fases: **antecipação** de 0,077 s (sem dano; o dash ou o Q cancelam e o golpe não conta) e **execução** de 0,231 s (não cancela; dash e Q apertados aqui são ignorados e não ficam guardados). A hitbox só fica ativa no **impacto**, 0,1 s no começo da execução, e cada inimigo leva no máximo 1 vez por golpe.
- **Recuperação** depois do golpe: 0,154 s (golpe 1), 0,308 s (golpe 2) e 0,4 s (golpe 3). Ciclo de ≈ 1,78 s, que nunca reseta. Na recuperação o dash funciona, mas não a encurta.
- **Área**: leque que sai do gato. Golpes 1 e 2: 120° e 30 px. Golpe 3: 90° e 40 px. Vale o retângulo do inimigo.
- **Passo e knockback**: 24 px cada. O passo é dado durante o impacto (240 px/s) e para ao encostar no inimigo ou em obstáculo.
- **Magnetismo de mira**: o golpe procura o inimigo vivo mais próximo num cone de ±45° em volta do olhar, até o alcance efetivo + 10 px (64 px nos golpes 1 e 2, 74 px no golpe 3), e aponta para ele com ângulo contínuo. O alvo anterior tem preferência. Não vale para dash nem rolamento.
- **Dash e rolamento**: o dash ofensivo atravessa inimigos e fere (1 de dano). O rolamento para no contato com parede, obstáculo ou inimigo. Sem stamina, o 3º rolamento é bloqueado e não conta na janela. O dash também cancela a janela do parry (a recuperação de 0,4 s continua contando).
- **Dano no gato**: 1 s de invulnerabilidade, piscando. Nela ele pode atacar e dar dash.
- **Sapos**: os dois têm 4 de vida. O sapo comum fere com o salto; o sapo com língua não (`salto_fere()`): todo o dano dele vem da língua.

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

No mapa em texto, cada caractere vale 32 × 32 px (2 × 2 tiles). A legenda é a do [level design](../docs/02-level-design-demo.md): `T` vegetação, `#` parede da ruína, `o` obstáculo, `.` chão, `:` trilha, `@` início do jogador, `X` Xennar, `F` fogueira, `L` flor, `G` estátua, `t` elemento tecnológico, `K` peça da KLM-99, `s` sapo comum, `l` sapo com língua, `!` gatilho de encontro, `=` entrada da ruína, `D` trecho escalável, `v` descida, `~` água, `x` alvo de treino e `a` alvo de treino que ataca.

## Atualizar a versão do navegador

A versão que roda no navegador fica na pasta `jogar/` do repositório. Para gerar de novo depois de mudar o jogo, na pasta `jogo/`:

```bash
C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Web" ../jogar/index.html
```

Depois é só salvar no GitHub, e o link atualiza em cerca de 1 minuto. No navegador, o jogo abre em janela e com ampliação livre (não só 2× ou 3×), para caber em qualquer tela.

## Rodar o teste automático

Na pasta `jogo/`:

```bash
C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/teste_m1.gd
```

Troque `teste_m1` pelo marco que quiser testar.
