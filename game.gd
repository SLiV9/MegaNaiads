extends Node2D


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

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$StrangerLeft/Face.set_frame(5)
	$StrangerMid/Face.set_frame(4)
	$StrangerRight/Face.set_frame(0)
	$StrangerLeft/Emote.visible = false
	$StrangerMid/Emote.visible = false
	$StrangerRight/Emote.visible = false
	var deck = range(0, 32)
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
	$PlayerHand.set_process_input(true)
	$Table.set_process_input(true)

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			match state:
				STATE.PLAYER:
					if not has_passed:
						var ownCard = $PlayerHand.get_raised_card()
						var tableCard = $Table.get_raised_card()
						if ownCard != null and tableCard != null:
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
							advance_state()
				STATE.BOT_LEFT:
					enact_ai_action(0, $StrangerLeft/Hand)
					advance_state()
				STATE.BOT_MID:
					enact_ai_action(1, $StrangerMid/Hand)
					advance_state()
				STATE.BOT_RIGHT:
					enact_ai_action(2, $StrangerRight/Hand)
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
						advance_state()
					elif $SwapButton.pressed:
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

func enact_ai_action(ai_index: int, hand: Hand):
	# TODO use AI to determine which action to take
	if ai_has_passed[ai_index]:
		pass
	elif (randi() % 100 < 20):
		ai_has_passed[ai_index] = true
	elif (randi() % 100 < 20):
		for i in range(0, 3):
			var ownCard = hand.cards[i]
			var tableCard = $Table.cards[i]
			hand.exchange_cards(ownCard, tableCard)
			$Table.exchange_cards(tableCard, ownCard)
			hand.reveal_cards()
		ai_has_passed[ai_index] = true
	else:
		var ownCard = hand.cards[randi() % hand.cards.size()]
		var tableCard = $Table.cards[randi() % $Table.cards.size()]
		hand.exchange_cards(ownCard, tableCard)
		$Table.exchange_cards(tableCard, ownCard)
