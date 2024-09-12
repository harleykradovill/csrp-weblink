-- Harley Kradovill
-- For use by Coastal State Roleplay
-- https://www.coastalstateroleplay.com/

json = require("json")


local activeBlips = {}

--[[
Trigger server event for route to incident
--]]
RegisterCommand('rti', function()
    TriggerServerEvent('fetchIncidentDetails')
end, false)

--[[
Sets a GPS route on the map using postals.json
--]]
local waypointBlip = nil
local arrivalDistanceThreshold = 125.0

RegisterNetEvent("setGpsRoute")
AddEventHandler("setGpsRoute", function(postalCode)
    if DoesBlipExist(waypointBlip) then
        RemoveBlip(waypointBlip)
        waypointBlip = nil

        exports.csrpnot:SendAdvanced({
            message = '~b~Routing Removed',
            title = 'Coastal State Roleplay',
            subject = 'PMCSS',
            icon = 'GST_MAPPER',
        })
        return
    end

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
        SetWaypointOff()
        if DoesBlipExist(waypointBlip) then
            RemoveBlip(waypointBlip)
        end

        waypointBlip = AddBlipForCoord(targetCoords.x, targetCoords.y, targetCoords.z)
        SetBlipSprite(waypointBlip, 0) 
        SetBlipColour(waypointBlip, 1)
        SetBlipRoute(waypointBlip, true)
        SetBlipRouteColour(waypointBlip, 1)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Custom Waypoint")
        EndTextCommandSetBlipName(waypointBlip)

        exports.csrpnot:SendAdvanced({
            message = '~b~Routing To Call',
            title = 'Coastal State Roleplay',
            subject = 'PMCSS',
            icon = 'GST_MAPPER',
        })

        Citizen.CreateThread(function()
            while DoesBlipExist(waypointBlip) do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - targetCoords)

                if distance <= arrivalDistanceThreshold then
                    RemoveBlip(waypointBlip)
                    waypointBlip = nil

                    exports.csrpnot:SendAdvanced({
                        message = '~b~You Have Arrived',
                        title = 'Coastal State Roleplay',
                        subject = 'PMCSS',
                        icon = 'GST_MAPPER',
                    })

                    break
                end

                Citizen.Wait(1000)
            end
        end)
    else
        print("Error: Postal code not found in postals.json")
    end
end)


--[[
Loop to check if current vehicle is popo car, and if so, change OOV status
--]]
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

--[[
Register the current vehicle to the player's identity
--]]
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

--[[
Match the vehicle color ID to a color in vehicle-colors.json
--]]
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

--[[
Make a proximity chat using the API return
--]]
RegisterNetEvent("displayId")
AddEventHandler("displayId", function(playerSource, senderName, name, dob)
    local senderID = GetPlayerFromServerId(playerSource)
    if senderID ~= -1 then
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local senderPed = GetPlayerPed(senderID)
        local senderCoords = GetEntityCoords(senderPed)
        local radius = 3.0

        if #(playerCoords - senderCoords) <= radius then
            TriggerEvent('chat:addMessage', {
                color = { 255, 255, 255 },
                multiline = true,
                args = {"", "^2" .. senderName .. " Shows ID:^0 " .. name .. " " .. dob}
            })
        end
    end
end)

--[[
Set the blips on the map based on the postal codes
--]]
RegisterNetEvent('updateBlips')
AddEventHandler('updateBlips', function(codes)
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}

    local postals = LoadResourceFile(GetCurrentResourceName(), 'postals.json')
    if not postals then
        print("Error: Unable to load postals.json")
        return
    end

    local postalData = json.decode(postals)

    for _, code in ipairs(codes) do
        for _, postal in pairs(postalData) do
            if tostring(postal.code) == tostring(code) then
                local blip = AddBlipForCoord(postal.x, postal.y, postal.z or 0.0)
                SetBlipSprite(blip, 37)
                SetBlipDisplay(blip, 2)
                SetBlipScale(blip, 0.6)
                SetBlipColour(blip, 49)
                SetBlipCategory(blip, 2)


                SetBlipAsShortRange(blip, false)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Call: " .. tostring(code))
                EndTextCommandSetBlipName(blip)

                table.insert(activeBlips, blip)
                --print("Blip created at postal code: " .. tostring(code))
                break
            end
        end
    end
end)

-- UNIVERSAL FUNCTION TO DRAW NOTIFICATION

function drawNotification(message)
    exports.csrpnot:SendAdvanced({
        message = message, 
        title = 'Coastal State Roleplay',
        subject = 'CAD', 
        icon = 'CSRP_ICON',
    })
end
