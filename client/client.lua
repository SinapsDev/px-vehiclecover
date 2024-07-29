Covers = {}

if Config.Framework == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == "esx" then
    ESX = exports['es_extended']:getSharedObject()
end

function ShowHelp(text, n)
    BeginTextCommandDisplayHelp(text)
    EndTextCommandDisplayHelp(n or 0, false, true, -1)
end

function ShowFloatingHelp(text, pos)
    SetFloatingHelpTextWorldPosition(1, pos)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    ShowHelp(text, 2)
end

local function doCarDamage(currentVehicle, stats, props)
    local engine = stats.engine + 0.0
    local body = stats.body + 0.0
    SetVehicleEngineHealth(currentVehicle, engine)
    SetVehicleBodyHealth(currentVehicle, body)
    if not next(props) then return end
    if props.doorStatus then
        for k, v in pairs(props.doorStatus) do
            if v then SetVehicleDoorBroken(currentVehicle, tonumber(k), true) end
        end
    end
    if props.tireBurstState then
        for k, v in pairs(props.tireBurstState) do
            if v then SetVehicleTyreBurst(currentVehicle, tonumber(k), true) end
        end
    end
    if props.windowStatus then
        for k, v in pairs(props.windowStatus) do
            if not v then SmashVehicleWindow(currentVehicle, tonumber(k)) end
        end
    end
end

RegisterNetEvent("px-cover:updateCovers", function(covers)
    Covers = covers
end)

function Thread()
    Citizen.CreateThread(function()
        local interval = 600
        local playerPed = PlayerPedId()
        while true do
            local coords = GetEntityCoords(playerPed)
            for k, v in pairs(Covers) do
                AddTextEntry("VOLE_VEH_MISSION", "~INPUT_CONTEXT~ Uncover Vehicle for ~g~$" .. v.price .."\n~w~~b~Plate:~s~ "..v.plate .."\n~b~Model:~s~"..v.modelName)
                local cover = v
                local distance = #(coords - vector3(cover.coords.x, cover.coords.y, cover.coords.z))
                if distance <= 2.0 then
                    interval = 1
                    ShowFloatingHelp("VOLE_VEH_MISSION", vector3(cover.coords.x, cover.coords.y, cover.coords.z+.6))
                    if IsControlJustPressed(1, 38) then
                        if Config.Framework == "qb" then
                            QBCore.Functions.TriggerCallback("px-garages:uncoverVehicle", function(success)
                                if success then
                                    TriggerServerEvent("px-cover:removeCover", cover.id)
                                    QBCore.Functions.TriggerCallback('px-garage:getVehiclesStats', function(data)
                                        QBCore.Functions.TriggerCallback('qb-garages:server:spawnvehicle', function(netId, properties, vehPlate)
                                        while not NetworkDoesNetworkIdExist(netId) do Wait(10) end
                                        local veh = NetworkGetEntityFromNetworkId(netId)
                                            QBCore.Functions.SetVehicleProperties(veh, properties)
                                            SetEntityHeading(veh, cover.heading)
                                            exports[Config.FuelResource]:SetFuel(veh, data.stats.fuel)
                                            TriggerServerEvent('qb-garages:server:updateVehicleState', 0, vehPlate)
                                            TriggerEvent('vehiclekeys:client:SetOwner', vehPlate)
                                            if Config.Warp then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
                                            if Config.VisuallyDamageCars then doCarDamage(veh, data.stats, properties) end
                                            SetVehicleEngineOn(veh, true, true, false)
                                        end, cover.plate, data.model, vector3(cover.coords.x, cover.coords.y, cover.coords.z))
                                    end, cover.plate)
                                else
                                    QBCore.Functions.Notify("You don't have enough money to uncover this vehicle.", "error")
                                end
                            end, cover.id)
                        elseif Config.Framework == "esx" then
                            ESX.TriggerServerCallback("px-garages:uncoverVehicle", function(success)
                                print('here', success)
                                if success then
                                    print('kandoz')
                                    TriggerServerEvent("px-cover:removeCover", cover.id)
                                    ESX.TriggerServerCallback("px-cover:spawnGarage", function(netId) 
                                        print('hehere')
                                        while not NetworkDoesNetworkIdExist(netId) do Wait(10) end
                                        local veh = NetworkGetEntityFromNetworkId(netId)
                                        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                                        SetVehicleEngineOn(veh, true, true, false)
                                        SetVehicleOnGroundProperly(veh)
                                    end, cover.plate, vector3(cover.coords.x, cover.coords.y, cover.coords.z), cover.heading)
                                else
                                    ESX.ShowNotification("You don't have enough money to uncover this vehicle.", "error")
                                end
                            end, cover.id)
                        end
                    end
                else interval = 600 end
            end
            Wait(interval)
        end
    end)
end

-- Citizen.CreateThread(function()
--     if Config.Framework == "qb" then
--         QBCore.Functions.TriggerCallback("px-garages:getAllCovers", function(data)
--             Covers = data
--             for k,v in pairs(Covers) do
--                 local coverProp = v.prop
--                 local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
--                 local heading = v.heading
--                 local obj = CreateObject(coverProp, coords.x, coords.y, coords.z, false, false, false)
--                 SetEntityHeading(obj, heading)
--                 PlaceObjectOnGroundProperly(obj)
--                 SetEntityAlpha(obj, 205)
--                 SetEntityCollision(obj, false, false)
--                 SetEntityInvincible(obj, true)
--                 v.obj = ObjToNet(obj)
--             end
--         end)
--     else
--         ESX.TriggerServerCallback("px-garages:getAllCovers", function(data)
--             Covers = data
--             for k,v in pairs(Covers) do
--                 local coverProp = v.prop
--                 local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
--                 local heading = v.heading
--                 local obj = CreateObject(coverProp, coords.x, coords.y, coords.z, false, false, false)
--                 SetEntityHeading(obj, heading)
--                 PlaceObjectOnGroundProperly(obj)
--                 SetEntityAlpha(obj, 205)
--                 SetEntityCollision(obj, false, false)
--                 SetEntityInvincible(obj, true)
--                 v.obj = ObjToNet(obj)
--             end
--         end)
--     end
--     Thread()
-- end)

AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    if Config.Framework == "qb" then
        QBCore.Functions.TriggerCallback("px-garages:getAllCovers", function(data)
            Covers = data
            for k,v in pairs(Covers) do
                local coverProp = v.prop
                local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
                local heading = v.heading
                local obj = CreateObject(coverProp, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(obj, heading)
                PlaceObjectOnGroundProperly(obj)
                SetEntityAlpha(obj, 205)
                SetEntityCollision(obj, false, false)
                SetEntityInvincible(obj, true)
                v.obj = ObjToNet(obj)
            end
        end)
        Thread()
    end
end)

-- esx on loaded
AddEventHandler("esx:playerLoaded", function()
    if Config.Framework == "esx" then
        ESX.TriggerServerCallback("px-garages:getAllCovers", function(data)
            Covers = data
            for k,v in pairs(Covers) do
                local coverProp = v.prop
                local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
                local heading = v.heading
                local obj = CreateObject(coverProp, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(obj, heading)
                PlaceObjectOnGroundProperly(obj)
                SetEntityAlpha(obj, 205)
                SetEntityCollision(obj, false, false)
                SetEntityInvincible(obj, true)
                v.obj = ObjToNet(obj)
            end
        end)
        Thread()
    end
end)

RegisterNetEvent("px-cover:addCover", function(id, cover)
    Covers[id] = cover
    local coverProp = cover.prop
    local coords = vector3(cover.coords.x, cover.coords.y, cover.coords.z)
    local heading = cover.heading
    local obj = CreateObject(coverProp, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAlpha(obj, 205)
    SetEntityCollision(obj, false, false)
    SetEntityInvincible(obj, true)
    Covers[id].obj = ObjToNet(obj)
end)

RegisterNetEvent("px-cover:removeCover", function(id)
    local cover = Covers[id]
    if Config.Framework == "qb" then
        closestObject, coords = QBCore.Functions.GetClosestObject(vector3(cover.coords.x, cover.coords.y, cover.coords.z))
    else
        closestObject, coords = ESX.Game.GetClosestObject(vector3(cover.coords.x, cover.coords.y, cover.coords.z))
    end
    DeleteEntity(closestObject)
    Covers[id] = nil
end)

RegisterNetEvent("px-cover:CoverVehicle", function(vehicle)
    if not vehicle then
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    local vehicleProps = Config.Framework == "qb" and QBCore.Functions.GetVehicleProperties(vehicle) or ESX.Game.GetVehicleProperties(vehicle)
    local vehicleClass = GetVehicleClass(vehicle)+1
    local coverProp = GetHashKey(Config.CoversProps[vehicleClass])
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local plate =  GetVehicleNumberPlateText(vehicle)

    if not Config.HasVehicleKeys(plate) then
        if Config.Framework == "qb" then
            QBCore.Functions.Notify("You don't have the keys for this vehicle.", "error")
        else
            ESX.ShowNotification("You don't have the keys for this vehicle.", "error")
        end
        return
    end

    Wait(100)
    if not HasModelLoaded(coverProp) then
        RequestModel(coverProp)
        while not HasModelLoaded(coverProp) do
            Citizen.Wait(1)
        end
    end
    TriggerServerEvent("px-garages:saveCover", plate, coords, heading, coverProp, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), GetHashKey(vehicle))
    if Config.Framework == "qb" then
        QBCore.Functions.DeleteVehicle(vehicle)
    elseif Config.Framework == "esx" then
        ESX.Game.DeleteVehicle(vehicle)
    end
end)