extends Node
## Todos os valores de calibragem do jogo num lugar só.
## Fonte: docs/04-game-design-demo.md (v1.4.1), seção 49.
## Para calibrar, mude o número aqui e rode o jogo de novo (F5).
## Distâncias em px da arte (base 640 × 360, ampliada 3× na tela), velocidades
## em px/s, tempos em segundos.

# Versão do game design que o protótipo implementa (aparece na tela). Atualize junto com o doc.
const VERSAO_GAME_DESIGN := "1.4.1"

# --- Escala ---
const TILE := 16.0
const ALTURA_TAMANHO_3 := 50.0

# --- Padrão do jogo ---
const CAMINHADA_PADRAO := 100.0
const DASH_COMPRIMENTO_PADRAO := 80.0
const DASH_VELOCIDADE_PADRAO := 400.0
const GOLPE_DURACAO_PADRAO := 0.40
const KNOCKBACK_PADRAO := 24.0
const STAMINA_RECUPERACAO_PADRAO := 3.0  # segundos por unidade
const STAMINA_MAXIMA := 4
const INTERACAO_DISTANCIA := ALTURA_TAMANHO_3 / 2.0

# --- Homem-gato: multiplicadores do game design ---
const GATO_ALTURA := 42.0
const GATO_RAIO_HITBOX := 10.0
const GATO_VIDA := 10
const GATO_MULT_CAMINHADA := 1.3
const GATO_MULT_DASH_COMPRIMENTO := 1.3
const GATO_MULT_DASH_VELOCIDADE := 2.0
const GATO_MULT_ROLAMENTO_COMPRIMENTO := 0.8
const GATO_MULT_ROLAMENTO_VELOCIDADE := 1.0
const GATO_MULT_STAMINA := 1.5
const GATO_MULT_GOLPE_VELOCIDADE := 1.3  # golpe 1,3× mais rápido que o padrão
const GATO_DASH_CUSTO := 2  # dash ofensivo, em unidades de stamina
const GATO_ROLAMENTO_CUSTO := 1  # terceiro rolamento dentro da janela
const GATO_ROLAMENTOS_GRATIS := 2
const GATO_ROLAMENTO_JANELA := 5.0
const GATO_ALCANCE_ATAQUE := GATO_RAIO_HITBOX * 3.0  # golpes 1 e 2: 30 px a partir do centro (seção 24)
const GATO_ANGULO_ATAQUE := 120.0  # golpes 1 e 2: abertura do leque, em graus
const GATO_ALCANCE_GOLPE_3 := GATO_RAIO_HITBOX * 4.0  # 40 px
const GATO_ANGULO_GOLPE_3 := 90.0  # corte vertical
const GATO_GOLPE_IMPACTO := 0.1  # janela em que a hitbox fica ativa, no início da execução (s)
const GATO_GOLPE_AVANCO := KNOCKBACK_PADRAO  # passo à frente em cada golpe: 24 px (igual ao knockback)
const GATO_GOLPE_AVANCO_VELOCIDADE := 2.0 * GATO_GOLPE_AVANCO / GATO_GOLPE_IMPACTO  # 480 px/s no começo, caindo linearmente a zero em 0,1 s (ease-out): anda os 24 px
const GATO_MAGNETISMO_CONE := 45.0  # graus para cada lado da direção do olhar (seção 18)
const GATO_MAGNETISMO_MARGEM := 10.0  # px além do alcance efetivo
const GATO_MAGNETISMO_PREFERENCIA := 2.0  # s: por quanto tempo o alvo anterior tem preferência
const GATO_MAGNETISMO_EMPATE := 1.0  # px: distâncias dentro dessa folga empatam; desempata o menor ângulo
const HITSTOP := 0.05  # congelamento curto a cada acerto
const GATO_DANO_GARRA := 1
const GATO_DANO_ESPADA := 2
const GATO_DANO_DASH := 1
const GATO_PARRY_JANELA := 0.2
const GATO_PARRY_RECUPERACAO := 0.4
const GATO_PARRY_ESPERA_CHUTE := 0.5  # inimigo atordoado entre a defesa e o chute
const GATO_PARRY_ATORDOAMENTO := 1.5  # depois do empurrão do chute (total de 2 s)
const GATO_INVULNERAVEL := 1.0  # recuperação depois de tomar dano (pode atacar e dar dash)

# --- Homem-gato: valores resultantes ---
const GATO_CAMINHADA := CAMINHADA_PADRAO * GATO_MULT_CAMINHADA  # 130
const GATO_DASH_COMPRIMENTO := DASH_COMPRIMENTO_PADRAO * GATO_MULT_DASH_COMPRIMENTO  # 104
const GATO_DASH_VELOCIDADE := DASH_VELOCIDADE_PADRAO * GATO_MULT_DASH_VELOCIDADE  # 800
const GATO_ROLAMENTO_COMPRIMENTO := DASH_COMPRIMENTO_PADRAO * GATO_MULT_ROLAMENTO_COMPRIMENTO  # 64
const GATO_ROLAMENTO_VELOCIDADE := DASH_VELOCIDADE_PADRAO * GATO_MULT_ROLAMENTO_VELOCIDADE  # 400
const GATO_STAMINA_RECUPERACAO := STAMINA_RECUPERACAO_PADRAO / GATO_MULT_STAMINA  # 2 s por unidade
const GATO_GOLPE_DURACAO := GOLPE_DURACAO_PADRAO / GATO_MULT_GOLPE_VELOCIDADE  # 0,308
const GATO_GOLPE_ANTECIPACAO := GATO_GOLPE_DURACAO / 4.0  # 0,077: sem dano; o dash cancela e o golpe não conta
const GATO_GOLPE_EXECUCAO := GATO_GOLPE_DURACAO - GATO_GOLPE_ANTECIPACAO  # 0,231: não cancela
const GATO_RECUPERACAO_GOLPE_1 := GATO_GOLPE_DURACAO * 0.5  # 0,154
const GATO_RECUPERACAO_GOLPE_2 := GATO_GOLPE_DURACAO * 1.0  # 0,308
const GATO_RECUPERACAO_GOLPE_3 := 0.4
const GATO_ALCANCE_EFETIVO_1_2 := GATO_ALCANCE_ATAQUE + GATO_GOLPE_AVANCO  # 54
const GATO_ALCANCE_EFETIVO_3 := GATO_ALCANCE_GOLPE_3 + GATO_GOLPE_AVANCO  # 64
const GATO_PARRY_KNOCKBACK := DASH_COMPRIMENTO_PADRAO  # 80
const PARRY_KNOCKBACK_VELOCIDADE := DASH_VELOCIDADE_PADRAO  # 400 -> 0,2 s de empurrão

# --- Alvo de treino que ataca (sala de teste, só para treinar o parry) ---
const TREINO_PERCEPCAO := 60.0
const TREINO_ALCANCE := 32.0
const TREINO_TELEGRAPH := 0.5
const TREINO_INTERVALO := 1.0
const TREINO_DANO := 1

# --- Sapos ---
const SAPO_VIDA := 4
const SAPO_HITBOX := Vector2(18.0, 14.0)
const SAPO_SALTO_COMPRIMENTO := DASH_COMPRIMENTO_PADRAO * 0.5  # 40
const SAPO_SALTO_VELOCIDADE := DASH_VELOCIDADE_PADRAO  # 400
const SAPO_LINGUA_ALCANCE := DASH_COMPRIMENTO_PADRAO * 0.5  # 40
const SAPO_LINGUA_VELOCIDADE := DASH_VELOCIDADE_PADRAO  # 400
const SAPO_PERCEPCAO := 200.0
const SAPO_ZONA_PROXIMA := 40.0
const SAPO_ZONA_INTERMEDIARIA := 80.0
const SAPO_TELEGRAPH := 0.5
const SAPO_INTERVALO := 1.0  # espera entre um ciclo e outro
const SAPO_DANO := 1
const SAPO_LINGUA_DANO := 1
const SAPO_LINGUA_PARRY_DANO := 1  # dano no sapo quando a língua é rebatida (dúvida 20)
const SAPO_LINGUA_PARRY_ATORDOAMENTO := 2.0
const ENCONTRO_ATRASO_MAXIMO := 0.25  # os sapos do encontro entram quase juntos

# --- Interação ---
const XENNAR_DISTANCIA_AUTO := 40.0  # o primeiro diálogo começa sozinho a essa distância
