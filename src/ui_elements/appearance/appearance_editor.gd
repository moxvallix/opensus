extends Node
# --Private Variables--

onready var tabs: Control  = $MenuMargin/HBoxContainer/TabBox/TabContainer
onready var character: Control = $MenuMargin/HBoxContainer/CharacterBox/CenterCharacter/MenuCharacter
onready var popupCharacter: Control = $SavePopup/MarginContainer/HBoxContainer/MenuCharacter

signal menuBack
signal menuSwitch(menu)

var currentTab: int # ID of selected tab
var selectedItem: int # ID of selected item
var itemsList: Dictionary # Dictionary of items, for selection lookup

# Directories of icons
var icons: Dictionary = {
	"Body": "res://game/character/assets/icons/body",
	"Clothes": "res://game/character/assets/icons/clothes",
	"Mouth": "res://game/character/assets/icons/mouth",
	"Face Wear": "res://game/character/assets/icons/face_wear",
	"Facial Hair": "res://game/character/assets/icons/facial_hair",
	"Hat/Hair": "res://game/character/assets/icons/hat_hair",
}

# --Configuration Variables--

# Item list config variables
const LIST_COLUMNS = 0 # Max columns
const LIST_SAME_WIDTH = true # Same column width
const ITEM_ICON_SIZE = Vector2(256, 256) # Icon size of items

# --Private Functions--

func _ready() -> void:
	Appearance.updateConfig() ## Update sample character
	$Darken.hide()
	_generateTabs() ## Generate customization tabs

## Generate the customization menu tabs
func _generateTabs() -> void:
	var files = Resources.list(Appearance.directories, Appearance.extensions) ## Get file list
	assert(not files.empty(), "Empty file list")
	for resource in files: ## Iterate over files
		for namespace in Appearance.groupClothing: # Iterate over the clothing groups
			## Check if resource is a child eg. Left Arm to Clothes
			if not Appearance.groupClothing[namespace].has(resource):
				_addChildTab(files, resource) ## Otherwise add the tab for this resource
	var colorScene = "res://ui_elements/appearance/colors.tscn"
	var colors = load(colorScene).instance()
	colors.connect("setColor", self, "_on_color_selected")
	tabs.add_child(colors) ## Add "Colors" as a child to tab container

# Add a child tab
func _addChildTab(files: Dictionary, resource: String) -> void:
	var child = _createChildTab(resource) ## Create a new child tab
	tabs.add_child(child) ## Add the new tab
	_populateChildTab(files, resource, child) ## Populate the tab with items

# Create a new child tab
func _createChildTab(resource: String) -> ItemList:
	## Set up new tab
	var child = ItemList.new() # Create new item list
	child.name = resource.capitalize() # Set the tab's name
	child.max_columns = LIST_COLUMNS # Set the max columns
	child.same_column_width = LIST_SAME_WIDTH # Set the same column width
	child.connect("item_selected", self, "_on_item_selected") ## Connect item selection signal
	return(child) # Return the newly configured child

# Populate the child tab with items
func _populateChildTab(files: Dictionary, resource: String, child: ItemList) -> void:
	itemsList[resource] = [] ## Ready the items list
	assert(not files[resource].empty(), "Empty resource list")
	for item in files[resource]: ## Iterate over the items
		itemsList[resource].append(item) ## Append item to items list dictionary
		var texture = _getTexture(files, resource, item) ## Get texture of icon
		child.add_icon_item(texture) ## Add the icon item with set texture
		child.fixed_icon_size = ITEM_ICON_SIZE ## Configure the icon size

# Update the outfit
func _updateOutfit() -> void:
	var tab = tabs.get_child(currentTab) ## Get the current tab
	var namespace = itemsList.keys()[currentTab] ## Get namespace from item list dictionary
	var resource = itemsList[namespace][selectedItem] ## Get selected resource from item list dictionary
	Appearance.setOutfitPart(resource, namespace) ## Set outfit part to correct resource

# Get the texture to use for the item's icon
func _getTexture(directories: Dictionary, namespace: String, resource: String) -> Texture:
	## Gather icons
	var iconList = Resources.list(icons, Appearance.extensions) # Get a list of all icons
	var icons = iconList[namespace] # Get the icons under the given namespace
	var texturePath: String # Path to the texture
	if icons.has(resource): ## If selected item has icon
		texturePath = iconList[namespace][resource] # Set item texture to corresponding icon
	else: ## If no icon is present
		texturePath = directories[namespace][resource] ## Use item texture
	var texture = load(texturePath) ## Load texture path as texture
	return(texture) # Return the new texture object

## Save overlay popup
func _savePopup() -> void:
	$Darken.show() ## Darken the screen behind
	$SavePopup.popup_centered() ## Show popup centered on screen
	popupCharacter.setOutline(Color.black) ## Sets outline for character sample

func _deselectItems():
	## Loop through tabs
	for child in tabs.get_children():
		## Unselect all
		if child is ItemList:
			child.unselect_all()

# --Signal Functions--

# Sets the current tab when a tab is changed
func _on_tab_changed(tab: int) -> void:
	currentTab = tab ## Saves current tab position

# Sets the current item when an item is selected
func _on_item_selected(item: int) -> void:
	selectedItem = item
	Appearance.customOutfit = true ## Set customOutfit to [TRUE] in appearance.gd
	_updateOutfit() ## Updates outfit on sample character

# Sets the color when selected from the picker
func _on_color_selected(shader, colorMap, position) -> void:
	Appearance.customOutfit = true
	Appearance.setColorFromPos(shader, colorMap, position) ## Set color from position

# Handles randomization of the character
func _on_Random_pressed() -> void:
	## If customOutfit [TRUE] in appearance.gd
	if Appearance.customOutfit:
		$RandomConfirm.popup_centered() ## Show confirmation popup
	else: ## If customOutfit [FALSE] in appearance.gd
		_deselectItems()
		Appearance.randomizeConfig() ## Randomize character appearance

# Switches back to the previous menu
func _on_Back_pressed() -> void:
	emit_signal("menuBack") ## Signal menuBack

# Open the save popup
func _on_Save_pressed() -> void:
	_savePopup() ## Show save popup

# Switch to closet scene
func _on_Closet_pressed() -> void:
	emit_signal("menuSwitch", "closet") ## Signal menuSwitch to closet

# Hide darkener on save popup close
func _on_Popup_hide() -> void:
	$Darken.hide()

# Close the save popup
func _on_Cancel_pressed() -> void:
	$SavePopup.hide()
	$RandomConfirm.hide()

func _on_Character_mouse_entered() -> void:
	character.setOutline(Color("#DB2921")) ## Outline to red

func _on_Character_mouse_exited() -> void:
	character.setOutline(Color("#E6E2DD")) ## Outline to yellow

func _on_Confirm_pressed():
	$RandomConfirm.hide() ## Hide confirmation popup
	Appearance.randomizeConfig() ## Randomize appearance
