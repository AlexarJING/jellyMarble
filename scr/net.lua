require "lib/Binary"
require "lib/LUBE"
game.net={}
local net=game.net

net.type="server"
net.client=require "scr/client"
net.server=require "scr/server"
net.isOn=false
function net:init()
	self.begin=true
	self[self.type]:init()
	self.isOn=true
end


function net:update()
	self[self.type]:update()
	self:msg()
end

function net:send(info)
	table.insert(self[self.type].toSend,info)
end


function net:msg()
	local data=self[self.type].toGet
	if not data.id then return end
	local id,cmd=data.id, data.msg["1"]
	--if cmd then print(cmd) end
	if cmd=="mouse pos" then
		game.hand.x,game.hand.y=data.msg["2"],data.msg["3"]
	elseif cmd=="lanch" then
		game.ball[game.opPlayer].shaderTween=Tween.new(1, game.ball[game.opPlayer].shaderArg, 
    	{outputX=game.ball[game.opPlayer].shaderArg.inputX,outputY=game.ball[game.opPlayer].shaderArg.inputY}, "outElastic")
    	game.ball[game.opPlayer].body:applyLinearImpulse( data.msg["2"],data.msg["3"] )
    	game.ball[game.opPlayer].active=false
	elseif cmd=="ic" then
		game.ball[game.opPlayer].shaderArg.inputX,game.ball[game.opPlayer].shaderArg.inputY=data.msg["2"],data.msg["3"]
	elseif cmd=="oc" then
		game.ball[game.opPlayer].shaderArg.outputX,game.ball[game.opPlayer].shaderArg.outputY=data.msg["2"],data.msg["3"]
	elseif cmd=="hello" then
		print(id.." has just linked to server")
		self[self.type].clientID=id
		self:send({"random", love.math.getRandomState()})
		game.mode="net"
		game:new()
	elseif cmd=="random" then
		print("conneted to server")
		love.math.setRandomState(data.msg["2"])
		game.mode="net"
		game:new()
	elseif cmd=="new npc" then
		--table.insert(game.npc, Ball:new( data.msg["2"],data.msg["3"],0))
	elseif cmd=="ready" then
		game.state="play"
	elseif cmd=="sync" then
		local t=data.msg["2"]
		if t=="over" then
			game.syncFinish=true
		else
			game[t][tonumber(data.msg["3"])].body:setPosition(data.msg["4"],data.msg["5"])
			game[t][tonumber(data.msg["3"])].body:setLinearVelocity(0,0)
		end
	elseif cmd=="gameover" then
		game.endgame=true
	end
end
