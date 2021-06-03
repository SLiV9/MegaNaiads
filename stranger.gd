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
	'Sore Loser',
]

var strategy = 0



func become_innkeeper():
	become_stranger(INNKEEPER_FRAME, randi() % 2)

func become_boss():
	become_stranger(BOSS_FRAME, 11)

func become_stranger(i: int, s: int):
	$Face.frame = i
	strategy = s
	var name = ADJECTIVES[i] + ' Stranger'
	$Name.bbcode_text = '[color=' + STRANGER_COLOR + ']' + name + '[/color]'
	$Brain.load("brains/A_54675_54484_54307.pth.tar")

func reveal_identity():
	var name
	match $Face.frame:
		INNKEEPER_FRAME:
			name = 'Innkeeper'
		BOSS_FRAME:
			name = 'Big Boss'
		var i:
			name = ADJECTIVES[i] + STRATEGY_NAMES[strategy]
	$Name.bbcode_text = '[color=' + REVEALED_COLOR + ']' + name + '[/color]'

func get_name_bbcode():
	return $Name.bbcode_text
