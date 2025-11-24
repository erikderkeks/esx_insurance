Config = {}

-- Allgemein
Config.Locale = 'de'

-- Datenbank (gleich wie beim Parking Script!)
Config.UseOxMysql   = false                -- true, wenn du oxmysql verwendest
Config.TableName    = 'owned_vehicles'     -- oder 'ownvehicles', je nach Server

-- Marker / Interaktion
Config.DrawDistance = 25.0
Config.Marker = {
    type  = 27,                            -- runder Marker
    size  = vector3(2.7, 2.7, 1.0),
    color = { r = 0, g = 150, b = 255, a = 180 }
}

Config.InteractKey      = 38               -- E
Config.InteractKeyLabel = '~INPUT_PICKUP~' -- E im Text

-- Menü-Design
Config.Menu = {
    Align          = 'top-left',
    InsuranceTitle = '~p~[ VERSICHERUNG ]~s~'
}

-- Wie bei Parking:
-- stored = 1  -> Garage
-- stored = 2  -> Abschlepphof
-- stored = 0  -> draußen / im Einsatz
Config.StoredTexts = {
    [0] = 'Ausgeparkt (auf der Straße / im Einsatz)',
    [1] = 'Eingeparkt in einer Garage',
    [2] = 'Im Abschlepphof'
}

-- Map für schöne Anzeige der Versicherung
Config.InsuranceDisplay = {
    premium  = 'Premium',
    standard = 'Standard',
    none     = 'Keine',
    default  = 'Keine'
}

-- Versicherungstypen + Preise
Config.InsuranceOptions = {
    premium  = { label = 'Premium',  dbValue = 'premium',  price = 0   },
    standard = { label = 'Standard', dbValue = 'standard', price = 200 },
    none     = { label = 'Keine',    dbValue = 'none',     price = 300 }
}

-- Reihenfolge im Menü
Config.InsuranceOrder = { 'premium', 'standard', 'none' }

-- Konto: 'bank' oder 'money'
Config.PayAccount = 'bank'

-- Versicherungsbüros (Ort mit Blip & Marker)
Config.InsuranceCenters = {
    ['cityinsurance'] = {
        label  = 'Versicherungsbüro Stadt',
        coords = vector3(-75.30, -818.70, 326.18),      -- Beispiel (Maze Bank Dach) -> anpassen!
        blip = {
            sprite = 408,                               -- z.B. Herz/Versicherungs-Icon
            color  = 27,
            scale  = 0.9
        }
    },

    -- weiteres Büro:
    -- ['sandyinsurance'] = {
    --     label  = 'Versicherungsbüro Sandy',
    --     coords = vector3(1839.0, 3672.0, 34.3),
    --     blip = {
    --         sprite = 408,
    --         color  = 46,
    --         scale  = 0.9
    --     }
    -- }
}
