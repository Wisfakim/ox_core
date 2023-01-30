---@type table<string, CGroup>
local GroupRegistry = {}
---Return data associated with the given group name.
---@param name string
---@return CGroup?
function Ox.GetGroup(name)
    local group = GroupRegistry[name]
    return group
end

function Ox.RegisterGroup(name, data)
    GroupRegistry[name] = data
    return true
end

return GroupRegistry
