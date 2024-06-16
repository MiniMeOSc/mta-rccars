------------------------------
-- Script wide used variables
------------------------------

-- Define a list of vehicle IDs with the rc vehicles
local g_rcVehicles = { 
	[441]=true, -- Bandit
	[464]=true, -- Baron
	[465]=true, -- Raider
	[501]=true, -- Goblin
	[564]=true  -- Tiger
}

-- get the garage door element from the map
local g_garageDoor = getElementByID("garagedoor")

-- get the collision shape element for the garage door from the map
local g_colshape = getElementByID("garage_colshape")

------------------------------
--	Functionality
------------------------------

-- recreate the garage collision shape from the map
do -- enter a new block, makes the following variables only visible and exisiting until we leave it again
	local ID = getElementID(g_colshape)
	local posX, posY, posZ = getElementPosition(g_colshape)
	local width = getElementData(g_colshape, "width")
	local depth = getElementData(g_colshape, "depth")
	local height = getElementData(g_colshape, "height")
	local dimension = getElementData(g_colshape, "dimension")
	destroyElement(g_colshape)
	g_colshape = createColCuboid(posX, posY, posZ, width, depth, height)
	setElementDimension(g_colshape, dimension)
	setElementID(g_colshape, ID)
end

-- recreate the marker from the map
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

-- shrink the garage door a little as the model is larger than the actual hole
setObjectScale(g_garageDoor, .75)

-- when all players leave the hitbox near the garage door, close the door
function closeGarageDoor(hitElement, matchingDimension)
	-- if a player had left the hitbox in the same dimension and there are no more other players in the hitbox
	if getElementType(hitElement) == "player" and matchingDimension and #getElementsWithinColShape(source, "player") < 1 then
		setGarageDoorOpen(false)
	end
end
addEventHandler("onColShapeLeave", g_colshape, closeGarageDoor)

-- if a player is in the way of the garage door stop its movement
function stopGarageDoor(hitElement, matchingDimension)
	-- if there's a player in the same dimension inseide the hitbox
	if getElementType(hitElement) == "player" and matchingDimension and #getElementsWithinColShape(source, "player") > 0 then
		-- stop the movement if it's open
		if getElementData(g_garageDoor, "state") then
			stopObject(g_garageDoor)
		end
	end
end
addEventHandler("onColShapeHit", g_colshape, stopGarageDoor)

-- show the vehicle selection ui if the player enters the marker
function openGui(hitElement, matchingDimension)
	-- make sure it's the player entering the hitbox and they're in the same dimension
	if getElementType(hitElement) == "player" and matchingDimension then 
		triggerClientEvent(hitElement, "onServerTriggersRcGuiOpen", hitElement)
	end
end
addEventHandler("onMarkerHit", marker, openGui)

-- open or close the garage door
function setGarageDoorOpen(state)
	-- define the coordinates for the opened and closed position of the gate
	local pos = { 
		[true]= {x = 189.19999694824, y = 1931.8000488281, z = 19.8},  -- opened
		[false]={x = 189.19999694824, y = 1931.8000488281, z = 17.85}, -- closed
	}

	-- if no state has been given as parameter, get its current state from the element
	if state == nil then
		-- if the state has not yet been set, i.e. it has not yet been opened, assume it's closed
		state = getElementData(g_garageDoor, "state") or false 
	end

	-- invert the state currently stored on the element
	setElementData(g_garageDoor, "state", not state) 

	-- move the door. Apply a percentage for the movement it is being interrupted mid movement to normalize the speed
	-- (i.e. it's still closing but someone is already triggering it again to open. Prevent it from opening too slow)
	local curentPosX, curentPosY, curentPosZ = getElementPosition(g_garageDoor)
	local percentage = getDistanceBetweenPoints3D(curentPosX, curentPosY, curentPosZ, pos[state]["x"], pos[state]["y"], pos[state]["z"]) / getDistanceBetweenPoints3D(pos[state]["x"], pos[state]["y"], pos[state]["z"], pos[not state]["x"], pos[not state]["y"], pos[not state]["z"])
	moveObject(g_garageDoor, 5000*percentage, pos[state]["x"], pos[state]["y"], pos[state]["z"])
end

-- spawn an rc car for the player when they click OK on the ui to select one
addEvent("onClientRequestsRcVehicle", true)
function spawnRcVehicle(modelID)
	-- abort if the player is already in rc mode
	if not exports["RcMode"]:isPlayerInRcMode(playerSource) then
		return
	end
	
	-- create a vehicle, put it in the same dimension as the player and enter rc mode with them
	local rcVehicle = createVehicle(modelID, 192.48693847656, 1931.5092773438, 17.094734191895, 0, 0, 88.845092773438)
	setElementDimension(rcVehicle, getElementDimension(source))
	exports["RcMode"]:enterRcMode(source, rcVehicle)

	-- open the garage door so they can drive out
	setGarageDoorOpen(true)
end
addEventHandler("onClientRequestsRcVehicle", root, spawnRcVehicle)

-- call to the rc mode resource to exit rc mode
function exitRcMode(keyPresser)
	local rcVehicle = getPedOccupiedVehicle(keyPresser)
	-- is the player remote controlling one of our rc models?
	if exports["RcMode"]:isPlayerInRcMode(keyPresser) and g_rcVehicles[getElementModel(rcVehicle)] then
		exports["RcMode"]:exitRcMode(keyPresser)

		-- go out with a bang
		blowVehicle(rcVehicle)
	end
end

-- bind key inputs for the player
function bindKeys(player)
	bindKey(player, "enter_exit", "down", exitRcMode)
end

-- handle a player joining the game
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

-- helper function to check whether there's an occupant in the vehicle
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

-- despawn a vehicle and remove map blips and markers
function despawnVehicle(vehicle)
	-- make sure the argument passed is an mta element
	if not isElement(vehicle) then
		return
	end

	-- make sure the vehicle is not occupied
	if isVehicleOccupied(vehicle) then
		return
	end

	-- get any attached elements such as map blips or markers and destroy them
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

	-- now destroy the vehicle
	destroyElement(vehicle)
end

-- create a despawn timer that will despawn the rc cars if they are unsused for more than 60 seconds
function setDespawnTimer()
	setTimer(despawnVehicle, 60000, 1, source)
end
addEventHandler("onVehicleExplode", resourceRoot, setDespawnTimer)

-- prevent other players from entering an rc car (they're way too small for them anyways)
function stopEnteringOrExitingRcCar()
	-- check if the car they want to enter is an rc car
	if g_rcVehicles[getElementModel(source)] then
		cancelEvent()
	end
end
addEventHandler("onVehicleStartEnter", resourceRoot, stopEnteringOrExitingRcCar)
addEventHandler("onVehicleStartExit", resourceRoot, stopEnteringOrExitingRcCar)
