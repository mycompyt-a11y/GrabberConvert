@tool
extends EditorPlugin

const BRAND_NAME := "GrabberConvert"
const Tool := preload("res://addons/grabber_convert/image_converter_tool.gd")
const FilesystemSetup := preload("res://addons/grabber_convert/filesystem_setup.gd")
const DockScript := preload("res://addons/grabber_convert/image_converter_dock.gd")

var _dock: Control
var _context_menu: EditorContextMenuPlugin


func _enter_tree() -> void:
	Tool.register_settings()
	Tool.editor_interface = get_editor_interface()
	FilesystemSetup.register_visible_extensions(get_editor_interface())

	_dock = DockScript.new()
	_dock.name = BRAND_NAME
	add_control_to_bottom_panel(_dock, BRAND_NAME)

	_context_menu = preload("res://addons/grabber_convert/image_converter_context_menu.gd").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

	add_tool_menu_item("GrabberConvert — Convert Selected", _on_tool_menu)
	add_tool_menu_item("GrabberConvert — Settings", _on_settings_menu)


func _exit_tree() -> void:
	remove_tool_menu_item("GrabberConvert — Convert Selected")
	remove_tool_menu_item("GrabberConvert — Settings")
	remove_context_menu_plugin(_context_menu)
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
	Tool.editor_interface = null


func _on_tool_menu() -> void:
	if not _dock:
		return
	make_bottom_panel_item_visible(_dock)
	_dock.call("_on_convert_pressed")


func _on_settings_menu() -> void:
	if not _dock:
		return
	make_bottom_panel_item_visible(_dock)
	var tabs := _dock.get_child(0) as TabContainer
	if tabs:
		tabs.current_tab = 1
