extends Node2D


class_name Stranger


const INNKEEPER_FRAME = 10
const BOSS_FRAME = 11

const REVEALED_COLOR = '#dc8b58'
const STRANGER_COLOR = '#8d659a'

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

var strategy = null



func become_innkeeper():
	strategy = STRATEGY.TRICKSTER
	become_stranger(INNKEEPER_FRAME)

func become_stranger(i: int):
	$Face.frame = i
	var name = ADJECTIVES[i] + ' Stranger'
	$Name.bbcode_text = '[color=' + STRANGER_COLOR + ']' + name + '[/color]'
	$Brain.load("brains/A_1_0_0.pth.tar")

func reveal_identity():
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
