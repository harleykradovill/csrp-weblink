local oovURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/setoov?api_token=[]'
local vehregURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/registervehicle?api_token=[]'
local rtiURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/incidentdetails?api_token=[]'
local showidURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/showid?api_token=[]'

RegisterServerEvent('fetchIncidentDetails')
AddEventHandler('fetchIncidentDetails', function()
    local playerSource = source
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local discordId = nil

    for _, identifier in pairs(playerIdentifiers) do
        if string.match(identifier, "discord:") then
            discordId = string.sub(identifier, 9)
            break
        end
    end

    if discordId then
        local payload = json.encode({discordid = discordId})
        PerformHttpRequest(rtiURL, function(err, text, headers)
            if err == 200 then
                local postalCode = text
                if tonumber(postalCode) then
                    TriggerClientEvent('setGpsRoute', playerSource, tonumber(postalCode))
                else
                    print("Error: Invalid postal code received from API.")
                end
            else
                print("Error: HTTP request failed. Status code: " .. tostring(err))
            end
        end, 'POST', payload, { ["Content-Type"] = 'application/json' })
    else
        print("Error: Discord ID not found for the player.")
    end
end)


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

        PerformHttpRequest(oovURL, function(err, text, headers)
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

        PerformHttpRequest(vehregURL, function(err, text, headers)
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

RegisterServerEvent('showId')
AddEventHandler('showId', function()
    local playerSource = source
    local playerName = GetPlayerName(playerSource)
    local playerIdentifiers = GetPlayerIdentifiers(playerSource)
    local discordId = nil

    for _, identifier in pairs(playerIdentifiers) do
        if string.match(identifier, "discord:") then
            discordId = string.sub(identifier, 9)
            break
        end
    end

    if discordId then
        local payload = json.encode({discordid = discordId})
        PerformHttpRequest(showidURL, function(err, text, headers)
            if err == 200 then
                local data = json.decode(text)
                if data and data.response then
                    local name = data.response.name
                    local dob = data.response.dob
                    if name and dob then
                        TriggerClientEvent('displayId', -1, playerSource, playerName, name, dob)
                    else
                        print("Error: Invalid data received from API. Data: " .. text)
                    end
                else
                    print("Error: Invalid response structure from API. Data: " .. text)
                end
            else
                print("Error: HTTP request failed. Status code: " .. tostring(err))
            end
        end, 'POST', payload, { ["Content-Type"] = 'application/json' })
    else
        print("Error: Discord ID not found for the player.")
    end
end)
