# Roadmap da Demo

Documento vivo: atualizar o status a cada entrega.

**Legenda:** ✅ feito · 🔄 em andamento · ⏳ aguardando · ⬜ não iniciado

## Cargos e responsabilidades

### Game Director
- **Game Director:** visão geral do jogo e decisão final sobre a experiência
- **Game Designer:** mecânicas, personagens, inimigos, habilidades, regras e especificação de gameplay
- **Narrative Designer:** história, mundo, diálogos e estrutura das campanhas
- **Art Director:** identidade visual e direção de toda a arte
- **Concept Artist:** personagens e cenários
- **Animator:** animações de personagens, inimigos e efeitos
- **UI Artist:** arte da interface (HUD, menus, ícones)
- **Composer:** trilha sonora

### Development Director
- **Development Director:** direção técnica, arquitetura e escolhas de ferramentas
- **General Programmer:** programação de gameplay, sistemas, integração de assets e áudio técnico
- **UX/UI Designer:** fluxo e usabilidade das telas, HUD e controles
- **Level Designer:** blockout, fluxo das fases e posicionamento de inimigos e elementos
- **Producer:** escopo, roadmap, prazos e acompanhamento das entregas

> Em aberto: arte final de sprites e tilesets em volume, efeitos sonoros e VFX. Ficam com o Game Director por enquanto, sob a direção de arte, até decidirmos se entra mais alguém.

---

## Etapas

### 1. Definir a demo — Game Director + Development Director ✅
- [x] O que a demo mostra
- [x] Gameplay principal
- [x] O que está e o que não está na demo
- [x] Escopo pequeno e fechado → [01-escopo-demo.md](01-escopo-demo.md)

### 2. Game design — Game Director 🔄
Entrega: **especificação de gameplay**.
- [x] **Floresta** → [04-game-design-demo.md](04-game-design-demo.md): Homem-gato, controles, dashes, stamina, combo, parry, sapos, Xennar, interações e mapa
- [ ] Responder as [dúvidas em aberto](04-game-design-demo.md#50-dúvidas-em-aberto) da floresta e validar os [valores propostos](04-game-design-demo.md#49-valores-propostos-pelo-desenvolvimento)
- [ ] **Ruína:** a KLM-99 (ataque à distância), inimigos, semi-boss e minions
- [ ] **Boss:** líder das criaturas, padrões de ataque
- [ ] Concept da região da demo

### 3. Protótipo — Development Director 🔄
> **Ordem definida pelo Game Director (30/09):** o blockout de cada área vem antes do resto do protótipo. Por isso o M4 ficou pausado enquanto a floresta era montada no Godot, e foi retomado depois.

Versão feia, mas jogável, no Godot. A floresta já pode ser feita inteira. Marcos em ordem:

**Floresta (liberada)**
- [x] **M1** Projeto Godot em 640×360 (×3 na tela), movimento em 8 direções (setas), colisão e câmera seguindo
- [x] **M2** Dash ofensivo, dash de rolamento (2 grátis em 5 s), troca com S, stamina em 4 unidades e HUD
- [x] **M3** Combo cíclico de 3 golpes (garra, garra, espada), dano do dash, knockback e feedback (hitstop, flash, tremida, sons provisórios)
- [x] **M4** Parry com Q: janela de 0,2 s, chute, knockback de 1 dash e atordoamento de 0,5 s + 1,5 s
- [x] **M5** Sapo comum: ciclo com telegraph, salto, cancelamento do pulo, HP em quadradinhos e morte
- [x] **M6** Sapo com língua: três zonas, língua que volta e parry da língua
- [x] **M7** Interação com E: Xennar e diálogos, flor, estátua, elemento tecnológico, interações ocultas
- [x] **M8** Escalada com dash, área superior e peça de upgrade
- [x] **M9** HP do jogador, morte com filtro e reinício da fase, pausa

**Ruína e boss (aguardando especificação)**
- [ ] **M10** KLM-99 e ataque à distância
- [ ] **M11** Semi-boss + minions
- [ ] **M12** Boss, cajado, entrega a Xennar e fim da demo

> O [protótipo web](../prototipo/index.html) foi feito antes da especificação e ficou desatualizado: usa escudo, outra NPC e outros inimigos. Serve só como referência de sensação de combate.

### 4. Blockout da fase — Development Director (Level Designer) 🔄
- [x] Floresta no papel, já pela especificação → [02-level-design-demo.md](02-level-design-demo.md)
- [x] Floresta no Godot com formas simples: área segura, corredor, clareira, exterior e área superior
- [x] Posicionar os 4 encontros (14 sapos comuns e 7 com língua) e os gatilhos
- [ ] Ruína *(aguardando especificação)*
- [ ] Sala do boss *(aguardando especificação)*

### 5. Primeiro playtest — Game Director + Development Director ⬜
Pergunta: *a experiência que imaginamos funciona?*
- [ ] Jogar a demo inteira do início ao fim
- [ ] Anotar o que não funcionou
- [ ] Se não funcionar → voltar para as etapas 2 e 3
- [ ] Se funcionar → produção

### 6. Concept art — Game Director (Art Director / Concept Artist) ⬜
Personagens, cenários, inimigos, objetos, identidade visual, UI e referências de animação.

### 7. Produção e implementação — em paralelo ⬜

| Game Director | Development Director |
|---|---|
| Assets e direção de arte | Programação |
| Animações | Integração dos assets |
| UI artística | Level design final |
| VFX | UX/UI |
| Narrativa e diálogos | Sistemas |
| Música | Áudio técnico |
| | Produção: roadmap, prazos e status |

---

## Histórico

| Data | O que mudou |
|---|---|
| 27/09/2026 | Escopo da demo definido, rascunho do level design e roadmap criado |
| 27/09/2026 | Protótipo web v0.2: a demo em miniatura com o Homem-gato, parry, arma e Sentinela |
| 28/09/2026 | Cargos e responsabilidades definidos |
| 30/09/2026 | Especificação da floresta recebida. Marcos do protótipo e blockout refeitos por ela |
| 30/09/2026 | Resolução base passa a 1920×1080, com personagens de 150 px e arte na resolução real |
| 30/09/2026 | M1 concluído: projeto Godot em [jogo/](../jogo/), com movimento em 8 direções, colisão e câmera |
| 30/09/2026 | Arte em pixel art com pixels visíveis: personagem padrão com 50 px, ampliado 3× (150 px na tela). Resolução base volta a 640×360 |
| 30/09/2026 | M2 concluído: dash padrão, rolamento, troca com S, stamina e HUD provisória, com sons provisórios |
| 30/09/2026 | M3 concluído: combo de 3 golpes, dano do dash, knockback, hitstop e alvos de treino na sala de teste |
| 30/09/2026 | Game Director pede o blockout antes do protótipo. M4 pausado. Blockout da floresta montado no Godot, com as 5 áreas e os 4 encontros marcados |
| 30/09/2026 | M4 a M9 concluídos: parry, sapos comum e com língua, encontros com gatilho, interações e diálogos, escalada, morte e pausa. A floresta está jogável do início à entrada da ruína |
| 02/10/2026 | Game design v1.3 aplicado no protótipo (dash ofensivo, rolamento contra projéteis, combo cíclico, área de ataque em arco, parry em dois tempos, invulnerabilidade, 14 + 7 sapos). Blockout: elemento tecnológico levado para longe da ruína, flor mais acima, ao lado de um lago |
| 04/10/2026 | Game design v1.4.1 aplicado no protótipo: magnetismo de mira, golpe em fases (antecipação, impacto, recuperação) com cancelamento, leque de 120°/90°, passo e knockback de 24 px, rolamento que para nos inimigos, dash que cancela o parry, 1 s de invulnerabilidade e sapo com língua sem dano no salto |
| 04/10/2026 | Docs conferidos depois da v1.4.1: escopo ([01-escopo-demo.md](01-escopo-demo.md)) atualizado (dash ofensivo com 2 de stamina e 1 de dano, rolamento que para em inimigo e janela de 5 s, combo cíclico com fases, parry com 0,5 s + 1,5 s e 0,4 s sem defesa, invulnerabilidade de 1 s) e marcos M2, M3 e blockout do roadmap corrigidos (14 + 7 sapos) |
| 04/10/2026 | Respostas do game design às dúvidas 35 a 40 aplicadas no jogo: passo em ease-out, preferência de 2 s pelo alvo anterior com desempate, sem ataque guardado. A versão do game design (1.4.1) aparece na tela |
