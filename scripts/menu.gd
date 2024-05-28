extends VBoxContainer

@onready var continueButton: Button = $ContinueButton;
func _ready() -> void:
	self.visible = false
	
func _process(_delta):
	if Input.is_action_just_pressed("menu"):
		toggle_menu()

func toggle_menu() -> void:
	self.visible = !self.visible;
	get_tree().paused = self.visible;

	if self.visible:
		continueButton.grab_focus()

func _on_continue_button_pressed() -> void:
	toggle_menu()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
