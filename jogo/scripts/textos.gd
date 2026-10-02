extends RefCounted
## Todas as falas e textos da floresta, num lugar só, para o game design revisar.
## Fonte: docs/04-game-design-demo.md, v1.3 (seções 13, 14, 15, 17, 38, 39 e 40).
## Cada fala é [quem fala, texto]. Quem fala vazio = texto sem nome (inscrição, narração).
## Xennar aparece como VELHO até dizer o próprio nome.

const XENNAR_PRIMEIRA := [
	["VELHO", "Ei... espere um momento..."],
	["VELHO", "Você parece jovem e ágil... o suficiente. Poderia me ajudar?"],
	["GATO", "Ajudo sim! Quer dizer, depende do que o senhor precisa. O que seria, miau?"],
	["VELHO", "Meu nome é Xennar. Sou o responsável pelo farol da região... que fica no alto da Costa das Pedras."],
	["XENNAR", "Há alguns dias... meu cajado foi tomado pelos malditos invasores. Sem ele, não consigo mais acender sua luz guia."],
	["GATO", "Tomado? Por quem?"],
	["XENNAR", "Por essas criaturas saltitantes... Estão espalhadas por toda a região e saqueando tudo aquilo que há de valor."],
	["XENNAR", "Agora o líder deles se instalou na ruína do monte adiante... e levou meu cajado para lá."],
	["XENNAR", "Por favor, temos poucos por aqui capazes de enfrentá-los..."],
	["XENNAR", "Poderia recuperá-lo para mim?"],
]

const XENNAR_DEPOIS := [
	["XENNAR", "Jovem felino... conseguiu encontrá-lo? Se aceita uma dica... talvez consiga roubá-lo de volta sem chamar muita atenção."],
	["XENNAR", "Minhas costas doem só de pensar..."],
]

const OBJETIVO := "Recuperar o cajado de Xennar"

const FLOR_COLETA := "Flor de lírio azul"
const FLOR := [
	["GATO", "Uma flor de lírio azul, miau!"],
	["GATO", "Minha irmã sempre diz que essa flor nasce onde a água é limpa. Acho que ela vai gostar!"],
]

const ESTATUA := [
	["", "Uma antiga estátua. Há algo escrito na base:"],
	["", "\"Aos olhos da Guardiã, nenhuma criatura da floresta está sozinha.\""],
	["GATO", "A Guardiã... quem será que ela foi?"],
]

const ELEMENTO := [
	["GATO", "Interessante... parece fazer parte da ruína..."],
	["GATO", "Como isso veio parar aqui?"],
]

const PECA_COLETA := "Peça de upgrade da KLM-99"
const PECA := [
	["GATO", "Isso é especial! Com uma dessas eu posso melhorar uma KLM-99."],
]
