local Tickets = {}
local AvailableTicketIds = {}
local NextTicketId = 1
local TeamGroups = { 'admin', 'support', 'mod', 'leitung' }
local TicketCategories = {
    ['support'] = '🛟 Support',
    ['bug'] = '🐛 Bug',
    ['question'] = '❔ Frage',
    ['cheater'] = '🚨 Cheater'
}
local DiscordWebhook = "https://discord.com/api/webhooks/..."
local NoNotifyPlayers = {}

-- Hilfsfunktion für Tabellen-Check
local function tableContains(tbl, item)
    for _, value in pairs(tbl) do
        if value == item then
            return true
        end
    end
    return false
end

-- Überprüft Gruppen-Zugehörigkeit
local function IsPlayerInTeam(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    local playerGroup = xPlayer.getGroup()
    return playerGroup and tableContains(TeamGroups, playerGroup)
end

-- Generiert neue Ticket-ID
local function GetNewTicketId()
    if #AvailableTicketIds > 0 then
        return table.remove(AvailableTicketIds, 1)
    else
        local id = NextTicketId
        NextTicketId = NextTicketId + 1
        return id
    end
end

-- Sendet Discord-Log
local function SendDiscordLog(title, description, color)
    if not DiscordWebhook or DiscordWebhook == "" then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16753920,
            ["footer"] = { ["text"] = os.date("%d.%m.%Y %H:%M:%S") }
        }
    }
    PerformHttpRequest(DiscordWebhook, function() end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Ticket erstellen
RegisterNetEvent('support:createTicket', function(category, message)
    local src = source
    if not TicketCategories[category] then return end

    local ticketId = GetNewTicketId()
    local playerName = GetPlayerName(src)
    
    Tickets[ticketId] = {
        id = ticketId,
        playerId = src,
        playerName = playerName,
        message = message,
        category = category,
        categoryName = TicketCategories[category],
        status = "offen",
        coords = GetEntityCoords(GetPlayerPed(src)),
        createdAt = os.time()
    }

    -- Benachrichtige Team-Mitglieder
    for _, player in ipairs(GetPlayers()) do
        local playerId = tonumber(player)
        if IsPlayerInTeam(playerId) and not NoNotifyPlayers[playerId] then
            TriggerClientEvent('support:notify', playerId, 
                string.format('~y~Neues Ticket #%d~s~\nKategorie: ~b~%s~s~\nSpieler: ~g~%s~s~\n%s', 
                ticketId, TicketCategories[category], playerName, message))
        end
    end

    -- Discord-Log
    SendDiscordLog(
        "NEUES TICKET #"..ticketId,
        "**Spieler:** "..playerName.."\n**Kategorie:** "..TicketCategories[category].."\n**Nachricht:** ```"..message.."```",
        65280
    )

    TriggerClientEvent('support:notify', src, '~g~Ticket #'..ticketId..' erstellt')
end)

-- Ticket annehmen
RegisterNetEvent('support:acceptTicket', function(ticketId)
    local src = source
    if not IsPlayerInTeam(src) or not Tickets[ticketId] then return end
    
    Tickets[ticketId].status = "in Bearbeitung"
    Tickets[ticketId].staffName = GetPlayerName(src)
    
    SendDiscordLog(
        "TICKET ANGENOMMEN #"..ticketId,
        "**Bearbeiter:** "..GetPlayerName(src),
        16776960
    )

    TriggerClientEvent('support:setWaypoint', src, Tickets[ticketId].coords)
end)

-- Ticket schließen
RegisterNetEvent('support:closeTicket', function(ticketId)
    local src = source
    if not IsPlayerInTeam(src) or not Tickets[ticketId] then return end
    
    local ticket = Tickets[ticketId]
    ticket.status = "geschlossen"
    table.insert(AvailableTicketIds, ticketId)
    
    SendDiscordLog(
        "TICKET GESCHLOSSEN #"..ticketId,
        "**Bearbeiter:** "..GetPlayerName(src).."\n**Dauer:** "..(os.time() - ticket.createdAt).."s",
        16711680
    )

    TriggerClientEvent('support:notify', ticket.playerId, '~b~Ticket geschlossen')
end)

-- Tickets abrufen
ESX.RegisterServerCallback('support:getTickets', function(source, cb)
    local filtered = {}
    for id, ticket in pairs(Tickets) do
        if ticket.status ~= "geschlossen" then
            filtered[id] = ticket
        end
    end
    cb(IsPlayerInTeam(source) and filtered or {})
end)

-- Benachrichtigungen deaktivieren
RegisterNetEvent('support:toggleNotifications', function(state)
    NoNotifyPlayers[source] = state
end)

-- /notickets Befehl
RegisterCommand('notickets', function(source)
    local src = source
    NoNotifyPlayers[src] = not NoNotifyPlayers[src]
    TriggerClientEvent('support:notify', src, 
        NoNotifyPlayers[src] and '~r~Ticket-Benachrichtigungen deaktiviert' 
        or '~g~Ticket-Benachrichtigungen aktiviert')
end, false)