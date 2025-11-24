local ESX = exports["es_extended"]:getSharedObject()

local usingOx   = Config.UseOxMysql
local tableName = Config.TableName

-- DB-Wrapper
local function fetchAll(query, params, cb)
    if usingOx then
        exports.oxmysql:execute(query, params, cb)
    else
        MySQL.Async.fetchAll(query, params, cb)
    end
end

local function execute(query, params, cb)
    if usingOx then
        exports.oxmysql:update(query, params, cb)
    else
        MySQL.Async.execute(query, params, cb)
    end
end

-- Versicherung → Gebühr
local function GetInsuranceData(insurance)
    insurance = insurance and insurance:lower() or 'default'
    local opt = Config.InsuranceOptions[insurance]
    if opt then return opt end
    -- Fallback: default
    local defaultOpt = Config.InsuranceOptions.default
    if defaultOpt then return defaultOpt end

    return { label = 'Keine', dbValue = 'none', price = 0 }
end

-- Alle Fahrzeuge des Spielers holen
ESX.RegisterServerCallback('esx_insurance:getPlayerVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    local identifier = xPlayer.getIdentifier()

    local query = ([[SELECT plate, vehicle, stored, garage, insurance
                     FROM %s
                     WHERE owner = @owner]])
        :format(tableName)

    fetchAll(query, { ['@owner'] = identifier }, function(result)
        local vehicles = {}

        for i = 1, #result do
            local row = result[i]
            local vehProps = json.decode(row.vehicle or '{}') or {}

            vehProps.plate        = row.plate
            vehProps.storedStatus = row.stored
            vehProps.garage       = row.garage
            vehProps.insurance    = row.insurance

            table.insert(vehicles, vehProps)
        end

        cb(vehicles)
    end)
end)

-- Versicherung ändern + bezahlen
ESX.RegisterServerCallback('esx_insurance:setInsurance', function(source, cb, plate, newInsuranceId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false, 'Fehler: Spieler nicht gefunden.') return end

    -- nur erlaubte Typen
    local opt = Config.InsuranceOptions[newInsuranceId]
    if not opt then
        cb(false, 'Ungültiger Versicherungstyp.')
        return
    end

    local identifier = xPlayer.getIdentifier()
    local account    = Config.PayAccount or 'bank'
    local fee        = opt.price or 0

    -- Preis prüfen
    if fee > 0 then
        local money = 0

        if account == 'bank' then
            money = xPlayer.getAccount('bank').money
        else
            money = xPlayer.getMoney()
        end

        if money < fee then
            cb(false, ('Du hast nicht genug Geld (benötigt: %s$).'):format(fee))
            return
        end

        if account == 'bank' then
            xPlayer.removeAccountMoney('bank', fee)
        else
            xPlayer.removeMoney(fee)
        end
    end

    local query = ([[UPDATE %s
                     SET insurance = @insurance
                     WHERE owner = @owner
                       AND plate = @plate]])
        :format(tableName)

    execute(query, {
        ['@insurance'] = opt.dbValue,
        ['@owner']     = identifier,
        ['@plate']     = plate
    }, function(rowsChanged)
        if rowsChanged == 0 then
            cb(false, 'Fahrzeug nicht gefunden oder gehört dir nicht.')
        else
            local msg
            if fee > 0 then
                msg = ('Versicherung auf ~c~%s~s~ geändert. Kosten: ~g~%s$~s~.'):format(opt.label, fee)
            else
                msg = ('Versicherung auf ~c~%s~s~ geändert.'):format(opt.label)
            end
            cb(true, msg, opt.dbValue)
        end
    end)
end)
