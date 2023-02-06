local GroupRegistry = require 'server.groups.registry'
local CGroup = require 'server.groups.class'
local db = require 'server.groups.db'

---Load groups from the database and creates permission groups.
local function loadGroups()
    local results = db.selectGroups()

    if results then
        for _, data in pairs(GroupRegistry) do
            local parent = data.principal

            lib.removeAce(parent, parent)

            for j = 0, #data.grades do
                local child = ('%s:%s'):format(data.principal, j)
                lib.removeAce(child, child)
                lib.removePrincipal(child, parent)
                parent = child
            end
        end

        for i = 1, #results do
            local group = results[i]
            local principal = ('group.%s'):format(group.name)
            group.grades = json.decode(group.grades--[[@as string]] )

            if not IsPrincipalAceAllowed(principal, principal) then
                lib.addAce(principal, principal)
            end

            local parent = principal

            for j = 0, #group.grades do
                local child = ('%s:%s'):format(principal, j)

                if not IsPrincipalAceAllowed(child, child) then
                    lib.addAce(child, child)
                    lib.addPrincipal(child, parent)
                end

                parent = child
            end

            GroupRegistry[group.name] = CGroup.new({
                name = group.name,
                label = group.label,
                grades = group.grades,
                principal = principal,
                hasAccount = group.hasAccount,
                adminGrade = group.adminGrade,
                type = group.type or nil,
                isUniqueType = group.unique or nil
            })

            GlobalState[principal] = GroupRegistry[group.name]
            GlobalState[('%s:count'):format(group.name)] = 0
        end
    end
end

function Ox.AddGroup(name, data)
    local insert = db.insertGroupJob(name,data)
    if insert then
        local group = CGroup.new({
            name = name,
            label = data.label,
            grades = data.grades,
            hasAccount = data.hasAccount,
            adminGrade = data.adminGrade,
            colour = data.colour,
            type = data.type,
        })
        return Ox.RegisterGroup(name,group)
    end
    return false
end

function Ox.RenameGroup(oldName, newName, newLabel)
    local rename = db.renameGroupJob(oldName,newName, newLabel)
    if rename then
        local group = GroupRegistry[oldName]
        if group then
            group.name = newName
            group.label = newLabel
            GroupRegistry[oldName] = nil
            GroupRegistry[newName] = group
            return true
        end
    end
    return false
end

function Ox.SetGroupColour(name, colour)
    local set = db.setGroupColour(name,colour)
    if set then
        local group = GroupRegistry[name]
        if group then
            group.colour = colour
            return true
        end
    end
    return false
end

function Ox.AddGroupGrade(group, index, label)
    local oxgroup = GroupRegistry[group]
    if oxgroup then
        local newGrades = {}
        for i = 1, #oxgroup.grades do
            if i == index then
                newGrades[i] = label
                newGrades[i + 1] = oxgroup.grades[i]
            elseif i > index then
                newGrades[i + 1] = oxgroup.grades[i]
            else
                newGrades[i] = oxgroup.grades[i]
            end
        end
        local add = db.updateGrades(group, newGrades)
        if add then
            GroupRegistry[group].grades = newGrades
            GroupRegistry[group].adminGrade = #newGrades
            db.updatePlayersGrades(group, index, false)
            return true
        end
    end
    return false
end

function Ox.RemoveGroupGrade(group, index)
    local oxgroup = GroupRegistry[group]
    print(group)
    print(index)
    if oxgroup then
        if tonumber(index) >= tonumber(oxgroup.adminGrade) then
            return false
        end
        local newGrades = {}
        for i = 1, #oxgroup.grades do
            if i ~= index then
                newGrades[#newGrades+1] = oxgroup.grades[i]
            end
        end
        local remove = db.updateGrades(group, newGrades)
        if remove then
            GroupRegistry[group].grades = newGrades
            GroupRegistry[group].adminGrade = #newGrades
            db.updatePlayersGrades(group, index, true)
            return true
        end
    end
    return false
end

MySQL.ready(loadGroups)

lib.addCommand('group.admin', 'refreshgroups', loadGroups)

lib.addCommand('group.admin', 'setgroup', function(source, args)
    local player = Ox.GetPlayer(args.target)
    return player and player:setGroup(args.group, args.grade)
end, { 'target:number', 'group:string', 'grade:number' })
