extends RefCounted
## Todas as falas e textos da floresta, num lugar só, para o game design revisar.
## Fonte: docs/04-game-design-floresta.md (seções 13, 14, 15, 17, 38, 39 e 40).
## Cada fala é [quem fala, texto]. Quem fala vazio = texto sem nome (inscrição, narração).
## Falas marcadas com [PROVISÓRIO] não estão na especificação e precisam ser escritas pelo game design.

const XENNAR_PRIMEIRA := [
	["VELHO", "Ei... espere um momento..."],
	["VELHO", "Você parece jovem e ágil... o suficiente. Poderia me ajudar?"],
	["GATO", "Ajudo sim! Quer dizer... depende do que o senhor precisa. O que seria, miau?"],
	["VELHO", "Meu nome é Xennar. Sou o responsável pelo farol da região... aquele lá no alto da Costa das Pedras."],
	["XENNAR", "Há alguns dias... meu cajado foi tomado pelos invasores. Sem ele, não consigo mais acender a luz guia."],
	["GATO", "Tomado? Por quem?"],
	["XENNAR", "Por essas criaturas saltitantes que estão por todo lugar... Elas tomaram a região e estão acabando com a nossa paz."],
	["XENNAR", "Agora o líder deles se instalou na ruína do monte mais adiante... e levou meu cajado consigo."],
	["XENNAR", "Temos poucos por aqui capazes de enfrentá-los..."],
	["XENNAR", "Por favor, jovem... poderia recuperá-lo para mim?"],
]

const XENNAR_DEPOIS := [
	["XENNAR", "Jovem felino... conseguiu encontrá-lo? Se aceita uma dica... talvez consiga roubá-lo de volta sem chamar muita atenção."],
	["XENNAR", "Minhas costas doem só de pensar..."],
]

const OBJETIVO := "Recuperar o cajado de Xennar"

const FLOR_COLETA := "Flor de lírio azul"
const FLOR := [
	["GATO", "Uma flor de lírio azul, miau!"],
	["GATO", "[PROVISÓRIO] Minha irmã sempre diz que essa flor só nasce onde a água é limpa. Ela vai adorar!"],
]

const ESTATUA := [
	["", "Aos olhos da Guardiã, nenhuma criatura da floresta está sozinha."],
	["GATO", "A Guardiã... quem será que ela foi, miau?"],
]

const ELEMENTO := [
	["GATO", "Interessante... parece fazer parte da ruína..."],
	["GATO", "Como isso veio parar aqui?"],
]

const PECA_COLETA := "Peça de upgrade da KLM-99"
const PECA := [
	["GATO", "Isso é especial! Com uma dessas eu posso melhorar uma KLM-99."],
]
