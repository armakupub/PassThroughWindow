require "PassThroughWindow_Action"

local PTW = {}

PTW.allowedTypes = {
    ["Base.Generator"] = true,
    ["Base.Generator_Blue"] = true,
    ["Base.Generator_Yellow"] = true,
    ["Base.Generator_Old"] = true,
}

function PTW.isPassableItem(character)
    local item = character:getPrimaryHandItem()
    if not item then return false end
    local fullType = item:getFullType()
    return PTW.allowedTypes[fullType] == true
end

-- A north-facing window on (wx, wy) connects (wx, wy) with (wx, wy - 1).
-- Any other orientation connects (wx, wy) with (wx - 1, wy).
function PTW.getWindowSides(window)
    local windowSq = window:getSquare()
    if not windowSq then return nil, nil end

    local wx = windowSq:getX()
    local wy = windowSq:getY()
    local wz = windowSq:getZ()
    local north = window:getNorth()

    local cell = getCell()
    if not cell then return nil, nil end

    local sideA = windowSq
    local sideB
    if north then
        sideB = cell:getGridSquare(wx, wy - 1, wz)
    else
        sideB = cell:getGridSquare(wx - 1, wy, wz)
    end

    return sideA, sideB
end

function PTW.getTargetSquare(character, window)
    local playerSq = character:getCurrentSquare()
    if not playerSq then return nil end

    local sideA, sideB = PTW.getWindowSides(window)
    if not sideA or not sideB then return nil end

    -- Player closer to sideA means target is sideB, and vice versa.
    local distA = math.abs(playerSq:getX() - sideA:getX()) + math.abs(playerSq:getY() - sideA:getY())
    local distB = math.abs(playerSq:getX() - sideB:getX()) + math.abs(playerSq:getY() - sideB:getY())

    if distA <= distB then
        return sideB
    else
        return sideA
    end
end

function PTW.isWindowPassable(window)
    if window:isDestroyed() then return true end
    if window:IsOpen() then return true end
    if window:isSmashed() then return true end
    return false
end

function PTW.onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    if not PTW.isPassableItem(playerObj) then return end

    local window = nil
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoWindow") or instanceof(obj, "IsoDoor") and obj:isWindow() then
            window = obj
            break
        end
    end

    if not window then return end

    local item = playerObj:getPrimaryHandItem()
    local itemName = item:getDisplayName()
    local menuLabel = getText("UI_PTW_PassThrough", itemName)

    if not PTW.isWindowPassable(window) then
        local option = context:addOption(menuLabel, nil, nil)
        option.notAvailable = true
        local tooltip = ISToolTip:new()
        tooltip.description = getText("UI_PTW_WindowClosed")
        option.toolTip = tooltip
        return
    end

    local targetSquare = PTW.getTargetSquare(playerObj, window)
    if not targetSquare then return end

    if not targetSquare:isFree(false) then
        local option = context:addOption(menuLabel, nil, nil)
        option.notAvailable = true
        local tooltip = ISToolTip:new()
        tooltip.description = getText("UI_PTW_OtherSideBlocked")
        option.toolTip = tooltip
        return
    end

    local option = context:addOption(menuLabel, playerObj, PTW.onPassThroughWindow, window, targetSquare)

    local tooltip = ISToolTip:new()
    tooltip.description = getText("UI_PTW_PushTooltip", itemName)
    option.toolTip = tooltip
end

-- Returns the square on the player's side of the window. Used as a walk
-- target so the player doesn't auto-climb through when the menu is clicked.
function PTW.getPlayerSideSquare(character, window)
    local playerSq = character:getCurrentSquare()
    if not playerSq then return nil end

    local sideA, sideB = PTW.getWindowSides(window)
    if not sideA or not sideB then return nil end

    local distA = math.abs(playerSq:getX() - sideA:getX()) + math.abs(playerSq:getY() - sideA:getY())
    local distB = math.abs(playerSq:getX() - sideB:getX()) + math.abs(playerSq:getY() - sideB:getY())

    if distA <= distB then
        return sideA
    else
        return sideB
    end
end

function PTW.onPassThroughWindow(playerObj, window, targetSquare)
    local playerSideSq = PTW.getPlayerSideSquare(playerObj, window)
    if not playerSideSq then return end

    local walkAction = ISWalkToTimedAction:new(playerObj, playerSideSq)
    ISTimedActionQueue.add(walkAction)
    ISTimedActionQueue.add(PassThroughWindowAction:new(playerObj, window, targetSquare))
end

Events.OnPreFillWorldObjectContextMenu.Add(PTW.onFillWorldObjectContextMenu)
