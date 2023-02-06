local MySQL = MySQL
local db = {}

local SELECT_GROUPS = 'SELECT ox_groups.*, ox_groups_types.id as type, ox_groups_types.unique FROM ox_groups, ox_groups_types AS ox_groups_types where ox_groups.type = ox_groups_types.`id` OR ox_groups.type IS NULL GROUP by ox_groups.name'
---Fetch all groups from the database.
function db.selectGroups()
    return MySQL.query.await(SELECT_GROUPS)
end

local ADD_CHARACTER_TO_GROUP = 'INSERT INTO `character_groups` (`charid`, `name`, `grade`) VALUES (?, ?, ?)'
---Adds the group to the character.
---@param charid number
---@param name string
---@param grade number
function db.addCharacterGroup(charid, name, grade)
    MySQL.prepare(ADD_CHARACTER_TO_GROUP, { charid, name, grade })
end

local UPDATE_CHARACTER_GROUP = 'UPDATE `character_groups` SET `grade` = ? WHERE `charid` = ? AND `name` = ?'
---Update the character's grade for the given group.
---@param charid number
---@param name string
---@param grade number
function db.updateCharacterGroup(charid, name, grade)
    MySQL.prepare(UPDATE_CHARACTER_GROUP, { grade, charid, name })
end

local REMOVE_CHARACTER_FROM_GROUP = 'DELETE FROM `character_groups` WHERE `charid` = ? AND `name` = ?'
---Removes the group from the user.
---@param charid number
---@param name string
function db.removeCharacterGroup(charid, name)
    MySQL.prepare(REMOVE_CHARACTER_FROM_GROUP, { charid, name })
end

local INSERT_GROUP_JOB = 'INSERT INTO `ox_groups` (`name`, `label`,`grades`,`hasAccount`, `adminGrade`, `colour`, `type`) VALUES(?, ?, ?, ? ,? ,? ,?)'
--- Insert new group.
--- @param name string
--- @param label string
--- @param grades json
--- @param hasAccount number
--- @param adminGrade number
--- @param colour number 
--- @param type boolean
function db.insertGroupJob(name, data)
    print(json.encode(data.grades, {indents = true}))
    local oxGroupQuery = MySQL.insert.await(INSERT_GROUP_JOB,{
        name,
        data.label,
        json.encode(data.grades),
        1,
        data.adminGrade,
        data.colour or 0,
        data.type or 0})
    return oxGroupQuery
end

--- Rename a job
--- @param oldName string
--- @param newLabel string
--- @param newName string
function db.renameGroupJob(oldName, newName, newLabel)
    local oxGroupQuery = MySQL.execute.await('UPDATE `ox_groups` SET `name` = ? , `label` = ? WHERE `name` = ?', {newName, newLabel, oldName})
    return oxGroupQuery
end

-- Change job color
--- @param name string
--- @param colour number
function db.setGroupColour(name, colour)
    local oxGroupQuery = MySQL.execute.await('UPDATE `ox_groups` SET `colour` = ? WHERE `name` = ?', {colour, name})
    return oxGroupQuery
end


function db.updatePlayersGrades(group, index, minus)
    local charIdLiveUpdated = {}
    local operator = minus and -1 or 1
    local players = Ox.GetPlayers({['groups'] = group})
    if players and next(players) then
        for k, v in pairs(players) do
            local player = Ox.GetPlayerByFilter({['charid'] = v.charid})
            local group, grade = player:hasGroup(group)
            if grade >= index then
                player:setGroup(group, grade + operator)
                print('Live Update ')
                charIdLiveUpdated[v.charid] = true
            end
        end
    end
    -- Offline players update
    local offlinePlayers = MySQL.query.await('SELECT * FROM `character_groups` WHERE `name` = ? AND `grade` >= ?', {group, index})
    if offlinePlayers and next(offlinePlayers) then
        for k, v in pairs(offlinePlayers) do
            if not charIdLiveUpdated[v.charid] then
                print('Offline Update')
                local newGrade = v.grade + operator
                MySQL.execute.await('UPDATE `character_groups` SET `grade` = ? WHERE `charid` = ? AND `name` = ?', {newGrade, v.charid, group})
            end
        end
    end
    return true
end
function db.updateGrades(group, newGrades)
    local newAdminGrade = #newGrades
    return MySQL.execute.await('UPDATE `ox_groups` SET `grades` = ?,`adminGrade` = ? WHERE `name` = ?', {json.encode(newGrades), newAdminGrade, group})
end

-- function db.updateGroupGrades(group, grades, isNewAdminGrade)
--     local adminGrade = #grades
--     local oxGroupQuery = MySQL.execute.await('UPDATE `ox_groups` SET `grades` = ?,`adminGrade` = ? WHERE `name` = ?', {json.encode(grades), adminGrade, group})
--     print(adminGrade)
--     if oxGroupQuery then
--         print('New Admin grade'..isNewAdminGrade)
--         if isNewAdminGrade and tonumber(isNewAdminGrade) > 0 then
--             local players = Ox.GetPlayers({['groups'] = group})
--             local newAdminGrade = #grades
--             local prevAdminGrade = isNewAdminGrade
--             print(json.encode(players, {indents = true}))
--             if players and next(players) then
--                 for k, v in pairs(players) do
--                      -- Live setter group
--                      -- Set who are not online so use the db
--                      -- Return to regisery the group of player need to be updated live else update here
--                      -- Decaler les autres grades aussi is besoin
--                     print(v)
--                     local player = Ox.GetPlayerByFilter({['charid'] = v.charid})
--                     local group, grade = player:hasGroup(group)
--                     if grade == prevAdminGrade then
--                         print('update player')
--                         player:setGroup(group, newAdminGrade)
--                     end
--                 end
--             end
--         end
--         return true
--     end
--     return false
-- end
return db
