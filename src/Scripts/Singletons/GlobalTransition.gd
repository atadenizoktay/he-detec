extends Node


signal faded_in
signal faded_out

export(int, 0, 100, 1) var wave_amp: int
export(int, 0, 10, 0.1) var wave_freq: int

var is_transitioning: bool = false

onready var AP: AnimationPlayer = $AnimationPlayer
onready var Notice: RichTextLabel = $C/Up/M/Notice
onready var Icon: TextureRect = $C/Down/M/Icon
onready var IconAP: AnimationPlayer = $C/Down/M/Icon/AnimationPlayer


func _ready() -> void:
	initialize_animations()
	initialize_notice()
	

func initialize_animations() -> void:
	# Initializes transition animations.
	IconAP.play("Active", -1, 1, false)


func initialize_notice() -> void:
	# Initializes transition notice.
	change_notice("So you wanna detec..?")
		
	
func fade_in() -> void:
	# Plays the `FadeIn` animation, and emits a signal at the end of the
	# animation indicating that the animation has finished.
	AP.play("FadeIn")
	yield(AP, "animation_finished")
	emit_signal("faded_in")
	

func fade_out() -> void:
	# Plays the `FadeOut` animation, and emits a signal at the end of the
	# animation indicating that the animation has finished.
	AP.play("FadeOut")
	yield(AP, "animation_finished")
	emit_signal("faded_out")


func change_notice(note: String) -> void:
	# Changes the transition notice. The transition notice is the text that is
	# displayed during transitions.
	var notice: String = "[wave amp={0} freq={1}][center]{2}[/center][/wave]" \
			.format({0: str(wave_amp), 1: str(wave_freq), 2: note})
	Notice.bbcode_text = notice
	

func change_icon(texture: Texture) -> void:
	# Changes the transition icon. The ransition icon is the icon that is
	# displayed during transitions.
	if texture:
		Icon.set_texture(texture)
		return
	Icon.set_texture(null)
