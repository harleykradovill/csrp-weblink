local cadURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/incidentdetails?api_token=[REDCATED]'
local cadURL2 = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/setoov?api_token=[REDACTED]'

-- /rti GETTING POSTAL CODE:

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
        -- print("Fetching incident details for Discord ID: " .. discordId)

        local payload = json.encode({discordid = discordId})

        PerformHttpRequest(cadURL, function(err, text, headers)
            -- print("Response Status Code: " .. tostring(err))
            -- print("API Response: " .. text)

            if err == 200 then
                local postalCode = text
                -- print("Received postalCode: " .. tostring(postalCode))
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

-- OOV CAD DETECTION:

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

        PerformHttpRequest(cadURL2, function(err, text, headers)
        end, 'POST', payload, { ["Content-Type"] = 'application/json' })
    end
end)
