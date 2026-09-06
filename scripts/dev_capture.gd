extends Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var capture_index := args.find("--capture")
	if capture_index == -1:
		return
	var folder := "res://verify"
	var folder_index := args.find("--capture-dir")
	if folder_index != -1 and folder_index + 1 < args.size():
		folder = "res://" + args[folder_index + 1].trim_prefix("res://").trim_suffix("/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	await get_tree().create_timer(1.5).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(folder.path_join("capture.png")))
	get_tree().quit()
