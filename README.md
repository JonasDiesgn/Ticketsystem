# Support-Ticket-System für FiveM

Ein einfaches aber leistungsstarkes Ticket-System für FiveM Server, das Spielern ermöglicht Support-Anfragen zu stellen und dem Team die Verwaltung erleichtert.

## Funktionen ✨

- **Spieler-Funktionen**:
  - Tickets erstellen mit 4 Kategorien (Support, Bug, Frage, Cheater)
  - Detaillierte Ticketbeschreibungen (500+ Zeichen)
  - Benachrichtigung bei Ticket-Schließung

- **Team-Funktionen**:
  - Alle offenen Tickets einsehen
  - Tickets annehmen (Status "in Bearbeitung")
  - Wegpunkt zum Ticket setzen
  - Geschlossene Tickets archivieren
  - Benachrichtigungen ein/ausschalten

- **Technische Features**:
  - Discord-Webhook Integration
  - Standortverfolgung der Tickets
  - Ticket-Dauer Berechnung
  - Optimiertes ID-Recycling System
  - ESX Framework Integration

## Installation 🛠️

1. Füge diesen Ordner in deinen `resources`-Ordner ein
2. Füge `ensure support-system` in deiner `server.cfg` hinzu
3. Konfiguriere den Discord-Webhook in der `server.lua` (optional)

## Konfiguration ⚙️

Diese Werte können in der `server.lua` angepasst werden:

```lua
-- Team-Gruppen mit Zugriff
local TeamGroups = { 'admin', 'support', 'mod', 'leitung' }

-- Verfügbare Ticket-Kategorien (Emoji + Beschreibung)
local TicketCategories = {
    ['support'] = '🛟 Support',
    ['bug'] = '🐛 Bug',
    ['question'] = '❔ Frage',
    ['cheater'] = '🚨 Cheater'
}

-- Discord Webhook URL (leer lassen zum Deaktivieren)
local DiscordWebhook = "DEINE_WEBHOOK_URL"
