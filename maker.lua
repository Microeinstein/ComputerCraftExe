--Recipe Maker by Microeinstein

loadfile("forms")()
if turtle then
	loadfile("stdturtle")()
end

local help = {
"~ Recipe Maker by Microeinstein ~",
"This program allows to create recipes ready to be used in AutoCraft.",
"",
"SLOTS:  123#",
"        456=",
"        789#",
"        ####",
"",
"COLUMNS:",
"  AMOUNT: The amount needed",
"  NAME:   The name of the item",
"  VAR.:   The required variant",
"  LOCK:   Enable if only the specified",
"          variant is needed",
"",
"NB: VAR is taken into account only if LOCK is green.",
"",
"EXAMPLE:",
"  WOOD FROM LOG:",
"    = 4 * minecraft:wood",
"    1 1 * minecraft:log",
"",
"DON'T FORGET TO SAVE"
}

args = {...}
if table.len(args) < 1 then
	print("Usage: maker [-h] <path>")
	return
elseif args[1] == "-h" then
	term.more(table.concat(help, "\n"))
	return
end
path = fs.combine(shell.dir(), args[1])

init(colors.black, colors.white, resolutions.turtle)

slotNames = {"F", 1, 2, 3, 4, 5, 6, 7, 8, 9}
c1 = colors.gray
c2 = colors.lightGray
c3 = colors.white
edited, confirm = false, false
local dlgOpen, dlgContinue, dlgText, lTitle, toDo
nonil = { count = 0, name = "", damage = 0, lock = false }
nums = {}
names = {}
vars = {}
chks = {}
maxStack = 64
maxVar = 999

function sslot(slot)
	slot = slot..""
	if string.sub(slot, 1, 1) == "s" then
		return slot
	else
		return "s"..slot
	end
end
function isEmpty(slot, keep)
	slot = sslot(slot)
	if keep then
		return nums[slot].num == 0 and string.isBlank(names[slot]:getText())
	else
		return nums[slot].num == 0 or string.isBlank(names[slot]:getText())
	end
end
function getSlot(slot)
	slot = sslot(slot)
	local obj = {
		count = nums[slot].num,
		name = names[slot]:getText(),
		damage = vars[slot].num
	}
	if slot ~= "sF" then
		obj.lock = chks[slot].checked
	end
	return obj
end
function setSlot(slot, details)
	slot = sslot(slot)
	details = details or nonil
	nums[slot]:setNum(details.count)
	names[slot]:setText(details.name)
	vars[slot]:setNum(details.damage)
	if slot ~= "sF" then
		if details.lock ~= nil then
			chks[slot]:setChecked(details.lock)
		else
			chks[slot]:setChecked(details.count > 0)
		end
	end
end
function clearSlot(slot)
	slot = sslot(slot)
	nums[slot]:setNum(0)
	names[slot]:setText("")
	vars[slot]:setNum(0)
	if slot ~= "sF" then
		chks[slot]:setChecked(false)
	end
end
function autoLock(slot, state)
	slot = sslot(slot)
	if slot ~= "sF" then
		chks[slot]:setChecked(state and nums[slot].num > 0)
	end
end
function moveSlot(from, to)
	from = sslot(from)
	to = sslot(to)
	setSlot(to, getSlot(from))
	setSlot(from)
end

function edit(...)
	edited = true
end
function open(p)
	local res, file = fs.read(p)
	if res == fs.mex.okRead then
		local data = textutils.unserialize(file)
		for _, s in pairs(slotNames) do
			setSlot(s, data[s])
		end
		edited = false
	end
end
function save()
	local data = {}
	for _, s in pairs(slotNames) do
		if not isEmpty(s) then
			data[s] = getSlot(s)
		end
	end
	
	local res = fs.write(path, textutils.serialize(data))
	if res == fs.mex.okWrite then
		edited = false
	end
end
function get()
	if askLose(get) then
		return
	end
	setSlot("sF", turtle.getItemDetailXY(4, 2))
	setSlot("s1", turtle.getItemDetailXY(1, 1))
	setSlot("s2", turtle.getItemDetailXY(2, 1))
	setSlot("s3", turtle.getItemDetailXY(3, 1))
	setSlot("s4", turtle.getItemDetailXY(1, 2))
	setSlot("s5", turtle.getItemDetailXY(2, 2))
	setSlot("s6", turtle.getItemDetailXY(3, 2))
	setSlot("s7", turtle.getItemDetailXY(1, 3))
	setSlot("s8", turtle.getItemDetailXY(2, 3))
	setSlot("s9", turtle.getItemDetailXY(3, 3))
	edited = false
end
function wipe()
	if askLose(wipe) then
		return
	end
	for _, s in pairs(slotNames) do
		clearSlot(s)
	end
	edited = false
end
function setLock(state)
	for _, s in pairs(slotNames) do
		autoLock(s, state)
	end
end
function fix()
	for _, s in pairs(slotNames) do
		if isEmpty(s) then
			clearSlot(s)
		end
	end
end
function compact()
	for y=1,3 do
		if isEmpty(1, true) and isEmpty(2, true) and isEmpty(3, true) then
			moveSlot(4, 1)
			moveSlot(5, 2)
			moveSlot(6, 3)
			moveSlot(7, 4)
			moveSlot(8, 5)
			moveSlot(9, 6)
		else
			break
		end
	end
	for x=1,3 do
		if isEmpty(1, true) and isEmpty(4, true) and isEmpty(7, true) then
			moveSlot(2, 1)
			moveSlot(5, 4)
			moveSlot(8, 7)
			moveSlot(3, 2)
			moveSlot(6, 5)
			moveSlot(9, 8)
		else
			break
		end
	end
end

function openPath()
	if askLose(openPath) then
		return
	end
	path = dlgText
	if fs.exists(path) then
		open(path)
	end
	lTitle:setText("Recipe Maker - "..path)
end
function askLose(action)
	if not confirm and edited then
		toDo = action
		dlgContinue:show()
		return true
	else
		confirm = false
		toDo = nil
		return false
	end
end
function dlgResult(dialog, result, text)
	if dialog == dlgOpen then
		if result == dialogResult.OK then
			dlgText = text
			openPath()
		end
	elseif dialog == dlgContinue then
		if result == dialogResult.Yes then
			confirm = true
			toDo()
		end
	end
end

function makeCN(g, w, h)
	nums.sF =   NumBox.new(g[1].x, g[1].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s1 =   NumBox.new(g[2].x, g[2].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s2 =   NumBox.new(g[3].x, g[3].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s3 =   NumBox.new(g[4].x, g[4].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s4 =   NumBox.new(g[5].x, g[5].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s5 =   NumBox.new(g[6].x, g[6].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s6 =   NumBox.new(g[7].x, g[7].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s7 =   NumBox.new(g[8].x, g[8].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s8 =   NumBox.new(g[9].x, g[9].y, 0, 0, maxStack, 2, true, w, h, nil, c1)
	nums.s9 = NumBox.new(g[10].x, g[10].y, 0, 0, maxStack, 2, true, w, h, nil, c1)

	for _, i in pairs(nums) do
		i:addEvent(events.valueChange, edit)
	end
end
function makeCI(g, w, h)
	names.sF =   TextBox.new(g[1].x, g[1].y, "", w, h, nil, c1)
	names.s1 =   TextBox.new(g[2].x, g[2].y, "", w, h, nil, c1)
	names.s2 =   TextBox.new(g[3].x, g[3].y, "", w, h, nil, c1)
	names.s3 =   TextBox.new(g[4].x, g[4].y, "", w, h, nil, c1)
	names.s4 =   TextBox.new(g[5].x, g[5].y, "", w, h, nil, c1)
	names.s5 =   TextBox.new(g[6].x, g[6].y, "", w, h, nil, c1)
	names.s6 =   TextBox.new(g[7].x, g[7].y, "", w, h, nil, c1)
	names.s7 =   TextBox.new(g[8].x, g[8].y, "", w, h, nil, c1)
	names.s8 =   TextBox.new(g[9].x, g[9].y, "", w, h, nil, c1)
	names.s9 = TextBox.new(g[10].x, g[10].y, "", w, h, nil, c1)
	
	for _, i in pairs(names) do
		i:addEvent(events.valueChange, edit)
	end
end
function makeCV(g, w, h)
	vars.sF =   NumBox.new(g[1].x, g[1].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s1 =   NumBox.new(g[2].x, g[2].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s2 =   NumBox.new(g[3].x, g[3].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s3 =   NumBox.new(g[4].x, g[4].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s4 =   NumBox.new(g[5].x, g[5].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s5 =   NumBox.new(g[6].x, g[6].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s6 =   NumBox.new(g[7].x, g[7].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s7 =   NumBox.new(g[8].x, g[8].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s8 =   NumBox.new(g[9].x, g[9].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	vars.s9 = NumBox.new(g[10].x, g[10].y, 0, 0, maxVar, 2, true, w, h, nil, c1)
	
	for _, i in pairs(vars) do
		i:addEvent(events.valueChange, edit)
	end
end
function makeCC(g, fg, bg)
	chks.s1 =   CheckBox.new(g[2].x, g[2].y, false, fg, bg)
	chks.s2 =   CheckBox.new(g[3].x, g[3].y, false, fg, bg)
	chks.s3 =   CheckBox.new(g[4].x, g[4].y, false, fg, bg)
	chks.s4 =   CheckBox.new(g[5].x, g[5].y, false, fg, bg)
	chks.s5 =   CheckBox.new(g[6].x, g[6].y, false, fg, bg)
	chks.s6 =   CheckBox.new(g[7].x, g[7].y, false, fg, bg)
	chks.s7 =   CheckBox.new(g[8].x, g[8].y, false, fg, bg)
	chks.s8 =   CheckBox.new(g[9].x, g[9].y, false, fg, bg)
	chks.s9 = CheckBox.new(g[10].x, g[10].y, false, fg, bg)
	
	for _, i in pairs(chks) do
		i:addEvent(events.valueChange, edit)
	end
end
function makeGUI()
	print("Building GUI...")
	local g = makeGrid({0,1,1,0,17,0,3}, {0,0,0,0,0,0,0,0,0,0})
	
	local sw, sh = resolutions.turtle.w, resolutions.turtle.h
	
	dlgOpen = Dialog.new(dlgResult, "Enter recipe to open:", buttonStyles.OKCancel, true, "Open file")
	dlgContinue = Dialog.new(dlgResult, "Recipe is not saved. Continue?", buttonStyles.YesNo, false, "Lose changes")
	
	local btnW = 8
	local btnOpen	= Button.new(0, 2, "Open",   btnW, 1, c3, colors.orange, function() dlgOpen:show() end)
	local btnSave	= Button.new(0, 3, "Save",   btnW, 1, c3, colors.green, save)
	local btnGet	= Button.new(0, 4, "Get",    btnW, 1, c3, colors.blue, get)
	local btnClear	= Button.new(0, 5, "Wipe",   btnW, 1, c3, colors.red, wipe)
	local btnLock	= Button.new(0, 6, "Lock",   btnW, 1, c3, colors.purple, function() setLock(true) end)
	local btnUnlock	= Button.new(0, 7, "Unlock", btnW, 1, c3, colors.pink, function() setLock(false) end)
	local btnFix	= Button.new(0, 8, "Fix",    btnW, 1, c3, colors.cyan, fix)
	local btnComp	= Button.new(0, 9, "Shrink", btnW, 1, c3, colors.lightBlue, compact)
	
	local slotPanel	= Panel.new(9, 2, g[7][10].x+1, g[7][10].y+1, c3, c2, c2)
	--	  lStat		= Label.new(0, sh - 1, "Ready", 7)
	
	local rNums	= Label.new(g[1][1].x, g[1][1].y, "=\n1\n2\n3\n4\n5\n6\n7\n8\n9", nil, nil, c1)
	local rX	= Label.new(g[3][1].x, g[3][1].y, "*\n*\n*\n*\n*\n*\n*\n*\n*\n*", nil, nil, c1)
	local rV	= Label.new(g[5][1].x, g[5][1].y, ":\n:\n:\n:\n:\n:\n:\n:\n:\n:", nil, nil, c1)
	
	btnGet.enabled = turtle ~= nil
	
	makeCN(g[2], 2, 1)
	makeCI(g[4], 18, 1)
	makeCV(g[6], 3, 1)
	makeCC(g[7], colors.lime, c3)
	
	slotPanel:addItem(rNums)
	slotPanel:addItem(rX)
	slotPanel:addItem(rV)
	slotPanel:addItems(nums)
	slotPanel:addItems(names)
	slotPanel:addItems(vars)
	slotPanel:addItems(chks)
	
	return {btnOpen, btnSave, btnGet, btnClear, btnLock, btnUnlock, btnFix, btnComp, slotPanel}
end

mainPanel:addItems(makeGUI())
if fs.exists(path) then
	open(path)
end
lTitle = mainPanel:addControlBar("Recipe Maker - "..path, true, true)
dlgOpen.txt:setText(path)
run()