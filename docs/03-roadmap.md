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
- [ ] Personagem e habilidades de raça
- [ ] Regras de movimento (pula? atravessa parede?)
- [ ] Combate: ataque, dash, stamina, escudo, parry, parry perfeito
- [ ] A arma encontrada e como ela muda o combate
- [ ] 3 inimigos comuns
- [ ] Semi-boss + minions
- [ ] Boss e padrões de ataque
- [ ] Experiência desejada em cada trecho
- [ ] Concept da região da demo

### 3. Protótipo — Development Director 🔄
Versão feia, mas jogável. Um ensaio web de todos os marcos já está em [prototipo/index.html](../prototipo/index.html), com inimigos e boss provisórios. Os marcos abaixo são do protótipo oficial no Godot, em ordem:
- [ ] **M1** Projeto Godot, resolução, câmera seguindo o personagem, movimento em 8 direções
- [ ] **M2** Dash, stamina e ataque corpo a corpo, com feedback (hitstop, flash, tremida, sons provisórios)
- [ ] **M3** Escudo, parry e parry perfeito (atordoar + crítico)
- [ ] **M4** Os 3 inimigos comuns com telegraph de ataque
- [ ] **M5** NPC, caixa de diálogo e pausa
- [ ] **M6** Pegar a arma e trocar para o ataque à distância
- [ ] **M7** Semi-boss + minions
- [ ] **M8** Boss
- [ ] **M9** Item de missão, entrega ao NPC, fim da demo, checkpoints e morte

### 4. Blockout da fase — Development Director (Level Designer) 🔄
- [x] Rascunho no papel → [02-level-design-demo.md](02-level-design-demo.md)
- [ ] Floresta no Godot com formas simples
- [ ] Ruína
- [ ] Sala do boss
- [ ] Posicionar os inimigos e os gatilhos de onda

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
