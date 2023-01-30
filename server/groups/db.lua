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

return db
