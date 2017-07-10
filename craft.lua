--AutoCraft for Turtles by Microeinstein

loadfile("stdturtle")()

local help = {
"Usage:",
"  [-s]  Scan bottom chest without move",
"  [-t]  Print only required items",
"  recipeDir  Recipe folder",
"  objective  Final recipe",
"  [count]  Amount of items"
}

args = {...}

argOnlyScan = false
argOnlyReq = false
argFolder = ""
argFinal = ""
argCount = 1
for k, v in pairs(args) do
	if v == "-s" then
		argOnlyScan = true
	elseif v == "-t" then
		argOnlyReq = true
	elseif argFolder == "" then
		argFolder = v
	elseif argFinal == "" then
		argFinal = v
	elseif argCount == 1 then
		argCount = math.max(tonumber(v) or 0, 1)
	end
end

if argFolder == "" or argFinal == "" then
	term.more(table.concat(help, "\n"))
	return
end

nonil = { count = 0, name = "", damage = 0, lock = false }
files = {}				--[path]	= "content"
recipes = {}			--[name~damage]	= {recipe1, recipe2}
final = nil				--recipe
recipeTree = {}			--[[
{
	"name~damage" = {
		1 = {
			required = <recipe1>,
			branch = {
				<loop>, ...
			}
		},
		2 = {
			required = <recipe2>,
			branch = {
				<loop>, ...
			}
		},
		"selected" = 1
	}
}
Final point: tree[item][tree[item].selected].required
]]--
objectives = {}			--[i]	= {name~damage, count, recipe}
nameCache = {}			--[id]	= name
items = {}				--[i]	= {name, count, damage}
slots = {}				--[i]	= {name, count, damage}
--noNeed = {}				--[i]	= {name, count, damage}
inverseDir = false
craft_debug = false

errors = {
	directoryEmpty	= "%s does not have recipes",
	missingUpDown	= "Expected top chest and bottom chest",
	missingRecipe	= "No recipes for %s",
	noOtherRecipes	= "There's no remaining recipes",
	recursiveBreak	= "No recipe for %s due to recursion",
	noDrop			= "Unable to free this slot",
	noTake			= "Unable to take items",
	noItem			= "Expected item details",
	noItems			= "Chests are empty",
	noRecipe		= "%s is not a recipe",
	noCraft			= "Unable to craft %s",
	countMinor		= "%s count (%d) is less than %d"
}
function stop(...)
	if #arg > 0 then
		term.printc(colors.white, colors.red, string.format(unpack(arg)))
	end
	error()
end
local function trace(txt, ...)
	if craft_debug then
		term.pausec(colors.white, colors.green, txt.."("..table.concat(arg, ",")..")")
	end
end

--Recipes
function recipeID(recipe)
	return getID(recipe.F)
end
function findRecipeGroup(ID)
	local p1, p2 = getNameDamage(ID)
	local _, rv = table.first(recipes, 
		function(rID,rec,nam,dam)
			local knam, kdam = getNameDamage(rID)
			return knam == nam and (dam == nil or kdam == dam)
		end, p1, p2)
	return rv
end
function recipeToXY(num)
	return math.numToXY(num, 3)
end
function isNeedSlot(k)
	return k ~= "F" and k ~= "w" and k ~= "h"
end
function fixRecipe(recipe)
	local minimal = recipe ~= nil and recipe.F ~= nil and (
		recipe[1] ~= nil or
		recipe[2] ~= nil or
		recipe[3] ~= nil or
		recipe[4] ~= nil or
		recipe[5] ~= nil or
		recipe[6] ~= nil or
		recipe[7] ~= nil or
		recipe[8] ~= nil or
		recipe[9] ~= nil
	)
	if minimal then
		for i=1, 9 do
			recipe[i] = recipe[i] or nonil
		end
	end
	return minimal
end
function isRecipeComplete(recipe, amount)
	trace("isRecipeComplete",recipe,amount)
	local m = math.max(recipe.w, recipe.h)
	local lowered = amount
	for y=1, recipe.h do
		for x=1, recipe.w do
			local item = turtle.getItemDetailXY(x, y)
			local slot = math.xyToNum(x, y, m)
			local required = recipe[slot]
			if item then
				if not (item.name == required.name and (not required.lock or item.damage == required.damage)) then
					return false
				elseif item.count < required.count / recipe.F.count * amount then
					lowered = math.min(lowered, amount - ((amount / recipe.F.count * required.count) - item.count))
				end
			elseif required.count > 0 and required.name ~= "" then
				return false
			end
		end
	end
	return lowered == amount or lowered
end
function requiredItems(recipe, amount)
	local required = {}
	local ID
	for k, item in pairs(recipe) do
		if isNeedSlot(k) and (not string.isBlank(item.name)) and item.count > 0 then
			ID = getID(item)
			required[ID] = (required[ID] or 0) + math.ceil(item.count / recipe.F.count * amount)
		end
	end
	return required
end
function missingItems(required)
	local missing = {}
	for item, count in pairs(required) do
		local p1, p2 = getNameDamage(item)
		if not table.exist(items,
			function(k,v,id,variant,c)
				return isNeedSlot(k) and v.name == id and v.count >= c and (variant == -1 or v.damage == variant)
			end, p1, p2 or -1, count) then
			missing[item] = (missing[item] or 0) + count
		end
	end
	return missing
end
function loadRecipes()
	local mex, obj1 = fs.readDir(argFolder, true)
	if mex ~= fs.mex.okRead then
		stop(mex)
	end
	files = obj1
	print("Loading recipes...")
	for path, content in pairs(files) do
		local r = textutils.unserialize(content)
		if fixRecipe(r) then
			local id = getID(r.F)
			print(string.format(" + %s", id))
			local w, h = 3, 3
			for x = 3, 1, -1 do
				if r[x].name == "" and r[x + 3].name == "" and r[x + 6].name == "" then
					w = w - 1
				end
			end
			for y = 7, 1, -3 do
				if r[y].name == "" and r[y + 1].name == "" and r[y + 2].name == "" then
					h = h - 1
				end
			end
			r.w = w
			r.h = h
			
			recipes[id] = recipes[id] or {}
			table.insert(recipes[id], r)
			
			if fs.getName(path) == argFinal then
				final = r
			end
		else
			print(string.format(" - "..errors.noRecipe, fs.getName(path)))
		end
	end
	if table.len(recipes) == 0 then
		stop(errors.directoryEmpty, argFolder)
	end
	if not final then
		stop(fs.mex.notFound..": %s", argFinal)
	end
end

--Logistic
function getID(details)
	local r = details.name
	--If lock doesn't exist (for items), else its value
	if details.lock == nil or details.lock then
		r = r.."~"..details.damage
	end
	return r;
end
function getNameDamage(ID)
	local p1, p2 = unpack(string.split(ID, "~"))
	return p1, tonumber(p2)
end
function getShortName(ID)
	if not nameCache[ID] then	
		local colon = string.split(ID, ":")
		local dot = string.split(colon[2], ".")
		local underscore = string.split(dot[#dot], "_")
		underscore[#underscore] = string.replace(underscore[#underscore], "~", ":")
		local long = {}
		for k, v in pairs(underscore) do
			if #v > 1 then
				table.insert(long, (#long > 0) and string.firstUpper(v) or v)
			end
		end
		nameCache[ID] = string.format("%s %s", colon[1], table.concat(long))
	end
	return nameCache[ID]
end
function findItems(tabl, name, damage)
	local rv = table.where(tabl,
		function(k,v,nam,dam)
			return v.name == nam and (v.lock == false or dam == nil or v.damage == dam)
		end, name, damage)
	return rv
end
function moveUp()
	print("Moving items up...")
	local get
	repeat
		get = turtle.suckDown()
		if get and not turtle.dropUp() then
			stop(errors.noDrop)
		end
	until not get
end
function moveDown()
	print("Moving items down...")
	local get
	repeat
		get = turtle.suckUp()
		if get and not turtle.dropDown() then
			stop(errors.noDrop)
		end
	until not get
end
function emptySlots()
	print("Freeing slots...")
	local drop = argOnlyScan and turtle.dropDown or turtle.dropUp
	for s = 1, 16 do
		if turtle.getItemCount(s) > 0 then
			turtle.select(s)
			if not drop() then
				stop(errors.noDrop)
			end
		end
	end
end
function addItem(details)
	if details then
		local id = getID(details)
		local item = items[id]
		if item then
			item.count = item.count + details.count
		else
			items[id] = details
		end
	else
		stop(errors.noItem)
	end
end
function scanChest()
	items = {}
	--slots = {}
	--noNeed = {}
	print("Scanning bottom chest...")
	local get, it, rcps
	repeat
		if not (turtle.detectUp() and turtle.detectDown()) then
			stop(errors.missingUpDown)
		end
		get = turtle.suckDown()
		if get then
			it = turtle.getItemDetail()
			addItem(it)
			print(string.format(" + %d * %s", it.count, getShortName(getID(it))))
			if not turtle.dropUp() then
				stop(errors.noDrop)
			end
		elseif table.len(items) == 0 then
			stop(errors.noItems)
		end
	until not get
	--Chest is scanned
end

--Sorting
function makeTree(ID, amount, position, remainingItems, tab)
	tab = tab or 0
		if amount <= 0 then
			return
		end
	local prnt = string.format("%s%d %s", string.rep(" ", tab), amount, getShortName(ID))
		if argOnlyReq then
			term.pause(prnt)
		else
			print(prnt)
			os.sleep(0.05)
		end
	local recipes = findRecipeGroup(ID)
		if not recipes or table.len(recipes) <= 0 then
			return
		end
	position[ID] = {}
	position[ID].selected = 1
	for n, recipe in pairs(recipes) do
		if n > 1 then
			print(string.rep(" ", tab).."-OR-")
		end
		local required = requiredItems(recipe, amount)
		--Remove already crafted items
		if not argOnlyReq then
			for rID, rAM in pairs(table.copy(required, false)) do
				local requiredRecipes = findRecipeGroup(rID)
				if requiredRecipes and table.len(requiredRecipes) > 0 then
					local existent = findItems(remainingItems, getNameDamage(rID))
					if existent then
						--objDebug(existent,"exBefore")
						for _, existem in pairs(existent) do
							if existem.count > 0 then
								local subtract = math.min(existem.count, rAM)
								rAM = rAM - subtract
								existem.count = existem.count - subtract
							end
							if rAM == 0 then
								required[rID] = nil
							elseif rAM > 0 then
								required[rID] = rAM
							else
								stop(errors.countMinor, "am", rAM, 0)
							end
						end
						--objDebug(existent,"exAfter")
					end
				end
			end
		end
		
		position[ID][n] = {
			required = required,
			branch = {}
		}
		for rID, rAM in pairs(required) do
			if rID ~= ID then
				makeTree(rID, rAM, position[ID][n].branch, remainingItems, tab + 1)
			else
				stop(errors.recursiveBreak, ID)
			end
		end
	end
end
function readTree(position)
	local total = {}
	--tree[item][tree[item].selected].required
	for _, combos in pairs(position) do
		local combo = combos[combos.selected]
		for ID, AM in pairs(combo.required) do
			if not combo.branch[ID] then
				total[ID] = (total[ID] or 0) + AM
			end
		end
		if table.len(combo.branch) > 0 then
			local branch = readTree(combo.branch)
			for ID, AM in pairs(branch) do
				total[ID] = (total[ID] or 0) + AM
			end
		end
	end
	return total
end
function nextBranch(position)
	local length = table.len(position)
	local at = 0
	for ID, combos in pairs(position) do
		at = at + 1
		local combo = combos[combos.selected]
		--If combo has other combinations
		if table.len(combo.branch) > 0 then
			if nextBranch(combo.branch) then
				return true
			end
		end
		combos.selected = combos.selected + 1
		if combos.selected >= table.len(combos) then
			combos.selected = 1
			if at >= length then
				return false
			end
		else
			return true
		end
	end
end
function selectObjectives()
	local req, mis
	local inc = 0
	while true do
		inc = inc + 1
		print(string.format("Checking combination %d...", inc))
		req = readTree(recipeTree)
		mis = missingItems(req)
		if table.len(mis) > 0 then
			if not nextBranch(recipeTree) then
				stop(errors.noOtherRecipes)
			end
		else
			print("Checked and selected")
			return true
		end
	end
end
function makeObjectives(branch, ID, count)
	--print((branch and "table" or "nil").." "..ID.." "..count)
	--[[local p1, p2 = getNameDamage(ID)
	if p2 == nil then
		ID = table.first(recipes,
			function(k,v,id)
				local pp1, pp2 = getNameDamage(k)
				return pp1 == id
			end, p1)
		objDebug(ID)
	end]]
	local bri = branch[ID]
	local sel = bri[bri.selected]
	local rec = findRecipeGroup(ID)[bri.selected]
	if table.len(sel.branch) > 0 then
		for rid, ra in pairs(sel.required) do
			local rec = findRecipeGroup(rid)
			if rec and table.len(rec) > 0 then
				makeObjectives(sel.branch, rid, ra)
			end
		end
	end
	print(string.format(" > %d %s", count, getShortName(ID)))
	table.insert(objectives, {
		ID = ID,
		count = count,
		recipe = rec
	})
end
function showRequirements()
	local inc = 0
	while true do
		inc = inc + 1
		print(string.format("COMBINATION %d:", inc))
		
		local requirements = readTree(recipeTree)
		for rID, rAM in pairs(requirements) do
			term.pause(" "..rAM.." "..getShortName(rID))
		end
		local otherCombos = nextBranch(recipeTree)
		--fs.write("recipeTree.lua", textutils.serialise(recipeTree))
		if not otherCombos then
			return
		end
		print("\n")
	end
end

--Move items
function slotsM(x, y, amount)
	local itk, itv = table.first(slots, function(_,v,x,y) return v.x == x and v.y == y end, x, y)
	if itv then
		if amount then
			itv.count = itv.count - amount
		else
			itv.count = turtle.getItemCountXY(x, y)
		end
		if itv.count <= 0 then
			table.remove(slots, itk)
		end
	end
end
function slotsP(x, y)
	local id = turtle.getItemDetailXY(x, y)
	id.x = x
	id.y = y
	table.insert(slots, id)
end
function reserveSlots(recipe)
	for y=1, recipe.h do
		for x=1, recipe.w do
			if turtle.getItemCountXY(x, y) > 0 then
				if turtle.push(x, y, inverseDir and turtle.faces.D or turtle.faces.U) then
					slotsM(x, y)
				else
					stop(errors.noDrop)
				end
			end
		end
	end
end
function transportBelt(recipe)
	local slots = {}
	for x=4, 1, -1 do
		for y=1, 4 do
			if recipe.w < x or recipe.h < y then
				table.insert(slots, {x=x, y=y})
			end
		end
	end
	return slots
end
function roll(transport)
	print("Rolling items...")
	local rev = table.reverse(transport)
	local to = inverseDir and turtle.faces.U or turtle.faces.D
	
	for n, s in pairs(rev) do
		if turtle.getItemCountXY(s.x, s.y) > 0 then
			if not turtle.push(s.x, s.y, to) then
				stop(errors.noDrop)
			end
			slotsM(s.x, s.y)
		end
	end
	for n, s in pairs(rev) do
		if not rollGetNext(s.x, s.y) then
			break
		end
	end
end
function rollGetNext(x, y, recur)
	recur = recur or false
	if not turtle.pull(x, y, inverseDir and turtle.faces.D or turtle.faces.U) then
		if recur then
			return false
		else
			inverseDir = not inverseDir
			return rollGetNext(x, y, true)
		end
	else
		slotsP(x, y)
	end
	return true
end

--Crafting
function placeItem(slot, recipe, amount)
	trace("placeItem",slot.x,slot.y,recipe.F.name,amount)
	local slotK, slotItem = table.first(slots,
		function(_,v,x,y) return v.x == x and v.y == y end,
		slot.x, slot.y)
	if not slotItem then
		return
	end
	local requirements = findItems(table.where(recipe, isNeedSlot), slotItem.name, slotItem.damage)
	if not requirements or table.len(requirements) < 1 then
		return
	end
	local ID = getID(slotItem)
	for k, required in pairs(requirements) do
		local finalSlot = recipeToXY(k)
		local alreadyPlaced = turtle.getItemDetailXY(finalSlot.x, finalSlot.y)
		local placedCount = alreadyPlaced and alreadyPlaced.count or 0
		if placedCount == 0 or ID.damage == alreadyPlaced.damage then
			local moveAmount = math.min(turtle.getItemCountXY(slot.x, slot.y),
							math.ceil(amount / recipe.F.count * required.count) - placedCount)
			if moveAmount > 0 then
				if items[ID].count < moveAmount then
					stop(errors.countMinor, getShortName(ID), items[ID].count, moveAmount)
				end
				if slotItem.count > 0 then
					slotItem.count = slotItem.count - moveAmount
					if not items[ID] then
						objDebug(ID,"ID")
						objDebug(items,"items")
					end
					items[ID].count = items[ID].count - moveAmount
					turtle.moveSlot(slot.x, slot.y, finalSlot.x, finalSlot.y, moveAmount)
				else
					table.remove(slots, slotK)
					break
				end
				--items[ID].count
				--elseif slotItem.count < moveAmount then
				--amount = amount - (math.ceil(amount / recipe.F.count * required.count) - placedCount)
				--objDebug(amount, "place_amount")
				--stop(errors.countMinor, getShortName(ID), items[ID].count, moveAmount)
			end
		end
	end
end
function reapItems(ID, slot)
	if items[ID] and items[ID].count <= 0 then
		items[ID] = nil
	end
	slotsM(slot.x, slot.y)
end
function reserveCraft(recipe, amount)
	print("Emptying other slots...")
	for y=1, 4 do
		for x=1, 4 do
			if (x > recipe.w or y > recipe.h) and turtle.getItemCountXY(x, y) > 0 then
				if turtle.push(x, y, inverseDir and turtle.faces.D or turtle.faces.U) then
					slotsM(x, y)
				else
					stop(errors.noDrop)
				end
			end
		end
	end
end
function craft(recipe)
	turtle.setSlot(4, 1)
	local fn = recipeID(recipe)
	local ct = 0
	repeat
		local success = turtle.craft()
		if success then
			ct = ct + 1
			for k, v in pairs(recipe) do
				if k ~= "F" and k ~= "w" and k ~= "h" then
					local ID = getID(v)
					if items[ID] then
						if items[ID].count == 0 then
							items[ID] = nil
						elseif items[ID].count < 0 then
							stop(errors.countMinor, getShortName(ID), items[ID].count, 0)
						end
					end
				end
			end
			addItem(turtle.getItemDetailXY(4, 1))
			turtle.push(4, 1, inverseDir and turtle.faces.U or turtle.faces.D)
		else
			local ID = turtle.getItemDetail()
			if (ID and ID.name ~= fn.name
				   and ID.count ~= fn.count
				   and ID.damage ~= fn.damage) or ct == 0 then
				stop(errors.noCraft, getShortName(fn))
			end
		end
	until not success
end
function reAddItems(recipe)
	for y=1, recipe.h do
		for x=1, recipe.w do
			local item = turtle.getItemDetailXY(x, y)
			if item and item.count > 0 then
				addItem(item)
				if not turtle.push(x, y, inverseDir and turtle.faces.D or turtle.faces.U) then
					stop(errors.noDrop)
				end
			end
		end
	end
end

--Main
function followOjectives()
	trace("followOjectives")
	for n, obj in pairs(objectives) do
		print(string.format("Making %d %s...", obj.count, getShortName(obj.ID)))
		print("Allocating slots...")
		reserveSlots(obj.recipe)
		followSubObjective(transportBelt(obj.recipe), obj.recipe, obj.count)
		print("\n")
	end
end
function followSubObjective(transport, recipe, count)
	local complete
	repeat
		roll(transport)
		for _, slot in pairs(transport) do
			placeItem(slot, recipe, count)
			reapItems(recipeID(recipe), slot)
		end
		complete = isRecipeComplete(recipe, count)
		if not isBool(complete) then
			reserveCraft(recipe, complete)
			craft(recipe)
			--reAddItems(recipe)
			count = count - complete
			complete = false
		end
	until complete
	reserveCraft(recipe, count)
	craft(recipe)
end
function start()
	term.wash()
	term.printc(colors.yellow, nil, "AutoCraft by Microeinstein")
	term.printc(colors.red, nil, "Please do not edit inventories during process.")
	term.printc(colors.red, nil, "Hold CTRL+T to halt")
	os.sleep(1.5)
	
	term.printc(colors.blue, nil, "\n <Loading recipes>")
	os.sleep(0.1)
	loadRecipes()
	
	if not argOnlyReq then
		term.printc(colors.blue, nil, "\n <Loading items>")
		os.sleep(0.1)
		emptySlots()
		if not argOnlyScan then
			moveUp()
			moveDown()
		end
		scanChest()
	end
	
	term.printc(colors.blue, nil, "\n <Building recipe tree>")
	os.sleep(0.1)
	makeTree(recipeID(final), argCount, recipeTree, table.copy(items, true))
	--fs.write("recipeTree.lua", textutils.serialise(recipeTree))
	
	if argOnlyReq then
		term.printc(colors.blue, nil, "\n <Showing requirements>")
		os.sleep(0.1)
		showRequirements()
		
	else
		term.printc(colors.blue, nil, "\n <Finding right combination>")
		os.sleep(0.1)
		selectObjectives()
		
		term.printc(colors.blue, nil, "\n <Making crafting order>")
		os.sleep(0.1)
		makeObjectives(recipeTree, recipeID(final), argCount)
		
		term.printc(colors.green, nil, "\n <Crafting started>")
		os.sleep(0.1)
		followOjectives()
		
		term.printc(colors.green, nil, "\nSUCCESS")
	end
end

start()
stop()