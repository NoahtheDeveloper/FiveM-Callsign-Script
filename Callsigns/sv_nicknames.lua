local GPN = GetPlayerName -- original GetPlayerName native
local Nicknames = {}

-- External data, configurable in their own files
local Blacklist = {}
local Colors = {}
CreateThread(function()
    Blacklist = json.decode(LoadResourceFile(GetCurrentResourceName(), "blacklist.json"))
    Colors = json.decode(LoadResourceFile(GetCurrentResourceName(), "colors.json"))
end)

function Notify(source, text)
    if GetConvar("nick_notify", "true") == "true" then
        TriggerClientEvent("chat:addMessage", source, {
            args = {"Error", text},
            color = {255, 0, 0},
        })
    end
end
function Success(source, text, col)
    if GetConvar("nick_notify", "true") == "true" then
        TriggerClientEvent("chat:addMessage", source, {
            args = (col and {text} or {"Success", text}),
            color = (col or {0, 255, 0}),
        })
    end
end

-- Override a players name with a nickname
function SetNickname(source, nickname)
    -- Setup data table if not already present
    source = tonumber(source)
    if not Nicknames[source] then Nicknames[source] = {} end

    -- Check name blacklist
    if GetConvar("nick_blacklist", "true") == "true" then
        local nickLower = nickname:lower()
        for _, phrase in next, Blacklist do
            if nickLower:find(phrase) ~= nil then
                -- illegal phrase, return to prevent further execution
                Notify(source, "Blacklisted phrase in nickname")
                return false
            end
        end
    end
    -- Check unique name
    if GetConvar("nick_unique", "true") == "true" then
        local nickLower = nickname:lower()
        -- check nicknames
        for serverId, nick in next, Nicknames do
            if nick.name and nick.name:lower() == nickLower then
                -- make sure we're not impersonating ourselves
                if tonumber(serverId) ~= source then
                    Notify(source, "Not a unique nickname")
                    return false
                end
            end
        end
        -- check base names
        for serverId, player in next, GetPlayers() do
            if GPN(player):lower() == nickLower then
                -- make sure we're not impersonating ourselves
                if tonumber(serverId) ~= source then
                    Notify(source, "Not a unique nickname")
                    return false
                end
            end
        end
    end
    -- Store new nickname
    Nicknames[source].name = nickname
    -- Send nickname update to clients and other resources
    Success(source, "^1[^0Callsign^1]^0 Changed to " .. nickname, GetPlayerColor(source))
    TriggerEvent("onPlayerNicknameChange", source, nickname)
    TriggerEvent("onPlayerNameChange", source, nickname)
    TriggerClientEvent("nicknames:update", -1, {[source] = Nicknames[source]})
end

-- Override a players color (for chat etc.)
function SetColor(source, r, g, b, name)
    -- Setup data table if not already present
    source = tonumber(source)
    if not Nicknames[source] then Nicknames[source] = {} end

    -- Store new color
    Nicknames[source].color = {r, g, b}
    -- Send color update to clients and other resources
    Success(source, "Color changed to " .. (name or "custom"), Nicknames[source].color)
    TriggerEvent("onPlayerColorChange", source, r, g, b, name)
    TriggerClientEvent("nicknames:update", -1, {[source] = Nicknames[source]})
end

-- Command handler for /nickname
function nicknameHandler(source, args)
    if #args < 1 then
        Notify(source, "No nickname specified")
        return false
    end
    local nickname = table.concat(args, " ")
    SetNickname(source, nickname)
end
-- Proxy function to check for permissions when required
function nicknameHandlerProxy(source, args)
    local function notify(text)
        Notify(source, text)
    end
    if GetConvar("nick_nick_everyone", "true") ~= "true" then
        if not IsPlayerAceAllowed(source, "command.nickname") then
            -- Player does not have permission to use the command
            Notify(source, "Not allowed to use this command")
            return false
        end
    end
    nicknameHandler(source, args)
end
RegisterCommand("callsign", nicknameHandlerProxy) -- /nickname [nickname]
RegisterCommand("cs", nicknameHandlerProxy) -- /nick [nickname]

-- Command handler for /color
function colorHandler(source, args)
    if #args < 1 then
        Notify(source, "No color specified")
        return false
    end
    local selectedColor = args[1]:lower()
    if Colors[selectedColor] then
        local color = Colors[selectedColor]
        SetColor(source, color[1], color[2], color[3], selectedColor)
    else
        Notify(source, "Invalid color specified")
        return false
    end
end
-- Proxy function to check for permissions when required
function colorHandlerProxy(source, args)
    if GetConvar("nick_color_everyone", "true") ~= "true" then
        if not IsPlayerAceAllowed(source, "command.color") then
            -- Player does not have permission to use the command
            Notify(source, "Not allowed to use this command")
            return false
        end
    end
    colorHandler(source, args)
end
RegisterCommand("a21saz23color", colorHandlerProxy) -- /color [color]

-- Command handler for /color_adv
function colorAdvHandler(source, args)
    if #args < 3 then
        Notify(source, "No color specified")
        return false
    end
    local r = math.min(255, math.max(0, math.floor(tonumber(args[1]))))
    local g = math.min(255, math.max(0, math.floor(tonumber(args[2]))))
    local b = math.min(255, math.max(0, math.floor(tonumber(args[3]))))
    SetColor(source, r, g, b, "custom")
end
-- Proxy function to check for permissions when required
function colorAdvHandlerProxy(source, args)
    if GetConvar("nick_color_everyone", "true") ~= "true" then
        if not IsPlayerAceAllowed(source, "command.color") then
            -- Player does not have permission to use the command
            Notify(source, "Not allowed to use this command")
            return false
        end
    end
    colorAdvHandler(source, args)
end
RegisterCommand("213123acolor_adv", colorAdvHandlerProxy) -- /color_adv [r] [g] [b]

-- Admin commands /command [id] [...]
RegisterCommand("setnick", function(source, args)
    nicknameHandler(table.remove(args, 1), args) -- /setnick [id] [nickname]
end, true)
RegisterCommand("aaaaadasasetcolor", function(source, args)
    colorHandler(table.remove(args, 1), args) -- /setcolor [id] [color]
end, true)
RegisterCommand("sdsadsadetcoloradv", function(source, args)
    colorAdvHandler(table.remove(args, 1), args) -- /setcoloradv [id] [r] [g] [b]
end, true)

-- Get a players nickname, if no nickname is set it uses default playername
-- Exported, can be used to replace GetPlayerName (via exports.nickname:GetPlayerName instead)
function GetPlayerName(source)
    source = tonumber(source)
    if Nicknames[source] and Nicknames[source].name then
        return Nicknames[source].name
    end
    return GPN(source)
end

-- Get a players color, if no color is set it uses white
-- Exported, no existing equivelent
function GetPlayerColor(source)
    source = tonumber(source)
    if Nicknames[source] and Nicknames[source].color then
        return Nicknames[source].color
    end
    return {255, 255, 255} -- white by default
end

-- Override a players nickname
-- Exported for other resources to use
function SetPlayerName(player, name)
    SetNickname(player, name)
end
AddEventHandler("setPlayerName", function(player, name)
    SetNickname(player, name)
end)

-- Override a players nickname
-- Exported for other resources to use
function SetPlayerNickname(player, nickname)
    SetNickname(player, nickname)
end
AddEventHandler("setPlayerNickname", function(player, nickname)
    SetNickname(player, nickname)
end)

-- Override a players color
-- Exported for other resources to use
function SetPlayerColor(player, r, g, b, name)
    SetColor(player, r, g, b, name)
end
AddEventHandler("setPlayerColor", function(player, r, g, b, name)
    SetColor(player, r, g, b, name)
end)

-- Client requests to receive all set nicknames
RegisterServerEvent("nicknames:init")
AddEventHandler("nicknames:init", function()
    TriggerClientEvent("nicknames:update", source, Nicknames)
end)




  RegisterCommand('me', function(source, args, user)
  	TriggerClientEvent('chatMessage', -1, "^0[^2ME^0] (^2-" .. GetPlayerName(source) .. "^0)", {11, 255, 150}, table.concat(args, " "))
  end, false)

  

 

  RegisterCommand('ooc', function(source, args, user)
  	TriggerClientEvent('chatMessage', -1, "OOC | " .. GetPlayerName(source), {128, 128, 128}, table.concat(args, " "))
  end, false)



  RegisterCommand('atc', function(source, args, user)
      TriggerClientEvent('chatMessage', -1, "^1[^7ATC^1]^1 " .. GetPlayerName(source), {255,215,0}, table.concat(args, " "))
  end, false)

 
  RegisterCommand('ATC', function(source, args, user)
      TriggerClientEvent('chatMessage', -1, "^1[^7ATC^1]^1 " .. GetPlayerName(source), {255,215,0}, table.concat(args, " "))
  end, false)







  RegisterCommand('DOT', function(source, args, user)
      TriggerClientEvent('chatMessage', -1, "^2[^7DOT^2]^2 " .. GetPlayerName(source), {255,215,0}, table.concat(args, " "))
  end, false)





  RegisterCommand('GC', function(source, args, user)
      TriggerClientEvent('chatMessage', -1, "^2[^7GC^2]^2 " .. GetPlayerName(source), {255,215,0}, table.concat(args, " "))
  end, false)


RegisterCommand('twt', function(source, args, user)
      TriggerClientEvent('chatMessage', -1, "^0[Twitter^0] (^5@" .. GetPlayerName(source) .. "^0)", {30, 144, 255}, table.concat(args, " "))
  end, false)
---------------

 



Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/GC", "Chat Function for GC", {

    })
    Citizen.Trace("Script made by Infinite Network")
end)
Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/DOT", "Chat Function for DOT", {

    })
    Citizen.Trace("Script made by Infinite Network")
end)


Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/ATC", "Chat Function for ATC", {

    })
    Citizen.Trace("Script made by Infinite Network")
end)
Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestion", "/atc", "Chat Function for ATC", {

    })
    Citizen.Trace("Script made by Infinite Network")
end)


	


-- Chat handler


