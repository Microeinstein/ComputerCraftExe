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
function recipeID(recipe)
	return getID(recipe.F)
end
function findRecipe(ID)
	local p1, p2 = getNameDamage(ID)
	local _, rv = table.first(recipes, 
		function(k,v,id,variant)
			local ki, kvar = getNameDamage(k)
			return ki == id and (variant == nil or kvar == variant)
		end, p1, p2)
	return rv
end
function recipeToXY(num)
	return math.numToXY(num, 3)
end
function isNeedSlot(k)
	return k ~= "F" and k ~= "w" and k ~= "h"
end
function fixRecipe(r)
	local minimal = r ~= nil and r.F ~= nil and (
		r[1] ~= nil or
		r[2] ~= nil or
		r[3] ~= nil or
		r[4] ~= nil or
		r[5] ~= nil or
		r[6] ~= nil or
		r[7] ~= nil or
		r[8] ~= nil or
		r[9] ~= nil
	)
	if minimal then
		for i=1, 9 do
			r[i] = r[i] or nonil
		end
	end
	return minimal
end
function isRecipeComplete(recipe, count)
	local m = math.max(recipe.w, recipe.h)
	for y=1, recipe.h do
		for x=1, recipe.w do
			local det = turtle.getItemDetailXY(x, y)
			local n = math.xyToNum(x, y, m)
			if det then
				if not (det.name == recipe[n].name
				    and (not recipe[n].lock or det.damage == recipe[n].damage)
					and det.count >= recipe[n].count / recipe.F.count * count) then
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
	local ID
	for slot, item in pairs(recipe) do
		if slot ~= "F" and slot ~= "w" and slot ~= "h" and (not string.isBlank(item.name)) and item.count > 0 then
			ID = getID(item)
			required[ID] = (required[ID] or 0) + math.ceil(item.count / recipe.F.count * count)
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
function getNameDamage(id)
	local p1, p2 = unpack(string.split(id, "~"))
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
	for s = 1, 16 do
		if turtle.getItemCount(s) > 0 then
			turtle.select(s)
			if not turtle.dropUp() then
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
function makeTree(ID, count, position, noNeeds, tab)
	tab = tab or 0
	if count > 0 then
		local prnt = string.format("%s%d %s", string.rep(" ", tab), count, getShortName(ID))
		if argOnlyReq then
			term.pause(prnt)
		else
			print(prnt)
			os.sleep(0.05)
		end
		local rcps = findRecipe(ID)
		if rcps and table.len(rcps) > 0 then
			position[ID] = {}
			position[ID].selected = 1
			for ren, re in pairs(rcps) do
				if ren > 1 then
					print(string.rep(" ", tab).."-OR-")
				end
				local req = requiredItems(re, count)
				--Remove already crafted items
				for id, am in pairs(table.copy(req, false)) do
					local rit = findRecipe(id)
					if rit and table.len(rit) > 0 then
						local existent = findItems(noNeeds, getNameDamage(id))
						if existent then
							for _, exitem in pairs(existent) do
								if exitem.count > 0 then
									local su = math.min(exitem.count, am)
									am = am - su
									exitem.count = exitem.count - su
								end
								if am == 0 then
									req[id] = nil
								elseif am > 0 then
									req[id] = am
								else
									stop(errors.countMinor, "am", am)
								end
							end
						end
					end
				end
				position[ID][ren] = {
					required = req,
					branch = {}
				}
				for id, am in pairs(req) do
					if id ~= ID then
						makeTree(id, am, position[ID][ren].branch, noNeeds, tab + 1)
					else
						stop(errors.recursiveBreak, ID)
					end
				end
			end
		end
	end
end
function readTree(position)
	local total = {}
	--tree[item][tree[item].selected].required
	for _, req in pairs(position) do
		local sel = req[req.selected]
		for id, am in pairs(sel.required) do
			if not sel.branch[id] then
				total[id] = (total[id] or 0) + am
			end
		end
		if table.len(sel.branch) > 0 then
			local branch = readTree(sel.branch)
			for id, am in pairs(branch) do
				total[id] = (total[id] or 0) + am
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
	local rec = findRecipe(ID)[bri.selected]
	if table.len(sel.branch) > 0 then
		for rid, ra in pairs(sel.required) do
			local rec = findRecipe(rid)
			if rec and table.len(rec) > 0 then
				makeObjectives(sel.branch, rid, ra)
			end
		end
	end
	print(string.format(" > %d %s", count, getShortName(ID)))
	table.insert(objectives, {
		id = ID,
		count = count,
		recipe = rec
	})
end
function showRequirements()
	local req
	local inc = 0
	while true do
		inc = inc + 1
		print(string.format("COMBINATION %d:", inc))
		
		req = readTree(recipeTree)
		for k, v in pairs(req) do
			term.pause(" "..v.." "..getShortName(k))
		end
		if not nextBranch(recipeTree) then
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
function placeItem(x, y, recipe, count)
	local itk, itv = table.first(slots, function(_,v,x,y) return v.x == x and v.y == y end, x, y)
	if not itv then
		return
	end
	local numbers = table.where(recipe, isNeedSlot)
	local rew = findItems(numbers, itv.name, itv.damage)
	if not rew or table.len(rew) < 1 then
		return
	end
	local id = getID(itv)
	local done
	for k, iad in pairs(rew) do
		local rxy = recipeToXY(k)
		local movC = math.min(turtle.getItemCountXY(x, y), (count / recipe.F.count * iad.count) - turtle.getItemCountXY(rxy.x, rxy.y))
		if movC > 0 then
			if items[id].count < movC then
				stop(errors.countMinor, getShortName(id), items[id].count)
			end
			if itv.count > 0 then
				itv.count = itv.count - movC
				items[id].count = items[id].count - movC
				turtle.moveSlot(x, y, rxy.x, rxy.y, movC)
			else
				table.remove(slots, itk)
				break
			end
		end
	end
end
function reapItems(id, x, y)
	if items[id] and items[id].count <= 0 then
		items[id] = nil
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
	local fn = recipeID(recipe)
	local ct = 0
	repeat
		local success = turtle.craft()
		if success then
			ct = ct + 1
			for k, v in pairs(recipe) do
				if k ~= "F" and k ~= "w" and k ~= "h" then
					local id = getID(v)
					if items[id] then
						if items[id].count == 0 then
							items[id] = nil
						elseif items[id].count < 0 then
							stop(errors.countMinor, getShortName(id), items[id].count)
						end
					end
				end
			end
			addItem(turtle.getItemDetailXY(4, 1))
			turtle.push(4, 1, inverseDir and turtle.faces.U or turtle.faces.D)
		else
			local id = turtle.getItemDetail()
			if (id and id.name ~= fn.name
				   and id.count ~= fn.count
				   and id.damage ~= fn.damage) or ct == 0 then
				stop(errors.noCraft, getShortName(fn))
			end
		end
	until not success
end

--Main
function followOjectives()
	for n, obj in pairs(objectives) do
		print(string.format("Making %d %s...", obj.count, getShortName(obj.id)))
		print("Allocating slots...")
		reserveSlots(obj.recipe)
		local tb = transportBelt(obj.recipe)
		repeat
			roll(tb)
			for n, s in pairs(tb) do
				placeItem(s.x, s.y, obj.recipe, obj.count)
				reapItems(recipeID(obj.recipe), s.x, s.y)
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