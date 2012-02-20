local rcVehicles = { [441]=true, [464]=true, [594]=true, [501]=true, [465]=true, [564]=true, }

local garageDoor = getElementByID("garagedoor")
setObjectScale(garageDoor, .75)

local colshape = getElementByID("garage_colshape")
do -- enter a new block, makes the following variables only visible and exisiting until we leave it again
	local ID = getElementID(colshape)
	local posX, posY, posZ = getElementPosition(colshape)
	local width = getElementData(colshape, "width")
	local depth = getElementData(colshape, "depth")
	local height = getElementData(colshape, "height")
	local dimension = getElementData(colshape, "dimension")
	destroyElement(colshape)
	colshape = createColCuboid(posX, posY, posZ, width, depth, height)
	setElementDimension(colshape, dimension)
	setElementID(colshape, ID)
end

function closeGarageDoor(hitElement, matchingDimension)
	if getElementType(hitElement) == "player" and matchingDimension and #getElementsWithinColShape(source, "player") < 1 then
		setGarageDoorOpen(false)
	end
end
addEventHandler("onColShapeLeave", colshape, closeGarageDoor)

function stopGarageDoor(hitElement, matchingDimension)
	if getElementType(hitElement) == "player" and matchingDimension and #getElementsWithinColShape(source, "player") > 0 then
		if getElementData(garageDoor, "state") then
			stopObject(garageDoor)
		end
	end
end
addEventHandler("onColShapeHit", colshape, stopGarageDoor)

local marker = getElementByID("marker")
do -- enter a new block, makes the following variables only visible and exisiting until we leave it again
	local ID = getElementID(marker)
	local posX, posY, posZ = getElementPosition(marker)
	local markerType = getMarkerType(marker)
	local size = getMarkerSize(marker)
	local r, g, b, a = getMarkerColor(marker)
	local dimension = getElementData(marker, "dimension")
	destroyElement(marker)
	marker = createMarker(posX, posY, posZ, markerType, size, r, g, b, a, root)
	setElementDimension(marker, dimension)
	setElementID(marker, ID)
end

function openGui(hitElement, matchingDimension)
	if getElementType(hitElement) == "player" and matchingDimension then 
		triggerClientEvent(hitElement, "onServerTriggersRcGuiOpen", hitElement)
	end
end
addEventHandler("onMarkerHit", marker, openGui)

function setGarageDoorOpen(state)
	local pos = { [true]={x = 189.19999694824, y = 1931.8000488281, z = 19.8}, [false]={x = 189.19999694824, y = 1931.8000488281, z = 17.85}, }
	if state == nil then
		state = getElementData(garageDoor, "state") or false -- "or false" if the state has not yet been set, i.e. it has not yet been opened
	end
	setElementData(garageDoor, "state", not state) -- if it is currently closed, assign it the state value that it is open(ing) ("not state" assigns the opposite of state)
	local curentPosX, curentPosY, curentPosZ = getElementPosition(garageDoor)
	local percentage = getDistanceBetweenPoints3D(curentPosX, curentPosY, curentPosZ, pos[state]["x"], pos[state]["y"], pos[state]["z"]) / getDistanceBetweenPoints3D(pos[state]["x"], pos[state]["y"], pos[state]["z"], pos[not state]["x"], pos[not state]["y"], pos[not state]["z"])
	moveObject(garageDoor, 5000*percentage, pos[state]["x"], pos[state]["y"], pos[state]["z"])
end

addEvent("onClientRequestsRcVehicle", true)
function spawnRcVehicle(modelID)
	if not exports["RcMode"]:isPlayerInRcMode(playerSource) then
		local rcVehicle = createVehicle(modelID, 192.48693847656, 1931.5092773438, 17.094734191895, 0, 0, 88.845092773438)
		setElementDimension(rcVehicle, getElementDimension(source))
		exports["RcMode"]:enterRcMode(source, rcVehicle)
		setGarageDoorOpen(true)
	end
end
addEventHandler("onClientRequestsRcVehicle", root, spawnRcVehicle)

function exitRcMode(keyPresser)
	local rcVehicle = getPedOccupiedVehicle(keyPresser)
	if exports["RcMode"]:isPlayerInRcMode(keyPresser) and rcVehicles[getElementModel(rcVehicle)] then
		exports["RcMode"]:exitRcMode(keyPresser)
		blowVehicle(rcVehicle)
	end
end
function bindKeys(player)
	bindKey(player, "enter_exit", "down", exitRcMode)
end
function playerJoinHandler()
	bindKeys(source)
end
addEventHandler("onPlayerJoin", resourceRoot, playerJoinHandler)
function resourceStartHandler()
	local players = getElementsByType("player")
	for i = 1, #players, 1 do
		bindKeys(players[i])
	end
end
addEventHandler("onResourceStart", resourceRoot, resourceStartHandler)

function isVehicleOccupied(vehicle)
	local occupants = getVehicleOccupants(vehicle)
	local seats = getVehicleMaxPassengers(vehicle)
	for i = 0, seats do
		if isElement(occupants[i]) then
			return true
		end
	end
	return false
end

function despawnVehicle(vehicle)
	if isElement(vehicle) then
		if not isVehicleOccupied(vehicle) then
			local attachedElements = getAttachedElements(vehicle)
			if attachedElements then
				for elementKey, elementValue in ipairs(attachedElements) do
					if isElement(elementValue) then
						if getElementType(elementValue) == "blip" or getElementType(elementValue) == "marker" then
							destroyElement(elementValue)
						end
					end
				end
			end
			destroyElement(vehicle)
		end
	end
end
function setDespawnTimer()
	setTimer(despawnVehicle, 60000, 1, source)
end
addEventHandler("onVehicleExplode", resourceRoot, setDespawnTimer)

function stopEnteringOrExitingRcCar()
	if rcVehicles[getElementModel(source)] then
		cancelEvent()
	end
end
addEventHandler("onVehicleStartEnter", resourceRoot, stopEnteringOrExitingRcCar)
addEventHandler("onVehicleStartExit", resourceRoot, stopEnteringOrExitingRcCar)
