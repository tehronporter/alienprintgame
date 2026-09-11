extends Node

const SAMPLE_RATE := 22050

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	streams["shot"] = _tone(92.0, 0.09, 0.42, 0.7)
	streams["scatter"] = _tone(58.0, 0.16, 0.62, 1.0)
	streams["reload"] = _tone(310.0, 0.1, 0.2, 0.0)
	streams["switch"] = _tone(520.0, 0.055, 0.17, 0.0)
	streams["hit"] = _tone(760.0, 0.045, 0.18, 0.0)
	streams["critical"] = _tone(1150.0, 0.07, 0.2, 0.0)
	streams["death"] = _tone(140.0, 0.2, 0.35, 0.4)
	streams["hurt"] = _tone(74.0, 0.13, 0.45, 0.55)
	streams["pickup"] = _tone(880.0, 0.16, 0.16, 0.0, true)
	streams["elite"] = _tone(48.0, 0.55, 0.5, 0.35)
	streams["tension"] = _tone(42.0, 0.32, 0.18, 0.12)
	for index in range(12):
		var player := AudioStreamPlayer.new()
		player.name = "Voice_%02d" % index
		player.volume_db = -7.0
		add_child(player)
		players.append(player)

func play_cue(cue: String, pitch := 1.0) -> void:
	if not streams.has(cue):
		return
	for player in players:
		if not player.playing:
			player.stream = streams[cue]
			player.pitch_scale = pitch
			player.play()
			return

func _tone(frequency: float, duration: float, volume: float, noise: float, rising := false) -> AudioStreamWAV:
	var frame_count := int(float(SAMPLE_RATE) * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = int(frequency * 100.0 + duration * 1000.0)
	for frame in range(frame_count):
		var time := float(frame) / float(SAMPLE_RATE)
		var progress := float(frame) / float(frame_count)
		var envelope := pow(1.0 - progress, 1.8)
		var sweep := frequency * (1.0 + progress * 0.8 if rising else 1.0 - progress * 0.28)
		var wave := sin(TAU * sweep * time) * (1.0 - noise) + random.randf_range(-1.0, 1.0) * noise
		var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
