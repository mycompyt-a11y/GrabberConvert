extends RefCounted

## Converts images (including HEIC/HEIF) using Godot or external ImageMagick/ffmpeg.

const SETTING_PREFIX := "grabber_convert/"
const LEGACY_SETTING_PREFIX := "image_converter/"

const EXTERNAL_EXTENSIONS: Array[String] = [
	"heic", "heif", "hif", "avif", "tif", "tiff", "psd", "gif",
]

const ALL_SOURCE_EXTENSIONS: Array[String] = [
	"heic", "heif", "hif", "avif", "tif", "tiff", "psd", "gif",
	"png", "jpg", "jpeg", "webp", "bmp", "tga", "exr", "hdr",
]

const OUTPUT_FORMATS: Array[String] = ["jpg", "png", "webp", "bmp"]

static var editor_interface: EditorInterface = null


static func collect_filesystem_selection(editor: EditorInterface) -> PackedStringArray:
	if editor == null:
		return PackedStringArray()
	var result: PackedStringArray = []
	var seen: Dictionary = {}

	for raw in editor.get_selected_paths():
		var path := normalize_res_path(str(raw))
		if path.is_empty() or seen.has(path):
			continue
		if is_directory_path(path):
			continue
		seen[path] = true
		result.append(path)

	# Split FileSystem mode often leaves only the folder in get_selected_paths().
	var current := normalize_res_path(str(editor.get_current_path()))
	if not current.is_empty() and not is_directory_path(current) and not seen.has(current):
		result.append(current)

	return result


static func normalize_res_path(path: String) -> String:
	var p := path.strip_edges().replace("\\", "/")
	if p.is_empty():
		return ""
	if p.begins_with("res://"):
		return p
	if p.begins_with("res:/"):
		return "res://" + p.substr(5).lstrip("/")
	if ":" in p and not p.begins_with("res://"):
		var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/")
		if not project_root.ends_with("/"):
			project_root += "/"
		var normalized := p.replace("\\", "/")
		if normalized.to_lower().begins_with(project_root.to_lower()):
			return "res://" + normalized.substr(project_root.length())
	return p


static func is_directory_path(path: String) -> bool:
	var p := normalize_res_path(path)
	if p.is_empty():
		return true
	if p == "res://" or p.ends_with("/"):
		return true
	var global_path := ProjectSettings.globalize_path(p)
	if global_path.is_empty():
		return false
	return DirAccess.dir_exists_absolute(global_path)


static func is_convertible(path: String) -> bool:
	var p := normalize_res_path(path)
	if p.is_empty() or not p.begins_with("res://"):
		return false
	return _source_extension(p) in ALL_SOURCE_EXTENSIONS


static func get_available_targets(paths: PackedStringArray) -> Array[String]:
	var targets: Array[String] = []
	for fmt in OUTPUT_FORMATS:
		for path in paths:
			if not is_convertible(path):
				continue
			if _source_extension(path) != fmt:
				targets.append(fmt)
				break
	return targets


static func get_all_source_extensions() -> Array[String]:
	return ALL_SOURCE_EXTENSIONS.duplicate()


static func can_convert_to(path: String, target_fmt: String) -> bool:
	var p := normalize_res_path(path)
	if not is_convertible(p):
		return false
	return _source_extension(p) != _normalize_format(target_fmt)


static func output_path_for(source: String, target_fmt: String) -> String:
	var base := source.get_basename()
	return "%s.%s" % [base, target_fmt]


static func convert_paths(paths: PackedStringArray, target_fmt: String) -> Dictionary:
	var normalized := _normalize_format(target_fmt)
	var results := {"ok": 0, "failed": [], "skipped": []}
	if paths.is_empty():
		return results

	var tool := _resolve_external_tool()
	var needs_external := false
	for path in paths:
		if _needs_external(path):
			needs_external = true
			break
	if needs_external and tool.is_empty():
		_show_missing_tool_dialog()
		return results

	for path in paths:
		path = str(path)
		if not can_convert_to(path, normalized):
			results.skipped.append(path)
			continue
		var err := convert_file(path, normalized, tool)
		if err == OK:
			results.ok += 1
		else:
			results.failed.append({"path": path, "error": err})

	if editor_interface:
		editor_interface.get_resource_filesystem().scan()

	return results


static func convert_file(path: String, target_fmt: String, external_tool: String = "") -> Error:
	var normalized := _normalize_format(target_fmt)
	var src_ext := _source_extension(path)
	if src_ext == normalized:
		return ERR_ALREADY_EXISTS

	var dest := output_path_for(path, normalized)
	var abs_in := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_in):
		return ERR_FILE_NOT_FOUND

	var abs_out := ProjectSettings.globalize_path(dest)
	if FileAccess.file_exists(abs_out) and not _get_setting("overwrite_existing", true):
		return ERR_FILE_ALREADY_IN_USE

	var err: Error = _convert_image(abs_in, abs_out, normalized, _needs_external(path), external_tool)
	if err != OK:
		return err

	if _get_setting("delete_original", false) and dest != path:
		var del_err := DirAccess.remove_absolute(abs_in)
		if del_err != OK:
			push_warning("GrabberConvert: could not delete original: %s" % path)

	if editor_interface:
		editor_interface.get_resource_filesystem().update_file(dest)
		if _get_setting("delete_original", false):
			editor_interface.get_resource_filesystem().update_file(path)

	return OK


static func _convert_image(
	input: String,
	output: String,
	target_fmt: String,
	prefer_external: bool,
	external_tool: String = ""
) -> Error:
	if prefer_external:
		var tool := external_tool if not external_tool.is_empty() else _resolve_external_tool()
		if tool.is_empty():
			return ERR_UNAVAILABLE
		return _convert_external(input, output, target_fmt, tool)

	var err := _convert_with_godot(input, output, target_fmt)
	if err == OK:
		return OK

	var tool := external_tool if not external_tool.is_empty() else _resolve_external_tool()
	if tool.is_empty():
		return err
	return _convert_external(input, output, target_fmt, tool)


static func _convert_with_godot(input: String, output: String, target_fmt: String) -> Error:
	var image := _load_image(input)
	if image.is_empty():
		return ERR_CANT_OPEN

	match target_fmt:
		"jpg":
			return image.save_jpg(output, float(_get_setting("jpeg_quality", 0.9)))
		"png":
			return image.save_png(output)
		"webp":
			return image.save_webp(output, true, float(_get_setting("webp_quality", 0.85)))
		"bmp":
			# Godot 4.x has no Image.save_bmp(); handled via external tool fallback.
			return ERR_UNAVAILABLE
		_:
			return ERR_INVALID_PARAMETER


static func _load_image(input: String) -> Image:
	var image := Image.new()
	if image.load(input) == OK:
		return image
	return Image.new()


static func _convert_external(input: String, output: String, target_fmt: String, tool: String) -> Error:
	var args := _build_external_args(input, output, target_fmt, tool)
	var run := _run_process(tool, args)
	if run.exit_code != 0:
		var detail := _format_process_output(run)
		push_error(
			"GrabberConvert: external tool failed (%s) for %s%s"
			% [tool, input, detail]
		)
		return ERR_CANT_CREATE
	if not FileAccess.file_exists(output):
		return ERR_CANT_CREATE
	return OK


static func _build_external_args(
	input: String,
	output: String,
	target_fmt: String,
	tool: String,
) -> PackedStringArray:
	if tool.ends_with("ffmpeg") or tool.ends_with("ffmpeg.exe"):
		var args := PackedStringArray(["-y", "-i", input])
		if target_fmt == "jpg":
			args.append_array([
				"-q:v",
				str(int((1.0 - float(_get_setting("jpeg_quality", 0.9))) * 31.0)),
			])
		args.append(output)
		return args

	# ImageMagick 6: convert.exe in.heic out.jpg
	# ImageMagick 7: magick.exe in.heic [opts] out.jpg  (never "magick convert ...")
	var args := PackedStringArray([input, "-auto-orient"])
	args.append_array(_magick_quality_args(target_fmt))
	args.append(output)
	return args


static func _magick_quality_args(target_fmt: String) -> PackedStringArray:
	match target_fmt:
		"jpg":
			return PackedStringArray([
				"-quality",
				str(int(float(_get_setting("jpeg_quality", 0.9)) * 100.0)),
			])
		"webp":
			return PackedStringArray([
				"-quality",
				str(int(float(_get_setting("webp_quality", 0.85)) * 100.0)),
			])
		_:
			return PackedStringArray()


static func _run_process(executable: String, arguments: PackedStringArray) -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute(executable, arguments, output, true)
	return {"exit_code": exit_code, "output": output}


static func _format_process_output(run: Dictionary) -> String:
	var lines: PackedStringArray = []
	for line in run.get("output", []):
		var text := str(line).strip_edges()
		if not text.is_empty():
			lines.append(text)
	if lines.is_empty():
		return ""
	return "\n" + "\n".join(lines)


static func _needs_external(path: String) -> bool:
	return _source_extension(path) in EXTERNAL_EXTENSIONS


static func _source_extension(path: String) -> String:
	var ext := path.get_extension().to_lower().strip_edges()
	if ext == "jpeg":
		return "jpg"
	return ext


static func _normalize_format(raw: String) -> String:
	var f := raw.to_lower().trim_prefix(".")
	if f == "jpeg":
		return "jpg"
	if f in OUTPUT_FORMATS:
		return f
	return "jpg"


static func _resolve_external_tool() -> String:
	var magick := find_magick_executable()
	if not magick.is_empty():
		return magick
	var ffmpeg := find_ffmpeg_executable()
	if not ffmpeg.is_empty():
		return ffmpeg
	return ""


static func _is_system32_convert(path: String) -> bool:
	var normalized := path.replace("\\", "/").to_lower()
	if not normalized.ends_with("/convert.exe"):
		return false
	return "/system32/" in normalized or "/syswow64/" in normalized


static func _is_imagemagick_executable(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	if _is_system32_convert(path):
		return false
	var output: Array = []
	if OS.execute(path, ["-version"], output, true) != 0:
		return false
	if output.is_empty():
		return false
	return "imagemagick" in str(output[0]).to_lower()


static func _is_unsafe_path_folder(folder: String) -> bool:
	var normalized := folder.replace("\\", "/").to_lower().trim_suffix("/")
	return (
		normalized.ends_with("/system32")
		or normalized.ends_with("/syswow64")
		or normalized.ends_with("/windows")
	)


static func _find_executable(names: PackedStringArray) -> String:
	if OS.has_environment("PATH"):
		var path_var := OS.get_environment("PATH")
		var sep := ";" if OS.get_name() == "Windows" else ":"
		for folder in path_var.split(sep, false):
			if _is_unsafe_path_folder(folder):
				continue
			for name in names:
				var candidate := folder.path_join(name)
				if FileAccess.file_exists(candidate):
					return candidate
	return ""


static func _find_imagemagick_install() -> String:
	if OS.get_name() != "Windows":
		return ""
	var program_files := [
		OS.get_environment("ProgramFiles"),
		OS.get_environment("ProgramFiles(x86)"),
		"C:/Program Files",
		"C:/Program Files (x86)",
	]
	for root in program_files:
		if root.is_empty():
			continue
		var magick_dir := _find_subdir_named(root, "ImageMagick")
		if magick_dir.is_empty():
			continue
		for name in ["magick.exe", "convert.exe"]:
			var exe := magick_dir.path_join(name)
			if FileAccess.file_exists(exe) and _is_imagemagick_executable(exe):
				return exe
	return ""


static func _find_subdir_named(root: String, prefix: String) -> String:
	var dir := DirAccess.open(root)
	if dir == null:
		return ""
	for entry in dir.get_directories():
		if entry.begins_with(prefix):
			return root.path_join(entry)
	return ""


static func get_setting(key: String, default_value: Variant) -> Variant:
	var full_key := SETTING_PREFIX + key
	if ProjectSettings.has_setting(full_key):
		return ProjectSettings.get_setting(full_key)
	var legacy_key := LEGACY_SETTING_PREFIX + key
	if ProjectSettings.has_setting(legacy_key):
		return ProjectSettings.get_setting(legacy_key)
	return default_value


static func _get_setting(key: String, default_value: Variant) -> Variant:
	return get_setting(key, default_value)


static func set_setting(key: String, value: Variant) -> void:
	ProjectSettings.set_setting(SETTING_PREFIX + key, value)


static func save_settings_to_disk() -> void:
	ProjectSettings.save()


static func find_magick_executable() -> String:
	var override: String = str(_get_setting("magick_path", ""))
	if not override.is_empty():
		if _is_imagemagick_executable(override):
			return override
		push_warning(
			"GrabberConvert: magick_path is not ImageMagick (check Dependencies tab). "
			+ "On Windows, do not use C:\\Windows\\System32\\convert.exe."
		)
	var from_install := _find_imagemagick_install()
	if not from_install.is_empty():
		return from_install
	# magick.exe only on PATH — never bare convert.exe (conflicts with Windows System32).
	var from_path := _find_executable(["magick.exe", "magick"])
	if not from_path.is_empty() and _is_imagemagick_executable(from_path):
		return from_path
	return ""


static func find_ffmpeg_executable() -> String:
	var override: String = str(_get_setting("ffmpeg_path", ""))
	if not override.is_empty() and FileAccess.file_exists(override):
		return override
	return _find_executable(["ffmpeg", "ffmpeg.exe"])


static func verify_executable(path: String) -> Dictionary:
	if path.is_empty():
		return {"ok": false, "message": "Path is empty."}
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "File not found."}
	if _is_system32_convert(path):
		return {
			"ok": false,
			"message": "This is Windows convert (disk tool), not ImageMagick. Use magick.exe from ImageMagick install.",
		}
	if path.ends_with("convert.exe") or path.ends_with("convert"):
		if not _is_imagemagick_executable(path):
			return {
				"ok": false,
				"message": "Not ImageMagick. Set path to magick.exe (e.g. Program Files\\ImageMagick).",
			}

	var output: Array = []
	var exit_code := OS.execute(path, ["-version"], output, true)
	if exit_code != 0:
		exit_code = OS.execute(path, ["--version"], output, true)
	if exit_code != 0:
		return {"ok": false, "message": "Could not run (exit %d)." % exit_code}

	var summary: String = "OK"
	if output.size() > 0:
		summary = str(output[0])
	var first_line := summary.get_slice("\n", 0)
	return {"ok": true, "message": first_line}


static func auto_detect_dependencies() -> Dictionary:
	return {
		"magick": find_magick_executable(),
		"ffmpeg": find_ffmpeg_executable(),
	}


static func register_settings() -> void:
	var defaults := {
		SETTING_PREFIX + "default_format": "jpg",
		SETTING_PREFIX + "jpeg_quality": 0.9,
		SETTING_PREFIX + "webp_quality": 0.85,
		SETTING_PREFIX + "delete_original": false,
		SETTING_PREFIX + "overwrite_existing": true,
		SETTING_PREFIX + "magick_path": "",
		SETTING_PREFIX + "ffmpeg_path": "",
	}
	for key in defaults:
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, defaults[key])
			ProjectSettings.set_initial_value(key, defaults[key])

	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "default_format",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "jpg,png,webp,bmp",
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "jpeg_quality",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.1,1.0,0.05",
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "webp_quality",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.1,1.0,0.05",
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "delete_original",
		"type": TYPE_BOOL,
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "overwrite_existing",
		"type": TYPE_BOOL,
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "magick_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "*",
	})
	ProjectSettings.add_property_info({
		"name": SETTING_PREFIX + "ffmpeg_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "*",
	})


static func _show_missing_tool_dialog() -> void:
	if not editor_interface:
		return
	var dialog := AcceptDialog.new()
	dialog.title = "GrabberConvert"
	dialog.dialog_text = (
		"HEIC/HEIF/AVIF need ImageMagick or FFmpeg.\n\n"
		+ "On Windows, use magick.exe from ImageMagick — not C:\\Windows\\System32\\convert.exe (that is a disk tool).\n\n"
		+ "Install: https://imagemagick.org/script/download.php\n"
		+ "Open GrabberConvert → Dependencies tab → set ImageMagick path (e.g. E:/ImageMagick/magick.exe)."
	)
	editor_interface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


static func get_tool_status() -> String:
	var tool := _resolve_external_tool()
	if tool.is_empty():
		return "External tool: not found (required for HEIC/HEIF/AVIF)"
	return "External tool: %s" % tool
