local currentTicketBlip = nil
local showNotifications = true

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
local function IsInTeam()
    local playerGroup = ESX.GetPlayerData().group or 'user'
    local teamGroups = { 'admin', 'support', 'mod', 'leitung' }
    return tableContains(teamGroups, playerGroup)
end

-- Benachrichtigungs-Handler
RegisterNetEvent('support:notify')
AddEventHandler('support:notify', function(msg)
    if showNotifications then
        ESX.ShowNotification(msg)
    end
end)

-- Wegpunkt setzen
RegisterNetEvent('support:setWaypoint')
AddEventHandler('support:setWaypoint', function(coords)
    if currentTicketBlip then RemoveBlip(currentTicketBlip) end
    
    currentTicketBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentTicketBlip, 280)
    SetBlipColour(currentTicketBlip, 5)
    SetBlipRoute(currentTicketBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Ticket-Standort")
    EndTextCommandSetBlipName(currentTicketBlip)
    ESX.ShowNotification('~b~Wegpunkt zum Ticket gesetzt!')
end)

-- Ticket erstellen Befehl
RegisterCommand('admins', function()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ticket_category', {
        title = 'Ticket-Typ wählen',
        align = 'top-left',
        elements = {
            {label = '🛟 Support', value = 'support'},
            {label = '🐛 Bug melden', value = 'bug'},
            {label = '❔ Frage stellen', value = 'question'},
            {label = '🚨 Cheater melden', value = 'cheater'}
        }
    }, function(data, menu)
        menu.close()
        
        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'ticket_message', {
            title = 'Beschreibe dein Anliegen:',
            maxChars = 500
        }, function(data2, menu2)
            if data2.value and #data2.value >= 5 then
                TriggerServerEvent('support:createTicket', data.current.value, data2.value)
                menu2.close()
            else
                ESX.ShowNotification('~r~Bitte gib mindestens 5 Zeichen ein')
            end
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
    end)
end, false)

-- Ticket Management Befehl
RegisterCommand('tickets', function()
    if not IsInTeam() then 
        ESX.ShowNotification('~r~Kein Zugriff!')
        return 
    end

    ESX.TriggerServerCallback('support:getTickets', function(tickets)
        local elements = {}
        
        for _, t in pairs(tickets) do
            local label = string.format("#%d - %s: %s", t.id, t.categoryName, t.message)
            
            if t.status == "in Bearbeitung" and t.staffName == GetPlayerName(PlayerId()) then
                table.insert(elements, {
                    label = '🔴 '..label,
                    value = 'close',
                    ticketId = t.id
                })
            elseif t.status == "offen" then
                table.insert(elements, {
                    label = '🟢 '..label,
                    value = 'accept',
                    ticketId = t.id,
                    coords = t.coords
                })
            end
        end

        if #elements == 0 then
            table.insert(elements, {label = 'Keine Tickets vorhanden', value = 'none'})
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ticket_menu', {
            title = 'Aktive Tickets',
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            if data.current.value == 'accept' then
                TriggerServerEvent('support:acceptTicket', data.current.ticketId)
            elseif data.current.value == 'close' then
                TriggerServerEvent('support:closeTicket', data.current.ticketId)
                if currentTicketBlip then
                    RemoveBlip(currentTicketBlip)
                    currentTicketBlip = nil
                end
            end
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    end)
end, false)

-- Benachrichtigungen deaktivieren
RegisterCommand('notickets', function()
    showNotifications = not showNotifications
    ESX.ShowNotification(showNotifications and 
        '~g~Ticket-Benachrichtigungen aktiviert' or 
        '~r~Ticket-Benachrichtigungen deaktiviert')
    TriggerServerEvent('support:toggleNotifications', not showNotifications)
end, false)