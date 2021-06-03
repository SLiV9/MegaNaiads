extends Node2D


const NUM_NORMAL_CARDS = 32
const NUM_CARDS = 36

const MAX_TURNS_PER_PLAYER = 11

const NUMBER_COLOR = "#dc8b58"

enum STATE {
	START,
	PLAYER,
	BOT_LEFT,
	BOT_MID,
	BOT_RIGHT,
	END
}

var state = STATE.START
var turn = 0
var has_passed = false
var ai_has_passed = [false, false, false]
var unused_faces = []
var unused_strategies = []
var text_lines = ["", "", "", "", "", ""]

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$StrangerLeft.become_innkeeper()
	$StrangerLeft.reveal_identity()
	unused_faces = range(0, 10)
	unused_strategies = range(0, 11)
	unused_strategies.remove(unused_strategies.find($StrangerLeft.strategy))
	unused_faces.shuffle()
	unused_strategies.shuffle()
	add_stranger($StrangerMid)
	$StrangerMid.reveal_identity()
	add_stranger($StrangerRight)
	$StrangerRight.reveal_identity()
	$StrangerLeft/Emote.visible = false
	$StrangerMid/Emote.visible = false
	$StrangerRight/Emote.visible = false
	$PlayerHand.discard_all_cards()
	$Table.discard_all_cards()
	$StrangerLeft/Hand.discard_all_cards()
	$StrangerMid/Hand.discard_all_cards()
	$StrangerRight/Hand.discard_all_cards()
	disable_player_controls()
	set_process_input(true)

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			match state:
				STATE.PLAYER:
					if not has_passed:
						var ownCard = $PlayerHand.get_raised_card()
						var tableCard = $Table.get_raised_card()
						if ownCard != null and tableCard != null:
							add_text_line("You took " + card_name(tableCard) +
								", discarding " + card_name(ownCard) + ".")
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
							if ai_has_passed.min() == true:
								has_passed = true
								$PlayerHand.has_passed = true
							advance_state()
				STATE.BOT_LEFT:
					enact_ai_action(0, $StrangerLeft)
					advance_state()
				STATE.BOT_MID:
					enact_ai_action(1, $StrangerMid)
					advance_state()
				STATE.BOT_RIGHT:
					enact_ai_action(2, $StrangerRight)
					advance_state()
				STATE.END:
					reveal_and_score()
					state = STATE.START
				STATE.START:
					deal_cards()
					start_playing()
		else:
			match state:
				STATE.PLAYER:
					if has_passed:
						state = STATE.BOT_LEFT
					elif $PassButton.pressed:
						has_passed = true
						$PlayerHand.has_passed = true
						add_text_line("You locked in " +
							"[color=" + NUMBER_COLOR + "]" +
							str(evaluate_hand($PlayerHand)) +
							"[/color]" +
							".")
						advance_state()
					elif $SwapButton.pressed:
						add_text_line("You took " +
							card_name($Table.cards[0]) + ", " +
							card_name($Table.cards[1]) + " and " +
							card_name($Table.cards[2]) + ", locking in " +
							"[color=" + NUMBER_COLOR + "]" +
							str(evaluate_hand($Table)) +
							"[/color]" +
							".")
						add_text_line("You discarded " +
							card_name($PlayerHand.cards[0]) + ", " +
							card_name($PlayerHand.cards[1]) + " and " +
							card_name($PlayerHand.cards[2]) + ".")
						for i in range(0, 3):
							var ownCard = $PlayerHand.cards[i]
							var tableCard = $Table.cards[i]
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
						has_passed = true
						$PlayerHand.has_passed = true
						advance_state()
				STATE.BOT_LEFT:
					pass
				STATE.BOT_MID:
					pass
				STATE.BOT_RIGHT:
					pass
				STATE.END:
					pass

func deal_cards():
	$PlayerHand.discard_all_cards()
	$Table.discard_all_cards()
	$StrangerLeft/Hand.discard_all_cards()
	$StrangerMid/Hand.discard_all_cards()
	$StrangerRight/Hand.discard_all_cards()
	var deck = range(0, NUM_NORMAL_CARDS)
	deck.shuffle()
	var i = 0
	# TODO cheating with Prince, Forger, Artist, Swindler, Trickster
	$PlayerHand.reveal_cards()
	$Table.reveal_cards()
	$StrangerLeft/Hand.hide_cards()
	$StrangerMid/Hand.hide_cards()
	$StrangerRight/Hand.hide_cards()
	for _t in range(0, 3):
		$PlayerHand.deal_card(deck[i])
		i += 1
		$StrangerLeft/Hand.deal_card(deck[i])
		i += 1
		$StrangerMid/Hand.deal_card(deck[i])
		i += 1
		$StrangerRight/Hand.deal_card(deck[i])
		i += 1
		$Table.deal_card(deck[i])
		i += 1
	# TODO cheating with Brute

func start_playing():
	var startingStates = [STATE.PLAYER, STATE.BOT_LEFT, STATE.BOT_MID,
		STATE.BOT_RIGHT]
	state = startingStates[randi() % startingStates.size()]
	turn = 0
	has_passed = false
	ai_has_passed = [false, false, false]
	disable_player_controls()
	match state:
		STATE.PLAYER:
			enable_player_controls()
			add_text_line("You start this round.")
		STATE.BOT_LEFT:
			var name = $StrangerLeft.get_name_bbcode()
			add_text_line("The " + name +  " starts this round.")
		STATE.BOT_MID:
			var name = $StrangerMid.get_name_bbcode()
			add_text_line("The " + name +  " starts this round.")
		STATE.BOT_RIGHT:
			var name = $StrangerRight.get_name_bbcode()
			add_text_line("The " + name +  " starts this round.")
		STATE.END:
			pass

func advance_state():
	if has_passed and ai_has_passed.min() == true:
		disable_player_controls()
		state = STATE.END
		return
	match state:
		STATE.PLAYER:
			disable_player_controls()
			turn += 1
			state = STATE.BOT_LEFT
			if ai_has_passed[0]:
				advance_state()
		STATE.BOT_LEFT:
			state = STATE.BOT_MID
			if ai_has_passed[1]:
				advance_state()
		STATE.BOT_MID:
			state = STATE.BOT_RIGHT
			if ai_has_passed[2]:
				advance_state()
		STATE.BOT_RIGHT:
			enable_player_controls()
			state = STATE.PLAYER
			if has_passed:
				advance_state()
		_:
			pass

func enable_player_controls():
	if has_passed:
		return
	$PlayerHand.set_process_input(true)
	$Table.set_process_input(true)
	$PassButton.text = "LOCK IN (" + str(evaluate_hand($PlayerHand)) + ")"
	$PassButton.visible = true
	$SwapButton.text = "TAKE ALL (" + str(evaluate_hand($Table)) + ")"
	$SwapButton.visible = true

func disable_player_controls():
	$PlayerHand.set_process_input(false)
	$Table.set_process_input(false)
	$PassButton.visible = false
	$SwapButton.visible = false

func reveal_and_score():
	var lowest_value = 30.0;
	var player_value = evaluate_hand($PlayerHand)
	var values = []
	var bots = [$StrangerLeft, $StrangerMid, $StrangerRight]
	for i in range(0, bots.size()):
		var bot: Stranger = bots[i]
		var hand: Hand = bot.get_node("Hand")
		var value = evaluate_hand(hand)
		if hand.revealed:
			add_text_line("The " + bot.get_name_bbcode() + " got " +
				"[color=" + NUMBER_COLOR + "]" + str(value) + "[/color]" +
				".")
		else:
			if bot.strategy == bot.STRATEGY.ILLUSIONIST and value <= 30.0:
				perform_illusion(hand)
				value = evaluate_hand(hand)
			hand.reveal_cards()
			add_text_line("The " + bot.get_name_bbcode() + " reveals " +
				"[color=" + NUMBER_COLOR + "]" + str(value) + "[/color]" +
				".")
		values.push_back(value)
	add_text_line("You got " +
		"[color=" + NUMBER_COLOR + "]" + str(player_value) + "[/color]" +
		".")

func prepare_brain_input(input, ownHand: Hand, isSpy: bool,
		leftHand: Hand, midHand: Hand, rightHand: Hand):
	input.resize((1 + 4 + 4 + 1) * NUM_CARDS)
	for i in range(0, input.size()):
		input[i] = 0
	for i in range(0, 3):
		input[$Table.cards[i]] = 1
		input[1 * NUM_CARDS + ownHand.cards[i]] = 1
		input[2 * NUM_CARDS + leftHand.cards[i]] = 1
		input[3 * NUM_CARDS + midHand.cards[i]] = 1
		input[4 * NUM_CARDS + rightHand.cards[i]] = 1
		input[5 * NUM_CARDS + ownHand.cards[i]] = 1
		input[6 * NUM_CARDS + leftHand.cards[i]] = (isSpy or
			leftHand.has_been_public[i])
		input[7 * NUM_CARDS + midHand.cards[i]] = (isSpy or
			midHand.has_been_public[i])
		input[8 * NUM_CARDS + rightHand.cards[i]] = (isSpy or
			rightHand.has_been_public[i])
	input[9 * NUM_CARDS + 0] = 1
	# TODO change this for the boss battle
	input[9 * NUM_CARDS + 1] = 1
	input[9 * NUM_CARDS + 2] = 1
	input[9 * NUM_CARDS + 3] = 1
	input[9 * NUM_CARDS + 4] = 0
	input[9 * NUM_CARDS + 5] = leftHand.has_passed
	input[9 * NUM_CARDS + 6] = midHand.has_passed
	input[9 * NUM_CARDS + 7] = rightHand.has_passed
	input[9 * NUM_CARDS + 8] = ownHand == $PlayerHand
	input[9 * NUM_CARDS + 9] = leftHand == $PlayerHand
	input[9 * NUM_CARDS + 10] = midHand == $PlayerHand
	input[9 * NUM_CARDS + 11] = rightHand == $PlayerHand

func enact_ai_action(ai_index: int, stranger: Stranger):
	var hand = stranger.get_node("Hand")
	if ai_has_passed[ai_index]:
		return
	var brain = stranger.get_node("Brain")
	if stranger.strategy == stranger.STRATEGY.DRUNK:
		brain.wantsToPass = (randi() % 100 < 20)
		brain.wantsToSwap = (randi() % 100 < 10)
		brain.ownCard = hand.cards[randi() % hand.cards.size()]
		brain.tableCard = $Table.cards[randi() % $Table.cards.size()]
	else:
		var allHands = [$StrangerLeft/Hand, $StrangerMid/Hand,
			$StrangerRight/Hand, $PlayerHand]
		prepare_brain_input(brain.input, hand,
			stranger.strategy == stranger.STRATEGY.SPY,
			allHands[(ai_index + 1) % 4],
			allHands[(ai_index + 2) % 4],
			allHands[(ai_index + 3) % 4])
		brain.evaluate()
	if brain.wantsToPass or turn >= MAX_TURNS_PER_PLAYER:
		add_text_line("The " + stranger.get_name_bbcode() +
			" locks in their hand.")
		ai_has_passed[ai_index] = true
		hand.has_passed = true
	elif brain.wantsToSwap:
		add_text_line("The " + stranger.get_name_bbcode() + " takes " +
			card_name($Table.cards[0]) + ", " +
			card_name($Table.cards[1]) + " and " +
			card_name($Table.cards[2]) + ", locking in " +
			"[color=" + NUMBER_COLOR + "]" +
			str(evaluate_hand($Table)) +
			"[/color]" +
			".")
		add_text_line("The " + stranger.get_name_bbcode() + " discarded " +
			card_name(hand.cards[0]) + ", " +
			card_name(hand.cards[1]) + " and " +
			card_name(hand.cards[2]) + ".")
		for i in range(0, 3):
			var ownCard = hand.cards[i]
			var tableCard = $Table.cards[i]
			hand.exchange_cards(ownCard, tableCard)
			$Table.exchange_cards(tableCard, ownCard)
			hand.reveal_cards()
		ai_has_passed[ai_index] = true
		hand.has_passed = true
	else:
		var ownCard = brain.ownCard
		var tableCard = brain.tableCard
		add_text_line("The " + stranger.get_name_bbcode() + " takes " +
			card_name(tableCard) + ", discarding " + card_name(ownCard) + ".")
		hand.exchange_cards(ownCard, tableCard)
		$Table.exchange_cards(tableCard, ownCard)
		if (has_passed and ai_has_passed[(ai_index + 1) % 3] and
				ai_has_passed[(ai_index + 2) % 3]):
			ai_has_passed[ai_index] = true
			hand.has_passed = true

func add_stranger(stranger: Stranger):
	var face = unused_faces[randi() % unused_faces.size()]
	var strategy = unused_strategies[randi() % unused_strategies.size()]
	stranger.strategy = strategy
	stranger.become_stranger(face)
	unused_faces.remove(unused_faces.find(face))
	unused_strategies.remove(unused_strategies.find(strategy))

func add_text_line(line):
	text_lines.pop_front()
	text_lines.push_back(line)
	var bbcode_text = text_lines[0]
	for i in range(1, text_lines.size()):
		bbcode_text += "\n" + text_lines[i]
	$TextBox/Content.bbcode_text = bbcode_text

func card_name(card: int):
	var suit = card % 4
	var face = card / 4
	var FACE_NAMES = ["Seven", "Eight", "Nine", "Ten",
		"Jack", "Queen", "King", "Ace"]
	var SUIT_NAMES = ["Clubs", "Diamonds", "Hearts", "Spades"]
	if face < 8:
		return "the " + FACE_NAMES[face] + " of " + SUIT_NAMES[suit]
	else:
		match (card - NUM_NORMAL_CARDS):
			0: return "an Ace of Clubs"
			1: return "a Joker"
			2: return "a Twelve of Hearts"
			3: return "an Ace of Spades"
			_: return "card #" + str(card)

func perform_illusion(hand: Hand):
	var valueOfHearts = 0
	var valueOfSpades = 0
	var diamondFace = null
	var clubFace = null
	var FACE_VALUES = [7, 8, 9, 10, 10, 10, 10, 11]
	for i in range(0, 3):
		var card = hand.cards[i]
		var suit = card % 4
		var face = card / 4
		if face < FACE_VALUES.size():
			var face_value = FACE_VALUES[face]
			match suit:
				0: clubFace = face
				1: diamondFace = face
				2: valueOfHearts += face_value
				3: valueOfSpades += face_value
		else:
			match (card - NUM_NORMAL_CARDS):
				2: valueOfHearts += 12
				_: pass
	if valueOfHearts >= 14 and diamondFace != null:
		if diamondFace < FACE_VALUES.size() - 1:
			var oldCard = diamondFace * 4 + 1
			var newCard = diamondFace * 4 + 2
			hand.exchange_cards(oldCard, newCard)
	elif valueOfSpades >= 14 and clubFace != null:
		if clubFace < FACE_VALUES.size() - 1:
			var oldCard = clubFace * 4 + 0
			var newCard = clubFace * 4 + 3
			hand.exchange_cards(oldCard, newCard)

func evaluate_hand(hand: Hand):
	return $Game.evaluate_hand(hand.cards[0], hand.cards[1], hand.cards[2])
