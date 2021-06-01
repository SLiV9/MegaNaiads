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
							disable_player_controls()
							state = STATE.BOT_LEFT
				STATE.BOT_LEFT:
					# TODO use AI to determine which action to take
					var ownCard = $StrangerLeft/Hand.cards[0]
					var tableCard = $Table.cards[0]
					$StrangerLeft/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					state = STATE.BOT_MID
				STATE.BOT_MID:
					# TODO use AI to determine which action to take
					var ownCard = $StrangerMid/Hand.cards[1]
					var tableCard = $Table.cards[1]
					$StrangerMid/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					state = STATE.BOT_RIGHT
				STATE.BOT_RIGHT:
					# TODO use AI to determine which action to take
					var ownCard = $StrangerRight/Hand.cards[2]
					var tableCard = $Table.cards[2]
					$StrangerRight/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					enable_player_controls()
					state = STATE.PLAYER
				STATE.END:
					pass
		else:
			match state:
				STATE.PLAYER:
					if has_passed:
						state = STATE.BOT_LEFT
					elif $PassButton.pressed:
						has_passed = true
						disable_player_controls()
						state = STATE.BOT_LEFT
					elif $SwapButton.pressed:
						for i in range(0, 3):
							var ownCard = $PlayerHand.cards[i]
							var tableCard = $Table.cards[i]
							$PlayerHand.exchange_cards(ownCard, tableCard)
							$Table.exchange_cards(tableCard, ownCard)
						has_passed = true
						disable_player_controls()
						state = STATE.BOT_LEFT
				STATE.BOT_LEFT:
					pass
				STATE.BOT_MID:
					pass
				STATE.BOT_RIGHT:
					pass
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
