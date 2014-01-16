--[[

TAGET - The 'Text Adventure Game Engine Thingy', used for the creation of simple text adventures
Copyright (C) 2013 Robert Cochran

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License in the LICENSE file for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

]]

local m = {};

print("Loading monster data...");
m.list = dofile("data/monsters.txt");
taget.state.encounter = nil;

local function createEncounter()
	math.randomseed(os.time());
	local encounterChance = math.random(1, 100);
	local monsterNum = math.random(1, #m.list);

	if m.list[monsterNum].startFloor <= taget.state.player.z and encounterChance <= m.list[monsterNum].rarity then
		taget.state.encounter = table.copy(m.list[monsterNum]);

		taget.state.encounter.baseHealth = (taget.state.player.z == 1) and taget.state.encounter.baseHealth or math.floor(taget.state.encounter.baseHealth * ((taget.state.player.z + 1) / 2));
		taget.state.encounter.baseAttack = (taget.state.player.z == 1) and taget.state.encounter.baseAttack or math.floor(taget.state.encounter.baseAttack * ((taget.state.player.z + 1) / 2));
		taget.state.encounter.baseDefense = (taget.state.player.z == 1) and taget.state.encounter.baseDefense or math.floor(taget.state.encounter.baseDefense * ((taget.state.player.z + 1) / 2));
		taget.state.encounter.baseExp = (taget.state.player.z == 1) and taget.state.encounter.baseExp or math.floor(taget.state.encounter.baseExp * ((taget.state.player.z + 1) / 2));

		taget.state.encounter.x = taget.state.player.x;
		taget.state.encounter.y = taget.state.player.y;
		taget.state.encounter.z = taget.state.player.z;
	
		print("A random "..taget.state.encounter.name.." has appeared!");
	end
end

function m.processEncounter()
	if not taget.state.encounter then
		if taget.world.getTileType(taget.state.dungeon, taget.state.player.x, taget.state.player.y, taget.state.player.z) == "boss" then
			taget.state.encounter = table.copy(m.list.boss);

			taget.state.encounter.x = taget.state.player.x;
			taget.state.encounter.y = taget.state.player.y;
			taget.state.encounter.z = taget.state.player.z;

			print(type(taget.state.encounter));
			print("The dungeon boss "..taget.state.encounter.name.." has appeared!");
		else
			createEncounter();
		end
	else
		if taget.state.encounter.x ~= taget.state.player.x or taget.state.encounter.y ~= taget.state.player.y or taget.state.encounter.z ~= taget.state.player.z then
			taget.state.encounter = nil;
			return;
		end

		if taget.state.encounter.baseHealth <= 0 then
			print("Defeated the "..taget.state.encounter.name.."!");
			
			if taget.state.encounter.name == m.list.boss.name then
				print("You win!");
				os.exit();
			end

			taget.state.player.experience = taget.state.player.experience + taget.state.encounter.baseExp;
			print("Got "..taget.state.encounter.baseExp.." experience points!");

			taget.state.encounter = nil;

			if taget.state.player.experience >= taget.state.player.nextLevel then
				taget.state.player.level = taget.state.player.level + 1;
				print("Got to level "..taget.state.player.level.."!");
				taget.state.player.nextLevel = taget.state.player.nextLevel + (25 * taget.state.player.level);
				taget.input.chooseLevelUp();
			end

			print("Next level : "..(taget.state.player.nextLevel - taget.state.player.experience).." more experience points");
			return;
		end

		local strength = math.random(taget.state.encounter.baseAttack);
		local defense = math.random(taget.state.player.defense);

		if strength - defense > -1 then
			taget.state.player.health = taget.state.player.health - (strength - defense);
		else
			-- Set them to dummy values that come out to 0
			strength = 1; defense = 1;
		end

		print("The "..taget.state.encounter.name.." hit you for "..(strength - defense).." damage!");
		print("You have "..taget.state.player.health.." hit points left!");

		if taget.state.player.health <= 0 then
			print("Game over! You died!");
			os.exit();
		end
	end
end

return m;
