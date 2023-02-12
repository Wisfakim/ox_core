---@class OxGroupProperties
---@field name string
---@field label string
---@field grades number[]
---@field principal string
---@field hasAccount boolean
---@field adminGrade number
---@field type = number
---@field isUniqueType = boolean

---@class OxGroup : OxGroupProperties
local OxGroup = {}
local pefcl = GetExport('pefcl')

---@param player OxPlayer
---@param grade number
function OxGroup:add(player, grade)
    lib.addPrincipal(player.source, ('%s:%s'):format(self.principal, grade))
    local playerGroups = player.private.groups
    playerGroups[self.name] = grade
    GlobalState[('%s:count'):format(self.name)] += 1

    if pefcl then
        self:setAccount(player, grade)
    end
end

---@param player OxPlayer
---@param grade number
function OxGroup:remove(player, grade)
    lib.removePrincipal(player.source, ('%s:%s'):format(self.principal, grade))
    local playerGroups = player.private.groups
    playerGroups[self.name] = nil
    GlobalState[('%s:count'):format(self.name)] -= 1

    if pefcl then
        self:setAccount(player, grade, true)
    end
end

---@param player OxPlayer
---@param grade number
---@param remove? boolean
function OxGroup:setAccount(player, grade, remove)
    local maxGrade = #self.grades

    if remove then
        if player.charid and grade >= maxGrade - 1 and exports.pefcl:getUniqueAccount(player.source, self.name).data then
            pefcl:removeUserFromUniqueAccount(player.source, {
                userIdentifier = player.charid,
                accountIdentifier = self.name
            })
        end
    else
        if self.hasAccount and grade >= maxGrade - 1 then
            if not exports.pefcl:getUniqueAccount(player.source, self.name).data then
                pefcl:createUniqueAccount(player.source, {
                    name = self.label,
                    type = 'shared',
                    identifier = self.name
                })
            end

            pefcl:addUserToUniqueAccount(player.source, {
                role = grade >= self.adminGrade and 'admin' or 'contributor',
                accountIdentifier = self.name,
                userIdentifier = player.charid,
                source = player.source,
            })
        end
    end
end

local db = require 'server.groups.db'

---@param player OxPlayer
---@param grade? number
function OxGroup:set(player, grade)
    if not grade then grade = 0 end

    if not self.grades[grade] and grade > 0 then
        error(("Attempted to set group '%s' to invalid grade '%s for player.%s"):format(self.name, grade, player.source))
    end

    local currentGrade = player.private.groups[self.name]

    if currentGrade then
        if currentGrade == grade then return end
        self:remove(player, currentGrade)
    else
        if self.type and self.isUniqueType then
            for groupName in pairs(player.private.groups) do
                local group = Ox.GetGroup(groupName)
                if group.type == self.type then
                    warn(("Attempted to add multiple unique group '%s' with '%s' for player.%s"):format(self.type, self.name, player.source))
                    return false
                end
            end
        end
    end

    if grade < 1 then
        if not currentGrade then return end
        grade = nil
        db.removeCharacterGroup(player.charid, self.name)
    else
        if currentGrade then
            db.updateCharacterGroup(player.charid, self.name, grade)
        else
            db.addCharacterGroup(player.charid, self.name, grade)
        end

        self:add(player, grade)
    end

    TriggerEvent('ox:setGroup', player.source, self.name, grade)
    TriggerClientEvent('ox:setGroup', player.source, self.name, grade)

    return true
end

local Class = require 'shared.class'
return Class.new(OxGroup)
