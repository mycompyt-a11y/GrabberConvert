extends RefCounted

## Ensures HEIC and other raw image types appear in the FileSystem dock (Godot 4.4+).

const EDITOR_KEY := "docks/filesystem/other_file_extensions"

const EXTENSIONS_TO_REGISTER: Array[String] = [
	"heic", "heif", "hif", "avif", "tif", "tiff", "psd", "gif",
]


static func register_visible_extensions(editor: EditorInterface) -> void:
	if editor == null:
		return
	var settings: EditorSettings = editor.get_editor_settings()
	if settings == null or not settings.has_setting(EDITOR_KEY):
		push_warning("GrabberConvert: EditorSettings missing '%s' (Godot 4.4+ required)." % EDITOR_KEY)
		return

	var current: String = str(settings.get_setting(EDITOR_KEY))
	var existing: Dictionary = {}
	for part in current.split(",", false):
		var ext := part.strip_edges().to_lower()
		if not ext.is_empty():
			existing[ext] = true

	var added: PackedStringArray = []
	for ext in EXTENSIONS_TO_REGISTER:
		if not existing.has(ext):
			existing[ext] = true
			added.append(ext)

	if added.is_empty():
		return

	var merged: PackedStringArray = []
	for ext in current.split(",", false):
		var e := ext.strip_edges().to_lower()
		if not e.is_empty():
			merged.append(e)
	for ext in added:
		merged.append(ext)

	settings.set_setting(EDITOR_KEY, ",".join(merged))
	editor.get_resource_filesystem().scan()
