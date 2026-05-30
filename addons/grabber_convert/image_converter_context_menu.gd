@tool
extends EditorContextMenuPlugin

const Tool := preload("res://addons/grabber_convert/image_converter_tool.gd")


func _popup_menu(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return

	var targets := Tool.get_available_targets(paths)
	if targets.is_empty():
		return

	for fmt in targets:
		var label := "Convert to %s" % fmt.to_upper()
		add_context_menu_item(label, _on_convert.bind(fmt))


func _on_convert(paths: PackedStringArray, target_fmt: String) -> void:
	var filtered: PackedStringArray = []
	for path in paths:
		if Tool.is_convertible(path):
			filtered.append(path)
	var results := Tool.convert_paths(filtered, target_fmt)
	_show_result_dialog(results, target_fmt)


func _show_result_dialog(results: Dictionary, target_fmt: String) -> void:
	if not Tool.editor_interface:
		return
	var failed: Array = results.get("failed", [])
	if failed.is_empty() and results.get("ok", 0) > 0:
		return

	var dialog := AcceptDialog.new()
	dialog.title = "GrabberConvert"
	if results.get("ok", 0) == 0 and failed.is_empty():
		dialog.dialog_text = "No files were converted."
	else:
		var lines: PackedStringArray = [
			"Converted %d file(s) to %s." % [results.get("ok", 0), target_fmt],
		]
		if not failed.is_empty():
			lines.append("%d failed:" % failed.size())
			for item in failed:
				var entry: Dictionary = item
				lines.append(
					"  - %s (error %s)" % [entry.get("path", ""), str(entry.get("error", ""))]
				)
		dialog.dialog_text = "\n".join(lines)
	Tool.editor_interface.get_base_control().add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
