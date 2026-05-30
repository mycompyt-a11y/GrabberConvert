@tool
extends ScrollContainer

const Tool := preload("res://addons/grabber_convert/image_converter_tool.gd")

signal settings_changed

var _magick_edit: LineEdit
var _ffmpeg_edit: LineEdit
var _magick_status: Label
var _ffmpeg_status: Label
var _jpeg_slider: HSlider
var _jpeg_value: Label
var _webp_slider: HSlider
var _webp_value: Label
var _delete_original: CheckBox
var _overwrite: CheckBox
var _file_dialog: EditorFileDialog
var _browse_target: StringName = &""


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(320, 280)
	_build_ui()
	_load_from_project()
	_refresh_dependency_status()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	_add_heading(root, "External tools (HEIC / HEIF / AVIF)")
	_add_hint(
		root,
		"Godot cannot decode HEIC natively. Set paths to ImageMagick or FFmpeg, or use Auto-detect."
	)

	_magick_edit = _add_path_row(root, "ImageMagick", _on_browse_magick)
	_magick_status = _add_status_label(root)

	_ffmpeg_edit = _add_path_row(root, "FFmpeg", _on_browse_ffmpeg)
	_ffmpeg_status = _add_status_label(root)

	var detect_row := HBoxContainer.new()
	var detect_btn := Button.new()
	detect_btn.text = "Auto-detect"
	detect_btn.pressed.connect(_on_auto_detect)
	detect_row.add_child(detect_btn)

	var test_magick_btn := Button.new()
	test_magick_btn.text = "Test ImageMagick"
	test_magick_btn.pressed.connect(_on_test_magick)
	detect_row.add_child(test_magick_btn)

	var test_ffmpeg_btn := Button.new()
	test_ffmpeg_btn.text = "Test FFmpeg"
	test_ffmpeg_btn.pressed.connect(_on_test_ffmpeg)
	detect_row.add_child(test_ffmpeg_btn)
	root.add_child(detect_row)

	root.add_child(HSeparator.new())
	_add_heading(root, "Conversion options")

	_jpeg_slider = _add_quality_row(root, "JPEG quality", _on_jpeg_changed)
	_jpeg_value = _jpeg_slider.get_meta("value_label") as Label
	_webp_slider = _add_quality_row(root, "WebP quality", _on_webp_changed)
	_webp_value = _webp_slider.get_meta("value_label") as Label

	_delete_original = CheckBox.new()
	_delete_original.text = "Delete original file after conversion"
	_delete_original.toggled.connect(_on_delete_original_toggled)
	root.add_child(_delete_original)

	_overwrite = CheckBox.new()
	_overwrite.text = "Overwrite existing output files"
	_overwrite.toggled.connect(_on_overwrite_toggled)
	root.add_child(_overwrite)

	root.add_child(HSeparator.new())

	var save_row := HBoxContainer.new()
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_apply_pressed)
	save_row.add_child(apply_btn)

	var save_btn := Button.new()
	save_btn.text = "Apply and Save Project"
	save_btn.pressed.connect(_on_save_pressed)
	save_row.add_child(save_btn)
	root.add_child(save_row)

	_setup_file_dialog()


func _setup_file_dialog() -> void:
	_file_dialog = EditorFileDialog.new()
	_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.filters = PackedStringArray(["Executables (*.exe);;All (*.*)"])
	_file_dialog.file_selected.connect(_on_file_selected)
	if Tool.editor_interface:
		Tool.editor_interface.get_base_control().add_child(_file_dialog)


func _add_heading(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)


func _add_hint(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	parent.add_child(label)


func _add_status_label(parent: Control) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	return label


func _add_path_row(parent: Control, label_text: String, browse_callable: Callable) -> LineEdit:
	var row := HBoxContainer.new()
	var caption := Label.new()
	caption.text = label_text
	caption.custom_minimum_size.x = 100
	row.add_child(caption)

	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "Leave empty to search PATH"
	edit.focus_exited.connect(_apply_paths)
	row.add_child(edit)

	var browse := Button.new()
	browse.text = "..."
	browse.custom_minimum_size.x = 36
	browse.pressed.connect(browse_callable)
	row.add_child(browse)

	parent.add_child(row)
	return edit


func _add_quality_row(parent: Control, label_text: String, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var caption := Label.new()
	caption.text = label_text
	caption.custom_minimum_size.x = 100
	row.add_child(caption)

	var slider := HSlider.new()
	slider.min_value = 0.1
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size.x = 40
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.set_meta("value_label", value_label)

	parent.add_child(row)
	return slider


func _load_from_project() -> void:
	_magick_edit.text = str(Tool.get_setting("magick_path", ""))
	_ffmpeg_edit.text = str(Tool.get_setting("ffmpeg_path", ""))
	_jpeg_slider.value = float(Tool.get_setting("jpeg_quality", 0.9))
	_webp_slider.value = float(Tool.get_setting("webp_quality", 0.85))
	_delete_original.button_pressed = bool(Tool.get_setting("delete_original", false))
	_overwrite.button_pressed = bool(Tool.get_setting("overwrite_existing", true))
	_update_quality_label(_jpeg_slider, _jpeg_value)
	_update_quality_label(_webp_slider, _webp_value)


func _apply_paths() -> void:
	Tool.set_setting("magick_path", _magick_edit.text.strip_edges())
	Tool.set_setting("ffmpeg_path", _ffmpeg_edit.text.strip_edges())
	_refresh_dependency_status()
	settings_changed.emit()


func _apply_all_settings() -> void:
	_apply_paths()
	Tool.set_setting("jpeg_quality", _jpeg_slider.value)
	Tool.set_setting("webp_quality", _webp_slider.value)
	Tool.set_setting("delete_original", _delete_original.button_pressed)
	Tool.set_setting("overwrite_existing", _overwrite.button_pressed)
	settings_changed.emit()


func _refresh_dependency_status() -> void:
	_set_tool_status(_magick_status, Tool.find_magick_executable(), "ImageMagick")
	_set_tool_status(_ffmpeg_status, Tool.find_ffmpeg_executable(), "FFmpeg")


func _set_tool_status(label: Label, path: String, tool_name: String) -> void:
	if path.is_empty():
		label.text = "%s: not configured" % tool_name
		label.add_theme_color_override("font_color", Color(0.9, 0.55, 0.35))
		return
	var check: Dictionary = Tool.verify_executable(path)
	if check.get("ok", false):
		label.text = "%s: %s" % [tool_name, check.get("message", path)]
		label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5))
	else:
		label.text = "%s: %s" % [tool_name, check.get("message", "Invalid")]
		label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))


func _update_quality_label(slider: HSlider, value_label: Label) -> void:
	value_label.text = "%d%%" % int(slider.value * 100.0)


func _on_browse_magick() -> void:
	_browse_target = &"magick"
	_open_file_dialog(_magick_edit.text)


func _on_browse_ffmpeg() -> void:
	_browse_target = &"ffmpeg"
	_open_file_dialog(_ffmpeg_edit.text)


func _open_file_dialog(start_path: String) -> void:
	if _file_dialog == null:
		_setup_file_dialog()
	if not start_path.is_empty() and FileAccess.file_exists(start_path):
		_file_dialog.current_dir = start_path.get_base_dir()
		_file_dialog.current_file = start_path.get_file()
	_file_dialog.popup_centered_ratio(0.5)


func _on_file_selected(path: String) -> void:
	if _browse_target == &"magick":
		_magick_edit.text = path
	elif _browse_target == &"ffmpeg":
		_ffmpeg_edit.text = path
	_apply_paths()


func _on_auto_detect() -> void:
	var found: Dictionary = Tool.auto_detect_dependencies()
	var magick_path: String = str(found.get("magick", ""))
	var ffmpeg_path: String = str(found.get("ffmpeg", ""))
	if not magick_path.is_empty():
		_magick_edit.text = magick_path
	if not ffmpeg_path.is_empty():
		_ffmpeg_edit.text = ffmpeg_path
	_apply_paths()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_file_dialog):
		_file_dialog.queue_free()


func _on_test_magick() -> void:
	_apply_paths()
	var path := Tool.find_magick_executable()
	var check: Dictionary = Tool.verify_executable(path)
	_show_test_dialog("ImageMagick", path, check)


func _on_test_ffmpeg() -> void:
	_apply_paths()
	var path := Tool.find_ffmpeg_executable()
	var check: Dictionary = Tool.verify_executable(path)
	_show_test_dialog("FFmpeg", path, check)


func _show_test_dialog(tool_name: String, path: String, check: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Test %s" % tool_name
	if path.is_empty():
		dialog.dialog_text = "No executable found. Set a path or run Auto-detect."
	elif check.get("ok", false):
		dialog.dialog_text = "OK\n\nPath: %s\n%s" % [path, check.get("message", "")]
	else:
		dialog.dialog_text = "Failed\n\nPath: %s\n%s" % [path, check.get("message", "")]
	if Tool.editor_interface:
		Tool.editor_interface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _on_jpeg_changed(value: float) -> void:
	_update_quality_label(_jpeg_slider, _jpeg_value)
	Tool.set_setting("jpeg_quality", value)
	settings_changed.emit()


func _on_webp_changed(value: float) -> void:
	_update_quality_label(_webp_slider, _webp_value)
	Tool.set_setting("webp_quality", value)
	settings_changed.emit()


func _on_delete_original_toggled(pressed: bool) -> void:
	Tool.set_setting("delete_original", pressed)
	settings_changed.emit()


func _on_overwrite_toggled(pressed: bool) -> void:
	Tool.set_setting("overwrite_existing", pressed)
	settings_changed.emit()


func _on_apply_pressed() -> void:
	_apply_all_settings()
	_refresh_dependency_status()


func _on_save_pressed() -> void:
	_apply_all_settings()
	Tool.save_settings_to_disk()
	_refresh_dependency_status()
