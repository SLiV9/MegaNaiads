extends Node2D

class_name Hand

var cards = []
var revealed = false
var has_passed = false
var has_been_public = [false, false, false]


func _ready():
	hide_cards()

func hide_cards():
	revealed = false
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		if i < cards.size():
			cardSprites[i].visible = true
			cardSprites[i].set_frame_to_back()
		else:
			cardSprites[i].visible = false

func reveal_cards():
	revealed = true
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		if i < cards.size():
			cardSprites[i].visible = true
			cardSprites[i].set_frame(cards[i])
		else:
			cardSprites[i].visible = false

func deal_card(card):
	var i = cards.size()
	cards.push_back(card)
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	cardSprites[i].visible = true
	if revealed:
		cardSprites[i].set_frame(card)
	else:
		cardSprites[i].set_frame_to_back()

func discard_all_cards():
	cards = []
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for i in range(0, 6):
		cardSprites[i].visible = false
	for i in range(0, 3):
		has_been_public[i] = false
	has_passed = false

func exchange_cards(oldCard, newCard):
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, cards.size()):
		if cards[i] == oldCard:
			cards[i] = newCard
			has_been_public[i] = true
			if cardSprites[i].get_frame() == oldCard:
				cardSprites[i].set_frame(newCard)
			cardSprites[i].position.y = 48

func get_raised_card():
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for i in range(0, cards.size()):
		if cardSprites[i].position.y < 48:
			return cards[i]
	return null


func _input(ev):
	if ev is InputEventMouseButton:
		var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
		var clickedIndex = null
		for i in range(0, cardSprites.size()):
			var s = cardSprites[i]
			if not s.visible:
				continue
			if s.get_rect().has_point(s.to_local(ev.position)):
				clickedIndex = i
				cardSprites[i].position.y = 32
		for i in range(0, cardSprites.size()):
			if clickedIndex != i and (clickedIndex != null or not ev.pressed):
				cardSprites[i].position.y = 48
