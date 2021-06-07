extends Sprite

class_name Card

const BACK_FRAME = 68

var is_on_table = false
var visibility_delay = null
var sound_delay = null


func deal(delay: float):
	if frame != BACK_FRAME:
		visible = false
	visibility_delay = delay + 0.05
	sound_delay = delay

func _process(delta):
	if visibility_delay != null:
		visibility_delay -= delta
		if visibility_delay < 0:
			visibility_delay = null
			visible = true
	if sound_delay != null:
		sound_delay -= delta
		if sound_delay < 0:
			sound_delay = null
			if is_on_table:
				play_place_sound_now()
			elif frame == BACK_FRAME:
				play_deal_sound_now()
			else:
				play_take_sound_now()

func play_deal_sound_now():
	var sounds = [$DealSound1, $DealSound2, $DealSound3]
	sounds[randi() % sounds.size()].play()

func play_place_sound_now():
	var sounds = [$PlaySound1, $PlaySound2, $PlaySound3, $PlaySound4]
	sounds[randi() % sounds.size()].play()

func play_take_sound_now():
	var sounds = [$TakeSound1, $TakeSound2, $TakeSound3, $TakeSound4,
		$TakeSound5, $TakeSound6, $TakeSound7, $TakeSound8]
	sounds[randi() % sounds.size()].play()

func play_click_sound_now():
	var sounds = [$ClickSound1]
	sounds[randi() % sounds.size()].play()
