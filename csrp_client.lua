json = require("json")

RegisterCommand('rti', function()
    TriggerServerEvent('fetchIncidentDetails')
end, false)

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

RegisterCommand('vehreg', function(source, args, rawCommand)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if not IsPedInAnyVehicle(PlayerPedId(), false) or vehicle == 0 then
        drawNotification("Error: Not in Vehicle")
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local make = GetLabelText(GetMakeNameFromVehicleModel(GetEntityModel(vehicle)))
    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local color = GetVehiclePrimaryColorText(vehicle)

    TriggerServerEvent('sendVehicleRegistration', plate, make, model, color)
end, false)

function GetVehiclePrimaryColorText(vehicle)
    local primaryColorID, _ = GetVehicleColours(vehicle)
    local colorJson = LoadResourceFile(GetCurrentResourceName(), "vehicle-colors.json")
    if colorJson then
        local colors = json.decode(colorJson)
        for _, color in ipairs(colors) do
            if color.ID == tostring(primaryColorID) then
                return color.Description
            end
        end
        return "Unknown"
    else
        print("Error: vehicle-colors.json not found or unable to read.")
        return "Unknown"
    end
end

RegisterNetEvent("showVehicleRegistrationNotification")
AddEventHandler("showVehicleRegistrationNotification", function(message)
    drawNotification(message)
end)

RegisterCommand('showid', function()
    TriggerServerEvent('showId')
end, false)

RegisterNetEvent("displayId")
AddEventHandler("displayId", function(playerSource, name, dob)
    local playerPed = PlayerPedId()
    local players = GetActivePlayers()
    local playerCoords = GetEntityCoords(playerPed)
    local radius = 10.0 -- Message Radius

    local currentPlayerName = GetPlayerName(PlayerId())

    for _, playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)

        if distance <= radius then
            TriggerEvent('chat:addMessage', {
                color = { 255, 255, 255 },
                multiline = true,
                args = {"", "^2" .. currentPlayerName .. " Shows ID:^0 " .. name .. " " .. dob}
            })
        end
    end
end)


-- UNIVERSAL FUNCTION TO DRAW NOTIFICATION

function drawNotification(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, true)
end
