extends Node2D


class_name Stranger


const INNKEEPER_FRAME = 10
const BOSS_FRAME = 11

const REVEALED_COLOR = '#dc8b58'
const STRANGER_COLOR = '#8d659a'
const QUOTE_COLOR = '#9c9887'

const ADJECTIVES = [
	'Affable',
	'Boastful',
	'Ominous',
	'Jolly',
	'Loud',
	'Tired',
	'Peculiar',
	'Callous',
	'Quiet',
	'Glum',
	'Welcoming',
	'Monstrous',
]
const STRATEGY_NAMES = [
	'Trickster',
	'Artist',
	'Drunk',
	'Fool',
	'Forger',
	'Swindler',
	'Illusionist',
	'Knight',
	'Prince',
	'Brute',
	'Spy',
]
const STRATEGY_CARDS = [33, 56, 58, 62, 64, 60, 67, 63, 57, 59, 66]
enum STRATEGY {
	TRICKSTER,
	ARTIST,
	DRUNK,
	FOOL,
	FORGER,
	SWINDLER,
	ILLUSIONIST,
	KNIGHT,
	PRINCE,
	BRUTE,
	SPY,
}

var revealed = false
var accused = false
var defeated = false
var strategy = null



func become_innkeeper():
	strategy = STRATEGY.TRICKSTER
	become_stranger(INNKEEPER_FRAME)

func become_stranger(i: int):
	revealed = false
	accused = false
	defeated = false
	$Face.frame = i
	var name = ADJECTIVES[i] + ' Stranger'
	$Name.bbcode_text = '[color=' + STRANGER_COLOR + ']' + name + '[/color]'
	$Brain.load("brains/A_1_0_0.pth.tar")

func reveal_identity():
	revealed = true
	var name
	match $Face.frame:
		INNKEEPER_FRAME:
			name = 'Innkeeper'
		BOSS_FRAME:
			name = 'Big Boss'
		var i:
			name = ADJECTIVES[i] + ' ' + STRATEGY_NAMES[strategy]
	$Name.bbcode_text = '[color=' + REVEALED_COLOR + ']' + name + '[/color]'

func get_name_bbcode():
	return $Name.bbcode_text

func get_introduction_name_bbcode():
	var adjective = ADJECTIVES[$Face.frame]
	var text = "A"
	# English majors: sue me.
	var vowels = ['A', 'I', 'E', 'O', 'U']
	if vowels.find(adjective[0]) >= 0:
		text += "n"
	text += " " + get_name_bbcode()
	return text

func get_reveal_quote():
	var quote = null
	match ADJECTIVES[$Face.frame]:
		'Welcoming': quote = ("Right you are!" +
			" I'm also the owner of this fine establishment." +
			" Now see if you can beat me!")
		'Monstrous': quote = "WAAAH!"
		'Affable': quote = "Ha, you've caught me."
		'Boastful': quote = ("And I would have gotten away with it," +
			" if it wasn't for your meddling...")
		'Ominous': quote = "Bah! And so I must step into the light."
		'Jolly': quote = "Hahaha! I got you good, didn't I?"
		'Loud': quote = "ARGH! YOU ARE NOT SUPPOSED TO NOTICE!"
		'Tired': quote = "Oh, yeah, that's me alright."
		'Peculiar': quote = "Indeed!"
		'Callous': quote = "You little snitch!"
		'Quiet': quote = "Damn."
		'Glum': quote = "Am I that obvious?"
	if quote == null:
		return null
	return (get_name_bbcode() + ": [color=" + QUOTE_COLOR + "]" +
		quote + "[/color]")

func get_reject_quote():
	var quote = null
	match ADJECTIVES[$Face.frame]:
		'Welcoming': quote = "No, not quite. Give it another go."
		'Monstrous': quote = "Hahahaha! You know nothing!"
		'Affable': quote = "No, you must have me confused with someone else."
		'Boastful': quote = "Ha! You're terrible at this, aren't you?"
		'Ominous': quote = "Ha! You fool!"
		'Jolly': quote = "What, me? No, hahaha."
		'Loud': quote = "Nuh-uh!"
		'Tired': quote = "What? No I don't have time for that sort of stuff."
		'Peculiar': quote = "Who, me? What a thought."
		'Callous': quote = "You insolent brat! You dare accuse me?"
		'Quiet': quote = "Huh?"
		'Glum': quote = "I wish."
	if strategy == STRATEGY.KNIGHT:
		quote += " I am an honerable Knight!"
	if quote == null:
		return null
	return (get_name_bbcode() + ": [color=" + QUOTE_COLOR + "]" +
		quote + "[/color]")

func get_defeat_quote():
	var quote = null
	match ADJECTIVES[$Face.frame]:
		'Welcoming': quote = "Well, time for me to get back to work!"
		'Monstrous': quote = "What... wait... WHAT?!"
		'Affable': quote = "Well played!"
		'Boastful': quote = "Hmpf. I'll get you next time!"
		'Ominous': quote = "Why you little... I'll get you for this!"
		'Jolly': quote = "Woah, what a game! Same time tomorrow?"
		'Loud': return ("The " + get_name_bbcode() +
			" throws their across the room.")
		'Tired': quote = "Huh. I guess it's time for me to go to bed."
		'Peculiar': quote = "Time to leave!"
		'Callous': quote = "You better sleep with one eye open tonight!"
		'Quiet': return null
		'Glum': quote = "Another day, another disappointment."
	if quote == null:
		return null
	return (get_name_bbcode() + ": [color=" + QUOTE_COLOR + "]" +
		quote + "[/color]")

static func get_accusation_card(s: int):
	return STRATEGY_CARDS[s]

static func get_strategy_from_accusation_card(x: int):
	return STRATEGY_CARDS.find(x)

static func get_accusation_bbcode(x: int):
	match get_strategy_from_accusation_card(x):
		STRATEGY.TRICKSTER:
			return "a dirty [color=" + REVEALED_COLOR + "]Trickster[/color]"
		STRATEGY.ARTIST:
			return "a lousy [color=" + REVEALED_COLOR + "]Artist[/color]"
		STRATEGY.DRUNK:
			return "a [color=" + REVEALED_COLOR + "]Drunk[/color]"
		STRATEGY.FOOL:
			return "a [color=" + REVEALED_COLOR + "]Fool[/color]"
		STRATEGY.FORGER:
			return "a [color=" + REVEALED_COLOR + "]Forger[/color]"
		STRATEGY.SWINDLER:
			return "a [color=" + REVEALED_COLOR + "]Swindler[/color]"
		STRATEGY.ILLUSIONIST:
			return "an [color=" + REVEALED_COLOR + "]Illusionist[/color]"
		STRATEGY.KNIGHT:
			return "an honorable [color=" + REVEALED_COLOR + "]Knight[/color]"
		STRATEGY.PRINCE:
			return "a spoiled [color=" + REVEALED_COLOR + "]Prince[/color]"
		STRATEGY.BRUTE:
			return "a [color=" + REVEALED_COLOR + "]Brute[/color]"
		STRATEGY.SPY:
			return "a [color=" + REVEALED_COLOR + "]Spy[/color]"

static func get_strategy_bbcode(x: int):
	match get_strategy_from_accusation_card(x):
		STRATEGY.TRICKSTER:
			return ("The [color=" + REVEALED_COLOR + "]Trickster[/color]" +
				" starts the round with a Joker in their hand.")
		STRATEGY.ARTIST:
			return ("The [color=" + REVEALED_COLOR + "]Artist[/color]" +
				" has drawn some extra Hearts on an unused card.")
		STRATEGY.DRUNK:
			return ("The [color=" + REVEALED_COLOR + "]Drunk[/color]" +
				" plays completely randomly.")
		STRATEGY.FOOL:
			return ("The [color=" + REVEALED_COLOR + "]Fool[/color]" +
				" doesn't know the rules and is just matching pictures.")
		STRATEGY.FORGER:
			return ("The [color=" + REVEALED_COLOR + "]Forger[/color]" +
				" has some extra Aces up their sleeves.")
		STRATEGY.SWINDLER:
			return ("The [color=" + REVEALED_COLOR + "]Swindler[/color]" +
				" swaps Sevens in their opening hand with Tens from the deck.")
		STRATEGY.ILLUSIONIST:
			return ("The [color=" + REVEALED_COLOR + "]Illusionist[/color]" +
				" can turn up to one Diamonds or Clubs into Hearts or Spades" +
				" (except Aces).")
		STRATEGY.KNIGHT:
			return ("The [color=" + REVEALED_COLOR + "]Knight[/color]" +
				" is honorable.")
		STRATEGY.PRINCE:
			return ("The [color=" + REVEALED_COLOR + "]Prince[/color]" +
				" is lucky enough to start with a King and a Queen in hand.")
		STRATEGY.BRUTE:
			return ("The [color=" + REVEALED_COLOR + "]Brute[/color]" +
				" takes another player's cards at the start of the round.")
		STRATEGY.SPY:
			return ("The [color=" + REVEALED_COLOR + "]Spy[/color]" +
				" can see everyone's cards at all times.")
		_:
			return "Who knows?"
