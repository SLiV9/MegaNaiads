extends Node2D


const NUM_NORMAL_CARDS = 32
const NUM_CARDS = 36

const MAX_TURNS_PER_PLAYER = 9
const MIN_TURNS_PER_PLAYER = 5
const MAX_TURNS_AFTER_PLAYER = 2

const NUMBER_COLOR = "#dc8b58"

enum STATE {
	START,
	PLAYER,
	BOT_LEFT,
	BOT_MID,
	BOT_RIGHT,
	END,
	ACCUSATIONS,
	ACCUSE,
	CULL_DEFEATED,
	ADD_FRESH_BLOOD,
	GAME_OVER
}

var state = STATE.START
var turn = 0
var player_pass_turn = -1
var ai_has_passed = [false, false, false]
var unused_faces = []
var unused_strategies = []
var text_lines = ["", "", "", "", "", ""]
var player_lives = 3
var current_accusation = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$StrangerLeft.become_innkeeper()
	unused_faces = range(0, 10)
	unused_strategies = range(0, 11)
	unused_strategies.remove(unused_strategies.find($StrangerLeft.strategy))
	unused_faces.shuffle()
	unused_strategies.shuffle()
	add_stranger($StrangerMid)
	add_stranger($StrangerRight)
	$StrangerLeft/Emote.visible = false
	$StrangerMid/Emote.visible = false
	$StrangerRight/Emote.visible = false
	clear_table()
	disable_player_controls()
	set_process_input(true)

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			match state:
				STATE.PLAYER:
					if player_pass_turn < 0:
						var ownCard = $PlayerHand.get_raised_card()
						var tableCard = $Table.get_raised_card()
						if ownCard != null and tableCard != null:
							add_text_line("You took " + card_name(tableCard) +
								", discarding " + card_name(ownCard) + ".")
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
							if ai_has_passed.min() == true:
								player_pass_turn = turn
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
				STATE.START:
					deal_cards()
					start_playing()
				STATE.ACCUSATIONS:
					if not $NoAccusationsButton.visible:
						clear_table()
						$NoAccusationsButton.visible = true
						for stranger in [$StrangerLeft, $StrangerMid,
								$StrangerRight]:
							stranger.accused = false
							if not stranger.revealed:
								stranger.get_node(
									"AccusationButton").visible = true
						add_text_line("Do you want to accuse anyone?")
				STATE.ACCUSE:
					var accused = null
					for bot in [$StrangerLeft, $StrangerMid,
							$StrangerRight]:
						if bot.accused == true:
							accused = bot
					var x = $PlayerHand.get_raised_card()
					if accused != null and x != null:
						if $AccuseButton.visible == false:
							$AccuseButton.visible = true
							$DoNotAccuseButton.visible = true
						current_accusation = x
						replace_text_line(Stranger.get_strategy_bbcode(x))
				STATE.CULL_DEFEATED:
					var defeats = 0
					for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
						if bot.defeated:
							var defeat_quote = bot.get_defeat_quote()
							if defeat_quote != null:
								add_text_line(defeat_quote)
							add_text_line("The " + bot.get_name_bbcode() +
								" leaves the table.")
							defeats += 1
					if defeats > unused_strategies.size():
						add_text_line("You win!")
						# TODO more satisfying ending with boss battle
						state = STATE.GAME_OVER
						return
					state = STATE.ADD_FRESH_BLOOD
				STATE.ADD_FRESH_BLOOD:
					for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
						if bot.defeated:
							if unused_strategies.size() > 0:
								add_stranger(bot)
							else:
								add_text_line("You win!")
								# TODO more satisfying ending with boss battle
								state = STATE.GAME_OVER
								return
					state = STATE.START
				STATE.GAME_OVER:
					pass
		else:
			match state:
				STATE.PLAYER:
					if player_pass_turn >= 0:
						state = STATE.BOT_LEFT
					elif $PassButton.pressed:
						player_pass_turn = turn
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
						player_pass_turn = turn
						$PlayerHand.has_passed = true
						advance_state()
				STATE.ACCUSATIONS:
					if $NoAccusationsButton.pressed:
						if current_accusation != null:
							replace_text_line("You did not accuse anyone else.")
						else:
							replace_text_line("You did not accuse anyone.")
						current_accusation = null
						disable_player_controls()
						state = STATE.START
						return
					for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
						var button = bot.get_node("AccusationButton")
						if button.visible && button.pressed:
							bot.accused = true
							state = STATE.ACCUSE
							$PlayerHand.discard_all_cards()
							var accusations = []
							for stranger in [$StrangerLeft, $StrangerMid,
									$StrangerRight]:
								if not stranger.revealed:
									accusations.push_back(
										Stranger.get_accusation_card(
											stranger.strategy))
							for i in range(0, 3):
								if i < unused_strategies.size():
									accusations.push_back(
										Stranger.get_accusation_card(
											unused_strategies[i]))
							accusations.shuffle()
							current_accusation = null
							for accusation in accusations:
								$PlayerHand.deal_card(accusation)
							disable_player_controls()
							$PlayerHand.set_process_input(true)
							break
				STATE.ACCUSE:
					if $AccuseButton.pressed:
						var accused = null
						for bot in [$StrangerLeft, $StrangerMid,
								$StrangerRight]:
							if bot.accused == true:
								accused = bot
						var x = current_accusation
						$PlayerHand.discard_all_cards()
						if accused != null and x != null:
							replace_text_line("You've accused the " +
								accused.get_name_bbcode() + " of being " +
								Stranger.get_accusation_bbcode(x) + "!")
							if x == Stranger.get_accusation_card(
									accused.strategy):
								accused.reveal_identity()
								var reveal_quote = accused.get_reveal_quote()
								if reveal_quote:
									add_text_line(reveal_quote)
								else:
									add_text_line("You are correct!")
							else:
								var reject_quote = accused.get_reject_quote()
								if reject_quote:
									add_text_line(reject_quote)
								else:
									add_text_line("You are wrong.")
								if accused.strategy == Stranger.STRATEGY.KNIGHT:
									accused.reveal_identity()
									add_text_line("The " +
										accused.get_name_bbcode() +
										" draws their sword, swings and " +
										" cuts your head clean off.")
									add_text_line("Game over.")
									disable_player_controls()
									state = STATE.GAME_OVER
									return
								else:
									player_lives -= 1
									if player_lives > 0:
										add_text_line("You have " +
											str(player_lives) + " lives left.")
										state = STATE.ACCUSATIONS
									else:
										add_text_line("Game over.")
										disable_player_controls()
										state = STATE.GAME_OVER
										return
						disable_player_controls()
						state = STATE.ACCUSATIONS
					elif $DoNotAccuseButton.pressed:
						$PlayerHand.discard_all_cards()
						disable_player_controls()
						state = STATE.ACCUSATIONS
				_:
					pass

func clear_table():
	$PlayerHand.discard_all_cards()
	$Table.discard_all_cards()
	$StrangerLeft/Hand.discard_all_cards()
	$StrangerMid/Hand.discard_all_cards()
	$StrangerRight/Hand.discard_all_cards()

func deal_cards():
	clear_table()
	var deck = range(0, NUM_NORMAL_CARDS)
	deck.shuffle()
	var i = 0
	$PlayerHand.reveal_cards()
	$Table.reveal_cards()
	$StrangerLeft/Hand.hide_cards()
	$StrangerMid/Hand.hide_cards()
	$StrangerRight/Hand.hide_cards()
	var bots = [$StrangerLeft, $StrangerMid, $StrangerRight]
	var trickeries = range(0, 3)
	trickeries.shuffle()
	for t in range(0, 3):
		$PlayerHand.deal_card(deck[i])
		i += 1
		for bot in bots:
			match bot.strategy:
				Stranger.STRATEGY.PRINCE:
					var trickj = null
					for j in range(i, deck.size()):
						var face = deck[j] / 4
						if ((t == trickeries[0] and face == 5)
								or (t == trickeries[1] and face == 6)):
							trickj = j
							break
					if trickj != null and trickj > i:
						var tmp = deck[i]
						deck[i] = deck[trickj]
						deck[trickj] = tmp
				Stranger.STRATEGY.FORGER:
					if t == trickeries[0]:
						deck[i] = NUM_NORMAL_CARDS + 3 * (randi() % 2)
				Stranger.STRATEGY.TRICKSTER:
					if t == trickeries[0]:
						deck[i] = NUM_NORMAL_CARDS + 1
				Stranger.STRATEGY.ARTIST:
					if t == trickeries[0]:
						deck[i] = NUM_NORMAL_CARDS + 2
				Stranger.STRATEGY.SWINDLER:
					if (deck[i] / 4) == 0:
						var trickj = null
						for j in range(i + 1, deck.size()):
							if deck[j] / 4 == 3:
								trickj = j
								break
						if trickj != null and trickj > i:
							var tmp = deck[i]
							deck[i] = deck[trickj]
							deck[trickj] = tmp
				_: pass
			bot.get_node("Hand").deal_card(deck[i])
			i += 1
		$Table.deal_card(deck[i])
		i += 1
	for u in range(0, bots.size()):
		var bot: Stranger = bots[u]
		if bot.strategy == Stranger.STRATEGY.BRUTE:
			var bruteHand: Hand = bot.get_node("Hand")
			var bruteValue = evaluate_hand(bruteHand)
			var others = range(0, bots.size())
			others.remove(others.find(u))
			others.shuffle()
			for v in others:
				var otherHand: Hand = bots[v].get_node("Hand")
				if evaluate_hand(otherHand) > bruteValue:
					for t in range(0, 3):
						var ownCard = bruteHand.cards[t]
						var otherCard = otherHand.cards[t]
						bruteHand.exchange_cards(ownCard, otherCard)
						otherHand.exchange_cards(otherCard, ownCard)
					break

func start_playing():
	var startingStates = [STATE.PLAYER, STATE.BOT_LEFT, STATE.BOT_MID,
		STATE.BOT_RIGHT]
	state = startingStates[randi() % startingStates.size()]
	turn = 0
	player_pass_turn = -1
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

func advance_state():
	if player_pass_turn >= 0 and ai_has_passed.min() == true:
		disable_player_controls()
		state = STATE.END
		return
	match state:
		STATE.PLAYER:
			var value = evaluate_hand($PlayerHand)
			if value >= 31.0:
				add_text_line("You reveal " +
					"[color=" + NUMBER_COLOR + "]" +
					str(value) + "[/color]" +
					"!")
				disable_player_controls()
				state = STATE.END
				return
			disable_player_controls()
			turn += 1
			state = STATE.BOT_LEFT
			if ai_has_passed[0]:
				advance_state()
		STATE.BOT_LEFT:
			var value = evaluate_hand($StrangerLeft/Hand)
			if value >= 31.0:
				add_text_line("The " + $StrangerLeft.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					str(value) + "[/color]" +
					"!")
				$StrangerLeft/Hand.reveal_cards()
				var win_quote = $StrangerLeft.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				state = STATE.END
				return
			state = STATE.BOT_MID
			if ai_has_passed[1]:
				advance_state()
		STATE.BOT_MID:
			var value = evaluate_hand($StrangerMid/Hand)
			if value >= 31.0:
				add_text_line("The " + $StrangerMid.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					str(value) + "[/color]" +
					"!")
				$StrangerMid/Hand.reveal_cards()
				var win_quote = $StrangerMid.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				state = STATE.END
				return
			state = STATE.BOT_RIGHT
			if ai_has_passed[2]:
				advance_state()
		STATE.BOT_RIGHT:
			var value = evaluate_hand($StrangerRight/Hand)
			if value >= 31.0:
				add_text_line("The " + $StrangerRight.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					str(value) + "[/color]" +
					"!")
				$StrangerRight/Hand.reveal_cards()
				var win_quote = $StrangerRight.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				state = STATE.END
				return
			enable_player_controls()
			state = STATE.PLAYER
			if player_pass_turn >= 0:
				advance_state()
		_:
			pass

func enable_player_controls():
	if player_pass_turn >= 0:
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
	$NoAccusationsButton.visible = false
	$AccuseButton.visible = false
	$DoNotAccuseButton.visible = false
	for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
		bot.get_node("AccusationButton").visible = false

func reveal_and_score():
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
	values.push_back(player_value)
	var lowest_value = values.min()
	var highest_value = values.max()
	if lowest_value == highest_value:
		add_text_line("It's a tie!")
		state = STATE.START
	elif player_value == lowest_value:
		player_lives -= 1
		if player_lives > 0:
			add_text_line("You have " + str(player_lives) + " lives left.")
			state = STATE.ACCUSATIONS
		else:
			add_text_line("Game over.")
			state = STATE.GAME_OVER
	else:
		var defeats = 0
		for i in range(0, 3):
			var bot = bots[i]
			if bot.revealed and values[i] == lowest_value:
				bot.defeated = true
				defeats += 1
		if defeats > 0:
			state = STATE.CULL_DEFEATED
		elif player_value == highest_value:
			state = STATE.ACCUSATIONS
		else:
			state = STATE.START

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
	if stranger.strategy == Stranger.STRATEGY.DRUNK:
		brain.wantsToPass = (randi() % 100 < 20)
		brain.wantsToSwap = (randi() % 100 < 10)
		brain.ownCard = hand.cards[randi() % hand.cards.size()]
		brain.tableCard = $Table.cards[randi() % $Table.cards.size()]
	else:
		var allHands = [$StrangerLeft/Hand, $StrangerMid/Hand,
			$StrangerRight/Hand, $PlayerHand]
		prepare_brain_input(brain.input, hand,
			stranger.strategy == Stranger.STRATEGY.SPY,
			allHands[(ai_index + 1) % 4],
			allHands[(ai_index + 2) % 4],
			allHands[(ai_index + 3) % 4])
		brain.evaluate()
	if (brain.wantsToPass
			or (turn >= MAX_TURNS_PER_PLAYER
				and (randi() % 2) == 0)
			or (player_pass_turn >= 0
				and turn >= player_pass_turn + MAX_TURNS_AFTER_PLAYER
				and turn >= MIN_TURNS_PER_PLAYER)):
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
		if (player_pass_turn >= 0 and ai_has_passed[(ai_index + 1) % 3] and
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
	add_text_line(stranger.get_introduction_name_bbcode() +
		" sits down at your table.")

func add_text_line(line):
	text_lines.pop_front()
	text_lines.push_back(line)
	var bbcode_text = text_lines[0]
	for i in range(1, text_lines.size()):
		bbcode_text += "\n" + text_lines[i]
	$TextBox/Content.bbcode_text = bbcode_text

func replace_text_line(line):
	text_lines.pop_back()
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
