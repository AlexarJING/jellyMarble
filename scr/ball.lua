local ball=Class("ball")
local force=90000
local shader_warp=[[

  extern Image img; //texture
  extern vec2 ic; //first point
  extern vec2 oc; //second point
  extern float r; //warp radian
  extern float limit; //max warp radian

  vec2 warp (vec2 tc,vec2 ic,vec2 oc,float r) {
    float dis_x_c=distance(tc,ic);
    float dis_m_c=distance(tc,oc);
    float div=pow(r,2.0) - pow(dis_x_c,2.0) + pow(dis_m_c,2.0);
    if (div==0.0) div=0.0000000001;
    float factor=pow((pow(r,2.0) - pow(dis_x_c,2.0)) / div,2.0);
    return vec2(tc-factor*(oc-ic));
  }

  vec4 effect( vec4 color, Image texture, vec2 tc, vec2 sc )
  {
    if (distance(tc,ic)>r) {
      vec2 rc=limit*tc-0.5*limit+0.5;
      if (rc.x<0.0 || rc.x>1.0 ||  rc.y<0.0 || rc.y>1.0) {
        return vec4(0,0,0,0);
      }else{    
        return Texel(img,rc);
      }
    }

    vec2 uv=warp(tc,ic,oc,r);
    
    if (uv.x<0.0 || uv.x>1.0 ||  uv.y<0.0 || uv.y>1.0) {
      return vec4(0,0,0,0);
    }else{    
      vec2 rc=limit*uv-0.5*limit+0.5;
      if (rc.x<0.0 || rc.x>1.0 ||  rc.y<0.0 || rc.y>1.0) {
        return vec4(0,0,0,0);
      }else{    
        return Texel(img,rc);
      }
    }
  }
]]

local shader_radian=[[
    extern Image img;
    extern float power;
    extern float limit;
    extern vec2 ic;

    vec2 warp(vec2 ic,vec2 tc,float power ) {
      tc=tc*2.0-1.0;
      ic=ic*2.0-1.0;
      float r = distance(tc,ic);
      float phi = atan(tc.y-ic.y, tc.x-ic.x);
      r=pow(r,power);
      return vec2((r * cos(phi)+ic.x)/2.0+0.5,(r * sin(phi)+ic.y)/2.0+0.5);
    }

    vec4 effect( vec4 color, Image texture, vec2 tc, vec2 sc )
    {
    
    vec2 uv=warp(ic,tc,power);
    
    if (uv.x<0.0 || uv.x>1.0 ||  uv.y<0.0 || uv.y>1.0) {
      return vec4(0,0,0,0);
    }else{    
      vec2 rc=limit*uv-0.5*limit+0.5;
      if (rc.x<0.0 || rc.x>1.0 ||  rc.y<0.0 || rc.y>1.0) {
        return vec4(0,0,0,0);
      }else{    
        return Texel(img,rc);
      }
    }
  }

]]

function ball:initialize(x,y,player)
	--if game.net.isOn and game.net.type=="server" then game.net:send({"new npc",x,y}) end
	self.x=x
	self.y=y
	self.active=false
	self.player=player
	self.color={255,255,255}
	self.point=0
	self.maxStrentch=3 --最大拉伸倍数
	if player==1 then
		self.image = love.graphics.newImage("asset/ball_green.png")
	elseif player==2 then
		self.image = love.graphics.newImage("asset/ball_blue.png")
	else
		self.image = love.graphics.newImage("asset/ball_red.png")
	end
	self.imageWidth=self.image:getWidth()
	self.imageHeight=self.image:getHeight()
	self.imageData=love.graphics.newImage(love.image.newImageData(self.imageWidth*self.maxStrentch,self.imageHeight*self.maxStrentch))
	self.dataWidth=self.imageWidth*self.maxStrentch
	self.dataHeight=self.imageHeight*self.maxStrentch
	

	self.r=self.imageWidth/2
	self.body = love.physics.newBody(game.world, x, y, "dynamic")
	self.shape = love.physics.newCircleShape(0, 0, self.r)
	self.fixture = love.physics.newFixture(self.body, self.shape, 1)
	--self.body:setAngularDamping(9999)
	self.body:setLinearDamping(2)
	self.fixture:setRestitution(0.5)


	self.shaderWarp=love.graphics.newShader(shader_warp)
	self.shaderRadian=love.graphics.newShader(shader_radian)

	self.shaderArg={
		inputX=0,
		inputY=0,
		outputX=0,
		outputY=0,
		power=0,
	}
	self.shaderTween=nil
	self.shaderWarp:send("img",self.image)
	self.shaderWarp:send("ic",{0,0}) --初点坐标
	self.shaderWarp:send("oc",{0,0}) --末点坐标
	self.shaderWarp:send("r",self.r/self.imageWidth/1.5) 
	self.shaderWarp:send("limit",self.maxStrentch)
	self.shaderRadian:send("img",self.image)
	self.shaderRadian:send("power",1)
	self.shaderRadian:send("limit",self.maxStrentch)
	self.shaderRadian:send("ic",{0.5,0.5})
	self.effect=self.shaderWarp
end

function ball:reset()
	if self.player==1 then
		self.body:setPosition(330,440)
	elseif self.player==2 then
		self.body:setPosition(330,640)
	else

	end
	self.body:setLinearVelocity(0,0)
	self:select()
end

function ball:delete()
	self.body:destroy()
end

function ball:update(dt,mx,my)
	self.x,self.y=self.body:getPosition()

	if self.active and (game.userPlayer==game.whosTurn or game.mode=="hot seat") then self:drag(love.mouse.isDown("l"),mx,my) end
	if self.shaderTween then
		self.shaderTween:update(dt)
	end
	if self.shaderArg.outputX ~= self.shaderArg.outputX then
		self.shaderArg.outputX, self.shaderArg.outputY=self.shaderArg.inputX, self.shaderArg.inputY
		--self:select()
	end
	
	
	self.shaderWarp:send("ic",{(self.shaderArg.inputX-self.x+self.dataWidth/2)/self.dataWidth,
								(self.shaderArg.inputY-self.y+self.dataHeight/2)/self.dataHeight})
	self.shaderWarp:send("oc",{(self.shaderArg.outputX-self.x+self.dataWidth/2)/self.dataWidth,
							(self.shaderArg.outputY-self.y+self.dataHeight/2)/self.dataHeight})
	self.shaderRadian:send("power",self.shaderArg.power)
end



function ball:draw()
	--love.graphics.setColor(255,0,0)
	--love.graphics.circle("fill", self.x,self.y,self.r)
	love.graphics.setShader(self.effect)
	love.graphics.draw(self.imageData,self.x-self.dataWidth/2,self.y-self.dataHeight/2)
	love.graphics.setShader()
end


function ball:select()
	self.shaderTween=nil
	self.effect=self.shaderRadian
	self.shaderRadian:send("power",1.5)
	self.shaderArg.power=1.5
	self.shaderTween=Tween.new(1, self.shaderArg, {power=1}, "outElastic")
	local effect=self.effect
	self.shaderTween:setCallback(function(obj) obj.effect=obj.shaderWarp end,self)
end

function ball:drag(down,x,y)
	local angle= -math.getRot(x,y,self.x,self.y)
	if down and not self.selected then
		 --if the pos is out of range then pass
		if math.getDistance(x,y,self.x,self.y)>self.r then return end
		self.shaderTween=nil
		self.selected=true
		self.effect=self.shaderWarp
		self.shaderArg.inputX, self.shaderArg.inputY = self.x,self.y
		self.shaderArg.outputX, self.shaderArg.outputY = self.x,self.y
		if game.mode=="net" then
			game.net:send({"ic",self.x,self.y})
			game.net:send({"oc",self.x,self.y})
		end
		game.source_tire:play()
	elseif down and self.selected then
		if math.getDistance(x,y,self.x,self.y)>self.r * self.maxStrentch/2 then --if pass the max distance then maintain that lenth
			x,y=self.x+math.sin(angle)*self.r * self.maxStrentch/2,self.y+math.cos(angle)*self.r * self.maxStrentch/2
		end
		self.shaderArg.outputX, self.shaderArg.outputY = x,y
		if game.mode=="net" then
			game.net:send({"oc",x,y})
		end

	elseif ((not down) and self.selected) or net then
		game.source_tire:stop()
		game.source_lanch:play()
		self.selected=false
		self.shaderTween=Tween.new(1, self.shaderArg, 
    	{outputX=self.shaderArg.inputX,outputY=self.shaderArg.inputY}, "outElastic")
		local p= force*math.getDistance(self.shaderArg.inputX,self.shaderArg.inputY,self.shaderArg.outputX,self.shaderArg.outputY)/self.r
		local fx,fy=math.sin(angle+math.pi)*p,math.cos(angle+math.pi)*p
		self.body:applyLinearImpulse( fx, fy )
		self.active=false
		if game.mode=="net" then
			game.net:send({"lanch",fx,fy})
		end		

	end
	if love.mouse.isDown("r") then
		self:select()
	end
end



return ball

