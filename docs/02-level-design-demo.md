# Level Design da Demo — Rascunho

**Versão:** 0.3 · **Status:** floresta refeita pela [especificação de gameplay](04-game-design-floresta.md). Ruína e boss aguardam a especificação deles.

Este é um blockout só com posições e funções. Não é arte. Cada elemento está marcado por **função**, e o concept decide o visual.

Os tamanhos consideram a resolução base de 1920 × 1080 px e tiles de 48 px. **Uma tela = 40 × 22,5 tiles.**

---

## Área 1 — Floresta

### Visão geral

A floresta sobe de baixo para cima, como no diagrama do game design, com a ruína no topo e a área superior em cima da própria ruína.

```
        ┌────────────────────────────┐
        │  ÁREA SUPERIOR (terraço)   │  opcional, pela escalada
        ├────────────────────────────┤  fachada da ruína: entrada + trecho escalável
        │                            │
        │     EXTERIOR DA RUÍNA      │  2 grupos de inimigos
        │                            │
        └─────────┬────────┬─────────┘
                  │CLAREIRA│            estátua + 1º combate
                  └───┬────┘
                      │ CORREDOR        sem combate, flor escondida
                  ┌───┴────┐
                  │ SEGURA │            Xennar + fogueira
                  └────────┘
```

### Dimensões propostas

| Parte | Tamanho (px) | Em tiles | Telas | Pedido no game design |
|---|---|---|---|---|
| Área segura | 1920 × 1080 | 40 × 22,5 | 1 | 1 tela |
| Corredor | 1152 × 1800 | 24 × 37,5 | 1 | 1 tela |
| Clareira | 1920 × 1632 | 40 × 34 | 1,5 | 1,5 tela |
| Exterior da ruína | 2880 × 1776 | 60 × 37 | 2,5 | 2 a 2,5 telas |
| Área superior | 2880 × 1056 | 60 × 22 | 1,5 | 1,5 tela |
| **Mapa inteiro** | **2880 × 7344** | 60 × 153 | **7,5** | |

Andando em linha reta a 390 px/s, o gato atravessa o mapa em cerca de 20 s. Com diálogo, exploração e combate, a floresta deve durar de 4 a 6 minutos.

### Legenda

```
T  vegetação densa (parede)        .  chão livre            :  trilha
@  início do jogador               X  Xennar                F  fogueira (só ambiente)
L  flor de lírio azul (oculta)     G  estátua da Guardiã    t  elemento tecnológico
s  sapo comum                      l  sapo com língua       !  gatilho do encontro
o  obstáculo (bloqueia ataque e língua, não bloqueia a percepção)
#  parede da ruína                 =  entrada da ruína      D  trecho escalável (dash)
K  peça de upgrade da KLM-99       v  descida de volta
```

Nos desenhos abaixo, cada caractere vale 96 × 96 px (2 tiles). As proporções verticais estão comprimidas.

### 1. Área segura (1 tela)

```
TTTTTTTT::::TTTTTTTT   <- saída para o corredor
TTT......::......TTT
TT.......::.......TT
TT...F..X.:.......TT   Xennar ao lado da trilha, fogueira perto
TT........:.......TT
TTT.......@.....TTTT   início
TTTTTTTTTTTTTTTTTTTT
```

- Nenhum inimigo aparece aqui, nem na borda da câmera.
- Xennar fica colado na trilha. Ao chegar perto, o gato para e o diálogo começa sozinho.
- Depois do diálogo, a saída para o corredor fica óbvia: é o único caminho.

### 2. Corredor (1 tela)

```
TTTTT::TTTTT   <- abre na clareira
TTTT::TTTTTT
TTT::TTTTTTT
TT::...TTTTT
TTT::.L.TTTT   recanto lateral com a flor
TTTT::TTTTTT
TTTTT::TTTTT
TTTT::TTTTTT   <- vem da área segura
```

- Passagem de 3 a 4 tiles de largura, sem árvore isolada no meio.
- O caminho faz uma curva em S, que esconde a clareira até o fim.
- **Flor de lírio azul** num recanto fora da trilha, sem indicador de E. É a primeira interação oculta, e recompensa quem olha para os lados. *(Posição a confirmar, dúvida 11.)*
- Sem combate. É o lugar para o jogador testar o dash e a troca para o rolamento.

### 3. Clareira (1,5 tela)

```
TTTTTTTT::::TTTTTTTT   <- segue para o exterior da ruína
TTT......::.......TT
TT...s...::....s..TT
TT.......G.........T   estátua da Guardiã
TT.................T
T....o....!....o...T   ! = passar do meio dispara o encontro
TT..l..........s..TT
TTT......::......TTT
TTTTTTTT::::TTTTTTTT   <- vem do corredor
```

- **Primeiro combate:** 3 sapos comuns + 1 com língua. Eles entram pulando da vegetação, espalhados e a pelo menos 360 px do jogador.
- Dois obstáculos baixos dão cobertura contra a língua, e ensinam que obstáculo bloqueia ataque.
- A **estátua da Guardiã** fica no caminho, mais perto da saída. O jogador lê depois do combate, no momento de calma.
- O "fragmento" que o game design cita na clareira ainda depende da dúvida 4.

### 4. Exterior da ruína (2,5 telas)

```
####D#########==#############   fachada: D = escalada, == = entrada da ruína
T...D.........::..........t.T   t = elemento tecnológico, encostado na parede
T.......o.....::....o.......T
T..s.....l....::......l..s..T   grupo 2: 3 comuns + 2 com língua, guardando a entrada
T.............::...s........T
T....o........::........o...T
T.............!.............T   ! = gatilho do grupo 2
T...s....o....::.....s......T   grupo 1: 3 comuns + 1 com língua
T.......l.....::...s........T
TTTTTTTTTTTT::::TTTTTTTTTTTTT   <- vem da clareira
```

- Área larga, com espaço para se mover e usar o dash atravessando os sapos.
- **Grupo 1** aparece na entrada. **Grupo 2** só aparece quando o jogador passa da metade, para os dois grupos não se somarem.
- Obstáculos espalhados quebram a linha da língua e obrigam os sapos a contornar.
- **Trecho escalável** no canto esquerdo da fachada, com o indicador **D**. Fica longe da entrada para ser uma escolha de exploração.
- **Elemento tecnológico** no canto direito, encostado na ruína, com as duas falas do gato.
- A **entrada da ruína** fica no centro, no fim da trilha. É a saída do cenário.

### 5. Área superior (1,5 tela, opcional)

```
TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TT.K....o.......s........o.TT   K = peça de upgrade, no fundo
TT....o......l........s....TT   2 comuns + 1 com língua
TT........................vTT   v = descida de volta
####D#########==#############   (mesma fachada do exterior)
```

- O jogador chega pelo trecho **D** e precisa atravessar a área para pegar a peça.
- O espaço é mais estreito que o exterior, então o rolamento grátis vale mais aqui.
- A **peça de upgrade da KLM-99** fica na ponta oposta à chegada.
- A **descida** fica perto da entrada da ruína, como atalho de volta. *(Como desce ainda depende da dúvida 10.)*

### Regras que saem da especificação

- Passagens principais com pelo menos 3 tiles de largura e sem árvore isolada.
- Inimigos não colidem entre si, então grupos podem se sobrepor. Espalhar bem as posições iniciais.
- Obstáculos bloqueiam ataques e a língua, mas não a percepção.
- Sprites de inimigos mortos ficam no chão, menos em cima de áreas de interesse (estátua, flor, elemento, entrada).
- Sem checkpoint: morrer recomeça a fase. Por isso a floresta é curta.

---

## Área 2 — Ruína (rascunho anterior, aguardando a especificação)

> Este trecho é o rascunho feito antes da especificação. Vale como ideia de estrutura e será refeito quando o game design da ruína chegar.

```
##########################
#====#..................##
#....#..C....m....C.....##   SALÃO PRINCIPAL (arena do semi-boss)
#.W..=.....o.....o......##   C = colunas, cobertura para o ataque à distância
#....#..m.....S.....m...=#-> sala do boss
#.!..#..C....o....C.....##
#==@=#..................##
##########################
 ANTESSALA
```

- **Antessala:** sem inimigos. A arma **KLM-99** (`W`) em destaque. Ao pegar, um alvo para testar o tiro.
- **Salão principal:** semi-boss (`S`) no centro e minions (`m`) nas laterais. As colunas bloqueiam tiro e passagem.
- **Saída** para a sala do boss, que só abre depois do semi-boss.

---

## Área 3 — Sala do boss (rascunho anterior, aguardando a especificação)

```
####################
#..................#
#...C..........C...#
#........B.........#   arena quase circular
#..................#
#...C..........C...#
#..................#
########=#=#########
```

- Arena limpa com 4 colunas.
- O boss é o líder das criaturas e está com o cajado de Xennar.
- Depois do boss, um atalho de volta para a floresta encurta o retorno até Xennar. *(A decidir.)*

---

## Ritmo esperado

| Trecho | Clima | Duração aprox. |
|---|---|---|
| Área segura + Xennar | Leve | 1 min |
| Corredor | Leve / exploração | 30 s |
| Clareira | Tensão, depois calma na estátua | 1 a 2 min |
| Exterior da ruína | Tensão | 2 a 3 min |
| Área superior (opcional) | Exploração + tensão | 1 min |
| Ruína: arma + semi-boss | Descoberta, depois tensão | 3 a 4 min |
| Boss | Tensão máxima | 3 a 5 min |
| Volta a Xennar | Alívio | 1 min |

---

## Próximos passos

- [ ] Respostas das dúvidas 4, 10 e 11 da especificação (fragmento, descida e flor)
- [ ] Montar o blockout da floresta no Godot com formas simples
- [ ] Ajustar os tamanhos depois de testar a velocidade e o dash no protótipo
- [ ] Receber o concept da região e trocar funções por elementos reais
- [ ] Refazer ruína e boss quando a especificação chegar
