# Game Design — Demo · Cenário 1: Floresta

> **Documento vivo.** Versão editável da especificação de gameplay da floresta. O PDF original está em [referencias/game-design-demo-v1.0.pdf](referencias/game-design-demo-v1.0.pdf).
> As seções 1 a 48 são do game design. A seção 49 traz os valores propostos pelo desenvolvimento para o que estava "a definir", e a seção 50 lista as dúvidas em aberto. Registre mudanças no [Histórico](#histórico-de-versões).

| | |
|---|---|
| **Versão** | 1.3 |
| **Status** | Especificação de gameplay em desenvolvimento |
| **Engine** | Godot 4 |
| **Resolução base** | 640 × 360 px, ampliada 3× na tela Full HD |

---

## Como ler os multiplicadores

- **Comprimento:** o multiplicador aumenta a distância. Um dash de 1,3× percorre 130% da distância do dash padrão.
- **Velocidade:** o multiplicador aumenta a velocidade e, portanto, diminui o tempo. Um dash de 2× executa duas vezes mais rápido.
- **Os dois juntos não se somam de forma óbvia.** Um dash com 2× de velocidade e 1,3× de comprimento não dura metade do tempo do dash padrão, porque a distância também mudou. A duração é sempre consequência: `duração = comprimento ÷ velocidade`.
- Ao alterar um valor, confira qual unidade está sendo alterada.

---

## 1. Objetivo do cenário

A floresta é o primeiro cenário jogável da demo.

Sua função é apresentar ao jogador:

- movimentação do Homem-gato;
- dash;
- gerenciamento de stamina;
- exploração simples;
- interação com elementos do cenário;
- combate melee;
- parry;
- primeiros inimigos;
- primeira recompensa opcional;
- escalada através de dash;
- preparação para a entrada na ruína.

O cenário começa em uma área segura e termina com a entrada da ruína.

Não há checkpoint na floresta.

---

## 2. Personagem jogável

### 2.1 Homem-gato

O personagem jogável da demo é o Homem-gato.

**Características**

- Raça: homem-gato.
- Altura relativa: **2**, considerando a escala de personagens:
  - 1 = baixo;
  - 2 = médio;
  - 3 = padrão;
  - 4 = alto.
- Possui movimentação naturalmente mais ágil que outros personagens.
- Possui gameplay híbrida entre combate melee e tecnologia à distância.
- Na floresta, entretanto, a arma tecnológica ainda não foi encontrada.

**Personalidade**

O Homem-gato:

- é ágil e agitado;
- é bondoso e gentil;
- fala rapidamente;
- mia ao final de algumas frases;
- luta de maneira feroz e agressiva.

---

## 3. Controles

| Ação | Comando |
|---|---|
| Movimento | Setas direcionais |
| Dash | D |
| Alternar tipo de dash | S |
| Interagir | E |
| Ataque | A |
| Parry | Q |

---

## 4. Movimentação

### 4.1 Movimento básico

O Homem-gato pode se movimentar em **8 direções**.

A velocidade diagonal é igual à velocidade das direções cardeais.

**Velocidade**

A velocidade de caminhada do Homem-gato é **1,3 × velocidade normal do jogo**.

O valor absoluto em px/s pertence aos parâmetros gerais do jogo e deverá ser definido no desenvolvimento.

**Colisão**

Existe colisão padrão com:

- paredes;
- objetos;
- obstáculos.

---

## 5. Dash Ofensivo

O Homem-gato possui uma variação do dash padrão, chamado Dash Ofensivo. Isso é uma característica conferido como um traço racial, assim como sua agilidade natural de movimentação.

**Parâmetros**

- Comprimento: **1,3 × dash padrão do jogo**.
- Velocidade: **2 × velocidade padrão do dash**.
- Não possui cooldown.
- É controlado exclusivamente pela stamina e consome 2 unidades.
- Não possui invulnerabilidade.

O multiplicador de comprimento representa aumento da distância percorrida.

O multiplicador de velocidade representa aumento da velocidade de deslocamento.

A duração do dash será consequência desses dois valores e não constitui parâmetro independente.

**Direção**

O dash ocorre na direção escolhida pelo jogador. Caso não haja uma direção, o dash é efetuado na direção que o personagem olha.

**Colisão**

Qualquer dash que atingir uma parede ou obstáculo é interrompido no contato.

---

## 6. Dash Ofensivo contra inimigos

O Homem-gato pode atravessar e dar dano a inimigos utilizando o dash ofensivo.

Ao atravessar um inimigo:

- o inimigo recebe dano;
- o dano equivale a 1 unidade;
- o ataque visual é realizado com as duas garras.

Alguns inimigos possuem dano de contato.

Nesse caso, o inimigo causa dano ao Homem-gato mesmo durante a passagem pelo dash.

O dash não concede invulnerabilidade.

---

## 7. Escalada

Algumas paredes da ruína possuem trechos especialmente preparados para escalada.

Quando o jogador utiliza o dash ofensivo próximo e na direção de uma dessas paredes, **o Homem-gato realiza a escalada**.

A escalada utiliza a mesma duração resultante do dash.

A altura alcançada corresponde ao trecho preparado da estrutura, permitindo chegar à parte superior como em um jogo de plataforma.

A ação é sinalizada ao jogador por uma indicação de interação: **D**

---

## 8. Stamina

A stamina é utilizada pelos dashes.

O sistema é baseado em **unidades de uso**.

**Homem-gato**

- Capacidade: **4 unidades**.
- Recuperação padrão: **1 unidade a cada 3 s**.
- Recuperação do Homem-gato: **1,5 × a recuperação padrão**.

Somente os dashes consomem stamina.

Ataques melee e parry **não consomem stamina**.

**HUD**

A stamina aparece no canto superior esquerdo.

Cada unidade é representada visualmente como um elemento individual na cor **laranja**.

---

## 9. Dash de rolamento

O Homem-gato possui um segundo tipo de dash.

O jogador alterna entre os tipos utilizando **S**.

O comando de execução continua sendo **D**.

**Características**

- Movimento em forma de rolamento.
- O personagem se transforma visualmente em uma espécie de bola durante o movimento.
- Comprimento: **0,8 × dash padrão**.
- Velocidade: **velocidade padrão do dash**.
- Não causa dano.
- Não pode atravessar paredes ou obstáculos para fins de escalada.
- Não realiza escalada.
- Esse rolamento é capaz de desviar de ataques que possuem a tag de "projétil".
- Ao desviar de um ataque projétil, esse ataque se torna incapaz de conferir dano mesmo que o rolamento acabe e a hitbox do ataque ainda esteja por cima da hitbox do gato.

**Regra especial de consumo de stamina no rolamento**

O rolamento utiliza um sistema de contagem própria.

O jogador pode utilizar o rolamento **duas vezes consecutivamente sem gastar stamina**.

O terceiro uso dentro da janela estabelecida consome uma unidade.

A cada vez que há o consumo de stamina, a contagem é resetada até que o rolamento seja usado novamente.

A janela é de **5 segundos**.

A contagem funciona continuamente e de forma deslizante:

- usa rolamento → primeiro uso;
- usa novamente dentro de 5 s → segundo uso;
- usa novamente dentro de 5 s do primeiro → terceiro uso → consome stamina;
- reseta a contagem.

Se o primeiro uso deixar de estar dentro da janela, o segundo passa a ser considerado o primeiro.

Em outras palavras, sempre que ocorrerem **3 rolamentos dentro de uma janela de 5 s**, uma unidade de stamina é consumida.

Não deve haver consumo no rolamento seguinte a um consumo, é importante que haja o reset.

---

## 10. Troca de dash

O jogador utiliza **S** para alternar entre:

- dash padrão;
- dash de rolamento.

A HUD apresenta qual tipo está atualmente equipado.

---

## 11. Interação com o ambiente

A interação ocorre através do comando **E**.

Quando o jogador se aproxima de um elemento importante e interagível, **aparece uma pequena indicação contendo a letra E**.

O jogador pressiona E para executar a interação.

**Distância de interação**

A distância mínima de ativação corresponde a **½ da altura de um personagem de tamanho 3**.

> **Correção do game design (30/09):** o PDF usava 16 px como altura de referência, o que dava 8 px de distância. Esse valor estava errado: 16 px é o tamanho de um tile. Um personagem de tamanho 3 é bem maior. A regra que vale é "½ da altura do tamanho 3". Com o tamanho 3 em 50 px, a distância é de 25 px.

---

## 12. Interações ocultas

Nem todos os elementos interagíveis são sinalizados antecipadamente.

Alguns elementos possuem interação deliberadamente misteriosa.

O jogador precisa:

1. perceber que determinado elemento pode ser interessante;
2. aproximar-se;
3. tentar utilizar E.

---

## 13. Flor de lírio azul

Existe uma flor de lírio azul interagível na floresta.

Ao interagir, o Homem-gato coleta a flor.

Em seguida, ocorre uma pequena fala:

> **GATO:** Uma flor de lírio azul, miau!
> **GATO:** Minha irmã sempre diz que essa flor nasce onde a água é limpa. Acho que ela vai gostar!

A flor funciona também como elemento de exploração opcional.

**Continuidade futura**

Na história da demo, o Homem-gato poderá levar a flor para sua terra natal e entregá-la à irmã.

Isso poderá posteriormente resultar em um upgrade de habilidade.

Essa consequência não precisa ser implementada nesta demo.

---

## 14. Elemento tecnológico na floresta

Existe um elemento tecnológico próximo à ruína.

O objeto parece fazer parte da própria estrutura da ruína.

Ao encontrá-lo, o Homem-gato comenta:

> **GATO:** Interessante... parece fazer parte da ruína...
> **GATO:** Como isso veio parar aqui?

A intenção é estabelecer sua familiaridade com tecnologia e criar curiosidade sobre a ruína.

---

## 15. Fragmento / peça de upgrade

Em uma área elevada da floresta existe uma peça tecnológica que pode melhorar a arma que o Homem-gato encontrará posteriormente.

Ao coletá-la:

> **GATO:** Isso é especial! Com uma dessas eu posso melhorar uma KLM-99.

A fala continua fazendo sentido caso o jogador já tenha encontrado a peça anteriormente e posteriormente retorne à área.

---

## 16. Escalada e área superior

Um trecho da parede da ruína permite que o Homem-gato utilize seu dash padrão para subir.

Ao alcançar a parte superior:

- existem inimigos adicionais;
- existe acesso a uma área elevada;
- o jogador encontra a peça de upgrade da KLM-99.

Essa área funciona como uma pequena recompensa para quem explora verticalmente o cenário.

---

## 17. Estátua da Guardiã

Na clareira existe uma estátua representando uma figura feminina associada à floresta.

Ela é conhecida como **A Guardiã**.

Ao interagir, está escrito:

> **Uma antiga estátua. Há algo escrito na base:**
> **"Aos olhos da Guardiã, nenhuma criatura da floresta está sozinha."**

Depois de ler, o Homem-gato comenta:

> **GATO:** A Guardiã... quem será que ela foi?

---

## 18. Combate melee

O comando **A** executa o ataque básico.

O gato possui três golpes.

**Golpe 1:** ataque rápido utilizando uma das garras.

**Golpe 2:** ataque rápido utilizando a outra garra.

Os dois primeiros golpes são ligeiramente mais rápidos.

**Golpe 3:** o Homem-gato retira uma espada média da capa e executa um corte vertical. Depois, guarda a espada.

Esses ataques rodam de forma cíclica e não resetam. Não há cancelamento de combo.

**1 → 2 → 3 → 1 → 2 → 3...**

---

## 19. Tempo dos ataques

A velocidade de cada golpe é **1,3 × velocidade padrão do golpe**.

Ou seja, o gato ataca mais rápido que o normal. Isso também é uma característica racial devido a sua agilidade natural.

**Intervalos**

- Entre os golpes 1 e 2: **½ da duração do próprio golpe**.
- Entre os golpes 2 e 3: **1 duração completa do golpe**.

---

## 20. Dano

O sistema de dano é baseado em unidades.

| Golpe | Dano |
|---|---|
| Golpe 1 | 1 |
| Golpe 2 | 1 |
| Golpe 3 | 2 |

O dash ofensivo também causa **1 unidade de dano**.

Após sofrer dano, o gato entra em um estado de recuperação de 1,5 segundos. Durante esse tempo ele permanece invulnerável.

---

## 21. Knockback dos ataques

Os ataques básicos produzem knockback padrão.

A função principal desse knockback é:

- impedir que inimigos avancem continuamente sobre o jogador;
- criar espaço durante o combate melee;
- compensar a aproximação dos inimigos.

O knockback ocorre enquanto o inimigo está em sua movimentação normal.

Se o inimigo estiver executando uma animação de avanço/dash, essa regra não se aplica.

Os ataques do gato também possuem uma avanço natural (attack lunge) que compensam o knockback e ajudam no game feel. 

---

## 22. Parry

O comando **Q** executa o parry.

Não existe postura de defesa contínua.

O jogador precisa executar o comando no momento correto.

**Janela:** 0,2 s.

Se o jogador errar o timing, **ele recebe o ataque**.

Se acertar:

- o ataque é defendido com a espada do gato e o inimigo sofre stun por 0,5 segundos até a segunda ação do parry;
- na segunda ação, o homem-gato executa um chute no inimigo após esses 0,5 segundos;
- o inimigo é lançado para trás.

**Knockback:** o knockback do parry corresponde à **distância de um dash padrão**.

**Stun:** depois que o inimigo chega ao final do knockback, **permanece atordoado por mais 1,5 s**.

Assim, o tempo total de stun é de 2 segundos. O chute do parry pode ter sua animação e execução cancelada com um dash, mas não com a movimentação base do gato. Nesse caso o stun é de apenas 0,5 segundos.

---

## 23. Parry da língua

A língua do sapo também pode ser defendida com parry.

Quando o Homem-gato executa um parry contra a língua:

- a língua é interrompida;
- o Homem-gato chuta a língua de volta na direção do sapo (aqui o chute é imediato ao bloqueio);
- o sapo é atingido;
- o sapo fica atordoado onde está por 2 segundos.

---

## 24. Regras de hitbox

A hitbox do Homem-gato é menor que sua área de ataque.

A área de ataque do personagem possui **2 × o raio da hitbox do personagem**.

As hitboxes dos inimigos são retangulares.

---

## 25. Área e ângulo de ataque

Os ataques do gato possuem um ângulo de acerto em sua frente. Esse ângulo é de **120° para os ataques 1 e 2 e de 60° para o ataque 3**, já que esse último é pensado como um ataque vertical. Porém, o ataque 3 possui maior alcance em distância, chegando a **2,5 x o raio da hitbox do personagem**.

Se um sapo estiver realizando um pulo e for atingido por um ataque do Homem-gato antes de alcançar a hitbox do jogador:

- o sapo recebe o knockback correspondente;
- o sapo ainda pode causar dano normalmente se atingir o jogador antes ou ao mesmo tempo que for atingido.

Isso vale tanto para o sapo comum quanto para o sapo com língua.

Existe uma exceção importante para a língua.

Se o Homem-gato atingir **somente a língua**, mas não o corpo do sapo:

- o corpo não sofre knockback;
- o pulo continua normalmente, caso esteja pulando;
- a língua ainda pode causar seu dano caso atinja o jogador.

---

## 26. Inimigos da floresta

Os inimigos da floresta pertencem principalmente à raça dos sapos.

Existem dois tipos comuns:

1. Sapo comum;
2. Sapo com língua.

A quantidade de cada tipo fica a critério do desenvolvimento.

A única regra de composição é: **sapos comuns > sapos com língua**.

Nenhum dos sapos tem dano de contato.

---

## 27. Regras gerais dos inimigos

### Colisão

Os inimigos:

- não colidem entre si;
- podem atravessar uns aos outros.

### Percepção

O aggro ocorre quando o jogador entra na zona de percepção do inimigo.

O tamanho dessa zona será definido posteriormente.

Árvores e obstáculos:

- não bloqueiam a percepção;
- bloqueiam ataques físicos;
- bloqueiam projéteis.

Os inimigos devem ser capazes de reconhecer que um obstáculo está bloqueando seu ataque e procurar uma forma de contorná-lo quando apropriado.

### Perseguição

Um inimigo pode seguir o jogador por todo o espaço acessível do mapa que estiver atrás de sua posição, permanecendo sempre dentro do mesmo cenário.

---

## 28. Telegraph

Os inimigos possuem um período de preparação antes de executar determinadas ações.

No protótipo, o telegraph pode ser representado por:

- squash do sprite;
- pequena vibração;
- outra alteração visual equivalente.

A implementação visual exata fica a critério do desenvolvedor.

---

## 29. Sapo comum

O sapo comum utiliza seu próprio salto como ataque.

**Ciclo**

decisão → telegraph → salto → possível contato → aterrissagem → espera → nova decisão

**Parâmetros**

- HP: **4**
- Comprimento do salto: **0,5 dash padrão**
- Velocidade: **velocidade padrão do dash**
- Telegraph: **0,5 s**
- Intervalo entre ciclos: **1 s**
- Dano: **1**

Se atingir a hitbox do Homem-gato durante o salto, **causa 1 dano**.

Se não atingir, **continua tentando nos ciclos seguintes**.

---

## 30. Sapo com língua

O sapo com língua mantém a mesma movimentação básica do sapo comum.

**Parâmetros**

- HP: **3**
- Pulo: **0,5 dash**
- Velocidade: **velocidade padrão do dash**
- Intervalo entre ciclos: **1 s**
- Dano da língua: **1**
- Alcance da língua: **0,5 dash**
- Velocidade da língua: **velocidade padrão do dash**
- Telegraph antes da ação: **0,5 s**

A língua pode ser utilizada:

- parado;
- durante um salto.

A decisão da ação ocorre no início do ciclo.

O sapo não altera sua ação no meio de um salto.

O ataque com língua desse sapo possui a tag de projétil e, portanto, pode ser desviada com o rolamento.

---

## 31. Zonas do sapo com língua

O comportamento é dividido em três zonas.

| Zona | Comportamento |
|---|---|
| **Próxima** | permanece parado → telegraph → usa a língua |
| **Intermediária** | telegraph → pula + usa a língua |
| **Externa** | telegraph → realiza um salto de perseguição |
| **Fora da área de atuação** | permanece aguardando |

A prioridade é: **zona próxima > zona intermediária > zona externa**.

Os tamanhos exatos dessas zonas ainda serão definidos.

---

## 32. Língua

A língua possui uma trajetória simples.

Quando erra, **retorna até o sapo normalmente da forma como saiu**.

Quando o jogador atinge a língua com parry, **ela é interrompida e rebatida em direção ao sapo**.

---

## 33. Morte dos inimigos

O HP dos inimigos é representado em unidades.

Abaixo do sprite existe uma indicação formada por pequenos quadrados.

Cada quadrado representa uma unidade de HP.

Quando o HP chega a **0, o inimigo morre**.

Após a morte:

- executa sua animação de morte;
- seu sprite permanece no chão.

Exceção: se o inimigo morrer sobre uma área de interesse do cenário, **o sprite desaparece**.

Ainda não foi definido se os inimigos deixam itens ou recompensas.

---

## 34. Composição dos encontros

A quantidade de inimigos é definida pelo desenvolvedor durante o blockout e implementação.

O design estabelece apenas a proporção: **maior quantidade de sapos comuns do que sapos com língua**.

Os inimigos entram em cena:

- pulando;
- aproximadamente ao mesmo tempo;
- espalhados pela área;
- a uma distância segura do jogador.

As posições exatas são definidas no blockout.

---

## 35. Estrutura do mapa

A floresta é propositalmente pequena.

A resolução base é **640 × 360 px**. A arte é desenhada nessa resolução e ampliada 3× num monitor 1920 × 1080.

As áreas são pensadas em relação ao tamanho da tela.

### 35.1 Área segura — 1 tela

Função:

- apresentação do cenário;
- encontro com Xennar;
- diálogo;
- fogueira;
- ausência de combate.

### 35.2 Corredor da floresta — 1 tela

Características:

- vegetação mais densa;
- passagem relativamente definida;
- árvores nas laterais;
- nenhuma árvore isolada bloqueando as passagens principais.

### 35.3 Clareira — 1,5 tela

Características:

- espaço mais aberto;
- estátua da Guardiã;
- fragmento/peça tecnológica;
- primeiros encontros de combate;
- vegetação continua densa ao redor, mas se abre na região percorrida.

### 35.4 Exterior da ruína — 2 a 2,5 telas

Área mais aberta.

Serve para:

- permitir movimentação ampla;
- combate contra grupos;
- exploração;
- acesso à escalada;
- preparação para entrar na ruína.

### 35.5 Área superior/lateral — 1,5 tela

Área acessada através da escalada.

Contém:

- inimigos;
- trecho superior da ruína;
- peça especial para upgrade da KLM-99.

---

## 36. Distribuição espacial

A progressão visual é aproximadamente:

```
┌──────────────────────────────┐
│        ÁREA SUPERIOR         │
│     inimigos + upgrade       │
└──────────────┬───────────────┘
               │
     FLORESTA  │  RUÍNA
               │
        ┌──────┴──────┐
        │             │
        │  EXTERIOR   │
        │             │
        └──────┬──────┘
               │
           CLAREIRA
       estátua + fragmento
               │
           CORREDOR
               │
          ÁREA SEGURA
        Xennar + fogueira
```

A ruína está posicionada à direita, mas provavelmente a melhor opção seria posicioná-la em cima, deixando a área superior acima da própria ruína. O espaço à direita poderia então ser preenchido com outros elementos da floresta, por exemplo. A representação serve apenas como referência estrutural; o layout final será definido durante o blockout.

---

## 37. Xennar

Xennar é o NPC encontrado no início da floresta.

Ele é:

- humano;
- velho;
- responsável pelo farol da região;
- cansado;
- fisicamente debilitado.

Possui uma fogueira próxima.

---

## 38. Diálogo inicial

Ao aproximar-se de Xennar, o personagem para e a caixa de diálogo aparece.

Cada frase exige um comando do jogador para avançar.

É importante que o nome do velho só seja identificado na caixa de diálogo após ser revelado.

**Diálogo**

> **VELHO:** Ei... espere um momento...
>
> **VELHO:** Você parece jovem e ágil... o suficiente. Poderia me ajudar?
>
> **GATO:** Ajudo sim! Quer dizer, depende do que o senhor precisa. O que seria, miau?
>
> **VELHO:** Meu nome é Xennar. Sou o responsável pelo farol da região... que fica no alto da Costa das Pedras.
>
> **XENNAR:** Há alguns dias... meu cajado foi tomado pelos malditos invasores. Sem ele, não consigo mais acender sua luz guia.
>
> **GATO:** Tomado? Por quem?
>
> **XENNAR:** Por essas criaturas saltitantes... Estão espalhadas por toda a região e saqueando tudo aquilo que há de valor.
>
> **XENNAR:** Agora o líder deles se instalou na ruína do monte adiante... e levou meu cajado para lá.
>
> **XENNAR:** Por favor, temos poucos por aqui capazes de enfrentá-los...
>
> **XENNAR:** Poderia recuperá-lo para mim?

---

## 39. Segunda interação com Xennar

As duas falas abaixo **não fazem parte do diálogo inicial**.

Elas são exibidas somente caso o jogador volte a interagir com Xennar depois que o primeiro diálogo foi concluído.

> **XENNAR:** Jovem felino... conseguiu encontrá-lo? Se aceita uma dica... talvez consiga roubá-lo de volta sem chamar muita atenção.
>
> **XENNAR:** Minhas costas doem só de pensar...

---

## 40. Objetivo da floresta

O objetivo apresentado ao jogador é **recuperar o cajado de Xennar**.

O cajado foi tomado pelos invasores e levado para a ruína.

O líder das criaturas está instalado na ruína.

A recuperação do cajado é o objetivo que conduz o jogador ao próximo cenário.

---

## 41. Fogueira

Existe uma fogueira próxima de Xennar.

Ela possui função visual e ambiental.

**Não é checkpoint.**

Se o jogador morrer, não retorna para a fogueira.

---

## 42. Morte do jogador

O Homem-gato possui **10 HP**.

O HP é contabilizado em unidades.

Quando chega a zero:

1. o estado de morte é acionado;
2. a tela recebe um filtro visual;
3. aparece uma indicação de que o personagem morreu;
4. o jogador pressiona **E**;
5. a demo reinicia desde o início da fase.

Não há sistema de respawn intermediário.

---

## 43. HUD

Durante a floresta, a HUD deve apresentar pelo menos:

**HP**

- HP atual do Homem-gato;
- **10 unidades máximas**.

**Stamina**

- 4 unidades;
- representadas no canto superior esquerdo;
- cor laranja.

**Dash equipado**

Indicação visual de qual dash está atualmente selecionado.

A HUD de munição/energia da arma será necessária posteriormente, quando a KLM-99 for introduzida.

---

## 44. Feedback de ações

Todo evento relevante deve possuir feedback visual e sonoro.

| Evento | Feedback visual | Feedback sonoro |
|---|---|---|
| Acerto | Piscar branco, empurrão, hitstop | Impacto curto |
| Dano recebido | Piscar, tela tremer, borda vermelha | Impacto |
| Parry | Faísca | Clang |
| Dash | Afterimage/rastro | Whoosh + rosnado |
| Sem stamina | Barra pisca | Som de falha |
| Inimigo atacando | Telegraph visual | — |
| Morte inimigo | Partículas | Som de morte |
| Interação | Indicador E | Som de interação |
| Coleta | Destaque/pausa/texto | Jingle |
| Escalada | Indicador D | Feedback de movimento |

---

## 45. Tom do ambiente

A floresta deve apresentar contraste entre:

**Área segura**

- atmosfera tranquila;
- Xennar;
- fogueira;
- ausência de inimigos;
- diálogo.

**Áreas de combate**

- presença de inimigos;
- maior tensão;
- movimentação;
- feedback de combate.

A vegetação é densa, mas as áreas efetivamente percorridas pelo jogador permanecem abertas.

---

## 46. Parâmetros numéricos consolidados

| Parâmetro | Valor |
|---|---|
| Resolução base | 640 × 360 px (×3 na tela) |
| Altura do Homem-gato | Tamanho 2 |
| Velocidade de caminhada | 1,3 × padrão |
| Dash do Homem-gato — comprimento | 1,3 × padrão |
| Dash do Homem-gato — velocidade | 2 × padrão |
| Dash de rolamento — comprimento | 0,8 × padrão |
| Dash de rolamento — velocidade | 1 × padrão |
| Stamina máxima | 4 unidades |
| Recuperação padrão | 1 unidade / 3 s |
| Recuperação do Homem-gato | 1,5 × padrão |
| Janela do rolamento | 5 s |
| Interação | ½ da altura do tamanho 3 = 25 px *(o PDF dizia 8 px; ver correção na seção 11)* |
| HP do Homem-gato | 10 |
| Dano golpe 1 | 1 |
| Dano golpe 2 | 1 |
| Dano golpe 3 | 2 |
| Dano do dash ofensivo | 1 |
| Velocidade do golpe | 1,3 × padrão |
| Intervalo golpe 1→2 | 0,5 × duração do golpe |
| Intervalo golpe 2→3 | 1 × duração do golpe |
| Janela de parry | 0,2 s |
| Knockback do parry | 1 dash |
| Stun após parry | 0,5 s + 1,5 s |
| Sapo comum — HP | 4 |
| Sapo comum — salto | 0,5 dash |
| Sapo comum — velocidade | 1 × dash padrão |
| Sapo comum — ciclo | 1 s |
| Sapo comum — telegraph | 0,5 s |
| Sapo comum — dano | 1 |
| Sapo língua — HP | 3 |
| Sapo língua — pulo | 0,5 dash |
| Sapo língua — língua | 0,5 dash |
| Sapo língua — velocidade | 1 × dash padrão |
| Sapo língua — ciclo | 1 s |
| Sapo língua — telegraph | 0,5 s |
| Sapo língua — dano | 1 |
| Área segura | 1 tela |
| Corredor | 1 tela |
| Clareira | 1,5 tela |
| Exterior da ruína | 2–2,5 telas |
| Área superior | 1,5 tela |

---

## 47. Parâmetros ainda não definidos

Estes pontos permanecem deliberadamente abertos. Os que já têm proposta do desenvolvimento estão na [seção 49](#49-valores-propostos-pelo-desenvolvimento).

**Homem-gato**

- Valor absoluto da velocidade de caminhada em px/s.
- Valor absoluto do dash em px/s.
- Valor absoluto do comprimento do dash em px.
- Valores absolutos derivados da escala geral do jogo.

**Inimigos**

- Raio das zonas de percepção.
- Tamanho das três zonas do sapo com língua.
- Quantidade exata de inimigos por encontro.
- Posicionamento exato dos inimigos.
- Itens/recompensas deixados pelos inimigos.
- Telegraphs específicos do semiboss.
- Comportamentos completos do semiboss na área posterior.

**Cenário**

- Dimensões exatas em pixels das áreas.
- Layout final do blockout.
- Obstáculos específicos.
- Forma exata da parede escalável.
- Posição definitiva dos inimigos.
- Posição definitiva da flor.
- Posição definitiva da estátua.
- Posição definitiva do fragmento.
- Posição definitiva da peça de upgrade.

**Trilha sonora**

---

## 48. Princípio de implementação

Os valores definidos neste documento são **parâmetros atuais de protótipo**.

O fluxo esperado é:

**Game Design → Blockout → Implementação → Playtest → Calibração**

Os valores não devem ser alterados arbitrariamente durante o desenvolvimento.

Caso um parâmetro precise ser alterado por questões de jogabilidade, a alteração deve ser feita conscientemente no Game Design e então refletida na implementação.

---

## 49. Valores propostos pelo desenvolvimento

> Seção do desenvolvimento. São chutes iniciais para o que estava "a definir", para o protótipo ter com o que começar. Todos serão calibrados no playtest. Os valores estão em **pixels da arte**, na resolução base de **640 × 360 px**. Na tela Full HD tudo aparece 3× maior.

### 49.1 Escala dos personagens

Definido pelo game design em 30/09: o personagem de tamanho 3 tem **50 px** de altura na arte. A arte é ampliada 3× na tela, então ele aparece com **150 px** num monitor 1920 × 1080, com os pixels visíveis, como em Hyper Light Drifter e Eastward.

| Tamanho | Altura na arte | Na tela Full HD (×3) |
|---|---|---|
| 1 · baixo | 34 px | 102 px |
| 2 · médio (Homem-gato) | 42 px | 126 px |
| 3 · padrão | **50 px** | **150 px** |
| 4 · alto | 58 px | 174 px |

- Os tamanhos 1, 2 e 4 são proposta do desenvolvimento, em degraus de 8 px.
- Tile: **16 × 16 px** na arte (48 × 48 px na tela). A tela tem 40 × 22,5 tiles, e um personagem de tamanho 3 tem pouco mais de 3 tiles de altura.
- A proporção na tela é a da [imagem de referência de câmera](referencias/referencia-camera-escala.jpg): o personagem ocupa cerca de 14% da altura.

### 49.2 Parâmetros gerais do jogo ("padrão")

| Parâmetro padrão | Valor proposto |
|---|---|
| Velocidade normal de caminhada | 100 px/s |
| Dash padrão — comprimento | 80 px |
| Dash padrão — velocidade | 400 px/s |
| Dash padrão — duração resultante | 0,20 s |
| Duração padrão do golpe | 0,40 s |
| Knockback padrão dos ataques | 16 px (1 tile) |
| Recuperação padrão de stamina | 1 unidade / 3 s |

### 49.3 Homem-gato (valores resultantes)

| Parâmetro | Regra | Valor resultante |
|---|---|---|
| Caminhada | 1,3 × 100 | **130 px/s** |
| Dash ofensivo — comprimento | 1,3 × 80 | **104 px** |
| Dash ofensivo — velocidade | 2 × 400 | **800 px/s** |
| Dash ofensivo — duração | 104 ÷ 800 | **0,13 s** |
| Dash ofensivo — custo | seção 5 | **2 unidades** de stamina (a escalada também) |
| Rolamento — comprimento | 0,8 × 80 | **64 px** |
| Rolamento — velocidade | 1 × 400 | **400 px/s** |
| Rolamento — duração | 64 ÷ 400 | **0,16 s** |
| Recuperação de stamina | 3 s ÷ 1,5 | **1 unidade / 2 s** |
| Duração do golpe | 0,40 ÷ 1,3 | **0,308 s**|
| Intervalo golpe 1→2 | 0,5 × 0,308 | **0,154 s** |
| Intervalo golpe 2→3 | 1 × 0,308 | **0,308 s** |
| Knockback do parry | 1 dash padrão | **80 px** |
| Atordoamento do parry | 0,5 s até o chute + 1,5 s depois | **2 s** (só 0,5 s se o chute for cancelado com dash) |
| Invulnerabilidade depois do dano | seção 20 | **1,5 s** |
| Distância de interação | ½ × 50 | **25 px** |
| Hitbox do corpo | — | círculo de **raio 10 px**, nos pés |
| Área de ataque | 2 × raio | **20 px** de alcance, em arco à frente com 120° |
| Área de ataque golpe 3 | 2,5 × raio | **25 px** de alcance, em arco à frente com 60° |
| Recuperação do parry errado | — | **0,4 s** sem poder repetir *(ver dúvida 7)* |

### 49.4 Sapos

| Parâmetro | Regra | Valor resultante |
|---|---|---|
| Salto — comprimento | 0,5 × 80 | **40 px** |
| Salto — velocidade | 1 × 400 | **400 px/s** |
| Salto — duração | 40 ÷ 400 | **0,10 s** |
| Língua — alcance | 0,5 × 80 | **40 px** |
| Língua — velocidade | 1 × 400 | **400 px/s** (0,10 s para sair e 0,10 s para voltar) |
| Hitbox | proporcional à escala | retângulo de **18 × 14 px** *(ver dúvida 3)* |
| Zona de percepção | — | raio de **200 px** |
| Zona próxima (língua) | alcance da língua | até **40 px** |
| Zona intermediária | pulo + língua | de **40 a 80 px** |
| Zona externa | até a percepção | de **80 a 200 px** |

### 49.5 Encontros

| Local | Sapos comuns | Sapos com língua |
|---|---|---|
| Clareira (primeiro combate) | 3 | 1 |
| Exterior da ruína — grupo 1 | 4 | 2 |
| Exterior da ruína — grupo 2 | 5 | 2 |
| Área superior | 2 | 2 |
| **Total** | **14** | **7** |

O grupo 1 do exterior é o primeiro que o jogador encontra (gatilho de baixo), e o grupo 2 fica guardando a entrada. Os sapos da área superior não têm gatilho: ficam acordados.

As dimensões das áreas e o posicionamento estão em [02-level-design-demo.md](02-level-design-demo.md).

---

## 50. Dúvidas em aberto

Perguntas do desenvolvimento para o game design. As respondidas ficam riscadas, com a resposta.

1. ~~**Estilo da arte.**~~ *Respondida em 30/09: pixel art com os pixels visíveis. O tamanho 3 tem 50 px na arte e aparece com 150 px na tela (×3).*
2. ~~**Duração do golpe.**~~ *Respondida na v1.3: é 1,3 × a velocidade, ou seja, o golpe do gato é mais rápido. Com a duração padrão de 0,40 s, o golpe do gato dura 0,308 s.*
3. ~~**Hitbox dos inimigos.**~~ *Respondida na v1.3: a largura de 6 px saiu da seção 24. Fica o retângulo de 18 × 14 px.*
4. ~~**Fragmento da clareira.**~~ *Respondida em 02/10: o fragmento é o elemento tecnológico da seção 14, e fica longe da ruína. Foi para o recanto do corredor onde ficava a flor.*
5. **Perseguição.** O que significa "todo o espaço acessível do mapa que estiver atrás de sua posição"? O inimigo só persegue voltando em direção ao início do mapa, ou em qualquer direção dentro do cenário?
6. ~~**Dano de contato.**~~ *Respondida na v1.3: nenhum sapo tem dano de contato. Só o salto (e a língua) causam dano.*
7. **Parry errado.** Existe algum tempo de recuperação quando o jogador erra o parry? Sem isso, apertar Q sem parar defende tudo. A proposta é 0,4 s.
8. **Inimigo atordoado.** Ele toma dano normal ou dano extra (crítico)?
9. **Dash por vários inimigos.** O dash ofensivo causa dano em todos os inimigos atravessados? No protótipo, sim: 1 de dano em cada um.
10. **Descida da área superior.** Como o jogador volta para baixo: pula, desce pelo mesmo trecho ou tem outro caminho?
11. ~~**Posição da flor.**~~ *Respondida em 02/10: no corredor, um pouco acima de onde estava, perto de um corpo d'água.*
12. **Controle.** A demo terá suporte a controle (gamepad) além do teclado?
13. ~~**Rolamentos seguidos.**~~ *Respondida na v1.3: depois de gastar stamina, a contagem zera. O quarto rolamento conta como primeiro. A janela passou para 5 s.*
14. ~~**Dash parado.**~~ *Respondida na v1.3: sem direção, o dash vai para onde o gato olha.*
15. ~~**Combo esquecido.**~~ *Respondida na v1.3: o combo é cíclico e nunca volta ao golpe 1.*
16. ~~**Passo à frente no golpe.**~~ *Respondida na v1.3: o avanço (attack lunge) compensa o knockback. Ficou 16 px por golpe.*
17. ~~**Dash durante o combo.**~~ *Respondida na v1.3: não há cancelamento de combo. Ver a dúvida 31, sobre como isso ficou no protótipo.*
18. **Knockback do dash.** O dash ofensivo fere o inimigo (1 de dano), mas não o empurra, porque o gato passa através dele. Pode ser?
19. **Rolamento e inimigos.** O rolamento também atravessa inimigos (sem dano). Andando normalmente, o inimigo vivo bloqueia a passagem. Pode ser?
20. **Parry na língua.** *Atordoamento respondido na v1.3: 2 s, com chute imediato.* Falta o dano: no protótipo, o sapo leva 1 de dano quando a língua é rebatida. Está certo?
21. **Distância de interação.** Com 25 px contados da borda do objeto, é preciso quase encostar na flor ou na peça para pegar. Aumentar?
22. **Diálogo automático de Xennar.** O primeiro diálogo começa sozinho quando o gato chega a 40 px dele. As outras conversas são com E. Pode ser?
23. **Elemento tecnológico.** A seção 14 diz "ao encontrá-lo, o gato comenta". No protótipo, o comentário é com E, com indicador. Deveria ser automático, ao chegar perto?
24. ~~**Fala da flor.**~~ *Respondida na v1.3: o texto está na seção 13.*
25. ~~**Invulnerabilidade depois do dano.**~~ *Respondida na v1.3: 1,5 s de recuperação invulnerável. No protótipo, o gato pisca nesse tempo.*
26. **Direção do salto do sapo.** É decidida no começo do telegraph e não muda depois, então o jogador consegue desviar. Pode ser, ou o sapo deve mirar no fim do telegraph?
27. **Direção do parry.** O parry defende ataques vindos de qualquer lado, sem precisar estar virado para o inimigo. Pode ser?
28. **Entrada dos sapos.** Nos encontros, os sapos aparecem caindo do alto no lugar marcado, quase juntos. A ideia era saírem pulando da vegetação?
29. **Tela de morte.** O texto é provisório ("O Homem-gato caiu" e "Pressione E para recomeçar"), com filtro cinza avermelhado. Algum texto específico?
30. **Pausa.** Esc abre o menu com Continuar, Recomeçar a fase e Sair do jogo. Pode ser?
31. **Dash no meio do golpe.** "Não há cancelamento de combo" foi lido assim: o dash ainda interrompe o golpe em andamento (para fugir), mas a sequência não volta ao golpe 1. Se o golpe 2 foi interrompido, o próximo A é o golpe 3. Era isso, ou o dash não deveria funcionar no meio de um golpe?
32. **Golpe no sapo durante o salto.** A seção 25 não fala mais em interromper o pulo. No protótipo, o knockback leva o sapo para trás e o salto acaba ali. Se ele já estiver encostando no gato no mesmo instante, o dano do salto vale. Está certo, ou o sapo deveria continuar o salto mesmo levando o golpe?
33. **Espera do chute no parry.** Nos 0,5 s entre a defesa e o chute, o gato fica parado: não anda, não ataca e não abre outro parry. Só o dash cancela. Outros inimigos podem acertar o gato nesse tempo. Pode ser?
34. **Lago da flor.** O corpo d'água é só cenário e bloqueia a passagem, inclusive com o dash. Ele terá outra função (por exemplo, beber água, reflexo, peixes)?

---

## Histórico de versões

| Versão | Data | Quem | O que mudou |
|---|---|---|---|
| 1.0 | 30/09/2026 | Game design | Versão inicial (PDF original) |
| 1.0 | 30/09/2026 | Game design | Explicação dos multiplicadores e correção da referência de altura (16 px era o tile, não o personagem) |
| 1.0 | 30/09/2026 | Desenvolvimento | Transcrição para Markdown, seção 49 com valores propostos e seção 50 com dúvidas |
| 1.1 | 30/09/2026 | Game design | Resolução base passa a 1920 × 1080, com a arte na resolução real. Personagem de tamanho 3 com 150 px |
| 1.1 | 30/09/2026 | Desenvolvimento | Seção 49 recalculada para a nova escala (valores em px multiplicados por 3) |
| 1.2 | 30/09/2026 | Game design | Arte em pixel art com pixels visíveis: tamanho 3 com 50 px na arte, ampliado 3× (150 px na tela). Resolução base volta a 640 × 360 |
| 1.2 | 30/09/2026 | Desenvolvimento | Seção 49 recalculada em pixels da arte (valores divididos por 3) |
| 1.2 | 30/09/2026 | Desenvolvimento | Dúvidas 13 e 14, que surgiram na implementação dos dashes (M2) |
| 1.2 | 30/09/2026 | Desenvolvimento | Dúvidas 15 a 19, que surgiram na implementação do combate melee (M3) |
| 1.2 | 30/09/2026 | Desenvolvimento | Dúvidas 20 a 30, que surgiram na implementação do M4 ao M9 |
| 1.3 | 02/10/2026 | Game design | Alterações em algumas regras e mecânicas |
| 1.3 | 02/10/2026 | Desenvolvimento | Seção 49 conferida com a v1.3. Dúvidas respondidas riscadas e dúvidas 31 a 34. Correções: "dash padrão" → "dash ofensivo" na seção 20 e largura de 6 px tirada da tabela da seção 46 |
