# Roadmap da Demo

Documento vivo: atualizar o status a cada entrega.

**Legenda:** ✅ feito · 🔄 em andamento · ⏳ aguardando · ⬜ não iniciado

## Papéis

| Papel | Responsável |
|---|---|
| Game design, narrativa, experiência, concept art | Game designer |
| Programação, protótipo, blockout, integração | Desenvolvedor |
| Arte final (sprites, tilesets) | A definir |

---

## Etapas

### 1. Definir a demo — juntos ✅
- [x] O que a demo mostra
- [x] Gameplay principal
- [x] O que está e o que não está na demo
- [x] Escopo pequeno e fechado → [01-escopo-demo.md](01-escopo-demo.md)

### 2. Game design — game designer 🔄
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

### 3. Protótipo — desenvolvedor 🔄
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

### 4. Blockout da fase — desenvolvedor 🔄
- [x] Rascunho no papel → [02-level-design-demo.md](02-level-design-demo.md)
- [ ] Floresta no Godot com formas simples
- [ ] Ruína
- [ ] Sala do boss
- [ ] Posicionar os inimigos e os gatilhos de onda

### 5. Primeiro playtest — juntos ⬜
Pergunta: *a experiência que imaginamos funciona?*
- [ ] Jogar a demo inteira do início ao fim
- [ ] Anotar o que não funcionou
- [ ] Se não funcionar → voltar para as etapas 2 e 3
- [ ] Se funcionar → produção

### 6. Concept art — game designer ⬜
Personagens, cenários, inimigos, objetos, identidade visual, UI e referências de animação.

### 7. Produção e implementação — em paralelo ⬜

| Arte e conteúdo | Desenvolvimento |
|---|---|
| Assets | Programação |
| Animações | Integração dos assets |
| UI artística | Level final |
| VFX | UX/UI |
| Narrativa | Sistemas |
| Música | Áudio técnico |

---

## Histórico

| Data | O que mudou |
|---|---|
| 27/09/2026 | Escopo da demo definido, rascunho do level design e roadmap criado |
| 27/09/2026 | Protótipo web v0.2: a demo em miniatura com o Homem-gato, parry, arma e Sentinela |
