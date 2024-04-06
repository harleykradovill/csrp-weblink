local oovURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/setoov?api_token=[REDACTED]'
local vehregURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/registervehicle?api_token=[REDACTED]'

RegisterServerEvent('updateVehicleStatus')
AddEventHandler('updateVehicleStatus', function(isInVehicleClass18)
    local playerSource = source
    local playerIdentifiers = GetPlayerIdentifiers(playerSource)
    local discordId = nil

    for _, identifier in pairs(playerIdentifiers) do
        if string.match(identifier, "discord:") then
            discordId = string.sub(identifier, 9)
            break
        end
    end

    if discordId then
        local payload = json.encode({
            discordid = discordId,
            ["oov?"] = not isInVehicleClass18
        })

        PerformHttpRequest(cadURL, function(err, text, headers)
        end, 'POST', payload, { ["Content-Type"] = 'application/json' })
    end
end)

RegisterServerEvent('sendVehicleRegistration')
AddEventHandler('sendVehicleRegistration', function(plate, make, model, color)
    local playerSource = source
    local playerIdentifiers = GetPlayerIdentifiers(playerSource)
    local discordId = nil

    for _, identifier in pairs(playerIdentifiers) do
        if string.match(identifier, "discord:") then
            discordId = string.sub(identifier, 9)
            break
        end
    end

    if discordId then
        local vehicleProps = {
            plate = plate,
            discordid = discordId,
	    make = make,
	    model = model,
	    color = color
        }

        PerformHttpRequest(cadURL, function(err, text, headers)
            if err == 200 then
		TriggerClientEvent('showVehicleRegistrationNotification', playerSource, text)
            else
		TriggerClientEvent('showVehicleRegistrationNotification', playerSource, "Error: Vehicle registration failed due to API.")
            end
        end, 'POST', json.encode(vehicleProps), { ["Content-Type"] = 'application/json' })
    else
        print("Error: Discord ID not found for the player.")
    end
end)
