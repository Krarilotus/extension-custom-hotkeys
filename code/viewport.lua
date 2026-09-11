-- Inverse of graphicsApiReplacer 1.3.0's public source mouse transform.
-- This maps render pixels to window pixels; it has no world/tile state.
local M={}
local function round(n) return math.floor(n+0.5) end
function M.point(x,y,gameWidth,gameHeight,windowWidth,windowHeight)
  for _,value in ipairs({x,y,gameWidth,gameHeight,windowWidth,windowHeight}) do
    if type(value)~='number' or value~=math.floor(value) or value<0 or value>32767 then return nil end
  end
  if gameWidth<2 or gameHeight<2 or windowWidth<2 or windowHeight<2
      or x>=gameWidth or y>=gameHeight then return nil end
  local ratio=math.max(gameWidth/windowWidth,gameHeight/windowHeight)
  local offsetX=round((1-gameWidth/windowWidth/ratio)*windowWidth/2)
  local offsetY=round((1-gameHeight/windowHeight/ratio)*windowHeight/2)
  local rangeX,rangeY=windowWidth-2*offsetX-1,windowHeight-2*offsetY-1
  if rangeX<1 or rangeY<1 then return nil end
  local clientX=round(x*rangeX/(gameWidth-1))
  local clientY=round(y*rangeY/(gameHeight-1))
  return clientX+offsetX,clientY+offsetY,
    round(clientX*(gameWidth-1)/rangeX),round(clientY*(gameHeight-1)/rangeY)
end
return M
