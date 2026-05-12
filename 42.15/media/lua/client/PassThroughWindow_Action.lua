require "TimedActions/ISBaseTimedAction"

PassThroughWindowAction = ISBaseTimedAction:derive("PassThroughWindowAction")

function PassThroughWindowAction:isValid()
    local item = self.character:getPrimaryHandItem()
    if not item then return false end
    if not self.window then return false end
    return true
end

function PassThroughWindowAction:start()
    self.character:faceThisObject(self.window)
    self:setActionAnim("Loot")
end

function PassThroughWindowAction:update()
end

function PassThroughWindowAction:stop()
    ISBaseTimedAction.stop(self)
end

function PassThroughWindowAction:perform()
    local item = self.character:getPrimaryHandItem()
    if not item then
        ISBaseTimedAction.perform(self)
        return
    end

    self.character:removeFromHands(item)
    local playerInv = self.character:getInventory()
    playerInv:Remove(item)
    self.targetSquare:AddWorldInventoryItem(item, 0.5, 0.5, 0.0)

    ISBaseTimedAction.perform(self)
end

function PassThroughWindowAction:new(character, window, targetSquare)
    local o = ISBaseTimedAction.new(self, character)
    o.window = window
    o.targetSquare = targetSquare
    o.maxTime = 150  -- ~2.5 seconds
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

return PassThroughWindowAction
