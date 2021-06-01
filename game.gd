extends Node2D


enum STATE {
	PLAYER,
	BOT_LEFT,
	BOT_MID,
	BOT_RIGHT,
	END
}

var state = STATE.PLAYER

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$StrangerLeft/Face.set_frame(5)
	$StrangerMid/Face.set_frame(4)
	$StrangerRight/Face.set_frame(0)
	$StrangerLeft/Emoticon.visible = false
	$StrangerMid/Emoticon.visible = false
	$StrangerRight/Emoticon.visible = false
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(ev):
	if ev is InputEventMouseButton:
		if ev.pressed:
			match state:
				STATE.PLAYER:
					var ownCard = $PlayerHand.get_raised_card()
					var tableCard = $Table.get_raised_card()
					if ownCard != null and tableCard != null:
						$PlayerHand.exchange_cards(ownCard, tableCard)
						$Table.exchange_cards(tableCard, ownCard)
						$Table.set_process_input(false)
						state = STATE.BOT_LEFT
				STATE.BOT_LEFT:
					if $PlayerHand.get_raised_card() != null:
						pass
					# TODO use AI to determine which action to take
					var ownCard = $StrangerLeft/Hand.cards[0]
					var tableCard = $Table.cards[0]
					$StrangerLeft/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					state = STATE.BOT_MID
				STATE.BOT_MID:
					if $PlayerHand.get_raised_card() != null:
						pass
					# TODO use AI to determine which action to take
					var ownCard = $StrangerMid/Hand.cards[1]
					var tableCard = $Table.cards[1]
					$StrangerMid/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					state = STATE.BOT_RIGHT
				STATE.BOT_RIGHT:
					if $PlayerHand.get_raised_card() != null:
						pass
					# TODO use AI to determine which action to take
					var ownCard = $StrangerRight/Hand.cards[2]
					var tableCard = $Table.cards[2]
					$StrangerRight/Hand.exchange_cards(ownCard, tableCard)
					$Table.exchange_cards(tableCard, ownCard)
					$Table.set_process_input(true)
					state = STATE.PLAYER
				STATE.END:
					pass
