game={
	ball={}, --可控
	npc={}, --不可控
	frame={}, --框架
	grave={}, --墓地
	state="play",
	mode="hot seat"
}

require "scr/net"
game.world = love.physics.newWorld(0,0,false)

love.physics.setMeter(32)

game.frame.body = love.physics.newBody(game.world,0,0)
game.frame.shape = love.physics.newChainShape(true, 20,20,1900,20,1900,1060,20,1060)
game.fixture = love.physics.newFixture(game.frame.body, game.frame.shape, 1)


table.insert(game.ball, Ball:new(0,400,1))
table.insert(game.ball, Ball:new(30,600,2))



game.source_bg = love.audio.newSource("asset/game.mp3")
game.source_bg:setLooping(true)
game.source_click = love.audio.newSource("asset/click.wav", "static")
game.source_collision = love.audio.newSource("asset/collision.wav", "static")
game.source_collision:setVolume(0.5)
game.source_start = love.audio.newSource("asset/start.mp3")
game.source_start:setLooping(true)
game.source_tire = love.audio.newSource("asset/tire.wav", "static")
game.source_tire:setVolume(0.5)
game.source_lanch = love.audio.newSource("asset/lanch.mp3", "static")
game.source_lanch :setVolume(0.5)
game.source_fault = love.audio.newSource("asset/fault.mp3","static")
game.source_fault:setVolume(0.5)
game.source_score  = love.audio.newSource("asset/score.mp3","static")
game.source_score: setVolume(0.5)
game.font = love.graphics.newFont("asset/Grundschrift-Bold.otf", 100)
game.uiFont=love.graphics.newFont("asset/Grundschrift-Bold.otf", 25)


game.world:setCallbacks(
	function(a,b,col) 
		if game.source_collision:isPlaying() then
			game.source_collision:rewind()
		end
		game.source_collision:play()
	end)

game.border={1200,300,1600,300,1600,780,1200,780}

game.turnScore=0

game.bgCanvas = love.graphics.newCanvas(unpack(designResolution))
love.graphics.setCanvas(game.bgCanvas)
	love.graphics.setLineWidth(5)
	love.graphics.setColor(255,255,255)
	love.graphics.line(20,20,1900,20,1900,1060,20,1060,20,20)
	love.graphics.handwrite_line(50,2,400,100,400,980)
	--love.graphics.arc( "line", 400, 540, 200, math.pi/2, 3*math.pi/2 )
	love.graphics.handwrite_line(50,2,1200,300,1600,300,1600,780,1200,780,1200,300)
love.graphics.setCanvas()

--------------gameUI--------------------
local style={
    bgColor = {100,100,230},
    fgColor = {255,255,255},
    howRound = 0.5,
    showBorder = true,
    borderColor = {150,150,200},
    font = game.uiFont
  }
  gooi.setStyle(style)
  
-------------------------------------------


---------------------------------------------

game.hand={}
game.hand.pic = love.graphics.newImage("asset/hand.png")
game.hand.x=500
game.hand.y=500
game.hand.cd=30

-----------------------
game.ai=require "scr/ai"



----------------
function game:new()

	if game.userPlayer==1 then game.opPlayer=2 else game.opPlayer=1 end
	for i,v in ipairs(self.npc) do
		v.body:destroy()
	end
	self.npc={}

	for i=1,6 do
		table.insert(self.npc, Ball:new( love.math.random(1220,1580),love.math.random(320,760),0))
	end

	
	self.whosTurn=1
	print("it's green's turn")
	self.ball[self.whosTurn].active= true

	for i,v in ipairs(self.ball) do
    	v.point=0
    	v:reset()
    end
end




function game:update(dt,mx,my)
	
	love.graphics.setFont(game.font)
	
	if self.mode=="solo" and self.whosTurn~=self.userPlayer then
		self.ai:update(dt)
	end

	for i,v in ipairs(self.ball) do
		v:update(dt,mx,my)
	end
	for i,v in ipairs(self.npc) do
		v:update(dt,mx,my)
	end
	for i,v in ipairs(self.grave,mx,my) do
		v:update(dt)
	end
	self.world:update(dt)
	self:nextTurnTest()
	--self:outBorderTest()
	self:eraseGrave()

	
	--print(self.ball[1].x)
	if self.mode=="net" then 
		self.hand.cd=self.hand.cd-1
		if self.hand.cd<0 then
			self.hand.cd=30
			self.net:send({"mouse pos",mx,my})
		end
		self.net:update() 
	end
 	if self.endgame then self:gameOver() end
end


function game:draw()
	
	love.graphics.setFont(game.font)
    --draw the board
	love.graphics.draw(game.bgCanvas)
	love.graphics.print("Green: "..self.ball[1].point.." vs ".. " Blue: ".. self.ball[2].point , 450,10)

	--draw items
	for i,v in ipairs(self.npc) do
		v:draw(dt)
	end
	for i,v in ipairs(self.ball) do
		v:draw()
	end
	for i,v in ipairs(self.grave) do
		v:draw()
	end
	
	if game.whosTurn~=game.userPlayer and game.mode~="hot seat" then
		love.graphics.draw(self.hand.pic, self.hand.x,self.hand.y,0,2,2)
	end

end

function game:allStopTest()
	for i,v in ipairs(self.ball) do
		local sx,sy=v.body:getLinearVelocity( )
		if math.abs(sx)>1 or math.abs(sy)>1 then 
			return false 
		end
	end
	for i,v in ipairs(self.npc) do
		local sx,sy=v.body:getLinearVelocity( )
		if math.abs(sx)>1 or math.abs(sy)>1 then 
			return false 
		end
	end	

	for i,v in ipairs(self.ball) do
		v.body:setLinearVelocity(0,0)
	end


	for i,v in ipairs(self.npc) do
		v.body:setLinearVelocity(0,0)
	end

	return true
end

function game:sync()
	if self.net.type=="server" then --客户端接收同步，服务端发送同步
		for i,v in ipairs(self.ball) do
			self.net:send({"sync","ball",i,v.x,v.y})
		end
		for i,v in ipairs(self.npc) do
			self.net:send({"sync","npc",i,v.x,v.y})
		end
		self.net:send({"sync","over"})
	end
end


function game:nextTurnTest()
	if self.ball[self.whosTurn].active  then return end --如果还没有动作则不检测停止
	
	if self.mode=="hot seat" or self.net.type=="server" then --如果是客户端则不做全停检测 而是根据同步数据进行
		if self:allStopTest() then
			if self.mode=="net" then
				self:sync()
			end
			self:outBorderTest()
			self:faultTest()
			self.whosTurn=self.whosTurn+1
			if self.whosTurn>#self.ball then
				self.whosTurn=1
			end
			self.ball[self.whosTurn].active= true
			self.ball[self.whosTurn]:select()
			if #self.npc==0 then
				self.endgame=true
				if self.mode=="net" then self.net:send({"gameover"}) end
			end

			if game.whosTurn==2 then
				print("it's blue's turn")
			else
				print("it's green's turn")
			end
		end
	elseif self.syncFinish then
		self.syncFinish=false
		self:outBorderTest()
		self:faultTest()
		self.whosTurn=self.whosTurn+1
		if self.whosTurn>#self.ball then
			self.whosTurn=1
		end
		self.ball[self.whosTurn].active= true
		self.ball[self.whosTurn]:select()
		if game.whosTurn==2 then
			print("it's blue's turn")
		else
			print("it's green's turn")
		end
	end
end

local function inBorder(x,y)
	if x>1200 and x<1600 and y>300 and y<780 then
		return true
	else
		return false
	end
end

function game:outBorderTest()
	for i=#self.npc,1,-1 do
		if not inBorder(self.npc[i].x,self.npc[i].y) then
			self.npc[i]:select()
			table.insert(self.grave, self.npc[i])
			table.remove(self.npc, i)
			self.turnScore=self.turnScore+1
		end
	end
end

function game:faultTest()
	local rt=false
	for i,v in ipairs(self.ball) do
		if inBorder(v.x,v.y) then
			if i==self.whosTurn then --如果是母球则
				for i=1,self.turnScore do
					table.insert(self.npc, Ball:new( love.math.random(1200,1600),love.math.random(300,780),0))
				end
				table.insert(self.npc, Ball:new(self.ball[i].x,self.ball[i].y,0))
				rt=true
				print("fault! cue in the quad!")
				game.source_fault:play()
			end
			self.ball[i]:reset()
		end
	end
	if not rt and self.turnScore~=0 then 
		self.ball[self.whosTurn].point=self.ball[self.whosTurn].point+self.turnScore 
		print("score!")
		game.source_score:play()
	end
	self.turnScore=0
	return rt
end


function game:eraseGrave()
	
	for i=#self.grave,1,-1 do
		if self.grave[i].shaderTween.over then
			self.grave[i]:delete()
			table.remove(self.grave, i)
		end
	end

end


function game:gameOver()
	self.endgame=false
	local title = "Game Over"
	local winner
	if self.ball[1].point>self.ball[2].point then
		winner="Green"
	else
		winner="Blue"
	end
	local message = "player ".. winner .." win the game, restart?"
	local buttons = {"no", "yes", escapebutton = 1}

	local pressedbutton = love.window.showMessageBox(title, message, buttons)
	if pressedbutton == 2 then
	    self:new()
	elseif pressedbutton == 1 then
	    love.event.quit()
	end
end
