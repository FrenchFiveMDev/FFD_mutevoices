local lastSay = {}
local codes, srcCode, fails = {}, {}, {}
math.randomseed(os.time())

local function clean(text)
    if type(text) ~= 'string' then return nil end
    text = (text:gsub('%c', ' '))
    text = text:match('^%s*(.-)%s*$')
    if text == '' then return nil end
    local len = utf8.len(text)
    if len and len > Config.MaxLength then
        text = text:sub(1, utf8.offset(text, Config.MaxLength + 1) - 1)
    end
    return text
end

local function allowed(src)
    return not Config.RequireAce or IsPlayerAceAllowed(src, 'muet.use')
end

-- Fonction commune : fait parler le joueur `src`
local function speak(src, text, mode)
    if not allowed(src) then return false, 'forbidden' end
    text = clean(text)
    if not text then return false, 'empty' end

    local now = GetGameTimer()
    if lastSay[src] and (now - lastSay[src]) < Config.Cooldown then return false, 'cooldown' end
    lastSay[src] = now

    local range  = Config.Ranges[mode] or Config.Ranges.normal
    local coords = GetEntityCoords(GetPlayerPed(src))

    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        local ped = GetPlayerPed(id)
        if ped and ped ~= 0 and #(GetEntityCoords(ped) - coords) <= range then
            TriggerClientEvent('muet:hear', id, src, text, coords, range)
        end
    end
    return true
end

RegisterNetEvent('muet:say', function(text, mode)
    speak(source, text, mode)
end)

-- ───────────── Code de liaison pour la page web ─────────────
local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
local function newCode()
    local c
    repeat
        c = ''
        for _ = 1, 6 do
            local r = math.random(#chars)
            c = c .. chars:sub(r, r)
        end
    until not codes[c]
    return c
end

RegisterNetEvent('muet:requestCode', function()
    local src = source
    if not allowed(src) then return end
    if srcCode[src] then codes[srcCode[src]] = nil end
    local c = newCode()
    codes[c] = { src = src, expires = os.time() + Config.WebCodeTTL }
    srcCode[src] = c
    TriggerClientEvent('muet:code', src, c, Config.WebUrl)
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastSay[src] = nil
    if srcCode[src] then codes[srcCode[src]] = nil end
    srcCode[src] = nil
end)

-- ───────────── Serveur HTTP (page téléphone/navigateur) ─────────────
local function tooManyFails(addr)
    local f = fails[addr]
    return f and (os.time() - f.t) < 60 and f.n >= 10
end

local function addFail(addr)
    local f = fails[addr]
    if not f or (os.time() - f.t) >= 60 then
        fails[addr] = { n = 1, t = os.time() }
    else
        f.n = f.n + 1
    end
end

local function findPlayer(code, addr)
    if type(code) ~= 'string' then
        addFail(addr)
        return nil
    end
    local e = codes[code:upper()]
    if not e or e.expires < os.time() or not GetPlayerName(e.src) then
        addFail(addr)
        return nil
    end
    return e.src
end

local function reply(res, status, tbl)
    res.writeHead(status, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(tbl))
end

SetHttpHandler(function(req, res)
    local path = req.path

    if req.method == 'GET' and (path == '/' or path == '') then
        res.writeHead(200, { ['Content-Type'] = 'text/html; charset=utf-8' })
        res.send(LoadResourceFile(GetCurrentResourceName(), 'web/index.html') or 'Page introuvable')
        return
    end

    if req.method == 'POST' and (path == '/say' or path == '/check') then
        req.setDataHandler(function(body)
            local ok, data = pcall(json.decode, body)
            if not ok or type(data) ~= 'table' then return reply(res, 400, { ok = false }) end

            local addr = req.address or '?'
            if tooManyFails(addr) then return reply(res, 429, { ok = false, error = 'trop_de_tentatives' }) end

            local src = findPlayer(data.code, addr)
            if not src then return reply(res, 403, { ok = false, error = 'code_invalide' }) end

            if path == '/check' then
                return reply(res, 200, { ok = true, name = GetPlayerName(src) })
            end

            local done, why = speak(src, data.text, data.mode)
            reply(res, done and 200 or 429, { ok = done, error = why })
        end)
        return
    end

    res.writeHead(404)
    res.send('')
end)
