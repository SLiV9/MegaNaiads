extends Node2D

class_name Hand

var cards = []
var public_card_history = []
var revealed = false
var has_passed = false


func _ready():
	hide_cards()

func hide_cards():
	revealed = false
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		cardSprites[i].visible = false

func reveal_cards(delay: float):
	revealed = true
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, 3):
		if i < cards.size():
			cardSprites[i].set_frame(cards[i])
			if delay >= 0:
				cardSprites[i].deal(delay)
				delay += 0.05
		else:
			cardSprites[i].visible = false

func deal_card(card: int, delay: float):
	var i = cards.size()
	cards.push_back(card)
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	if revealed:
		cardSprites[i].set_frame(card)
	else:
		cardSprites[i].set_frame(Card.BACK_FRAME)
	cardSprites[i].deal(delay)

func discard_all_cards():
	cards = []
	public_card_history = []
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for i in range(0, 6):
		cardSprites[i].visible = false
	has_passed = false

func exchange_cards(oldCard, newCard, delay: float):
	var cardSprites = [$Card1, $Card2, $Card3]
	for i in range(0, cards.size()):
		if cards[i] == oldCard:
			cards[i] = newCard
			add_to_public_card_history(oldCard)
			add_to_public_card_history(newCard)
			if cardSprites[i].get_frame() == oldCard:
				cardSprites[i].set_frame(newCard)
			cardSprites[i].position.y = 48
			if delay >= 0:
				cardSprites[i].deal(delay)

func get_raised_card():
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for i in range(0, cards.size()):
		if cardSprites[i].position.y < 48:
			return cards[i]
	return null

func add_to_public_card_history(card):
	if public_card_history.find(card) < 0:
		public_card_history.push_back(card)


func become_table():
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for s in cardSprites:
		s.is_on_table = true

func shuffle_deck():
	$ShuffleSound.play()

func focus():
	$PlayerTurnSound.play()


func detect_invalid_card_click(ev: InputEventMouseButton):
	var cardSprites = [$Card1, $Card2, $Card3, $Card4, $Card5, $Card6]
	for i in range(0, cardSprites.size()):
		var s = cardSprites[i]
		if s.visible and s.get_rect().has_point(s.to_local(ev.position)):
			s.get_node('InvalidClickSound').play()
			return true
	return false

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
				cardSprites[i].play_click_sound_now()
		for i in range(0, cardSprites.size()):
			if clickedIndex != i and (clickedIndex != null or not ev.pressed):
				cardSprites[i].position.y = 48
