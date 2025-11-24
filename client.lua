local ESX = exports["es_extended"]:getSharedObject()

local PlayerData = {}
local IsInMarker  = false
local CurrentCenter = nil -- { id = 'cityinsurance' }

-- ESX Events
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    if PlayerData then
        PlayerData.job = job
    end
end)

-- Blips für Versicherungsbüros
CreateThread(function()
    for id, center in pairs(Config.InsuranceCenters) do
        if center.blip then
            local blip = AddBlipForCoord(center.coords)
            SetBlipSprite(blip, center.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, center.blip.scale)
            SetBlipColour(blip, center.blip.color)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(center.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Marker zeichnen
local function DrawMarkerAt(coords)
    DrawMarker(
        Config.Marker.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
        Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
        false, true, 2, nil, nil, false
    )
end

-- Hilfsfunktionen
local function GetVehicleDisplayName(model)
    if not model then return 'Unbekannt' end
    return GetLabelText(GetDisplayNameFromVehicleModel(model))
end

local function GetInsuranceLabel(ins)
    if not ins or ins == '' then
        return Config.InsuranceDisplay.default or 'Keine'
    end
    ins = ins:lower()
    return Config.InsuranceDisplay[ins] or Config.InsuranceDisplay.default or ins
end

local function GetLocationText(storedStatus, garage)
    local baseText = Config.StoredTexts[storedStatus] or 'Unbekannter Standort'

    if storedStatus == 1 and garage then
        return baseText .. (' (~b~Garage: %s~s~)'):format(garage)
    elseif storedStatus == 2 and garage then
        return baseText .. (' (~o~Depot: %s~s~)'):format(garage)
    else
        return baseText
    end
end

-- Hauptloop: Marker + Notify + E
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords    = GetEntityCoords(playerPed)

        local newCenter = nil

        for id, center in pairs(Config.InsuranceCenters) do
            local dist = #(coords - center.coords)

            if dist < Config.DrawDistance then
                sleep = 0
                DrawMarkerAt(center.coords)
            end

            if dist < Config.Marker.size.x then
                newCenter = { id = id }
            end
        end

        if newCenter and not IsInMarker then
            IsInMarker = true
            CurrentCenter = newCenter

            local c = Config.InsuranceCenters[newCenter.id]
            ESX.ShowNotification(
                ('Versicherungsbüro: ~p~%s~s~\nDrücke %s um das Versicherungs-Menü zu öffnen.')
                    ):format(c.label, Config.InteractKeyLabel)

        elseif not newCenter and IsInMarker then
            IsInMarker   = false
            CurrentCenter = nil
        end

        if IsInMarker and CurrentCenter then
            sleep = 0
            if IsControlJustReleased(0, Config.InteractKey) then
                OpenInsuranceMainMenu(CurrentCenter.id)
            end
        end

        Wait(sleep)
    end
end)

-- Hauptmenü: alle Fahrzeuge
function OpenInsuranceMainMenu(centerId)
    local center = Config.InsuranceCenters[centerId]
    if not center then return end

    ESX.TriggerServerCallback('esx_insurance:getPlayerVehicles', function(vehicles)
        local elements = {}

        if #vehicles == 0 then
            table.insert(elements, {
                label    = 'Du besitzt keine Fahrzeuge.',
                value    = 'none',
                disabled = true
            })
        else
            for _, v in ipairs(vehicles) do
                local name = GetVehicleDisplayName(v.model)
                local insLabel = GetInsuranceLabel(v.insurance)
                local label = string.format('%s | %s { %s }', name, v.plate or 'N/A', insLabel)

                table.insert(elements, {
                    label  = label,
                    value  = 'vehicle',
                    veh    = v
                })
            end
        end

        ESX.UI.Menu.CloseAll()

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'insurance_main', {
            title    = string.format('%s ~w~%s', Config.Menu.InsuranceTitle, center.label),
            align    = Config.Menu.Align,
            elements = elements
        }, function(data, menu)
            if data.current.value == 'vehicle' and data.current.veh then
                menu.close()
                OpenInsuranceVehicleMenu(centerId, data.current.veh)
            end
        end, function(data, menu)
            menu.close()
        end)
    end)
end

-- Fahrzeug-spezifisches Menü
function OpenInsuranceVehicleMenu(centerId, veh)
    local center = Config.InsuranceCenters[centerId]
    if not center then return end

    local name     = GetVehicleDisplayName(veh.model)
    local location = GetLocationText(veh.storedStatus or 0, veh.garage)
    local insLabel = GetInsuranceLabel(veh.insurance)

    local elements = {}

    table.insert(elements, {
        label    = ('Fahrzeug: ~b~%s~s~ | %s'):format(name, veh.plate or 'N/A'),
        value    = 'info_vehicle',
        disabled = true
    })
    table.insert(elements, {
        label    = ('Standort: %s'):format(location),
        value    = 'info_location',
        disabled = true
    })
    table.insert(elements, {
        label    = ('Aktuelle Versicherung: ~c~%s~s~'):format(insLabel),
        value    = 'info_ins',
        disabled = true
    })
    table.insert(elements, { label = '──────────────', value = 'sep', disabled = true })

    -- Versicherungs-Optionen
    for _, key in ipairs(Config.InsuranceOrder) do
        local opt = Config.InsuranceOptions[key]
        if opt then
            local isCurrent = (veh.insurance or 'none') == opt.dbValue
            local label = string.format('%s – %s$', opt.label, opt.price or 0)
            if isCurrent then
                label = label .. ' ~g~[Aktuell]~s~'
            end

            table.insert(elements, {
                label       = label,
                value       = 'set_insurance',
                insuranceId = key,
                isCurrent   = isCurrent
            })
        end
    end

    table.insert(elements, { label = 'Zurück', value = 'back' })

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'insurance_vehicle', {
        title    = string.format('%s ~w~%s', Config.Menu.InsuranceTitle, center.label),
        align    = Config.Menu.Align,
        elements = elements
    }, function(data, menu)
        if data.current.value == 'back' then
            menu.close()
            OpenInsuranceMainMenu(centerId)
        elseif data.current.value == 'set_insurance' then
            if data.current.isCurrent then
                ESX.ShowNotification('Diese Versicherung ist bereits aktiv.')
                return
            end

            local insuranceId = data.current.insuranceId
            local plate       = veh.plate

            ESX.TriggerServerCallback('esx_insurance:setInsurance', function(success, msg, newInsurance)
                if msg then
                    ESX.ShowNotification(msg)
                end

                if success and newInsurance then
                    veh.insurance = newInsurance
                    menu.close()
                    -- neu öffnen, damit Anzeige aktualisiert
                    OpenInsuranceVehicleMenu(centerId, veh)
                end
            end, plate, insuranceId)
        end
    end, function(data, menu)
        menu.close()
        OpenInsuranceMainMenu(centerId)
    end)
end
