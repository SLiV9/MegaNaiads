extends Node2D


const NUM_NORMAL_CARDS = 32
const NUM_CARDS = 36

const MAX_TURNS_PER_PLAYER = 9
const MIN_TURNS_PER_PLAYER = 5
const MAX_TURNS_AFTER_PLAYER = 2

const NUMBER_COLOR = "#dc8b58"

enum STATE {
	INTRO1,
	INTRO2,
	ASK_TUTORIAL,
	TUTORIAL0,
	TUTORIAL1,
	TUTORIAL2,
	TUTORIAL3,
	TUTORIAL4,
	TUTORIAL5,
	TUTORIAL6,
	TUTORIAL7,
	TUTORIAL8,
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


var state = STATE.INTRO1
var turn = 0
var player_pass_turn = -1
var ai_has_passed = [false, false, false]
var unused_faces = []
var unused_strategies = []
var text_lines = ["", "", "", "", "", ""]
var player_lives = 3
var current_accusation = null
var boss_battle = false
var boss_revealed = false
var animation_delay = null
var player_controls_delay = null
var player_accusation_controls_delay = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$StrangerLeft.become_innkeeper()
	unused_faces = range(0, 10)
	unused_strategies = range(0, 11)
	unused_strategies.remove(unused_strategies.find($StrangerLeft.strategy))
	unused_strategies.shuffle()
	$StrangerLeft.visible = false
	$StrangerMid.visible = false
	$StrangerRight.visible = false
	$StrangerLeft/Emote.visible = false
	$StrangerMid/Emote.visible = false
	$StrangerRight/Emote.visible = false
	$Table.become_table()
	clear_table()
	match (randi() % 4):
		0: add_text_line("The sound of crackling fire" +
			" greets you as you enter the Inn." +
			" You find an empty table near the back.")
		1: add_text_line("The sound of drunken merriment" +
			" greets you as you enter the Inn." +
			" You find an empty table near the back.")
		2: add_text_line("The sound of hushed voices" +
			" greets you as you enter the Inn." +
			" You find an empty table near the back.")
		3: add_text_line("The sound of laughter and games" +
			" greets you as you enter the Inn." +
			" You find an empty table near the back.")
	disable_player_controls()
	set_process_input(true)

func _process(delta):
	if animation_delay != null:
		animation_delay -= delta
		if animation_delay < 0:
			animation_delay = null
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if player_controls_delay != null:
		player_controls_delay -= delta
		if player_controls_delay < 0:
			player_controls_delay = null
			enable_player_controls(-1)
	if player_accusation_controls_delay != null:
		player_accusation_controls_delay -= delta
		if player_accusation_controls_delay < 0:
			player_accusation_controls_delay = null
			enable_player_accusation_controls(-1)

func _input(ev):
	if ev is InputEventMouseButton:
		if animation_delay != null:
			return
		if ev.pressed:
			match state:
				STATE.INTRO1:
					var delay = 0.5
					$StrangerLeft.arrive(delay)
					add_text_line("Someone spots you from across the room," +
						" flashes you a big grin and then approaches. The " +
						$StrangerLeft.get_name_bbcode() +
						" takes a seat at your table.")
					start_animations(delay)
					state = STATE.INTRO2
				STATE.INTRO2:
					var delay = 0
					add_text_line("The " +
						$StrangerLeft.get_name_bbcode() +
						" produces a deck of cards and start shuffling.")
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"Do you know how to play?" + "[/color]")
					$AccuseButton.text = "YES"
					$DoNotAccuseButton.text = "NO, TEACH ME"
					disable_player_controls()
					delay += 0.5
					start_animations(delay)
					enable_player_accusation_controls(delay)
					state = STATE.ASK_TUTORIAL
				STATE.TUTORIAL0:
					var delay = 0
					add_stranger($StrangerMid, delay)
					delay += 0.5
					add_stranger($StrangerRight, delay)
					delay += 0.5
					start_animations(delay)
					state = STATE.TUTORIAL1
				STATE.TUTORIAL1:
					deal_cards()
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"Each of us gets three cards, and there's three cards" +
						" on the table." +
						"[/color]")
					state = STATE.TUTORIAL2
				STATE.TUTORIAL2:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"On your turn, you can take a card from the table" +
						" in exchange for one from your hand." +
						" Try to collect cards of the same suit." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL3
				STATE.TUTORIAL3:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"Aces are worth" +
						" [color=" + NUMBER_COLOR + "]" +
						stringify_value(11) + "[/color] points." +
						" Jacks, Queens and Kings are worth" +
						" [color=" + NUMBER_COLOR + "]" +
						stringify_value(10) + "[/color]." +
						" Seven through Ten..." +
						" well I'm sure you can figure those out." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL4
				STATE.TUTORIAL4:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"If someone gets to" +
						" [color=" + NUMBER_COLOR + "]" +
						stringify_value(31) + "[/color]" +
						", they win the round." +
						" Otherwise the game continues until everyone" +
						" is satisfied with their hand and locks in." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL5
				STATE.TUTORIAL5:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"At the end of the round," +
						" the player with the worst hand has to pay up." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL6
				STATE.TUTORIAL6:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"Oh, if you collect three of a kind," +
						" say three Sevens or three Queens," +
						" that's " +
						" [color=" + NUMBER_COLOR + "]" +
						stringify_value(30.5) + "[/color]" +
						"!" +
						" Not enough to end the game," +
						" but worth looking out for." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL7
				STATE.TUTORIAL7:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"One last thing:" +
						" if the cards on the table look especially appealing," +
						" you can take the lot!" +
						" But you won't be able to change cards afterwards." +
						"[/color]")
					start_animations(delay)
					state = STATE.TUTORIAL8
				STATE.TUTORIAL8:
					var delay = 0.5
					add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
						" [color=" + Stranger.QUOTE_COLOR + "]" +
						"That's it!" +
						"[/color]")
					delay += 0.5
					start_animations(delay)
					start_playing(delay)
				STATE.PLAYER:
					if player_pass_turn < 0:
						var ownCard = $PlayerHand.get_raised_card()
						var tableCard = $Table.get_raised_card()
						if ownCard != null and tableCard != null:
							var delay = 0.35
							add_text_line("You took " + card_name(tableCard) +
								", discarding " + card_name(ownCard) + ".")
							$PlayerHand.exchange_cards(ownCard, tableCard,
								delay)
							delay += 0.25
							$Table.exchange_cards(tableCard, ownCard, delay)
							delay += 0.25
							start_animations(delay)
							if ai_has_passed.min() == true:
								player_pass_turn = turn
								$PlayerHand.has_passed = true
							advance_state()
				STATE.BOT_LEFT:
					#if $PlayerHand.detect_invalid_card_click(ev):
					#	return
					#if $Table.detect_invalid_card_click(ev):
					#	return
					enact_ai_action(0, $StrangerLeft)
					advance_state()
				STATE.BOT_MID:
					#if $PlayerHand.detect_invalid_card_click(ev):
					#	return
					#if $Table.detect_invalid_card_click(ev):
					#	return
					enact_ai_action(1, $StrangerMid)
					advance_state()
				STATE.BOT_RIGHT:
					#if $PlayerHand.detect_invalid_card_click(ev):
					#	return
					#if $Table.detect_invalid_card_click(ev):
					#	return
					enact_ai_action(2, $StrangerRight)
					advance_state()
				STATE.END:
					reveal_and_score()
				STATE.START:
					deal_cards()
					if animation_delay != null:
						start_playing(animation_delay + 1.0)
					else:
						start_playing(-1)
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
							enable_player_accusation_controls(-1)
						current_accusation = x
						replace_text_line(Stranger.get_strategy_bbcode(x))
				STATE.CULL_DEFEATED:
					var delay = 0.5
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
						if not boss_battle:
							boss_battle = true
							for bot in [$StrangerLeft, $StrangerMid,
									$StrangerRight]:
								if not bot.defeated:
									bot.strategy = Stranger.STRATEGY.GOON
									bot.load_brain()
							unused_strategies = [Stranger.STRATEGY.BOSS]
							for _i in range(1, defeats):
								unused_strategies.push_back(
									Stranger.STRATEGY.GOON)
					clear_table()
					start_animations(delay)
					state = STATE.ADD_FRESH_BLOOD
				STATE.ADD_FRESH_BLOOD:
					var delay = 0
					for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
						if bot.defeated:
							if unused_strategies.size() > 0:
								add_stranger(bot, delay)
							else:
								unused_strategies = [Stranger.STRATEGY.GOON]
								add_stranger(bot, delay)
							delay += 0.5
							if boss_revealed:
								bot.reveal_identity()
					start_animations(delay)
					state = STATE.START
				STATE.GAME_OVER:
					pass
		else:
			match state:
				STATE.ASK_TUTORIAL:
					if $AccuseButton.pressed:
						$AccuseButton/ClickSound.play()
						add_text_line("You nod." +
							" From behind you, you hear people approaching.")
						add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
							" [color=" + Stranger.QUOTE_COLOR + "]" +
							"Excellent!" + "[/color]")
						$AccuseButton.text = "ACCUSE"
						$DoNotAccuseButton.text = "DO NOT ACCUSE"
						var delay = 1.0
						add_stranger($StrangerMid, delay)
						delay += 0.5
						add_stranger($StrangerRight, delay)
						delay += 0.5
						start_animations(delay)
						disable_player_controls()
						state = STATE.START
					elif $DoNotAccuseButton.pressed:
						$DoNotAccuseButton/ClickSound.play()
						var delay = 0.5
						add_text_line("Before you can speak, the " +
							$StrangerLeft.get_name_bbcode() +
							" sees the confused look on your face and laughs.")
						add_text_line($StrangerLeft.get_name_semicolon_bbcode() +
							" [color=" + Stranger.QUOTE_COLOR + "]" +
							"Don't worry, the rules are simple. It's your" +
							" fellow players that you should worry about." +
							"[/color]")
						$AccuseButton.text = "ACCUSE"
						$DoNotAccuseButton.text = "DO NOT ACCUSE"
						start_animations(delay)
						disable_player_controls()
						state = STATE.TUTORIAL0
				STATE.PLAYER:
					if player_pass_turn >= 0:
						state = STATE.BOT_LEFT
					elif $PassButton.pressed:
						$PassButton/ClickSound.play()
						var delay = 0.5
						player_pass_turn = turn
						$PlayerHand.has_passed = true
						add_text_line("You locked in " +
							"[color=" + NUMBER_COLOR + "]" +
							stringify_value(evaluate_hand($PlayerHand)) +
							"[/color]" +
							".")
						start_animations(delay)
						advance_state()
					elif $SwapButton.pressed:
						$SwapButton/ClickSound.play()
						var delay = 0.50
						add_text_line("You took " +
							card_name($Table.cards[0]) + ", " +
							card_name($Table.cards[1]) + " and " +
							card_name($Table.cards[2]) + ", locking in " +
							"[color=" + NUMBER_COLOR + "]" +
							stringify_value(evaluate_hand($Table)) +
							"[/color]" +
							".")
						add_text_line("You discarded " +
							card_name($PlayerHand.cards[0]) + ", " +
							card_name($PlayerHand.cards[1]) + " and " +
							card_name($PlayerHand.cards[2]) + ".")
						for i in range(0, 3):
							var ownCard = $PlayerHand.cards[i]
							var tableCard = $Table.cards[i]
							$PlayerHand.exchange_cards(ownCard, tableCard,
								delay)
							$Table.exchange_cards(tableCard, ownCard,
								delay + 0.5)
							delay += 0.05
						delay += 0.5
						start_animations(delay)
						player_pass_turn = turn
						$PlayerHand.has_passed = true
						advance_state()
				STATE.ACCUSATIONS:
					if $NoAccusationsButton.pressed:
						$NoAccusationsButton/ClickSound.play()
						var delay = 0.5
						if current_accusation != null:
							replace_text_line("You did not accuse anyone else.")
						else:
							replace_text_line("You did not accuse anyone.")
						current_accusation = null
						start_animations(delay)
						disable_player_controls()
						state = STATE.START
						return
					for bot in [$StrangerLeft, $StrangerMid, $StrangerRight]:
						var button = bot.get_node("AccusationButton")
						if button.visible && button.pressed:
							button.get_node("ClickSound").play()
							bot.accused = true
							state = STATE.ACCUSE
							$PlayerHand.discard_all_cards()
							var accusations = []
							for stranger in [$StrangerLeft, $StrangerMid,
									$StrangerRight]:
								if not stranger.revealed:
									var card = Stranger.get_accusation_card(
											stranger.strategy)
									if card != null:
										accusations.push_back(card)
							for i in range(0, 3):
								if i < unused_strategies.size():
									accusations.push_back(
										Stranger.get_accusation_card(
											unused_strategies[i]))
							accusations.shuffle()
							current_accusation = null
							var delay = 0.5
							for accusation in accusations:
								$PlayerHand.deal_card(accusation, delay)
								delay += 0.1
							disable_player_controls()
							delay += 0.5
							start_animations(delay)
							enable_player_accusation_controls(delay)
							break
				STATE.ACCUSE:
					if $AccuseButton.pressed:
						$AccuseButton/ClickSound.play()
						var delay = 0.5
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
								if accused.strategy == Stranger.STRATEGY.BOSS:
									boss_revealed = true
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
									start_animations(delay)
									disable_player_controls()
									state = STATE.GAME_OVER
									return
								else:
									player_lives -= 1
									if player_lives > 0:
										add_text_line("You have " +
											str(player_lives) + " lives left.")
									else:
										add_text_line("Game over.")
										start_animations(delay)
										disable_player_controls()
										state = STATE.GAME_OVER
										return
						start_animations(delay)
						disable_player_controls()
						if boss_revealed:
							for bot in [$StrangerLeft, $StrangerMid,
									$StrangerRight]:
								if not bot.revealed:
									bot.reveal_identity()
							state = STATE.START
						else:
							state = STATE.ACCUSATIONS
					elif $DoNotAccuseButton.pressed:
						$DoNotAccuseButton/ClickSound.play()
						var delay = 0.5
						$PlayerHand.discard_all_cards()
						start_animations(delay)
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
	var delay = 0
	var deck = range(0, NUM_NORMAL_CARDS)
	deck.shuffle()
	$StrangerLeft/Hand.shuffle_deck()
	delay += 1.0
	var i = 0
	$PlayerHand.reveal_cards(-1)
	$Table.reveal_cards(-1)
	$StrangerLeft/Hand.hide_cards()
	$StrangerMid/Hand.hide_cards()
	$StrangerRight/Hand.hide_cards()
	var bots = [$StrangerLeft, $StrangerMid, $StrangerRight]
	var trickeries = range(0, 3)
	trickeries.shuffle()
	for t in range(0, 3):
		$PlayerHand.deal_card(deck[i], delay)
		delay += 0.25
		if t == 0:
			delay += 0.05
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
			bot.get_node("Hand").deal_card(deck[i], delay)
			delay += 0.25
			if t == 0:
				delay += 0.05
			i += 1
	delay += 0.3
	for t in range(0, 3):
		$Table.deal_card(deck[i], delay)
		delay += 0.3
		if t == 0:
			delay += 0.05
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
						bruteHand.exchange_cards(ownCard, otherCard, -1)
						otherHand.exchange_cards(otherCard, ownCard, -1)
					break
	start_animations(delay)

func start_animations(delay: float):
	animation_delay = delay
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func start_playing(delay: float):
	var startingStates = [STATE.PLAYER, STATE.BOT_LEFT, STATE.BOT_MID,
		STATE.BOT_RIGHT]
	state = startingStates[randi() % startingStates.size()]
	turn = 0
	player_pass_turn = -1
	ai_has_passed = [false, false, false]
	disable_player_controls()
	match state:
		STATE.PLAYER:
			enable_player_controls(delay)
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
					stringify_value(value) + "[/color]" +
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
				var delay = 0
				if animation_delay != null:
					delay = animation_delay + 1.5
				add_text_line("The " + $StrangerLeft.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					stringify_value(value) + "[/color]" +
					"!")
				$StrangerLeft/Hand.reveal_cards(delay)
				delay += 0.5
				var win_quote = $StrangerLeft.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				start_animations(delay)
				state = STATE.END
				return
			state = STATE.BOT_MID
			if ai_has_passed[1]:
				advance_state()
		STATE.BOT_MID:
			var value = evaluate_hand($StrangerMid/Hand)
			if value >= 31.0:
				var delay = 0
				if animation_delay != null:
					delay = animation_delay + 1.5
				add_text_line("The " + $StrangerMid.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					stringify_value(value) + "[/color]" +
					"!")
				$StrangerMid/Hand.reveal_cards(delay)
				delay += 0.5
				var win_quote = $StrangerMid.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				start_animations(delay)
				state = STATE.END
				return
			state = STATE.BOT_RIGHT
			if ai_has_passed[2]:
				advance_state()
		STATE.BOT_RIGHT:
			var value = evaluate_hand($StrangerRight/Hand)
			if value >= 31.0:
				var delay = 0
				if animation_delay != null:
					delay = animation_delay + 1.5
				add_text_line("The " + $StrangerRight.get_name_bbcode() +
					" reveals " +
					"[color=" + NUMBER_COLOR + "]" +
					stringify_value(value) + "[/color]" +
					"!")
				$StrangerRight/Hand.reveal_cards(delay)
				delay += 0.5
				var win_quote = $StrangerRight.get_win_quote()
				if win_quote:
					add_text_line(win_quote)
				start_animations(delay)
				state = STATE.END
				return
			state = STATE.PLAYER
			if player_pass_turn >= 0:
				advance_state()
			else:
				var delay = 0
				if animation_delay != null:
					delay = animation_delay + 1.0
				start_animations(delay)
				enable_player_controls(delay)
		_:
			pass

func stringify_value(value):
	if value == 30.5:
		return "30 ½"
	else:
		return str(value)

func enable_player_controls(delay: float):
	if delay >= 0:
		player_controls_delay = delay
		return
	if player_pass_turn >= 0:
		return
	$PlayerHand.focus()
	$PlayerHand.set_process_input(true)
	$Table.set_process_input(true)
	$PassButton.text = ("LOCK IN (" +
		stringify_value(evaluate_hand($PlayerHand)) + ")")
	$PassButton.visible = true
	$SwapButton.text = ("TAKE ALL (" +
		stringify_value(evaluate_hand($Table)) + ")")
	$SwapButton.visible = true

func enable_player_accusation_controls(delay: float):
	if delay >= 0:
		player_accusation_controls_delay = delay
		return
	$PlayerHand.focus()
	$PlayerHand.set_process_input(true)
	$AccuseButton.visible = true
	$DoNotAccuseButton.visible = true

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
	var delay = 0
	var bots = [$StrangerLeft, $StrangerMid, $StrangerRight]
	for i in range(0, bots.size()):
		var bot: Stranger = bots[i]
		var hand: Hand = bot.get_node("Hand")
		var value = evaluate_hand(hand)
		if hand.revealed:
			add_text_line("The " + bot.get_name_bbcode() + " got " +
				"[color=" + NUMBER_COLOR + "]" +
				stringify_value(value) + "[/color]" +
				".")
		else:
			if bot.strategy == bot.STRATEGY.ILLUSIONIST and value <= 30.0:
				perform_illusion(hand)
				value = evaluate_hand(hand)
			hand.reveal_cards(delay)
			delay += 0.5
			add_text_line("The " + bot.get_name_bbcode() + " reveals " +
				"[color=" + NUMBER_COLOR + "]" +
				stringify_value(value) + "[/color]" +
				".")
		values.push_back(value)
	add_text_line("You got " +
		"[color=" + NUMBER_COLOR + "]" +
		stringify_value(player_value) + "[/color]" +
		".")
	values.push_back(player_value)
	start_animations(delay)
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
				if bot.strategy == Stranger.STRATEGY.BOSS:
					var defeat_quote = bot.get_defeat_quote()
					if defeat_quote != null:
						add_text_line(defeat_quote)
					add_text_line("You beam with pride in your victory." +
						" But when you hear the scraping of chairs" +
						" and the drawing of swords," +
						" you wonder how long that feeling will last...")
					state = STATE.GAME_OVER
					return
				defeats += 1
		if defeats > 0:
			state = STATE.CULL_DEFEATED
		elif player_value == highest_value:
			state = STATE.ACCUSATIONS
		else:
			state = STATE.START

func prepare_brain_input(input, ownHand: Hand, isSpy: bool, isGoon: bool,
		leftHand: Hand, midHand: Hand, rightHand: Hand,
		relativePlayerIndex: int, relativeBossIndex: int):
	input.resize((1 + 4 + 4 + 1) * NUM_CARDS)
	for i in range(0, input.size()):
		input[i] = 0
	for i in range(0, 3):
		input[$Table.cards[i]] = 1
	for i in range(0, 3):
		input[1 * NUM_CARDS + ownHand.cards[i]] = 1
	for c in ownHand.public_card_history:
		input[5 * NUM_CARDS + c] = 1
	for t in range(0, 3):
		var enemyHands = [leftHand, midHand, rightHand]
		var enemyHand = enemyHands[t]
		for i in range(0, 3):
			if (enemyHand.public_card_history.find(enemyHand.cards[i]) >= 0 or
					(isGoon && relativeBossIndex == t + 1) or
					isSpy):
				input[(2 + t) * NUM_CARDS + leftHand.cards[i]] = 1
		for c in enemyHand.public_card_history:
			input[(6 + t) * NUM_CARDS + c] = 1
	input[9 * NUM_CARDS + 0] = 1
	input[9 * NUM_CARDS + 1] = 1
	input[9 * NUM_CARDS + 2] = 1
	input[9 * NUM_CARDS + 3] = 1
	input[9 * NUM_CARDS + 4] = 0
	input[9 * NUM_CARDS + 5] = leftHand.has_passed
	input[9 * NUM_CARDS + 6] = midHand.has_passed
	input[9 * NUM_CARDS + 7] = rightHand.has_passed
	if relativePlayerIndex >= 0:
		input[9 * NUM_CARDS + 8 + relativePlayerIndex] = 1
	if relativeBossIndex >= 0:
		input[9 * NUM_CARDS + 12 + relativeBossIndex] = 1

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
		var relativePlayerIndex = 3 - ai_index
		var relativeBossIndex = -1
		var others = [$StrangerLeft, $StrangerMid, $StrangerRight]
		for i in range(0, 3):
			if others[i].strategy == Stranger.STRATEGY.BOSS:
				relativeBossIndex = (i - ai_index + 4) % 4
		var allHands = [$StrangerLeft/Hand, $StrangerMid/Hand,
			$StrangerRight/Hand, $PlayerHand]
		prepare_brain_input(brain.input, hand,
			stranger.strategy == Stranger.STRATEGY.SPY,
			stranger.strategy == Stranger.STRATEGY.GOON,
			allHands[(ai_index + 1) % 4],
			allHands[(ai_index + 2) % 4],
			allHands[(ai_index + 3) % 4],
			relativePlayerIndex, relativeBossIndex)
		brain.evaluate()
	if (brain.wantsToPass
			or (turn >= MAX_TURNS_PER_PLAYER
				and (randi() % 2) == 0)
			or (player_pass_turn >= 0
				and turn >= player_pass_turn + MAX_TURNS_AFTER_PLAYER
				and turn >= MIN_TURNS_PER_PLAYER)):
		var delay = 0.25
		add_text_line("The " + stranger.get_name_bbcode() +
			" locks in their hand.")
		start_animations(delay)
		ai_has_passed[ai_index] = true
		hand.has_passed = true
	elif brain.wantsToSwap:
		var delay = 0.25
		add_text_line("The " + stranger.get_name_bbcode() + " takes " +
			card_name($Table.cards[0]) + ", " +
			card_name($Table.cards[1]) + " and " +
			card_name($Table.cards[2]) + ", locking in " +
			"[color=" + NUMBER_COLOR + "]" +
			stringify_value(evaluate_hand($Table)) +
			"[/color]" +
			".")
		add_text_line("The " + stranger.get_name_bbcode() + " discarded " +
			card_name(hand.cards[0]) + ", " +
			card_name(hand.cards[1]) + " and " +
			card_name(hand.cards[2]) + ".")
		for i in range(0, 3):
			var ownCard = hand.cards[i]
			var tableCard = $Table.cards[i]
			hand.exchange_cards(ownCard, tableCard, delay)
			$Table.exchange_cards(tableCard, ownCard, delay + 0.5)
			hand.reveal_cards(delay)
			delay += 0.05
		delay += 0.5
		delay += 0.2
		start_animations(delay)
		ai_has_passed[ai_index] = true
		hand.has_passed = true
	else:
		var ownCard = brain.ownCard
		var tableCard = brain.tableCard
		var delay = 0.25
		add_text_line("The " + stranger.get_name_bbcode() + " takes " +
			card_name(tableCard) + ", discarding " + card_name(ownCard) + ".")
		hand.exchange_cards(ownCard, tableCard, delay)
		delay += 0.2
		$Table.exchange_cards(tableCard, ownCard, delay)
		delay += 0.2
		start_animations(delay)
		if (player_pass_turn >= 0 and ai_has_passed[(ai_index + 1) % 3] and
				ai_has_passed[(ai_index + 2) % 3]):
			ai_has_passed[ai_index] = true
			hand.has_passed = true

func add_stranger(stranger: Stranger, delay: float):
	if unused_faces.size() == 0:
		unused_faces = range(0, 10)
	var face = unused_faces[randi() % unused_faces.size()]
	var strategy = unused_strategies[randi() % unused_strategies.size()]
	stranger.strategy = strategy
	if strategy == Stranger.STRATEGY.BOSS:
		face = Stranger.BOSS_FRAME
	stranger.become_stranger(face)
	if face != Stranger.BOSS_FRAME:
		unused_faces.remove(unused_faces.find(face))
	unused_strategies.remove(unused_strategies.find(strategy))
	# TODO delay
	add_text_line(stranger.get_introduction_name_bbcode() +
		" sits down at your table.")
	stranger.arrive(delay)

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
			hand.exchange_cards(oldCard, newCard, -1)
	elif valueOfSpades >= 14 and clubFace != null:
		if clubFace < FACE_VALUES.size() - 1:
			var oldCard = clubFace * 4 + 0
			var newCard = clubFace * 4 + 3
			hand.exchange_cards(oldCard, newCard, -1)

func evaluate_hand(hand: Hand):
	return $Game.evaluate_hand(hand.cards[0], hand.cards[1], hand.cards[2])
