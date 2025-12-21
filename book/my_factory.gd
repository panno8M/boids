extends BookFactory
class_name MyBookFactory

enum BookKind {SAMPLE, TEXT, IMAGE, AUDIO, MODEL}

@export var blueprints: Dictionary[BookKind, PackedScene]

func _create(controller: BoidController3D, path: String) -> Bookfly:
	var result = blueprints[detect_book_kind(path)].instantiate() as BookBase
	return result

const image_exts = ["png", "jpg", "jpeg", "svg", "svgz", "bmp", "tga", "webp", "exr", "hdr", "qoi", "dds", "ktx", "ktx2", "pvr"]
const valid_audio_exts = ["mp3", "wav", "ogg"]
const valid_3d_model_exts = ["glb", "gltf", "fbx", "obj"]

func detect_book_kind(path: String) -> BookKind:
	var ext = path.get_extension()
	if ext in image_exts:
		return BookKind.IMAGE
	elif ext in valid_audio_exts:
		return BookKind.AUDIO
	elif ext in valid_3d_model_exts:
		return BookKind.MODEL
	#if is_text_file(path):
	#	return BookKind.TEXT
	#else:
	#	return BookKind.SAMPLE
	return BookKind.TEXT

func is_text_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var bytes = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return false

	var sample_size = min(4096, bytes.size())
	var sample = bytes.slice(0, sample_size)

	var non_text_count = 0
	for b in sample:
		if b == 0:
			return false
		if b < 0x09 or (b > 0x0D and b < 0x20):
			non_text_count += 1

	return float(non_text_count) / float(sample_size) < 0.01
