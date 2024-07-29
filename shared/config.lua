Config = {}

Config.Framework = "esx" -- "qb" or "esx"    
Config.oxKeys = false
Config.payForUncover = true
Config.pricePerHour = 100
Config.Warp = true
Config.VisuallyDamageCars = true
Config.FuelResource = 'LegacyFuel'
Config.UseCommand = true -- Use only command to cover your owned vehicle
Config.AddCoverItemAfterUncover = true

/*
    1: Compacts  
    2: Sedans  
    3: SUVs  
    4: Coupes  
    5: Muscle  
    6: Sports Classics  
    7: Sports  
    8: Super  
    9: Motorcycles  
    10: Off-road  
    11: Industrial  
    12: Utility  
    13: Vans  
    14: Cycles  
*/

Config.CoversProps = {
    [1] = 'imp_prop_covered_vehicle_05a',
    [2] = 'imp_prop_covered_vehicle_02a',
    [3] = 'imp_prop_covered_vehicle_07a',
    [4] = 'imp_prop_covered_vehicle_04a',
    [5] = 'imp_prop_covered_vehicle_03a',
    [6] = 'prop_jb700_covered',
    [7] = 'imp_prop_covered_vehicle_01a',
    [8] = 'imp_prop_covered_vehicle_01a',
    [9] = 'imp_prop_covered_vehicle_02a',
    [10] = 'imp_prop_covered_vehicle_05a',
    [11] = 'imp_prop_covered_vehicle_05a',
    [12] = 'imp_prop_covered_vehicle_07a',
    [13] = 'imp_prop_covered_vehicle_07a',
    [14] = 'imp_prop_covered_vehicle_02a',
}

RegisterCommand("covervehicle", function()
    if not Config.UseCommand then return end
    TriggerEvent("px-cover:CoverVehicle")
end)

Config.HasVehicleKeys = function(plate) -- Replace the code if you have a different function
    local owned = false
    local loading = true
    if Config.Framework == "qb" then
        QBCore.Functions.TriggerCallback('px-garages:isVehicleOwner', function(data)
            loading = false
            owned = data
        end, plate)
    elseif Config.Framework == "esx" then
        if Config.oxKeys then
            Inventory = exports.ox_inventory
            local vehicleMetadata = {
                plate = plate,
            }
        
            local keyItem = Inventory:GetItem(source, 'keys', vehicleMetadata, true)
            if keyItem > 0 then
                loading = false
                return true
            end
            return false
        else    
            ESX.TriggerServerCallback('px-garages:isVehicleOwner', function(data)
                owned = data
                loading = false
            end, plate)
        end
    end
    while loading do Wait(300) end
    return owned
end