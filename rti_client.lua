json = require("json")

-- COMMANDS:

RegisterCommand('rti', function()
    TriggerServerEvent('fetchIncidentDetails')
end, false)

-- SET GPS ROUTE FOR /rti

RegisterNetEvent("setGpsRoute")
AddEventHandler("setGpsRoute", function(postalCode)
    local postals = LoadResourceFile(GetCurrentResourceName(), 'postals.json')
    if not postals then
        print("Error: Unable to load postals.json")
        return
    end

    local postalData = json.decode(postals)
    local targetCoords = nil

    for _, postal in pairs(postalData) do
        if tostring(postal.code) == tostring(postalCode) then
            targetCoords = vector3(postal.x, postal.y, postal.z or 0)
            break
        end
    end

    if targetCoords then
        SetNewWaypoint(targetCoords.x, targetCoords.y)
        -- print("Waypoint set to postal code: " .. tostring(postalCode))
        drawNotification("Waypoint Set: " .. tostring(postalCode))
    else
        print("Error: Postal code not found in postals.json")
    end
end)

-- WHILE LOOP TO CHECK FOR OOV:

local wasInVehicleClass18 = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)

        local playerPed = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)
        local isInVehicleClass18 = false

        if isInVehicle then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            isInVehicleClass18 = GetVehicleClass(vehicle) == 18
        end

        if isInVehicleClass18 ~= wasInVehicleClass18 then
            TriggerServerEvent('updateVehicleStatus', isInVehicleClass18)
            wasInVehicleClass18 = isInVehicleClass18
        end
    end
end)

-- UNIVERSAL FUNCTION TO DRAW NOTIFICATION

function drawNotification(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, true)
end
