local pokedex = {}

local HTTP = require('socket.http')
local JSON = require('dkjson')
local bindings = require('otouto.bindings')
local utilities = require('otouto.utilities')

pokedex.command = 'pokedex <query>'

function pokedex:init(config)
    pokedex.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('pokedex', true):t('dex', true).table
    pokedex.doc = config.cmd_pat .. [[pokedex <query>
Returns a Pokedex entry from pokeapi.co.
Queries must be a number of the name of a Pokémon.
Alias: ]] .. config.cmd_pat .. 'dex'
end

function pokedex:action(msg, config)

    local input = utilities.input_from_msg(msg)
    if not input then
        utilities.send_reply(self, msg, pokedex.doc, true)
        return
    end

    bindings.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' } )

    local url = 'http://pokeapi.co'

    local dex_url = url .. '/api/v1/pokemon/' .. input
    local dex_jstr, res = HTTP.request(dex_url)
    if res ~= 200 then
        utilities.send_reply(self, msg, config.errors.connection)
        return
    end

    local dex_jdat = JSON.decode(dex_jstr)

    if not dex_jdat.descriptions or not dex_jdat.descriptions[1] then
        utilities.send_reply(self, msg, config.errors.results)
        return
    end

    local desc_url = url .. dex_jdat.descriptions[math.random(#dex_jdat.descriptions)].resource_uri
    local desc_jstr, _ = HTTP.request(desc_url)
    if res ~= 200 then
        utilities.send_reply(self, msg, config.errors.connection)
        return
    end

    local desc_jdat = JSON.decode(desc_jstr)

    local poke_type
    for _,v in ipairs(dex_jdat.types) do
        local type_name = v.name:gsub("^%l", string.upper)
        if not poke_type then
            poke_type = type_name
        else
            poke_type = poke_type .. ' / ' .. type_name
        end
    end
    poke_type = poke_type .. ' type'

    local output = '*' .. dex_jdat.name .. '*\n#' .. dex_jdat.national_id .. ' | ' .. poke_type .. '\n_' .. desc_jdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon') .. '_'


    utilities.send_message(self, msg.chat.id, output, true, nil, true)

end

return pokedex
