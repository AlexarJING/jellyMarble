local ai={}
ai.cmd={}
ai.player=2
ai.ball=game.ball[ai.player]
-- border: x>1200 and x<1600 and y>300 and y<780
ai.hand=game.hand
ai.hand.x=designResolution[1]/2
ai.hand.y=designResolution[2]/2

ai.state="goto"
function ai:moveHand()
	self.tween=Tween.new(1.5,self.hand,{x=self.ball.x,y=self.ball.y},"inOutQuad")
	self.tween:set(-1)
	self.tween:setCallback(function(obj) obj.state="aim"; obj.tween=nil end,self)
end

function ai:findAngle()
	local ball = game.npc[love.math.random(1,#game.npc)]
	local angle = -math.getRot(self.ball.x,self.ball.y,ball.x,ball.y)+ (love.math.random()*2-1)*math.pi/48
	local offx = self.ball.x+ math.sin(angle)*self.ball.r*self.ball.maxStrentch
	local offy = self.ball.y+ math.cos(angle)*self.ball.r*self.ball.maxStrentch
	self.tween=Tween.new(1,self.hand,{x=offx,y=offy},"inOutQuad")
	self.tween:setCallback(function(obj) obj.state="lanch"; obj.tween=nil end,self)
end

function ai:lanch()
	self.ball:drag(true,self.hand.x,self.hand.y)
	self.ball:drag(false,self.hand.x,self.hand.y)
	self.state="over"
end

function ai:update(dt) 
	if not self.ball.active then self.state="goto";return end
	
	if self.tween then 
		self.tween:update(dt) 
		if self.state=="aim" then
			self.ball:drag(true,self.hand.x,self.hand.y)
		end
	else
		if self.state=="goto" then self:moveHand() end
		if self.state=="aim" then self:findAngle() end
		if self.state=="lanch" then self:lanch() end
	end
end

return ai