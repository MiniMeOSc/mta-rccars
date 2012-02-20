local colshape = getElementByID("garage_colshape")
function replaceCollisionModel()
	local col = engineLoadCOL("door.col")
	if col then
		local replacement = engineReplaceCOL(col, 9823)
		if not replacement then
			outputDebugString("The garagedoor collision could not be replaced.", 1)
		end
	else
		outputDebugString("The garagedoor collision could not be loaded.", 1)
	end
end
addEventHandler("onClientColShapeHit", colshape, replaceCollisionModel)

local spawnWindow
do
	local screenWidth, screenHeight = guiGetScreenSize()
	spawnWindow = guiCreateWindow(screenWidth / 2 - 289 / 2, screenHeight / 2 - 232 / 2, 289, 232, "Remote Controlled vehicles", false)
	local text = guiCreateLabel(8, 23, 272, 47, "Choose the RC vehicle you want to use.\nEach vehicle has a special weapon type with limited ammunition.", false, spawnWindow)
	guiWindowSetSizable(spawnWindow, false)
	guiLabelSetHorizontalAlign(text, "left", true)
	local vehicleList = guiCreateGridList(9, 72, 269, 120, false, spawnWindow)
	guiGridListSetSelectionMode(vehicleList, 0)
	local listItems =	{
							{	"Name",		"Type",		"Weapon",		"Ammo",			},
							{	"Goblin",	"heli",		"aerial bomb",	"1 bomb",		"501",	},
							{	"Tiger",	"tank",		"tank gun",		"1 shell",		"564",	},
							{	"Raider",	"heli",		"molotov",		"1 bottle",		"465",	},
							{	"Bandit",	"car",		"carbomb",		"1 \"BOOM\"",	"441",	},
							{	"Baron",	"plane",	"machinegun",	"50 bullets",	"464",	},
							{	"DeLorean",	"car",		"disappear",	"1 use",		"594",	},
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
		guiGridListSetItemData(vehicleList, row, 1, listItems[row + 1][5])
	end
	local confirmButton = guiCreateButton(22, 196, 100, 25, "OK", false, spawnWindow)
	function processChoice(button, state)
		if button == "left" and state == "up" then
			local window = getElementParent(source)
			local gridlist = getElementsByType("gui-gridlist", window)
			local row, column = guiGridListGetSelectedItem(gridlist[1])
			if row ~= -1 and column ~= -1 then
				triggerServerEvent("onClientRequestsRcVehicle", getLocalPlayer(), tonumber(guiGridListGetItemData(gridlist[1], row, column)))
				guiSetVisible(getElementParent(source), false)
				guiSetInputEnabled(false)
			else
				outputChatBox("You need to do a selection!")
			end
		end
	end
	addEventHandler("onClientGUIClick", confirmButton, processChoice)
	local cancelButton = guiCreateButton(167, 196, 100, 25, "Cancel", false, spawnWindow)
	function closeWindow(button, state)
		if button == "left" and state == "up" then
			guiSetVisible(getElementParent(source), false)
			guiSetInputEnabled(false)
		end
	end
	addEventHandler("onClientGUIClick", cancelButton, closeWindow)
	guiSetVisible(spawnWindow, false)
end

addEvent("onServerTriggersRcGuiOpen", true)
function openGui()
	guiSetVisible(spawnWindow, true)
	guiSetInputEnabled(true)
end
addEventHandler("onServerTriggersRcGuiOpen", root, openGui)