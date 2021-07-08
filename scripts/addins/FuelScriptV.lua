-- Fuel Script V 0.8 by Sakis25
-- http://sakis25games.blogspot.com

-- Special Thanks:
---- faztsquirrel
---- haws1290
---- Daxwolf
---- headscript


-- Configuration:1
-- x,y of gas bar
local gasx = 0.01 --set to 0 if safezone is at 100%
local gasy = 0.8

-- refuel key (for jerry can)
local refuelKey = Keys.L


---------------------------------------
--     DO NOT EDIT BEYOND HERE     --
---------------------------------------

local GUI = {}
GUI.GUI = {}
GUI.time = 0

local gasStations = {{-724, -935, 30},{-71, -1762, 30},{265, -1261, 30},{819, -1027, 30},{-2097, -320, 30},
	{1212, 2657, 30},{2683, 3264, 30},{-2555, 2334, 30},{180, 6603, 30},{2581, 362, 30},
	{1702, 6418, 30},{-1799, 803, 30},{-90, 6415, 30},{264, 2609, 30},{50, 2776, 30},
	{2537, 2593, 30},{1182, -330, 30},{-526, -1212, 30},{1209, -1402, 30},{2005, 3775, 30},
	{621, 269, 30},{-1434, -274, 30},{1687, 4929, 30}}
	
    
local gasw = 0.3
local gash = 0.009
local refillCar = false
local lowFuel = false
local drawHint = false
local drawHintB = false
local hasfuel = false

local blip = {}
local cars = {}
--local dict = "misscarsteal2peeing"
--local anim = "peeing_loop"
     
function GUI.unload()
	for i, coords in pairs(gasStations) do
		UI.REMOVE_BLIP(blip[i])
	end
end
     
function GUI.init()
GUI.time = GAMEPLAY.GET_GAME_TIMER()
--STREAMING.REQUEST_ANIM_DICT(dict)

	for i, coords in pairs(gasStations) do
		blip[i] = UI.ADD_BLIP_FOR_COORD(coords[1],coords[2],coords[3])
		UI.SET_BLIP_SPRITE(blip[i], 361)
        UI.SET_BLIP_SCALE(blip[i], 0.8)
		UI.SET_BLIP_AS_SHORT_RANGE(blip[i], true)
	end
end
     
function GUI.tick()
local playerPed = PLAYER.PLAYER_PED_ID()
local player = PLAYER.GET_PLAYER_PED(playerPed)
local playerExists = ENTITY.DOES_ENTITY_EXIST(playerPed)
local playerPosition = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)

	if( playerExists ) then
		--refill with jerry can
		if( hasfuel and GAMEPLAY.GET_HASH_KEY(WEAPON.GET_SELECTED_PED_WEAPON(playerPed)) == 2821749192 ) then -- 2821749192 = jerrycan
			for key, value in pairs(cars) do
				if( ENTITY.DOES_ENTITY_EXIST(value.pointer) and value.fuel < 0.14 ) then
					local coords = ENTITY.GET_ENTITY_COORDS( value.pointer, nil )
					local coords2 = ENTITY.GET_ENTITY_COORDS( playerPed, nil )
					
					if( GAMEPLAY.GET_DISTANCE_BETWEEN_COORDS( coords.x, coords.y, coords.z, coords2.x, coords2.y, coords2.z, false ) < 3 ) then
						local ammo = WEAPON.GET_AMMO_IN_PED_WEAPON( playerPed, WEAPON.GET_SELECTED_PED_WEAPON(playerPed) )
						drawHintB = false
						drawHint = true
						GUI.drawText()
						GUI.renderGUI()
						if( get_key_pressed(refuelKey) and ammo > 0 ) then
							value.fuel = value.fuel + 0.0005
							AI.TASK_TURN_PED_TO_FACE_ENTITY( playerPed, value.pointer, 100) 
							WEAPON.SET_PED_AMMO( playerPed, WEAPON.GET_SELECTED_PED_WEAPON(playerPed), ammo-9 )
						end
						if( CONTROLS.IS_CONTROL_PRESSED(2,70) and ammo > 0 ) then
							value.fuel = value.fuel + 0.0005
							AI.TASK_TURN_PED_TO_FACE_ENTITY( playerPed, value.pointer, 100) 
							--AI.TASK_PLAY_ANIM( playerPed, dict, anim, 5, -1, -1, 16, 0, false, 0, false)
							WEAPON.SET_PED_AMMO( playerPed, WEAPON.GET_SELECTED_PED_WEAPON(playerPed), ammo-9 )
						end
					else
						drawHint = false
                    end
				end
			end
		end
     
	--ENTERED CAR
	if( PED.IS_PED_IN_ANY_VEHICLE( playerPed, false ) and VEHICLE.GET_PED_IN_VEHICLE_SEAT(PED.GET_VEHICLE_PED_IS_IN( playerPed,true ), -1) == playerPed ) then
	--if( PED.IS_PED_IN_ANY_VEHICLE( playerPed, false ) ) then
		local veh = PED.GET_VEHICLE_PED_IS_IN( playerPed,true )
		local carspeed = ENTITY.GET_ENTITY_SPEED( veh )
	 
		if (PED.IS_PED_MODEL(playerPed, GAMEPLAY.GET_HASH_KEY("player_zero"))) then
			model = 0
		elseif (PED.IS_PED_MODEL(playerPed, GAMEPLAY.GET_HASH_KEY("player_one"))) then                                
			model = 1                                         
		elseif (PED.IS_PED_MODEL(playerPed, GAMEPLAY.GET_HASH_KEY("player_two"))) then
			model = 2
		end
		local statname = "SP"..model.."_TOTAL_CASH"
		local hash = GAMEPLAY.GET_HASH_KEY(statname)
		local bool, val = STATS.STAT_GET_INT(hash, 0, -1)
	 
		-- If vehicle has changed
		if not cars[1] or cars[1].pointer ~= veh then
			local found = false
			local emptyfound = false
     
			-- Check if current vehicle is used before
            for key, value in pairs(cars) do
              if value.pointer == veh then
                -- Has been in this car before
                found = true
                local temp = table.remove(cars, key)
                table.insert(cars, 1, temp)
                break
              else
                -- Check if vehicle still exists, if not then make a possible value if there is no other one (really sloppy)
                if not ENTITY.DOES_ENTITY_EXIST(value.pointer) then
                  value = {veh, fuel=math.random(6,12)/100}
                  emptyfound = true
                end
              end
            end
     
            if ( not found ) then
              -- There is a possible value from earlier
              if ( emptyfound ) then
                for key, value in pairs(cars) do
                  if not ENTITY.DOES_ENTITY_EXIST(value.pointer) then
                    table.remove(cars, key)
                  end
                end
			else
                -- Remove cars if we are over the 10 cars limit
				if ( #cars > 10 ) then
					table.remove(cars, 1)
				end
			end
     
				-- Insert current car at pos #1
				table.insert(cars, 1, {pointer=veh, fuel=math.random(6,12)/100})
			end
		end
     
		-- Does vehicle use fuel?
		if (VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh)) or VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(veh)) or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(ENTITY.GET_ENTITY_MODEL(veh))) then
            -- Fuel usage
			if((GAMEPLAY.GET_GAME_TIMER() - GUI.time)> 200) then
				if(cars[1].fuel > 0 and cars[1].pointer) then
					cars[1].fuel = cars[1].fuel - (carspeed/600000)
					GUI.time = GAMEPLAY.GET_GAME_TIMER()
				else
					cars[1].fuel = 0
				end
			end
		GUI.renderGUI()
		hasfuel = true
		-- Has used his horn to refuel
		if (refillCar==true) then
			if (cars[1].fuel < 0.14) then
				-- car refuel slower than bike
				if (VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh))) then
					cars[1].fuel = cars[1].fuel + 0.001
				else
					cars[1].fuel = cars[1].fuel + 0.002
				end
				
				VEHICLE.SET_VEHICLE_ENGINE_ON(veh, false,true)
				UI.DISPLAY_CASH(true)
				STATS.STAT_SET_INT(hash, val - 1, true)
			else
				refillCar=false
				cars[1].fuel = 0.14
				VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true,true)
			end
		end
     
		-- OUT OF GAS
		if (cars[1].fuel == 0) then
			VEHICLE.SET_VEHICLE_ENGINE_ON(veh, false, true)
		end
     
		--sound horn to refill gas
		if (carspeed < 1 and refillCar == false) then
			local coords = ENTITY.GET_ENTITY_COORDS(playerPed, nil);
			for i, current in pairs(gasStations) do
				if(GAMEPLAY.GET_DISTANCE_BETWEEN_COORDS(coords.x,coords.y,coords.z,current[1],current[2],coords.z,false) < 12 and drawHintB==false) then
					--you are close show hint
						drawHint = false
						drawHintB = true
						GUI.drawText()

						if (cars[1].fuel < 0.14 and drawHintB==true) then
							refillCar = PLAYER.IS_PLAYER_PRESSING_HORN(player)
						else
							if (drawHintB==true) then
							drawHintB = false
							end
						end
					break
				else
				--you are far hide hint
					if (drawHintB==true) then
						drawHintB = false
					end
				end
			end
		end
		else
		hasfuel = false
		end
	else
	--EXIT CAR
		lowFuel=false
		drawHintB = false
		refillCar=false
		end
	end
end
     
function GUI.drawText()
  if (hasfuel) then
    if(drawHint) then
        UI.SET_TEXT_FONT(0)
        UI.SET_TEXT_PROPORTIONAL(1)
        UI.SET_TEXT_SCALE(0.0, 0.35)
        UI.SET_TEXT_COLOUR(255, 255, 255, 255)
        UI.SET_TEXT_DROPSHADOW(0, 0, 0, 0,255)
        UI.SET_TEXT_EDGE(1, 0, 0, 0, 255)
        UI.SET_TEXT_DROP_SHADOW()
        UI.SET_TEXT_OUTLINE()
        UI._SET_TEXT_ENTRY("STRING")
        UI._ADD_TEXT_COMPONENT_STRING("Hold L (default) to refuel your vehicle.")
        UI._DRAW_TEXT(0.015, 0.015)
	GRAPHICS.DRAW_RECT(gasx+0.07, gasy, 0.14, gash, 0, 0, 0, 60);
	GRAPHICS.DRAW_RECT(gasx+(cars[1].fuel/2), gasy, cars[1].fuel, gash, 156, 181, 42, 255)
    elseif(drawHintB) then
        UI.SET_TEXT_FONT(0)
        UI.SET_TEXT_PROPORTIONAL(1)
        UI.SET_TEXT_SCALE(0.0, 0.35)
        UI.SET_TEXT_COLOUR(255, 255, 255, 255)
        UI.SET_TEXT_DROPSHADOW(0, 0, 0, 0,255)
        UI.SET_TEXT_EDGE(1, 0, 0, 0, 255)
        UI.SET_TEXT_DROP_SHADOW()
        UI.SET_TEXT_OUTLINE()
        UI._SET_TEXT_ENTRY("STRING")
        UI._ADD_TEXT_COMPONENT_STRING("Sound the horn to refuel your vehicle.")
        UI._DRAW_TEXT(0.015, 0.015)
    end
  end
end

function GUI.renderGUI()
	GRAPHICS.DRAW_RECT(gasx+0.07, gasy, 0.14, gash+0.01, 0, 0, 0, 60)--bar bg 1
    GRAPHICS.DRAW_RECT(gasx+0.07, gasy, 0.14, gash, 220, 20, 20, 60)--bar bg 2
	
if (cars[1].fuel==0) then
        UI.SET_TEXT_FONT(0)
        UI.SET_TEXT_PROPORTIONAL(1)
        UI.SET_TEXT_SCALE(0.0, 0.32)
        UI.SET_TEXT_COLOUR(230, 0, 0, 255)
        UI.SET_TEXT_DROP_SHADOW()
        UI._SET_TEXT_ENTRY("STRING")
        UI._ADD_TEXT_COMPONENT_STRING("OUT OF FUEL")
        UI._DRAW_TEXT(gasx+0.028, gasy-0.03)
end
	
	
	
        if (cars[1].fuel<0.026) then
                GRAPHICS.DRAW_RECT(gasx+(cars[1].fuel/2), gasy, cars[1].fuel, gash, 220, 20, 20, 255)
                lowFuel=true
        else
               -- GRAPHICS.DRAW_RECT(gasx+(cars[1].fuel/2), gasy, cars[1].fuel, gash, 156, 181, 42, 255)
                GRAPHICS.DRAW_RECT(gasx+(cars[1].fuel/2), gasy, cars[1].fuel, gash, 246, 154, 80, 255)
                lowFuel=false
        end
		
	GRAPHICS.DRAW_RECT(gasx+0.07, gasy, 0.002, gash, 0, 0, 0, 50);
end

return GUI