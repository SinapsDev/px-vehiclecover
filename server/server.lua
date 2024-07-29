Covers = {}

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    local loadFile = LoadResourceFile(GetCurrentResourceName(), "./files/data.json")
    Covers = json.decode(loadFile)

    if Config.Framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()

        exports['qb-core']:AddItem('vehicle_cover', {
            name = 'vehicle_cover',
            label = 'Vehicle cover',
            weight = 0,
            type = 'item',
            image = 'vehicle_cover.png',
            unique = false,
            useable = true,
            shouldClose = true,
            combinable = nil,
        })

        QBCore.Functions.CreateUseableItem("vehicle_cover", function(source, item)
            local src = source
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.Functions.GetItemByName(item.name) then
                TriggerClientEvent("px-cover:CoverVehicle", src)
                Player.Functions.RemoveItem("vehicle_cover", 1)
            end
        end)

        QBCore.Functions.CreateCallback("px-garages:isVehicleOwner", function(source, cb, plate)
            local Player = QBCore.Functions.GetPlayer(source)
            local isOwned = MySQL.scalar.await(
                'SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1',
                {plate})
            cb(isOwned == Player.PlayerData.citizenid)
        end)
        

        QBCore.Functions.CreateCallback("px-garages:uncoverVehicle", function(source, cb, id)
            if not Covers[id] then return end
            local cover = Covers[id]
            local uncoverPrice = math.ceil(Config.pricePerHour * (os.time() - cover.time) / 3600)
            local Player = QBCore.Functions.GetPlayer(source)
            if Config.payForUncover then
                if Player.Functions.RemoveMoney('cash', uncoverPrice) then
                    cb(true)
                else
                    cb(false)
                end
            end
            cb(true)
        end)

        QBCore.Functions.CreateCallback("px-garages:getAllCovers", function(source, cb)
            cb(Covers)
        end)

        QBCore.Functions.CreateCallback("px-garage:getVehiclesStats", function(source, cb, plate)
            vehicle = MySQL.rawExecute.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
            local data = vehicle[1]
            local stats = {
                fuel = data.fuel,
                engine = data.engine,
                body = data.body
            }
            cb({
                stats = stats,
                model = data.vehicle
            })
        end)
    elseif Config.Framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
        ESX.RegisterServerCallback("px-garages:isVehicleOwner", function(source, cb, plate)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return end
            local isOwned = MySQL.scalar.await("SELECT owner FROM owned_vehicles WHERE plate = ? LIMIT 1", {plate})
            cb(isOwned == xPlayer.getIdentifier())
        end)

        ESX.RegisterUsableItem('vehicle_cover', function(source)
            local src = source
            local xPlayer = ESX.GetPlayerFromId(src)
            TriggerClientEvent("px-cover:CoverVehicle", src)
            xPlayer.removeInventoryItem("vehicle_cover", 1)
        end)
        
        ESX.RegisterServerCallback("px-garages:uncoverVehicle", function(source, cb, id)
            if not Covers[id] then return end
            local cover = Covers[id]
            local uncoverPrice = math.ceil(Config.pricePerHour * (os.time() - cover.time) / 3600)
            local xPlayer = ESX.GetPlayerFromId(source)
            if Config.payForUncover then
                if xPlayer.getMoney() >= uncoverPrice then
                    xPlayer.removeMoney(uncoverPrice)
                    cb(true)
                else
                    cb(false)
                end
            end
            cb(true)
        end)

        ESX.RegisterServerCallback("px-garages:getAllCovers", function(source, cb)
            cb(Covers)
        end)

        ESX.RegisterServerCallback("px-garage:getVehiclesStats", function(source, cb, plate)
            local vehicle = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ?", {plate})
            local data = vehicle[1]
            local stats = {
                fuel = data.fuel,
                engine = data.engine,
                body = data.body
            }
            cb({
                stats = stats,
                model = json.encode(vehicle).vehicle
            })
        end)

        ESX.RegisterServerCallback("px-cover:spawnGarage", function(source, cb, plate, spawn, heading)
            local source = source
            local xPlayer  = ESX.GetPlayerFromId(source)
            local vehicle = MySQL.update('UPDATE owned_vehicles SET `stored` = @stored WHERE `plate` = @plate AND `owner` = @identifier',
            {
                ['@plate'] 		= plate,
                ['@stored']     = 1,
            })
    
            MySQL.query('SELECT * FROM owned_vehicles WHERE `plate` = @plate AND `owner` = @identifier',
            {
                ['@plate'] 		= plate,
                ['@identifier'] = xPlayer.identifier
            }, function(result)
                if result[1] then
                    local data = result[1]
                    ESX.OneSync.SpawnVehicle(json.decode(data.vehicle).model, spawn, heading, json.decode(data.vehicle), function(vehicle)
                        cb(vehicle)
                    end)
                end
            end)
        end)
    end
end)

function SaveToFile()
    SaveResourceFile(GetCurrentResourceName(), "./files/data.json", json.encode(Covers, {indent = true}), -1)
end

RegisterServerEvent('px-garages:saveCover', function(plate, coords, heading, prop, modelName, model)
    Covers[#Covers+1] = {
        id = #Covers+1,
        plate = plate,
        prop = prop,
        coords = coords,
        heading = heading,
        model = model,
        modelName = modelName,
        time = os.time(),
        price = 1
    }
    TriggerClientEvent("px-cover:addCover", -1, #Covers, Covers[#Covers])
    SaveToFile()
end)

Citizen.CreateThread(function()
    while true do
        for k, v in pairs(Covers) do
            v.price = math.ceil(Config.pricePerHour * (os.time() - v.time) / 3600)
        end
        SaveToFile()
        TriggerClientEvent("px-cover:updateCovers", -1, Covers)
        Wait(1000*60*2)
    end
end)

RegisterNetEvent("px-cover:removeCover", function(id)
    local source = source
    if Covers[id] then
        Covers[id] = nil
        TriggerClientEvent("px-cover:removeCover", -1, id)
        SaveToFile()
    end
    if not Config.AddCoverItemAfterUncover then return end
    if Config.Framework == "qb" then
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.AddItem("vehicle_cover", 1, nil, nil)
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addInventoryItem("vehicle_cover", 1)
    end
end)