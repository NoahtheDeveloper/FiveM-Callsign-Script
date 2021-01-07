local GPN = GetPlayerName -- original GetPlayerName native
local Nicknames = {}

function GetPlayerName(player)
    player = tonumber(player)
    local source = GetPlayerServerId(player)
    source = tonumber(source)
    if Nicknames[source] and Nicknames[source].name then
        return Nicknames[source].name
    end
    return GPN(source)
end

function GetPlayerColor(source)
    source = tonumber(source)
    if Nicknames[source] and Nicknames[source].color then
        return Nicknames[source].color
    end
    return {255, 255, 255} -- white by default
end

RegisterNetEvent("nicknames:update")
AddEventHandler("nicknames:update", function(nicknames)
    for source, nickname in next, nicknames do
        Nicknames[source] = nickname
    end
end)

CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/callsign", "Set your chat nickname", {{name = "Callsign", help = "The name to display in chat"}})
    TriggerEvent("chat:addSuggestion", "/cs", "Set your chat nickname", {{name = "Callsign", help = "The name to display in chat"}})
  

    local colorList = json.decode(LoadResourceFile(GetCurrentResourceName(), "colors.json"))
    local availableColors = {}
    for color, _ in next, colorList do
        availableColors[#availableColors + 1] = color
    end
    TriggerEvent("chat:addSuggestion", "/color", "Set your name color in chat", {{name = "color", help = "Available colors: " .. table.concat(availableColors, ", ")}})

    TriggerServerEvent("nicknames:init")
end)



