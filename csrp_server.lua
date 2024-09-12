-- Harley Kradovill
-- For use by Coastal State Roleplay
-- https://www.coastalstateroleplay.com/

local apiKey = ''

local oovURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/setoov?api_token=' .. apiKey
local vehregURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/registervehicle?api_token=' .. apiKey
local rtiURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/incidentdetails?api_token=' .. apiKey
local showidURL = 'https://coastalstateroleplay.bubbleapps.io/api/1.1/wf/showid?api_token=' .. apiKey

--[[
Make a GET request to receive user's currently selected call, and set a GPS route to
it's postal code.
--]]
RegisterServerEvent('fetchIncidentDetails')
AddEventHandler('fetchIncidentDetails', function(playerid)
    local playerSource = playerid or source
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

--[[
Check if a user is in a POLICE vehicle. If so, send a boolean to the CAD
to show they are not oov.
--]]
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

--[[
Makes a POST request to register a vehicle within the CAD System.

Usage: /vehreg
--]]
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

--[[
Makes a GET request to receive a user's currently selected identities information.

Usage: /showid
--]]
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

--[[
Creates an endpoint /updateBlips which receives POST requests.

Used to update the user's calls on the map & minimap.
--]]
SetHttpHandler(function(request, response)
    -- API Key to prevent malicious people
    local authHeader = request.headers['Authorization']
    if not authHeader or not authHeader:find("Bearer ") then
        response.writeHead(401, { ['Content-Type'] = 'application/json' })
        response.send(json.encode({ status = "error", message = "Unauthorized" }))
        return
    end

    local receivedApiKey = authHeader:sub(8)
    if receivedApiKey ~= apiKey then
        response.writeHead(401, { ['Content-Type'] = 'application/json' })
        response.send(json.encode({ status = "error", message = "Unauthorized" }))
        return
    end

    if request.path == "/updateBlips" then
        request.setDataHandler(function(data)
            --print("Received request body: " .. data)

            local success, parsedData = pcall(json.decode, data)
            if not success then
                print("Error decoding JSON: " .. parsedData)
                response.writeHead(400, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "error", message = "Invalid JSON" }))
                return
            end

            if parsedData and parsedData.discordid and parsedData.codes then
                local discordid = parsedData.discordid
                local codes = parsedData.codes

                for _, playerId in ipairs(GetPlayers()) do
                    local identifiers = GetPlayerIdentifiers(playerId)
                    for _, id in pairs(identifiers) do
                        if id:find("discord:") and id:sub(9) == discordid then
                            TriggerClientEvent('updateBlips', playerId, codes)
                            --print("Sent codes to player: " .. playerId)
                            break
                        end
                    end
                end

                response.writeHead(200, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "success", message = "Success" }))
            else
                print("Error: 'discordid' or 'codes' key not found in the data.")
                response.writeHead(400, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "error", message = "'discordid' or 'codes' key not found" }))
            end
        end)
			
    elseif request.path == "/initiateRti" then
        request.setDataHandler(function(data)
            local success, parsedData = pcall(json.decode, data)
            if not success then
                print("Error decoding JSON: " .. parsedData)
                response.writeHead(400, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "error", message = "Invalid JSON" }))
                return
            end

            if parsedData and parsedData.discordid then
                local discordid = parsedData.discordid

                for _, playerId in ipairs(GetPlayers()) do
                    local identifiers = GetPlayerIdentifiers(playerId)
                    for _, id in pairs(identifiers) do
                        if id:find("discord:") and id:sub(9) == discordid then
                            TriggerEvent('fetchIncidentDetails', playerId)
                            break
                        end
                    end
                end

                response.writeHead(200, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "success", message = "RTI initiated successfully." }))
            else
                print("Error: 'discordid' key not found in the data.")
                response.writeHead(400, { ['Content-Type'] = 'application/json' })
                response.send(json.encode({ status = "error", message = "'discordid' key not found" }))
            end
        end)
    else
        response.writeHead(404, { ['Content-Type'] = 'application/json' })
        response.send(json.encode({ status = "error", message = "Route not found" }))
    end
end)
