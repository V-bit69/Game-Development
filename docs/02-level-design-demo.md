# Level Design da Demo — Rascunho

**Versão:** 0.1 · **Status:** rascunho antes do concept da região

Este é um primeiro blockout só com posições e funções. Não é arte. Cada elemento está marcado por **função** (cobertura, obstáculo, gargalo), e o concept decide **o que** ele é visualmente: coluna, estátua, árvore, pilha de areia etc.

Os tamanhos consideram resolução base de 640×360 e tiles de 16 px. **Uma tela ≈ 40×22 tiles.**

---

## Legenda

```
@  início do jogador          N  NPC               F  fogueira / checkpoint
#  parede / borda intransponível                    T  árvore grande (bloqueia)
o  obstáculo baixo (pedra, tronco, caixa; cobertura) C  coluna (bloqueia tiro e passagem)
~  água / buraco (bloqueia passagem, não bloqueia tiro)
e  inimigo comum   r  inimigo à distância   m  minion   S  semi-boss   B  boss
W  arma            I  item de missão        !  gatilho de evento (onda, porta)
=  portão / porta   .  chão livre            :  trilha / caminho marcado
$  item opcional (cura ou colecionável)
```

---

## Área 1 — Floresta (≈ 3×2 telas · 120×44 tiles)

Fluxo da esquerda para a direita e de baixo para cima. Cada caractere abaixo ≈ 4×4 tiles.

```
################################
#TT..T....TT.......T..TT...==###   <- entrada da ruína (norte-leste)
#T....o......T.......o.....:.TT#
#..T.....TT......e...o..e..:...#
#.....T.......o.....r.......:..#   ARENA 1 (clareira aberta)
#TT.......~~~......o....e..:..T#   onda 1: 3 e · onda 2: 2 e + 1 r
#..$...T..~~~..T..........:....#
#T.....T...~~.....!.....T......#   ! = entrar na clareira dispara a onda
#...TT......::::::::::::::T..TT#
#.....::::::::T..T....T........#   TRILHA (respiro, exploração)
#.F.N::..T......TT...o..T..$...#
#.@....T.....T.........TT....TT#   CLAREIRA SEGURA
################################
```

### Zonas

1. **Clareira segura** (canto inferior esquerdo, ~1 tela)
   - Spawn `@`, NPC `N`, fogueira `F`.
   - Nenhum inimigo visível daqui. A câmera não deve mostrar a arena.
   - Diálogo inicial com o NPC.

2. **Trilha** (~1 tela)
   - Caminho `:` claro, mas com espaço para desviar.
   - Um item opcional `$` fora do caminho recompensa quem explora.
   - Serve de respiro e ensina o movimento sem pressão.
   - Um pequeno lago `~` cria uma curva no caminho e esconde a arena até o último momento.

3. **Arena 1** (clareira aberta, ~1,5 tela)
   - Entrar dispara `!` a **onda 1**: 3 inimigos corpo a corpo `e`. Ensina ataque, dash e parry.
   - **Onda 2:** 2 `e` + 1 à distância `r`. Obriga a se mover e usar a cobertura `o`.
   - Obstáculos baixos `o` espalhados: dá para contornar, e o inimigo à distância não atira através deles.
   - Ao limpar a arena, o caminho para a ruína fica disponível (portão `=` ou apenas liberado).

4. **Entrada da ruína** (canto superior direito)
   - Uma construção grande e visível desde a arena, para puxar o jogador para lá.

---

## Área 2 — Ruína (≈ 2×1,5 telas · 80×32 tiles)

```
##########################
#====#..................##
#....#..C....m....C.....##   SALÃO PRINCIPAL (arena do semi-boss)
#.W..=.....o.....o......##   colunas C = cobertura para o novo ataque à distância
#....#..m.....S.....m...=#-> sala do boss
#.!..#..C....o....C.....##
#==@=#..................##
##########################
 ANTESALA
```

### Zonas

1. **Antessala** (pequena, sem inimigos)
   - O jogador entra por baixo. A arma `W` está em destaque, sob um feixe de luz ou junto a um corpo.
   - Ao pegar a arma: pausa curta, texto explicando o novo controle e um alvo ou objeto destrutível para testar o tiro.
   - Quando o jogador passa pela porta `=`, ela se fecha atrás dele `!`.

2. **Salão principal** (arena do semi-boss)
   - Semi-boss `S` no centro e minions `m` nas laterais.
   - **Colunas `C`** bloqueiam tiro e passagem, o que dá jogo de posicionamento para o ataque novo.
   - Obstáculos baixos `o` bloqueiam passagem, mas não bloqueiam tiro.
   - O espaço é grande o bastante para dash e desvio.

3. **Saída** para a sala do boss, à direita. Ela só se abre depois do semi-boss.

---

## Área 3 — Sala do boss (≈ 1,5×1,5 telas)

```
####################
#..................#
#...C..........C...#
#........B.........#   arena quase circular
#..................#   poucas colunas: o boss é o foco
#...C..........C...#
#.........F........#   fogueira antes da porta (checkpoint pré-boss)
########=#=#########
```

- Arena limpa, com **4 colunas** que o boss pode destruir numa segunda fase *(ideia a validar)*.
- **Checkpoint antes do boss:** se o jogador morrer, volta direto para a porta, sem refazer a ruína.
- Quando o boss morre, dropa o item `I`, e **uma passagem se abre de volta para a floresta** (atalho), para que a volta até o NPC seja curta.

---

## Ritmo esperado

| Trecho | Clima | Duração aprox. |
|---|---|---|
| Clareira segura + NPC | Leve | 1 min |
| Trilha | Leve / exploração | 1 a 2 min |
| Arena 1 (2 ondas) | Tensão | 2 a 3 min |
| Antessala + arma | Pausa / descoberta | 1 min |
| Semi-boss + minions | Tensão | 2 a 3 min |
| Boss | Tensão máxima | 3 a 5 min |
| Volta ao NPC | Alívio | 1 min |

---

## Próximos passos

- [ ] Receber o concept da região (floresta e ruína) e trocar funções por elementos reais
- [ ] Ajustar os tamanhos depois de testar a velocidade do personagem no protótipo
- [ ] Montar o blockout no Godot com formas simples (etapa 4)
- [ ] Posicionar os inimigos quando a especificação deles chegar
