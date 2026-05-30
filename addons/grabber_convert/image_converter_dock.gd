@tool
extends VBoxContainer

const Tool := preload("res://addons/grabber_convert/image_converter_tool.gd")
const SettingsPanelScript := preload("res://addons/grabber_convert/image_converter_settings_panel.gd")

var _out_format_option: OptionButton
var _convert_btn: Button
var _status: Label
var _tool_status: Label
var _settings_panel: ScrollContainer

const OUTPUT_FMTS: Array[String] = ["jpg", "png", "webp", "bmp"]


func _ready() -> void:
	custom_minimum_size = Vector2(360, 320)
	_build_ui()
	_refresh_status()


func _build_ui() -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var convert_tab := _build_convert_tab()
	convert_tab.name = "Convert"
	tabs.add_child(convert_tab)

	_settings_panel = SettingsPanelScript.new()
	_settings_panel.name = "Dependencies"
	_settings_panel.settings_changed.connect(_refresh_status)
	tabs.add_child(_settings_panel)


func _build_convert_tab() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "GrabberConvert"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "by Thumbnail Grabber"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	panel.add_child(subtitle)

	var hint := Label.new()
	hint.text = "Select images in FileSystem (HEIC, JPG, PNG, ...), pick a format, then convert."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	panel.add_child(hint)

	panel.add_child(HSeparator.new())

	var fmt_row := HBoxContainer.new()
	var fmt_label := Label.new()
	fmt_label.text = "Output format"
	fmt_row.add_child(fmt_label)

	_out_format_option = OptionButton.new()
	_out_format_option.add_item("JPG")
	_out_format_option.add_item("PNG")
	_out_format_option.add_item("WebP")
	_out_format_option.add_item("BMP")
	_out_format_option.item_selected.connect(_on_output_format_selected)

	var default_fmt: String = str(Tool.get_setting("default_format", "jpg"))
	match default_fmt:
		"png":
			_out_format_option.select(1)
		"webp":
			_out_format_option.select(2)
		"bmp":
			_out_format_option.select(3)
		_:
			_out_format_option.select(0)

	fmt_row.add_child(_out_format_option)
	panel.add_child(fmt_row)

	_convert_btn = Button.new()
	_convert_btn.text = "Convert Selected Files"
	_convert_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_convert_btn.pressed.connect(_on_convert_pressed)
	panel.add_child(_convert_btn)

	_tool_status = Label.new()
	_tool_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tool_status.add_theme_font_size_override("font_size", 12)
	panel.add_child(_tool_status)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status)

	return panel


func _on_output_format_selected(_index: int) -> void:
	Tool.set_setting("default_format", OUTPUT_FMTS[_out_format_option.selected])


func _refresh_status() -> void:
	if _tool_status == null:
		return
	_tool_status.text = Tool.get_tool_status()


func _on_convert_pressed() -> void:
	var editor: EditorInterface = Tool.editor_interface
	if editor == null:
		return

	var out_fmt: String = OUTPUT_FMTS[_out_format_option.selected]
	Tool.set_setting("default_format", out_fmt)

	var raw_selection := Tool.collect_filesystem_selection(editor)
	var selection := _filter_for_conversion(raw_selection, out_fmt)
	if selection.is_empty():
		_status.text = _conversion_blocked_message(raw_selection, out_fmt)
		return

	_status.text = "Converting..."
	_convert_btn.disabled = true
	var results: Dictionary = Tool.convert_paths(selection, out_fmt)
	_convert_btn.disabled = false
	_refresh_status()

	var failed: Array = results.get("failed", [])
	if failed.is_empty():
		_status.text = "Done. Converted %d file(s)." % int(results.get("ok", 0))
	else:
		_status.text = "Converted %d, %d failed. See Output panel." % [
			int(results.get("ok", 0)),
			failed.size(),
		]
		for item in failed:
			var entry: Dictionary = item
			push_error(
				"GrabberConvert failed: %s (%s)" % [entry.get("path", ""), str(entry.get("error", ""))]
			)


func _filter_for_conversion(paths: PackedStringArray, out_fmt: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for path in paths:
		var p := Tool.normalize_res_path(str(path))
		if not Tool.is_convertible(p):
			continue
		if Tool.can_convert_to(p, out_fmt):
			result.append(p)
	return result


func _conversion_blocked_message(raw_selection: PackedStringArray, out_fmt: String) -> String:
	if raw_selection.is_empty():
		var editor: EditorInterface = Tool.editor_interface
		if editor != null and editor.get_selected_paths().size() > 0:
			return (
				"FileSystem shows a folder selected, not the image file. "
				+ "Click the .heic file in the list (or turn off FileSystem split view), then convert."
			)
		return "Select one or more image files in the FileSystem dock."

	var supported: PackedStringArray = []
	for path in raw_selection:
		if Tool.is_convertible(path):
			supported.append(path)

	if supported.is_empty():
		return "Selected file(s) are not supported image types."

	var already_target := true
	for path in supported:
		if Tool.can_convert_to(path, out_fmt):
			already_target = false
			break
	if already_target:
		return "Selected file(s) are already %s." % out_fmt.to_upper()

	return "Could not convert the current selection."
