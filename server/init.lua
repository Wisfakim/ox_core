Server = {
    PRIMARY_IDENTIFIER = GetConvar('ox:primaryIdentifier', 'license2'),
}

if GetExport('ox_inventory') then
    SetConvarReplicated('inventory:framework', 'ox')
    SetConvarReplicated('inventory:trimplate ', 'false')
end

if GetExport('npwd') then
    SetConvar('npwd:useResourceIntegration', 'true')
    SetConvar('npwd:database', json.encode({
        playerTable = 'characters',
        identifierColumn = 'charid',
    }))
end

require 'server.groups.main'
require 'server.status.main'
require 'server.license.main'
require 'server.player.main'
require 'server.vehicle.main'
