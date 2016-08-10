local console={}
local p = print
function print(...)
  p(...)
  local arg={...}
  local txt=""
  for i,v in ipairs(arg) do
    txt=txt..tostring(v)..", "
  end
  txt=string.sub(txt,1,-3)
  table.insert(console,txt)
  if #console>15 then table.remove(console, 1) end
end
print("welcome to jelly marble!")



require "lib/util"
Tween=require "lib/tween"
Class=require "lib/middleclass"
Gamestate = require "lib/gamestate"
require "lib/class"
require "lib/gooi"
delay= require "scr/delay"
Ball= require "scr/ball"

resolution={ love.graphics.getDimensions() }
designResolution={1920,1080}
scaleX=resolution[1]/designResolution[1]
scaleY=resolution[2]/designResolution[2]

function love.load()
  require "scr/game"
 -- require "playerInfo"
  love.graphics.setBackgroundColor(100,100,100)
  state={}
  state.start=require("scene/start")
  state.play=require("scene/play")
  Gamestate.registerEvents()
  Gamestate.switch(state.start)
  
end

function love.update(dt)
    gooi.update(dt)
    delay:update(dt)
end


function love.draw()
    --love.graphics.setFont(game.uiFont)
    gooi.draw()
    for i,v in ipairs(console) do
      love.graphics.print(v, 50,30+i*25)
    end
end

function love.textinput(key, code) gooi.textinput(key, code) end
function love.keypressed(key)
  gooi.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end
function love.mousepressed(x, y, button)  gooi.pressed() end
function love.mousereleased(x, y, button) gooi.released() end