-- VRP
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("punish", src)
vCLIENT = Tunnel.getInterface("punish")

vRP.prepare("punish/getPunish","SELECT * FROM punish WHERE user_id = @user_id")
vRP.prepare("punish/applyPunishment", "INSERT INTO punish(user_id,x,y,z,punish) VALUES (@user_id,@x,@y,@z,@punish)")
vRP.prepare("punish/addPunishment", "UPDATE punish SET punish = punish + @punish WHERE user_id = @user_id")
vRP.prepare("punish/reducePunishment", "UPDATE punish SET punish = punish - @punish WHERE user_id = @user_id")
vRP.prepare("punish/delPunishment","DELETE FROM punish WHERE user_id = @user_id")
vRP.prepare("punish/createTable", "CREATE TABLE IF NOT EXISTS `punish` (`user_id` INT(11) NOT NULL,`x` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',`y` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',`z` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',`punish` INT(11) NOT NULL DEFAULT '0',PRIMARY KEY (`user_id`) USING BTREE)")

CreateThread(function()
	Wait(2000)
	vRP.query("punish/createTable", {})
end)

local outfitGarbage = {
    ["homem"] = {
        ["hat"] = { item = -1, texture = 0 },
        ["pants"] = { item = 13, texture = 0 },
        ["vest"] = { item = 0, texture = 0 },
        ["bracelet"] = { item = -1, texture = 0 },
        ["decals"] = { item = 0, texture = 0 },
        ["mask"] = { item = 0, texture = 0 },
        ["shoes"] = { item = 51, texture = 0 },
        ["tshirt"] = { item = 59, texture = 0 },
        ["torso"] = { item = 56, texture = 0 },
        ["accessory"] = { item = 0, texture = 0 },
        ["watch"] = { item = -1, texture = 0 },
        ["arms"] = { item = 0, texture = 0 },
        ["glass"] = { item = 0, texture = 0 },
        ["ear"] = { item = -1, texture = 0 }
    },
    ["mulher"] = {
        ["hat"] = { item = -1, texture = 0 },
        ["pants"] = { item = 30, texture = 0 },
        ["vest"] = { item = 0, texture = 0 },
        ["bracelet"] = { item = -1, texture = 0 },
        ["decals"] = { item = 0, texture = 0 },
        ["mask"] = { item = 36, texture = 0 },
        ["shoes"] = { item = 26, texture = 0 },
        ["tshirt"] = { item = 14, texture = 0 },
        ["torso"] = { item = 428, texture = 0 },
        ["accessory"] = { item = 0, texture = 0 },
        ["watch"] = { item = -1, texture = 0 },
        ["arms"] = { item = 20, texture = 0 },
        ["glass"] = { item = 0, texture = 0 },
        ["ear"] = { item = -1, texture = 0 }
    }
}

-- -- CLEARTABLE
-- vRP.prepare("punish/truncate", "TRUNCATE TABLE punish")

-- Citizen.CreateThread(function()
--     vRP.query("punish/truncate", {})
-- end)

RegisterCommand("punir", function(source, args)
    local user_id = vRP.getUserId(source)
    if user_id then
        if vRP.hasRank(user_id,"Admin",60) then
            if args[1] and args[2] then
                local otherSource = vRP.getUserSource(parseInt(args[1]))
                local Time = args[2]
                local x,y,z = vRPC.getPositions(otherSource)
                if otherSource then
                    TriggerClientEvent("Notify",source,"verde","Punição aplicada com sucesso!",5000)
                    
                    local otherId = vRP.getUserId(otherSource)
                    vRP.query("punish/applyPunishment",{ user_id = otherId, x = x, y = y, z = z, punish = Time })

                    Wait(1000)
                    vRP.teleport(otherSource,732.05,4182.18,40.68)
                    vCLIENT.startPunishment(otherSource,1)
                    local model = vRP.modelPlayer(source)
                    if model == "mp_m_freemode_01" then
                        TriggerClientEvent("updateRoupas",source,outfitGarbage["homem"])
                    elseif model == "mp_f_freemode_01" then
                        TriggerClientEvent("updateRoupas",source,outfitGarbage["mulher"])
                    end
                    
                    TriggerClientEvent("Notify",otherSource,"verde","Foi aplicada em você uma punição de " ..args[2].. " Cocôs para serem coletados.",5000)
                else
                    TriggerClientEvent("Notify",source,"vermelho","ID Inválido.",5000)
                end
            else
                TriggerClientEvent("Notify",source,"amarelo","Você precisar usar no formato <b>ID</b> <b>TEMPO</b ",5000)
            end
        end
    end
end)

function src.reducePunishment()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then

        vRP.query("punish/reducePunishment", { user_id = user_id, punish = 1 })

        local consultPunish = vRP.query("punish/getPunish", { user_id = user_id })
        if parseInt(consultPunish[1]["punish"]) <= 0 then
            vCLIENT.stopPunishment(source)
            vRP.teleport(source,consultPunish[1]["x"],consultPunish[1]["y"],consultPunish[1]["z"])
            vRP.query("punish/delPunishment", { user_id = user_id })

            TriggerClientEvent("Notify",source,"vermelho","Sua punição acabou.")
            return
        end

        vCLIENT.startPunishment(source,1)
        TriggerClientEvent("Notify",source,"azul","Você ainda tem <b>"..parseInt(consultPunish[1]["punish"]).." cocôs</b>.",5000)
    end
end


function src.increasePunish()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        vRP.query("punish/addPunishment", { user_id = user_id, punish = 15 })
        TriggerClientEvent("Notify",source,"vermelho","Sua punição foi aumentada em mais 15 cocôs.",5000)
    end
end


AddEventHandler("vRP:playerSpawn",function(user_id,source)
    checkForPunishment(source)
end)

function checkForPunishment(player)
	local user_id = vRP.getUserId(player)
    local consultPunish = vRP.query("punish/getPunish", { user_id = user_id })
    if consultPunish[1] then
        if parseInt(consultPunish[1]["punish"]) >= 0 then

            vCLIENT.startPunishment(player,1)
            TriggerClientEvent("Notify",player,"azul","Você ainda tem <b>"..parseInt(consultPunish[1]["punish"]).." cocôs</b>.",5000)
            vRP.teleport(player,1677.72,2509.68,45.57)
        end
    end
end