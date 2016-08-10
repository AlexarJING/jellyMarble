local scene = Gamestate.new()
local function createRoom()
	game.mode="net"
	game.net.type="server"
	game.net:init()
	game.userPlayer=1
	Gamestate.switch(state.play)
end

local function jointRoom()
	game.mode="net"
	game.net.type="client"
	game.net:init()
	game.userPlayer=2
	Gamestate.switch(state.play)
end

local function hotSeat()
	game.mode="hot seat"
	Gamestate.switch(state.play) 
end

local function solo()
	game.userPlayer=1
	game.mode="solo"
	Gamestate.switch(state.play)
end


function scene:init()
	self.ui= gooi.newPanel("panelGrid", 10, 10, resolution[1]-10, resolution[2]-10, "grid 5x5")
    :add(gooi.newButton(1, "Single Game"):onRelease(function() solo();game.source_click:play() end),"1,5")
    :add(gooi.newButton(2, "Hot Seat"):onRelease(function() hotSeat();game.source_click:play() end),"2,5")
    :add(gooi.newButton(3, "Create Room"):onRelease(function() createRoom();game.source_click:play() end),"3,5")
    :add(gooi.newButton(4, "Joint Room"):onRelease(function() jointRoom();game.source_click:play() end),"4,5")
    :add(gooi.newButton(5, "Help"):onRelease(function() game.source_click:play();love.window.showMessageBox("help", "drag your ball and release to kick all the red ball out of border!", {"ok"}) end),"5,5")
    --:add(gooi.newButton(6, "Insert Icon"):onRelease(function() love.window.showMessageBox("help", "drag your ball and release to kick all the red ball out of border!", {"ok"}) end),"5,1")
    --gooi.setVisible(pGrid,false)
    self.font = love.graphics.newFont("asset/Grundschrift-Bold.otf", 70)
    self.title="JELLY MARBLE"
    self.color={}
    self.cd=-1
end

function scene:enter()
	self.ball=Ball:new( 75/scaleX,100/scaleY,0)
	game.source_start:play()
end

function scene:changeColor()
	self.cd=self.cd-1
	if self.cd<0 then
		self.cd=100
		for i=1,string.len(self.title) do
			self.color[i]=love.graphics.randomColor()
		end
		--self.ball:select()
	end

end


function scene:drawTitle()
	self:changeColor()
	love.graphics.setFont(self.font)
	for i=1,string.len(self.title) do
		love.graphics.setColor(self.color[i])
		love.graphics.print(string.sub(self.title,i,i), 25*i/scaleX,70/scaleY)
	end
end

function scene:draw()
	self:drawTitle()
	love.graphics.push()
  	love.graphics.scale(1/scaleX,1/scaleY) 
  	self.ball:draw()
  	love.graphics.pop()
end

function scene:update(dt)
    
    if game.net.begin then game.net:update() end
    
    self.ball:drag(love.mouse.isDown("l"), love.mouse.getX()*scaleX,love.mouse.getY()*scaleY)
    self.ball:update(dt)
end 

function scene:leave()
	gooi.setVisible(self.ui,false)
	gooi.setEnabled(self.ui,false)
	self.ball:delete()
	game.source_start:stop()
end



return scene