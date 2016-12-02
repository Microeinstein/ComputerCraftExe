--Recipe Maker on turtles by Microeinstein

loadfile("stdturtle")()

local nonil = { name = "", count = 0 }
local sF	= turtle.getItemDetailXY(4, 2) or nonil
if sF.name == "" or sF.count == 0 then
	sF.name = term.input("Recipe item: ")
	sF.count = tonumber(string.remChars(term.input("Recipe amount: "):upper(), ".,xABCDEF"))
else
	print("Recipe item: "..sF.name)
	print("Recipe amount: "..sF.count)
end
local save = term.input("Save path: ")

local s11	= turtle.getItemDetailXY(1, 1) or nonil
local s21	= turtle.getItemDetailXY(2, 1) or nonil
local s31	= turtle.getItemDetailXY(3, 1) or nonil
local s12	= turtle.getItemDetailXY(1, 2) or nonil
local s22	= turtle.getItemDetailXY(2, 2) or nonil
local s32	= turtle.getItemDetailXY(3, 2) or nonil
local s13	= turtle.getItemDetailXY(1, 3) or nonil
local s23	= turtle.getItemDetailXY(2, 3) or nonil
local s33	= turtle.getItemDetailXY(3, 3) or nonil
local data = textutils.serialize({
	F	= {name=sF.name, count=sF.count},
	[1]	= {name=s11.name, count=s11.count},
	[2]	= {name=s21.name, count=s21.count},
	[3]	= {name=s31.name, count=s31.count},
	[4]	= {name=s12.name, count=s12.count},
	[5]	= {name=s22.name, count=s22.count},
	[6]	= {name=s32.name, count=s32.count},
	[7]	= {name=s13.name, count=s13.count},
	[8]	= {name=s23.name, count=s23.count},
	[9]	= {name=s33.name, count=s33.count}
})

print(fs.write(save, data))