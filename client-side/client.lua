-- VRP
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface("punish", src)
vSERVER = Tunnel.getInterface("punish")

local Punish = false
local punishLocal = 1
local punishLeave = 0
local Random = 1
local Quantity = 0
local Shit = {}

local punishServices = {
	[1] = {
		box = { 717.05102539063,4182.7509765625,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" }, -- caixa para limpar
		[1] = { 720.47729492188,4172.712890625,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[2] = { 717.07489013672,4171.6108398438,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[3] = { 712.55187988281,4171.5,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[4] = { 710.23541259766,4176.2373046875,40.709190368652,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[5] = { 721.78198242188,4180.111328125,40.709190368652,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[6] = { 714.96350097656,4175.1274414063,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[7] = { 719.12927246094,4175.9326171875,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
		[8] = { 1718.3525390625,4180.392578125,40.709186553955,"amb@world_human_janitor@male@idle_a","idle_a","prop_tool_broom" },
	}
}

local polyPunish = PolyZone:Create({
	vector2(666.04602050781, 4166.5493164062),
	vector2(686.57763671875, 4199.8891601562),
	vector2(733.77453613281, 4216.8149414062),
	vector2(777.93267822266, 4148.7143554688)
  }, { name="coco" })


polyPunish:onPlayerInOut(function(isPointInside, point)
	if not isPointInside and Punish then
		local ped = PlayerPedId()
		while IsPedInAnyVehicle(ped) do
			TaskLeaveAnyVehicle(ped, 0, 16)
			Wait(1000)
		end

		SetEntityCoords(ped,723.55,4177.42,42.3)		
		if punishLeave == 0 then
			TriggerEvent("Notify","vermelho","Você não pode sair da area de punição, caso saia novamente, sua punição irá aumentar.",5000)
			punishLeave = punishLeave + 1
		else
			vSERVER.increasePunish()
		end
	end
end)

function startPunishmentThread()
    CreateThread(function()
        while Punish do
            local timeDistance = 1000
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)

			local loc = punishServices[punishLocal][Random]
			local Distance = #(Coords - vector3(loc[1],loc[2],loc[3]))
			if Distance <= 150 then
				timeDistance = 4

				DrawText3D(loc[1],loc[2],loc[3],"PRESSIONE ~r~E~w~  PARA LIMPAR A ~r~MERDA~w~")
				if Distance <= 1.5 then
					DrawText3D(loc[1],loc[2],loc[3],"PRESSIONE ~g~E~w~  PARA LIMPAR A ~g~MERDA~w~")
					if IsControlJustPressed(1,38) then
						if Quantity < 4 then
							LocalPlayer["state"]["Commands"] = true
							vRP.createObjects(loc[4],loc[5],loc[6],49,28422)
							FreezeEntityPosition(Ped,true)
							TriggerEvent("Progress",5000)
							Wait(5000)
							FreezeEntityPosition(Ped,false)
							LocalPlayer["state"]["Commands"] = false
							vRP.removeObjects()
							vSERVER.reducePunishment()
							Quantity = Quantity + 1

							if Quantity == 4 then
								placeObject("prop_box_wood05b", "box")
								startBoxThread()
							end
						else
							TriggerEvent("Notify","amarelo","Limpe sua vassoura primeiro antes de continuar.",5000)
						end
					end
				end
			end
			Wait(timeDistance)
        end
    end)

	CreateThread(function()
		while Punish do
			local Ped = PlayerPedId()
			if GetEntityHealth(Ped) <= 101 then
				vRP.revivePlayer(199)
			end
			Wait(1000)
		end
	end)
end

function startBoxThread()
	CreateThread(function()
		while Quantity >= 4 do
			local timeDistance = 1000
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)

			local loc = punishServices[punishLocal].box
			local Distance = #(Coords - vector3(loc[1],loc[2],loc[3]))
			if Distance <= 150 then
				timeDistance = 4

				DrawText3D(loc[1],loc[2],loc[3],"PRESSIONE ~r~E~w~  PARA LIMPAR SUA VASSOURA")
				if Distance <= 2 then
					DrawText3D(loc[1],loc[2],loc[3],"PRESSIONE ~g~E~w~  PARA LIMPAR SUA VASSOURA")
					if IsControlJustPressed(1,38) then
						-- LocalPlayer["state"]["Commands"] = true
						vRP.createObjects(loc[4],loc[5],loc[6],49,28422)
						TriggerEvent("Progress",5000)
						Wait(5000)
						vRP.removeObjects()
						LocalPlayer["state"]["Commands"] = false
						Quantity = 0

						removeObject("box")
					end
				end
			end
			Wait(timeDistance)
		end
	end)
end

function placeObject(hash, Number)
	local hash = GetHashKey(hash)
	while not HasModelLoaded(hash) do
		RequestModel(hash)
		Wait(10)
	end

	local loc = punishServices[punishLocal][Number]
	Shit[Number] = CreateObject(hash,loc[1],loc[2],loc[3],true,false,false)
	PlaceObjectOnGroundProperly(Shit[Number])
	FreezeEntityPosition(Shit[Number],true)
	SetModelAsNoLongerNeeded(hash)
end

function removeObject(Number)
	DeleteObject(Shit[Number])
end

function src.startPunishment(Locate)
    if not Punish then
        Punish = true
		for i = 1, #punishServices[punishLocal] do
			placeObject("prop_big_shit_02", i)
		end
        startPunishmentThread()
    end

	removeObject(Random)
	Random = Random + 1
	if Random >= #punishServices[punishLocal] then
		Random = 1
		for i = 1, #punishServices[punishLocal] do
			placeObject("prop_big_shit_02", i)
		end
	end
end

function src.stopPunishment()
	Punish = false
	Quantity = 0
	punishLeave = 0
	TriggerServerEvent("player:outfitFunctions","aplicar")
end

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = GetScreenCoordFromWorldCoord(x,y,z)

	if onScreen then
		BeginTextCommandDisplayText("STRING")
		AddTextComponentSubstringKeyboardDisplay(text)
		SetTextColour(255,255,255,150)
		SetTextScale(0.35,0.35)
		SetTextFont(4)
		SetTextCentre(1)
		EndTextCommandDisplayText(_x,_y)

		local width = string.len(text) / 160 * 0.45
		DrawRect(_x,_y + 0.0125,width,0.03,38,42,56,200)
	end
end