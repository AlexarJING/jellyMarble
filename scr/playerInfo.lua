player={}

local file, errorstr = love.filesystem.newFile("gamedata.dat")
local ui= gooi.newPanel("player_info", 10, 10, resolution[1]-10, resolution[2]-10, "grid 8x5")
	:add(gooi.newLabel("l1", "123"):setOrientation("center"),"1,3")
	:add(gooi.newText("t1", "xxx"),"3,3")

function player:save()
	local save=bin:pack(self)
	file:open("w")
	local data=bin:pack(self)
	file:write(data)
	file:close()
	return data
end

function player:load()
	file:open("r")
	local data=file:read()
	file:close()
	if data==nil then self:new();return end --no data
	local tab=bin:unpackdata(data)
	table.copy(tab,player)
	if not self.name then self:reset() end
end


function player:new()
	self:newName()
	self.money=100
	self.gamePlayed=0
	self.gameWinned=0
	self.netBattle=0
end

function player:buy()

end

function player:noMoney()


end

function player:draw()
	love.graphics.setFont(game.font)
	love.graphics.print(self.name..": "..self.money,400,20)
end