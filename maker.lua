--Recipe Maker by Microeinstein

loadfile("forms")()

init(colors.black, colors.white)

args = {...}

c1 = colors.gray
c2 = colors.lightGray
c3 = colors.white
nums = {}
ids = {}
tPath = nil
lStat = nil
edited = false
force = false

function edit()
	force = false
	edited = true
	lStat:setText("Modified")
end
function open()
	if edited and not force then
		lStat:setText("Press again to open")
		force = true
		return
	end
	force = false
	
	local res, file = fs.read(tPath.text)
	lStat:setText(res)
	
	if res == fs.mex.okRead then
		local data = textutils.unserialize(file)
		ids.sF:setText(data["F"].name); nums.sF:setText(data["F"].count)  
		ids.s1:setText(data[1].name); nums.s1:setText(data[1].count)  
		ids.s2:setText(data[2].name); nums.s2:setText(data[2].count)  
		ids.s3:setText(data[3].name); nums.s3:setText(data[3].count)  
		ids.s4:setText(data[4].name); nums.s4:setText(data[4].count)  
		ids.s5:setText(data[5].name); nums.s5:setText(data[5].count)  
		ids.s6:setText(data[6].name); nums.s6:setText(data[6].count)  
		ids.s7:setText(data[7].name); nums.s7:setText(data[7].count)  
		ids.s8:setText(data[8].name); nums.s8:setText(data[8].count)  
		ids.s9:setText(data[9].name); nums.s9:setText(data[9].count) 
		edited = false
	end
end
function save()
	if edited and not force then
		lStat:setText("Press again to save")
		force = true
		return
	end
	force = false
	
	local data = textutils.serialize({
		["F"]={name=ids.sF:getText(), count=nums.sF:getText()},
		[1]={name=ids.s1:getText(), count=nums.s1:getText()},
		[2]={name=ids.s2:getText(), count=nums.s2:getText()},
		[3]={name=ids.s3:getText(), count=nums.s3:getText()},
		[4]={name=ids.s4:getText(), count=nums.s4:getText()},
		[5]={name=ids.s5:getText(), count=nums.s5:getText()},
		[6]={name=ids.s6:getText(), count=nums.s6:getText()},
		[7]={name=ids.s7:getText(), count=nums.s7:getText()},
		[8]={name=ids.s8:getText(), count=nums.s8:getText()},
		[9]={name=ids.s9:getText(), count=nums.s9:getText()}
	})
	
	local res = fs.write(tPath:getText(), data)
	lStat:setText(res)
	
	if res == fs.mex.okWrite then
		edited = true
	end
end
function wash()
	if force then
		nums.sF:setText("0"); ids.sF:setText("");
		nums.s1:setText("0"); ids.s1:setText("");
		nums.s2:setText("0"); ids.s2:setText("");
		nums.s3:setText("0"); ids.s3:setText("");
		nums.s4:setText("0"); ids.s4:setText("");
		nums.s5:setText("0"); ids.s5:setText("");
		nums.s6:setText("0"); ids.s6:setText("");
		nums.s7:setText("0"); ids.s7:setText("");
		nums.s8:setText("0"); ids.s8:setText("");
		nums.s9:setText("0"); ids.s9:setText("");
		lStat:setText("Cleared")
		edited = false
		force = false
	else
		force = true
		lStat:setText("Press again to clear")
	end
end

function stackMinMax(self)
	local txt = self:getText()
	txt = string.remChars(txt:upper(), ".,xABCDEF")
	local num = tonumber(txt)
	local bet = math.between(0, num or 0, 64)
	self:setText(bet)
end

function makeC2(g, w, h)
	print("Column 2...")
	nums.sF = TextBox.new(g[1].x, g[1].y, "0", w, h, nil, c1)
	nums.s1 = TextBox.new(g[2].x, g[2].y, "0", w, h, nil, c1)
	nums.s2 = TextBox.new(g[3].x, g[3].y, "0", w, h, nil, c1)
	nums.s3 = TextBox.new(g[4].x, g[4].y, "0", w, h, nil, c1)
	nums.s4 = TextBox.new(g[5].x, g[5].y, "0", w, h, nil, c1)
	nums.s5 = TextBox.new(g[6].x, g[6].y, "0", w, h, nil, c1)
	nums.s6 = TextBox.new(g[7].x, g[7].y, "0", w, h, nil, c1)
	nums.s7 = TextBox.new(g[8].x, g[8].y, "0", w, h, nil, c1)
	nums.s8 = TextBox.new(g[9].x, g[9].y, "0", w, h, nil, c1)
	nums.s9 = TextBox.new(g[10].x, g[10].y, "0", w, h, nil, c1)
	
	for k, t in pairs(nums) do
		t:addEvent(events.focusOff, stackMinMax)
		t:addEvent(events.text, edit)
	end
	return nums
end
function makeC4(g, w, h)
	print("Column 4...")
	ids.sF = TextBox.new(g[1].x, g[1].y, "", w, h, nil, c1)
	ids.s1 = TextBox.new(g[2].x, g[2].y, "", w, h, nil, c1)
	ids.s2 = TextBox.new(g[3].x, g[3].y, "", w, h, nil, c1)
	ids.s3 = TextBox.new(g[4].x, g[4].y, "", w, h, nil, c1)
	ids.s4 = TextBox.new(g[5].x, g[5].y, "", w, h, nil, c1)
	ids.s5 = TextBox.new(g[6].x, g[6].y, "", w, h, nil, c1)
	ids.s6 = TextBox.new(g[7].x, g[7].y, "", w, h, nil, c1)
	ids.s7 = TextBox.new(g[8].x, g[8].y, "", w, h, nil, c1)
	ids.s8 = TextBox.new(g[9].x, g[9].y, "", w, h, nil, c1)
	ids.s9 = TextBox.new(g[10].x, g[10].y, "", w, h, nil, c1)
	
	for k, t in pairs(ids) do
		t:addEvent(events.text, edit)
	end
	return ids
end
function makeGUI()
	print("Building GUI...")
	local w, g = 24, grid(7, 1, 4, 10, {0, 1, 2, 2})
	
	local sw, sh = term.getSize()
	local controlT  = Label.new(0, 0, "Recipe Maker", sw, 1, colors.white, colors.blue)
	local controlX  = Button.new(sw - 4, 0, "X", 3, 1, colors.white, colors.red, stop)
	
	local btnOpen   = Button.new(1, 4, "Open", 6, 3, c3, c2, open)
	local btnSave   = Button.new(1, 8, "Save", 6, 3, c3, c2, save)
	local btnClear  = Button.new(1, 12, "Wash", 6, 3, colors.pink, colors.red, wash)
	
	local slotPanel = Panel.new(8, 4, g[4][10].x + w + 1, g[4][10].y + 2, c3, c2)
	
	local lPath	 = Label.new(1, 2, "Path: ")
		  tPath	 = TextBox.new(slotPanel.x - 1, 2, "recipes/", mainPanel.width - slotPanel.x, 1, c3, c2)
		  lStat	 = Label.new(0, sh - 1, "Ready", sw)
	
	local rGrid = Label.new(1, 1, "123\n456=\n789", nil, nil, c1)
	local rNums = Label.new(7, 1, "=\n1\n2\n3\n4\n5\n6\n7\n8\n9", nil, nil, c1)
	local rX = Label.new(11, 1, "x\nx\nx\nx\nx\nx\nx\nx\nx\nx", nil, nil, c1)
	
	slotPanel:addItem(rGrid)
	slotPanel:addItem(rNums)
	slotPanel:addItem(rX)
	slotPanel:addItems(makeC2(g[2], 2, 1))
	slotPanel:addItems(makeC4(g[4], w, 1))
	tPath:addEvent(events.text, function() force = false; end)
	
	return { controlX, controlT, btnOpen, btnClear, btnSave, slotPanel, lPath, tPath, lStat }
end

mainPanel:addItems(makeGUI())
if args and args[1] then
	tPath:setText(args[1])
	open()
end	
run()