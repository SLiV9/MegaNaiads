extends Node2D


const CARD_BACK_FRAME = 53

var cards = []
var revealed = false


func _ready():
	hide_cards()

func hide_cards():
	revealed = false
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		if i < cards.size():
			cardSprites[i].visible = true
			cardSprites[i].set_frame(CARD_BACK_FRAME)
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
	var cardSprites = [$Card1, $Card2, $Card3]
	cardSprites[i].visible = true
	if revealed:
		cardSprites[i].set_frame(card)
	else:
		cardSprites[i].set_frame(CARD_BACK_FRAME)

func discard_all_cards():
	cards = []
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		cardSprites[i].visible = false

func exchange_cards(oldCard, newCard):
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, cards.size()):
		if cards[i] == oldCard:
			cards[i] = newCard
			if cardSprites[i].get_frame() == oldCard:
				cardSprites[i].set_frame(newCard)
			cardSprites[i].position.y = 48

func get_raised_card():
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, cards.size()):
		if cardSprites[i].position.y < 48:
			return cards[i]
	return null


func _input(ev):
	if ev is InputEventMouseButton:
		var cardSprites = [$Card1, $Card2, $Card3]
		var clickedIndex = null
		for i in range(0, cardSprites.size()):
			var s = cardSprites[i]
			if s.get_rect().has_point(s.to_local(ev.position)):
				clickedIndex = i
				cardSprites[i].position.y = 32
		for i in range(0, cardSprites.size()):
			if clickedIndex != i and (clickedIndex != null or not ev.pressed):
				cardSprites[i].position.y = 48
