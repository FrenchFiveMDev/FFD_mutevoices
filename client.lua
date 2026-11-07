local uiOpen  = false
local bubbles = {}

-- ───────────── Interface ─────────────
local function openUI()
    if uiOpen then return end
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', phrases = Config.QuickPhrases, recLang = Config.RecLang, autoSend = Config
    .AutoSend })
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('dire', function(_, args)
    local text = table.concat(args, ' ')
    if text ~= '' then
        TriggerServerEvent('muet:say', text, 'normal')
    else
        openUI()
    end
end, false)

RegisterKeyMapping('dire', 'Parler (synthèse vocale)', 'keyboard', Config.OpenKey)

RegisterNUICallback('say', function(data, cb)
    TriggerServerEvent('muet:say', data.text, data.mode)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('pair', function(_, cb)
    TriggerServerEvent('muet:requestCode')
    cb('ok')
end)

RegisterCommand('dire-web', function()
    TriggerServerEvent('muet:requestCode')
end, false)

RegisterNetEvent('muet:code', function(code, url)
    SendNUIMessage({ action = 'code', code = code, url = url })
    TriggerEvent('chat:addMessage', {
        color = { 80, 170, 255 },
        args = { 'Voix', ('Code de liaison : %s%s'):format(code, (url and url ~= '') and (' — page : ' .. url) or '') },
    })
end)

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

-- ───────────── Bulle 3D ─────────────
local function drawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()
        for id, b in pairs(bubbles) do
            if b.expires < now then
                bubbles[id] = nil
            else
                sleep = 0
                local ply = GetPlayerFromServerId(id)
                if ply ~= -1 then
                    local c = GetEntityCoords(GetPlayerPed(ply))
                    drawText3D(c.x, c.y, c.z + 1.05, b.text)
                end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── Bouche qui bouge ─────────────
local function animateMouth(srcId, duration)
    local ply = GetPlayerFromServerId(srcId)
    if ply == -1 then return end
    local ped = GetPlayerPed(ply)

    RequestAnimDict('mp_facial')
    local t = GetGameTimer()
    while not HasAnimDictLoaded('mp_facial') and GetGameTimer() - t < 2000 do Wait(0) end

    PlayFacialAnim(ped, 'mic_chatter', 'mp_facial')
    SetTimeout(duration, function()
        if DoesEntityExist(ped) then
            PlayFacialAnim(ped, 'mood_normal_1', 'facials@gen_male@variations@normal')
        end
    end)
end

-- ───────────── Réception d'un message ─────────────
RegisterNetEvent('muet:hear', function(srcId, text, coords, range)
    local dist     = #(GetEntityCoords(PlayerPedId()) - coords)
    local volume   = math.max(0.05, 1.0 - (dist / range))
    local duration = math.max(1500, #text * 75)

    SendNUIMessage({ action = 'speak', text = text, volume = volume, lang = Config.Language })

    if Config.ShowBubble then
        bubbles[srcId] = { text = text, expires = GetGameTimer() + duration + 2000 }
    end

    if Config.ShowChat then
        TriggerEvent('chat:addMessage', {
            color = { 200, 200, 200 },
            args = { ('[%s]'):format(GetPlayerName(GetPlayerFromServerId(srcId))), text },
        })
    end

    if Config.MouthAnim then
        CreateThread(function() animateMouth(srcId, duration) end)
    end
end)
