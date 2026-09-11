extends RefCounted
## Shared atlas regions preserve the original generated image and its alpha.
const WEAPONS = preload("res://assets/ink/first-person-weapons.png")
const REINFORCEMENTS = preload("res://assets/ink/reinforcements-atlas.png")
const ATLAS = preload("res://assets/ink/defense-atlas.png")

static func texture(kind: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	match kind:
		"capitol": result.region = Rect2(0, 0, 645, 604)
		"tree": result.region = Rect2(645, 0, 609, 627)
		"alien": result.region = Rect2(110, 627, 430, 627)
		"rifle": result.region = Rect2(627, 650, 627, 604)
	if kind in ["scatter", "pistol", "bruiser", "elite"]:
		result.atlas = REINFORCEMENTS
		match kind:
			"scatter": result.region = Rect2(0, 0, 627, 565)
			"pistol": result.region = Rect2(627, 0, 627, 565)
			"bruiser": result.region = Rect2(0, 570, 627, 675)
			"elite": result.region = Rect2(665, 565, 490, 680)
	if kind in ["rifle", "scatter", "pistol"]:
		result.atlas = WEAPONS
		match kind:
			"rifle": result.region = Rect2(0, 0, 627, 627)
			"scatter": result.region = Rect2(627, 0, 627, 627)
			"pistol": result.region = Rect2(0, 627, 627, 627)
	result.filter_clip = true
	return result

static func sprite(kind: String, height: float, billboard := false) -> Sprite3D:
	var result := Sprite3D.new()
	result.texture = texture(kind)
	result.pixel_size = height / result.texture.get_height()
	result.position.y = height * 0.5
	result.shaded = false
	result.modulate = Color(1.35, 1.6, 1.5)
	result.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	result.alpha_scissor_threshold = 0.2
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	return result
