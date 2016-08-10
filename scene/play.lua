local scene = Gamestate.new()

function scene:init()

end 

function scene:enter(from,to,time,how,...)
	game:new()
	game.source_bg:play()
	if game.mode=="net" then game.mode="hot seat" end
end


function scene:draw()
	love.graphics.push()
  	love.graphics.scale(scaleX,scaleY) 
  	game:draw()
  	love.graphics.pop()
end

function scene:update(dt)
    game:update(1/60,love.mouse.getX()/scaleX, love.mouse.getY()/scaleY)
end 

function scene:leave()

end

return scene