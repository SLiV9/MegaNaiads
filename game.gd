extends Node2D


const NUM_NORMAL_CARDS = 32
const NUM_CARDS = 36

const NUMBER_COLOR = "#dc8b58"

enum STATE {
	PLAYER,
	BOT_LEFT,
	BOT_MID,
	BOT_RIGHT,
	END
}

var state = STATE.PLAYER
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
	var deck = range(0, NUM_NORMAL_CARDS)
	deck.shuffle()
	var i = 0
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
	set_process_input(true)
	start_game()

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			match state:
				STATE.PLAYER:
					if not has_passed:
						var ownCard = $PlayerHand.get_raised_card()
						var tableCard = $Table.get_raised_card()
						if ownCard != null and tableCard != null:
							add_text_line("You take " + card_name(tableCard) +
								", discarding " + card_name(ownCard) + ".")
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
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
					pass
		else:
			match state:
				STATE.PLAYER:
					if has_passed:
						state = STATE.BOT_LEFT
					elif $PassButton.pressed:
						has_passed = true
						add_text_line("You lock in " +
							"[color=" + NUMBER_COLOR + "]" +
							str(evaluate_hand($PlayerHand)) +
							"[/color]" +
							".")
						advance_state()
					elif $SwapButton.pressed:
						add_text_line("You take " +
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
						advance_state()
				STATE.BOT_LEFT:
					pass
				STATE.BOT_MID:
					pass
				STATE.BOT_RIGHT:
					pass
				STATE.END:
					pass

func start_game():
	var startingStates = [STATE.PLAYER, STATE.BOT_LEFT, STATE.BOT_MID,
		STATE.BOT_RIGHT]
	state = startingStates[randi() % startingStates.size()]
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
		STATE.END:
			pass

func enable_player_controls():
	if has_passed:
		return
	$PlayerHand.set_process_input(true)
	$Table.set_process_input(true)
	$PassButton.visible = true
	$SwapButton.visible = true

func disable_player_controls():
	$PlayerHand.set_process_input(false)
	$Table.set_process_input(false)
	$PassButton.visible = false
	$SwapButton.visible = false

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
		# TODO visiblity
		input[6 * NUM_CARDS + leftHand.cards[i]] = 0
		input[7 * NUM_CARDS + midHand.cards[i]] = 0
		input[8 * NUM_CARDS + rightHand.cards[i]] = 0
	input[9 * NUM_CARDS + 0] = 1
	# TODO do these players exist?
	input[9 * NUM_CARDS + 1] = 1
	input[9 * NUM_CARDS + 2] = 1
	input[9 * NUM_CARDS + 3] = 1
	# TODO who has passed?
	input[9 * NUM_CARDS + 4] = 0
	input[9 * NUM_CARDS + 5] = 0
	input[9 * NUM_CARDS + 6] = 0
	input[9 * NUM_CARDS + 7] = 0
	# TODO who is the player?
	input[9 * NUM_CARDS + 8] = 0
	input[9 * NUM_CARDS + 9] = 0
	input[9 * NUM_CARDS + 10] = 0
	input[9 * NUM_CARDS + 11] = 0

func enact_ai_action(ai_index: int, stranger: Stranger):
	var hand = stranger.get_node("Hand")
	if ai_has_passed[ai_index]:
		return
	var brain = stranger.get_node("Brain")
	if stranger.is_drunk():
		brain.wantsToPass = (randi() % 100 < 20)
		brain.wantsToSwap = (randi() % 100 < 10)
		brain.ownCard = hand.cards[randi() % hand.cards.size()]
		brain.tableCard = $Table.cards[randi() % $Table.cards.size()]
	else:
		# TODO determine hands
		prepare_brain_input(brain.input, hand, stranger.is_spy(),
			$StrangerLeft/Hand, $StrangerMid/Hand, $StrangerRight/Hand)
		brain.evaluate()
	if brain.wantsToPass:
		add_text_line("The " + stranger.get_name_bbcode() +
			" locks in their hand.")
		ai_has_passed[ai_index] = true
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
	else:
		var ownCard = brain.ownCard
		var tableCard = brain.tableCard
		add_text_line("The " + stranger.get_name_bbcode() + " takes " +
			card_name(tableCard) + ", discarding " + card_name(ownCard) + ".")
		hand.exchange_cards(ownCard, tableCard)
		$Table.exchange_cards(tableCard, ownCard)

func add_stranger(stranger: Stranger):
	var face = unused_faces[randi() % unused_faces.size()]
	var strategy = unused_strategies[randi() % unused_strategies.size()]
	stranger.become_stranger(face, strategy)
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

func evaluate_hand(hand: Hand):
	return $Game.evaluate_hand(hand.cards[0], hand.cards[1], hand.cards[2])
