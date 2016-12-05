--AutoCraft for Turtles by Microeinstein

loadfile("stdturtle")()

args = {...}	--Recipe folder, objective, count
if table.len(args) < 2 then
	print("Expected at least 2 arguments")
	print("craft recipeDir finalRecipe [count] [-t]")
	print("  -t  Print only required items")
	return
end
argFolder = args[1]
argFinal = fs.combine(args[1], args[2])
argCount = math.max(tonumber(args[3]) or 0, 1)
argOnlyReq = args[4] and args[4] == "-t"

files = {}				--[path]	= "content"
recipes = {}			--[name]	= {recipe1, recipe2}
final = {}				--			  recipe
recipeTree = {}			--[[
{
	"item" = {
		1 = {
			required = <requiredA>,
			branch = {
				"itemA" = ...
				"itemB" = ...
			}
		},
		2 = {
			required = <requiredB>,
			branch = {
				"itemA" = ...
				"itemB" = ...
			}
		},
		"selected" = 1
	}
}
Final point: tree[item][tree[item].selected].required
]]--
objectives = {}			--[i]	= {name, count, recipe}

items = {}				--[i]	= {name, count, damage}
slots = {}				--[i]	= {name, count, damage}
noNeed = {}				--[i]	= {name, count, damage}
inverseDir = false

errors = {
	directoryEmpty	= "%s does not have recipes",
	missingUpDown	= "Expected top chest and bottom chest",
	missingRecipe	= "No recipes for %s",
	noOtherRecipes	= "There's no remaining recipes",
	recursiveBreak	= "No recipe for %s due to recursion",
	noDrop			= "Unable to free this slot",
	noTake			= "Unable to take items",
	noItem			= "Expected item details",
	noItems			= "Bottom chest is empty",
	noRecipe		= "%s is not a recipe",
	noCraft			= "Unable to craft %s",
	countMinor		= "%s count is %d"
}
function stop(...)
	if #arg > 0 then
		term.printc(colors.white, colors.red, string.format(unpack(arg)))
	end
	error()
end

--Recipes
function recipeToXY(num)
	return math.numToXY(num, 3)
end
function isNeedSlot(k, v, name)
	return k ~= "F" and k ~= "w" and k ~= "h" and v.name == name
end
function isRecipe(r)
	return r[1] ~= nil and r[2] ~= nil and r[3] ~= nil and
		   r[4] ~= nil and r[5] ~= nil and r[6] ~= nil and
		   r[7] ~= nil and r[8] ~= nil and r[9] ~= nil and r.F ~= nil
end
function isRecipeComplete(recipe, count)
	local m = math.max(recipe.w, recipe.h)
	for y=1, recipe.h do
		for x=1, recipe.w do
			local det = turtle.getItemDetailXY(x, y)
			local n = math.xyToNum(x, y, m)
			if det then
				if not (det.name == recipe[n].name and det.count >= recipe[n].count / recipe.F.count * count) then
					return false
				end
			elseif recipe[n].count > 0 and recipe[n].name ~= "" then
				return false
			end
		end
	end
	return true
end
function requiredItems(recipe, count)
	local required = {}
	for slot, item in pairs(recipe) do
		if slot ~= "F" and slot ~= "w" and slot ~= "h" and item.name ~= "" then
			required[item.name] = (required[item.name] or 0) + math.ceil(item.count / recipe.F.count * count)
		end
	end
	return required
end
function missingItems(required)
	local missing = {}
	for item, count in pairs(required) do
		if not table.exist(items, function(k,v,i,c) return isNeedSlot(k,v,i) and v.count >= c end, item, count) then
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
		if isRecipe(r) then
			print(string.format(" + %s", r.F.name))
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
			
			recipes[r.F.name] = recipes[r.F.name] or {}
			table.insert(recipes[r.F.name], r)
			
			if path == argFinal then
				final = r
			end
		else
			print(string.format(" - "..errors.noRecipe, fs.getName(path)))
		end
	end
	if table.len(recipes) == 0 then
		stop(errors.directoryEmpty, argFolder)
	end
end

--Items
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
	for s = 1, 16 do
		if turtle.getItemCount(s) > 0 then
			turtle.select(s)
			if not turtle.dropUp() then
				stop(errors.noDrop)
			end
		end
	end
end
function addItem(id)
	if id ~= nil then
		id.damage = 0
		if items[id.name] then
			items[id.name].count = items[id.name].count + id.count
		else
			items[id.name] = id
		end
	else
		stop(errors.noItem)
	end
end
function scanChest()
	items = {}
	slots = {}
	noNeed = {}
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
			print(string.format(" + %d * %s", it.count, it.name))
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
function makeTree(item, count, position, noNeeds, tab)
	tab = tab or 0
	if count > 0 then
		local prnt = string.format("%s%d * %s", string.rep("  ", tab), count, item)
		if argOnlyReq then
			term.pause(prnt.."...")
		else
			print(prnt)
		end
		local rcps = recipes[item]
		if rcps and table.len(rcps) > 0 then
			position[item] = {}
			position[item].selected = 1
			for ren, re in pairs(rcps) do
				if ren > 1 then
					print(string.rep("  ", tab).."-OR-")
				end
				local req = requiredItems(re, count)
				--Remove already crafted items
				for it, am in pairs(table.copy(req, false)) do
					local rit = recipes[it]
					if rit and table.len(rit) > 0 then
						if noNeeds[it] and noNeeds[it].count > 0 then
							local su = math.min(noNeeds[it].count, am)
							am = am - su
							noNeeds[it].count = noNeeds[it].count - su
						end
						if am == 0 then
							req[it] = nil
						elseif am > 0 then
							req[it] = am
						else
							stop(errors.countMinor, "am", am)
						end
					end
				end
				position[item][ren] = {
					required = req,
					branch = {}
				}
				for it, am in pairs(req) do
					if it ~= item then
						makeTree(it, am, position[item][ren].branch, noNeeds, tab + 1)
					else
						stop(errors.recursiveBreak, item)
					end
				end
			end
		end
	end
end
function readTree(position)
	local total = {}
	--tree[item][tree[item].selected].required
	for it, req in pairs(position) do
		local sel = req[req.selected]
		for it, am in pairs(sel.required) do
			if not sel.branch[it] then
				total[it] = (total[it] or 0) + am
			end
		end
		if table.len(sel.branch) > 0 then
			for it, am in pairs(readTree(sel.branch)) do
				total[it] = (total[it] or 0) + am
			end
		end
	end
	return total
end
function nextBranch(position)
	for it, req in pairs(position) do
		local sel = req[req.selected]
		if table.len(sel.branch) > 0 then
			--for it, am in pairs(sel.required) do
			--	if sel.branch[it] then
			--		if nextBranch(sel.branch[it]) then
			--			return true
			--		end
			--	end
			--end
			if nextBranch(sel.branch) then
				return true
			end
		end
		req.selected = req.selected + 1
		if req.selected > table.len(req) - 1 then
			req.selected = 1
			return false
		else
			return true
		end
	end
end
function selectObjectives()
	local req, non, mis
	local inc = 0
	while true do
		inc = inc + 1
		req = readTree(recipeTree)
		mis = missingItems(req)
		if table.len(mis) > 0 then
			print(string.format("Selecting combination %d...", inc))
			if not nextBranch(recipeTree) then
				stop(errors.noOtherRecipes)
			end
		else
			print(string.format("Selected combination %d", inc + 1))
			return true
		end
	end
end
function makeObjectives(branch, item, count)
	--print((branch and "table" or "nil").." "..item.." "..count)
	local bri = branch[item]
	local sel = bri[bri.selected]
	local rec = recipes[item][bri.selected]
	if table.len(sel.branch) > 0 then
		for ri, ra in pairs(sel.required) do
			if recipes[ri] and table.len(recipes[ri]) > 0 then
				makeObjectives(sel.branch, ri, ra)
			end
		end
	end
	print(string.format("Adding %d * %s", count, item))
	table.insert(objectives, {
		name = item,
		count = count,
		recipe = rec
	})
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
	print("Getting available slots...")
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
	print("Getting next items...")
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
function placeItem(x, y, recipe, count)
	local itk, itv = table.first(slots, function(_,v,x,y) return v.x == x and v.y == y end, x, y)
	if not itv then
		return
	end
	local rew = table.where(recipe, isNeedSlot, itv.name)
	if not rew or table.len(rew) < 1 then
		return
	end
	local done
	for k, ia in pairs(rew) do
		local rxy = recipeToXY(k)
		local movC = math.min(turtle.getItemCountXY(x, y), (count / recipe.F.count * ia.count) - turtle.getItemCountXY(rxy.x, rxy.y))
		if movC > 0 then
			if items[itv.name].count < movC then
				stop(errors.countMinor, itv.name, items[itv.name].count)
			end
			if itv.count > 0 then
				itv.count = itv.count - movC
				items[itv.name].count = items[itv.name].count - movC
				turtle.moveSlot(x, y, rxy.x, rxy.y, movC)
			else
				table.remove(slots, itk)
				break
			end
		end
	end
end
function reapItems(name, x, y)
	if items[name] and items[name].count <= 0 then
		items[name] = nil
	end
	slotsM(x, y)
end
function reserveCraft(recipe)
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
function craft(recipe, count)
	turtle.setSlot(4, 1)
	local fn = recipe.F.name
	local ct = 0
	repeat
		local success = turtle.craft()
		if success then
			ct = ct + 1
			for k, v in pairs(recipe) do
				if k ~= "F" and k ~= "w" and k ~= "h" and items[v.name] then
					if items[v.name].count == 0 then
						items[v.name] = nil
					elseif items[v.name].count < 0 then
						stop(errors.countMinor, v.name, items[v.name].count)
					end
				end
			end
			addItem(turtle.getItemDetailXY(4, 1))
			turtle.push(4, 1, inverseDir and turtle.faces.U or turtle.faces.D)
		else
			local d = turtle.getItemDetail()
			if (d and d.name ~= fn) or ct == 0 then
				stop(errors.noCraft, fn)
			end
		end
	until not success
end

--Main
function followOjectives()
	for n, obj in pairs(objectives) do
		print(string.format("Crafting %d * %s...", obj.count, obj.name))
		reserveSlots(obj.recipe)
		local tb = transportBelt(obj.recipe)
		repeat
			roll(tb)
			for n, s in pairs(tb) do
				placeItem(s.x, s.y, obj.recipe, obj.count)
				reapItems(obj.recipe.F.name, s.x, s.y)
			end
		until isRecipeComplete(obj.recipe, obj.count)
		reserveCraft(obj.recipe)
		craft(obj.recipe, obj.count)
		print("\n")
	end
end
function start()
	term.wash()
	term.printc(colors.yellow, nil, "AutoCraft by Microeinstein")
	term.printc(colors.red, nil, "Please do not edit inventories during process.")
	term.printc(colors.red, nil, "Hold CTRL+T to halt")
	os.sleep(1)
	if not fs.exists(argFinal) then
		stop(fs.mex.notFound..": %s", argFinal)
	end
	
	term.printc(colors.blue, nil, "\n <Loading recipes>")
	os.sleep(0.1)
	loadRecipes()
	
	if not argOnlyReq then
		term.printc(colors.blue, nil, "\n <Loading items>")
		os.sleep(0.1)
		emptySlots()
		moveUp()
		moveDown()
		scanChest()
	end
	
	term.printc(colors.blue, nil, "\n <Building recipe tree>")
	os.sleep(0.1)
	makeTree(final.F.name, argCount, recipeTree, table.copy(items, true))
	
	if not argOnlyReq then
		term.printc(colors.blue, nil, "\n <Finding right combination>")
		os.sleep(0.1)
		selectObjectives()
		
		term.printc(colors.blue, nil, "\n <Making crafting order>")
		os.sleep(0.1)
		makeObjectives(recipeTree, final.F.name, argCount)
		
		term.printc(colors.green, nil, "\n <Crafting started>")
		os.sleep(0.1)
		followOjectives()
		
		term.printc(colors.green, nil, "\nSUCCESS")
	end
end

start()
stop()