-- when the player enters the hitbox near the garage door replace its colision to ensure they don't get stuck in it
local g_colshape = getElementByID("garage_colshape")
function replaceCollisionModel()
	-- load the colision model
	local col = engineLoadCOL("door.col")
	if not col then
		outputDebugString("The garagedoor collision could not be loaded.", 1)
		return 
	end
	
	-- replace the colision model
	local replacement = engineReplaceCOL(col, 9823)
	if not replacement then
		outputDebugString("The garagedoor collision could not be replaced.", 1)
	end
end
addEventHandler("onClientColShapeHit", g_colshape, replaceCollisionModel)

-- prepare the vehicle selection window
local spawnWindow
do
	-- center the window on the screen
	local screenWidth, screenHeight = guiGetScreenSize()
	spawnWindow = guiCreateWindow(screenWidth / 2 - 289 / 2, screenHeight / 2 - 232 / 2, 289, 232, "Remote Controlled vehicles", false)
	guiWindowSetSizable(spawnWindow, false)

	-- add a little descriptive text
	local text = guiCreateLabel(8, 23, 272, 47, "Choose the RC vehicle you want to use.\nEach vehicle has a special weapon type with limited ammunition.", false, spawnWindow)
	guiLabelSetHorizontalAlign(text, "left", true)

	-- create a selection gridlist with 4 columns and fill it
	local vehicleList = guiCreateGridList(9, 72, 269, 120, false, spawnWindow)
	guiGridListSetSelectionMode(vehicleList, 0)
	local listItems = {
		{	"Name",		"Type",		"Weapon",		"Ammo",					},
		{	"Bandit",	"car",		"carbomb",		"1 \"BOOM\"",	"441",	},
		{	"Baron",	"plane",	"machinegun",	"50 bullets",	"464",	},
		{	"Raider",	"heli",		"molotov",		"1 bottle",		"465",	},
		{	"Goblin",	"heli",		"aerial bomb",	"1 bomb",		"501",	},
		{	"Tiger",	"tank",		"tank gun",		"1 shell",		"564",	},
	}
	guiGridListAddColumn(vehicleList, listItems[1][1], 0.255)
	guiGridListAddColumn(vehicleList, listItems[1][2], 0.15)
	guiGridListAddColumn(vehicleList, listItems[1][3], 0.3)
	guiGridListAddColumn(vehicleList, listItems[1][4], 0.23)
	for row = 1, 7 do
		guiGridListAddRow(vehicleList)
	end
	for row = 1, 6 do
		for column = 1, 4 do
			guiGridListSetItemText(vehicleList, row, column, listItems[row + 1][column], false, false)
		end
		-- store the vehicle ID as item data on the grid list
		guiGridListSetItemData(vehicleList, row, 1, listItems[row + 1][5])
	end

	-- add an OK button
	local confirmButton = guiCreateButton(22, 196, 100, 25, "OK", false, spawnWindow)
	function processChoice(button, state)
		-- we only want to react to the left mouse button being released
		if button ~= "left" or state ~= "up" then
			return
		end

		-- go up in the element hierarchy and find the gridlist to get the selected row
		local window = getElementParent(source)
		local gridlist = getElementsByType("gui-gridlist", window)
		local row, column = guiGridListGetSelectedItem(gridlist[1])

		-- if no selection has been made abort
		if row == -1 or column == -1 then
			return
		end

		-- relay the selection it to the server and close the window
		triggerServerEvent("onClientRequestsRcVehicle", getLocalPlayer(), tonumber(guiGridListGetItemData(gridlist[1], row, column)))
		guiSetVisible(window, false)
		guiSetInputEnabled(false)
	end
	addEventHandler("onClientGUIClick", confirmButton, processChoice)

	-- add a cancel button to close the window
	local cancelButton = guiCreateButton(167, 196, 100, 25, "Cancel", false, spawnWindow)
	function closeWindow(button, state)
		-- we only want to react to the left mouse button being released
		if button ~= "left" or state ~= "up" then
			return
		end
		
		-- hide the window and disable the mouse
		guiSetVisible(getElementParent(source), false)
		guiSetInputEnabled(false)
	end
	addEventHandler("onClientGUIClick", cancelButton, closeWindow)

	-- hide the window until the server calls for it
	guiSetVisible(spawnWindow, false)
end

-- unhide the window if the server calls for it to be shown
addEvent("onServerTriggersRcGuiOpen", true)
function openGui()
	-- change visibility and enable mouse input
	guiSetVisible(spawnWindow, true)
	guiSetInputEnabled(true)
end
addEventHandler("onServerTriggersRcGuiOpen", root, openGui)