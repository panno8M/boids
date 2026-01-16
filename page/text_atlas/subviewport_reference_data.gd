extends RefCounted
class_name SubViewportReferenceData

var sub_viewport: SubViewport
var size: Vector2i
var offset: Vector2i
var texture: AtlasTexture

static func initialize(viewport: SubViewport, page_size: Vector2i, page_offset: Vector2i) -> SubViewportReferenceData:
	var result = SubViewportReferenceData.new()
	result.offset = page_offset
	result.size = page_size
	var tex := AtlasTexture.new()
	tex.region = Rect2(page_size * page_offset, page_size)
	tex.atlas = viewport.get_texture()
	result.texture = tex
	result.sub_viewport = viewport
	return result
