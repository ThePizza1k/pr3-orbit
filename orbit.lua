do
  local DO_ERROR_CHECKING = true
  local ERROR_COLOR = 0xff0000

  local DISPLAY_CONFIG = {
    width = 80,
    height = 60,
    x = -100, -- start at x = -60
    y = -60, -- start at y = -60
  }

  local PLAYER_INFO = {
    x = DISPLAY_CONFIG.x + DISPLAY_CONFIG.width/2,
    y = DISPLAY_CONFIG.y + DISPLAY_CONFIG.height + 4,
    Cw = 2*DISPLAY_CONFIG.width, -- Amount of blocks that can fit horizontally on screen
    Cx = DISPLAY_CONFIG.x + DISPLAY_CONFIG.width/2 - 8.4375, -- X pos of camera center
    Cy = DISPLAY_CONFIG.y + DISPLAY_CONFIG.height/2 - 6, -- Y pos of camera center
  }

  display = {
    x = DISPLAY_CONFIG.x,
    y = DISPLAY_CONFIG.y,
    width = DISPLAY_CONFIG.width,
    height = DISPLAY_CONFIG.height,
  }

  aux = {}

  do
    local kp = function(key) return key end
    local pc = function(str,col) player.chat(str,col) end
    local al = function(str) player.alert(str) end
    local ps = function(id,vol) player.playsound(id,vol) end

    function aux.keypressed(key)
      return tolua(kp(keys[key]))
    end
    function aux.chat(str,col)
      pc(str,col)
    end
    function aux.alert(str)
      al(str)
    end
    function aux.playsound(id,vol)
      ps(id,vol)
    end
    function PLAYER_INFO.supplyKeyPressed(keypressed)
      kp = tolua(keypressed)
    end
    function PLAYER_INFO.supplyPlayerChat(pchat)
      pc = tolua(pchat)
    end
    function PLAYER_INFO.supplyPlayerAlert(palert)
      al = tolua(palert)
    end
    function PLAYER_INFO.supplyPlayerPlaySound(psound)
      ps = tolua(psound)
    end
  end

  DISPLAY = display


  local pixels = {}
  local old_pixels = {}

  display.pixels = pixels

  for i = 0,(DISPLAY_CONFIG.height)-1,1 do
    local row = {}
    local old_row = {}
    for j = 0,(DISPLAY_CONFIG.width)-1,1 do
      row[j] = 0
      old_row[j] = 0
    end
    pixels[i] = row
    old_pixels[i] = old_row
  end

  local blocks = {}
  local btps = {}

  local PlayerInit

  game.start.addListener(function()
    player.chat("Display V0.9.4",0x00aa00)

  --[[ GETTING BLOCKS ]]--

    local MAXY = 0

    do   
      local BlockID = 0
      local x = 0
      local y = 0
      local gbat = tolua(game.level.getBlockAt)
      while true do -- Loop over the provided blocks
        blocks[BlockID] = gbat(x,y)
        if not tolua(blocks[BlockID]) then
          break
        end
        btps[BlockID] = tolua(blocks[BlockID].teleporttopos) -- Cache teleporttopos
        x = x + 1
        if x >= 16 then
          x = 0
          y = y + 1
        end
        BlockID = BlockID + 1
      end
      MAXY = y
    end

  player.chat("Block Count: " .. #blocks,0xaa00aa)


  --[[ CONFIG VALIDITY CHECK ]]--

    do
      local a = (DISPLAY_CONFIG.x < 16)
      local b = (DISPLAY_CONFIG.x + DISPLAY_CONFIG.width) > 0
      local c = (DISPLAY_CONFIG.y < MAXY)
      local d = (DISPLAY_CONFIG.y + DISPLAY_CONFIG.height) > 0
      if (a and b and c and d) then
        player.chat("ERROR: Display collides with block storage!\nPlease move your display out of the way.",0xff0000)
        error()
      end
    end

    player.chat("Validity check complete!",0x00aaaa)

  --[[ FILLING DISPLAY AREA ]]--    

    do
      local xstart = DISPLAY_CONFIG.x
      local ystart = DISPLAY_CONFIG.y
      local xend = xstart + DISPLAY_CONFIG.width - 1
      local yend = ystart + DISPLAY_CONFIG.height - 1
      local a = -1
      local U = {}
      local bulktpt = tolua(blocks[0].bulkteleportto)
      for x = xstart,xend,1 do
        for y = ystart,yend,1 do
          a = a + 2
          U[a] = x
          U[a+1] = y
          if a > 4000 then
            bulktpt(false,true,unpack(U))
            U = {}
            a = -1
          end
        end
      end
      bulktpt(false,true,unpack(U))
      player.chat("Attempted to fill from (".. xstart ..", ".. ystart ..") to (".. xend ..", ".. yend ..")",0x0000aa)
    end

  --[[ SET PLAYER STUFF? ]]--

    PlayerInit = function()
      player.minimap = false -- hide minimap
      player.xpos = PLAYER_INFO.x -- place player at the intended position (:
      player.ypos = PLAYER_INFO.y
      player.xvelocity = 0
      player.xmove = 0
      player.yvelocity = 0
      player.ymove = 0
      
      player.disableup(200000000) -- lock player for 77 days
      player.disableleft(200000000)
      player.disableright(200000000)
      player.disabledown(200000000)

      player.stiffness = 0
      player.fov = 16.875 / PLAYER_INFO.Cw
      player.camerax = PLAYER_INFO.Cx
      player.cameray = PLAYER_INFO.Cy

      PLAYER_INFO.supplyKeyPressed(player.keypressed)
      PLAYER_INFO.supplyPlayerChat(player.chat)
      PLAYER_INFO.supplyPlayerAlert(player.alert)
      PLAYER_INFO.supplyPlayerPlaySound(player.playsound)

      local piss = player.playsound
      function display.playsound(i,v)
        piss(i,v)
      end

      player.tick.removeListener(PlayerInit)
    end

    player.tick.addListener(PlayerInit)

    --[[ CREATE RUNNER GARBAGE ]]--

    local program_initialized = false

    local RUN_P = true

    local keypressed
    do
      local kp = player.keypressed
      keypressed = function(key)
        return tolua(kp(keys[key]))
      end
    end
    
    local iCount = 25 -- ctrl to double, shift to 4x
    local do_Recov = false
    local xfrom = 0
    local xat = 0
    local yat = 0
    local xto = 0
    local yto = 0

    game.tick.addListener(function()
      if RUN_P == true then
        if not program_initialized then
          program_initialized = true
          if program_init then 
            if DO_ERROR_CHECKING then
              xpcall(program_init,function(err) player.chat(err,ERROR_COLOR) end)
            else 
              program_init() 
            end
          end
        end
        if do_Recov then
          do_Recov = false
          if program_recover then program_recover() end
        else
          if program_frame then 
            if DO_ERROR_CHECKING then
              xpcall(program_frame,function(err) player.chat(err,ERROR_COLOR) end)
            else 
              program_frame() 
            end
          end
        end
      else -- We do a little block filling
        local i = 0
        local ic = iCount
        if keypressed("SHIFT") then ic = ic * 4 end
        if keypressed("CONTROL") then ic = ic * 2 end
        while i < ic do
          i = i + 1
          btps[0](xat,yat,false,true)
          xat = xat + 1
          if xat > xto then xat = xfrom yat = yat + 1 if yat > yto then do_Recov = true RUN_P = true break end end
        end
      end
    end)

    --updater

    function DISPLAY_CONFIG.triggerNew(x,y,w,h)
      do
        local a = (x < 16)
        local b = (x + w) > 0
        local c = (y < MAXY)
        local d = (y + h) > 0
        if (a and b and c and d) then
          player.chat("ERROR: Display collides with block storage!\nPlease move your display out of the way.",0xff0000)
          error()
        end
      end
      player.chat("Display resolution updating to ".. w .. " x ".. h .." pixels.",0x0000aa)
      RUN_P = false
      display.x = x
      display.y = y
      display.width = w
      display.height = h
      xfrom = x
      xat = x
      yat = y
      xto = x + w - 1
      yto = y + h - 1
      pixels = {}
      old_pixels = {}

      display.pixels = pixels

      for i = 0,(h)-1,1 do
        local row = {}
        local old_row = {}
        for j = 0,(w)-1,1 do
          row[j] = 0
          old_row[j] = 0
        end
        pixels[i] = row
        old_pixels[i] = old_row
      end
    end

    --[[ Display getblock ]]--

    do
      local gbat = game.level.getBlockAt
      function display.getblock(x,y)
        return gbat(display.x + x, display.y + y)
      end
    end

    --[[ END OF GAME.START ]]--
    
  end)

  --[[ define garbage ]] --

  function display.setpixel(x,y,i)
    local r = pixels[y]
    if r then
      if r[x] then r[x] = i end
    end
  end

  function display.fillrect(x1,y1,x2,y2,i)
    if x1 < 0 then x1 = 0 end
    if y1 < 0 then y1 = 0 end
    if x2 >= display.width then x2 = display.width - 1 end
    if y2 >= display.height then y2 = display.height - 1 end
    for y = y1,y2,1 do
      local row = pixels[y]
      for x = x1,x2,1 do
        row[x] = i
      end
    end
  end

  function display.updatepixel(x,y)
    local nval = pixels[y][x]
    if nval ~= old_pixels[y][x] then
      old_pixels[y][x] = nval
      btps[nval](display.x + x,display.y + y,false,true)
    end
  end

  function display.updaterect(x1,y1,x2,y2)
    local disp_x = display.x
    local disp_y = display.y
    if x1 < 0 then x1 = 0 end
    if y1 < 0 then y1 = 0 end
    if x2 >= display.width then x2 = display.width - 1 end
    if y2 >= display.height then y2 = display.height - 1 end
    for y = y1,y2,1 do
      local newrow = pixels[y]
      local oldrow = old_pixels[y]
      for x = x1,x2,1 do
        local nv = newrow[x]
        if nv ~= oldrow[x] then
          oldrow[x] = nv
          btps[nv](disp_x + x, disp_y + y, false, true)
        end
      end
    end
  end

  function display.getpixel(x,y)
    return pixels[y][x]
  end

  function display.setcamera(x,y,s)
    if x then
      player.camerax = x - 8.4375
    end
    if y then
      player.cameray = y - 6
    end
    if s then
      player.chat("Set fov to ".. 16.875/s)
      player.fov = 16.875/s
    end
  end

  function display.getcamera()
    return tolua(player.camerax) + 8.4375,tolua(player.cameray) + 6,16.875/tolua(player.fov)
  end

  function display.updatepixels()
    local disp_x = display.x
    local disp_y = display.y
    local disp_width = display.width - 1
    local disp_height = display.height - 1
    for y = 0,disp_height,1 do
      local newrow = pixels[y]
      local oldrow = old_pixels[y]
      for x = 0,disp_width,1 do
        local nv = newrow[x]
        if nv ~= oldrow[x] then
          oldrow[x] = nv
          btps[nv](disp_x + x, disp_y + y, false, true)
        end
      end
    end
  end

  function display.newscreen(x,y,w,h,c)
    local x = x or display.x
    local y = y or display.y
    local w = w or display.width
    local h = h or display.height
    if w > 0 and h > 0 then
      DISPLAY_CONFIG.triggerNew(x,y,w,h)
    end
    if c then
      player.camerax = x + w/2 - 8.4375
      player.cameray = y + h/2 - 6
      player.fov = 16.875/(2*w)
    end
  end

  function display.updateByLists(lists,lens)
    local dx = display.x
    local dy = display.y
    for i = 0, (DISPLAY.height - 1) do
      local l = lens[i]
      if l > 0 then
        local list = lists[i]
        local row = pixels[i]
        local owo = old_pixels[i]
        for listpos = 1,l do
          local x = list[listpos]
          local npix = row[x]
          if npix ~= owo[x] then
            owo[x] = npix
            btps[npix](dx + x, dy + i, false, true)
          end
        end
      end
    end
  end

  --[[ Define some auxiliary stuff ]]--

  aux.chartable = {
    ["!"] = 80,
    ['"'] = 81,
    ["#"] = 82,
    ["$"] = 83,
    ["%"] = 84,
    ["&"] = 85,
    ["'"] = 86,
    ["("] = 87,
    [")"] = 88,
    ["*"] = 89,
    ["+"] = 90,
    [","] = 91,
    ["-"] = 92,
    ["."] = 93,
    ["/"] = 94,
    ["0"] = 95,
    ["1"] = 96,
    ["2"] = 97,
    ["3"] = 98,
    ["4"] = 99,
    ["5"] = 100,
    ["6"] = 101,
    ["7"] = 102,
    ["8"] = 103,
    ["9"] = 104,
    [":"] = 105,
    [";"] = 106,
    ["<"] = 107,
    ["="] = 108,
    [">"] = 109,
    ["?"] = 110,
    ["@"] = 111,
    a = 112,
    b = 113,
    c = 114,
    d = 115,
    e = 116,
    f = 117,
    g = 118,
    h = 119,
    i = 120,
    j = 121,
    k = 122,
    l = 123,
    m = 124,
    n = 125,
    o = 126,
    p = 127,
    q = 128,
    r = 129,
    s = 130,
    t = 131,
    u = 132,
    v = 133,
    w = 134,
    x = 135,
    y = 136,
    z = 137,
    ["["] = 138,
    ["\\"] = 139,
    ["]"] = 140,
    ["^"] = 141,
    ["_"] = 142,
    ["`"] = 143,
    ["{"] = 144,
    ["|"] = 145,
    ["}"] = 146,
    ["~"] = 147,
  }


end

--[[
DISPLAY REFERENCE

  Provided display functions:
    display.setpixel(int x, int y, int i)
      Set pixel on the screen at (x,y) to value i
      Does not update the block, see updatepixel for that

    display.fillrect(int x1, int y1, int x2, int y2, int i)
      Fills the pixels within the rectangle from (x1,y1) to (x2,y2)
      x2 must be greater than or equal to x1, y2 must be greater than or equal to y1.
      WARNING: Can be slow if you attempt to fill large areas

    display.updatepixel(int x, int y)
      Updates the pixel on the screen at (x,y)

    display.updaterect(int x1, int y1, int x2, int y2)
      Updates the pixels within the rectangle from (x1,y1) to (x2,y2)
      x2 must be greater than or equal to x1, y2 must be greater than or equal to y1.
      WARNING: Can be slow if you attempt to update large areas.

    display.getpixel(int x, int y)
      Get value for pixel on the screen at (x,y)

    display.getblock(int x, int y)
      Get the block object for pixel on the screen at (x,y)

    display.playsound(int i, number v)
      Play sound of id i at volume v

    display.setcamera(number x, number y, number w)
      Set center of camera to (x,y) and sets FOV based on w.
      w is the amount of blocks that can fit on screen horizontally.
      If a value is not provided, it stays the same.

    display.getcamera()
      Returns 3 values: x pos, y pos, and camera width.
      Position values describe the center of the camera.
      Camera width is the amount of blocks that can fit on screen.

    display.updatepixels()
      Updates every pixel on screen.
      WARNING: Can be slow at higher screen sizes.

    display.newscreen(int x, int y, int width, int height, boolean update_camera)
      Changes the display to have new properties.
      Any values not provided will use the existing values.
      If update_camera is true, the camera will automatically be moved.


  Provided display variables:
    display.x
      The absolute x position of the top left of the screen.

    display.y
      The absolute y position of the top left of the screen.

    display.width
      The width of the screen in blocks.

    display.height
      The height of the screen in blocks.

    display.pixels
      The table containing all pixel data. Don't do stupid shit.

  Provided auxiliary functions:
    aux.keypressed(key)
      Takes a string keycode and returns whether that key is pressed
      See https://pr3hub.com/lua/modules/utils.html#keys for reference
    
    aux.chat(string,color)
      Takes a string and color and prints it to chat.
      Does not work when level lua is being run.

    aux.alert(string)
      Takes a string and prints it as an alert.
      Does not work when level lua is being run.
  
  Provided auxiliary variables:
    aux.chartable
      Table containing block IDs for single characters.
      (can be used to help implement something like print)

  Functions you define:
    program_recover
      A function that is called after a new display is made.
      This allows your program to redraw what it needs to immediately.

    program_frame
      A function that is called on every frame.
      This is where your program should run.

    program_init
      A function that is called at the start.
      This is where you should set player variables as needed.

  Other information:
    DISPLAY is an alias for display because it looks cooler and more important to use all caps.


]]--

function math.lerp(a,b,m)
  return a + m*(b-a)
end

--[[ END DISPLAY GARBAGE ]] --

  --[[PRINT DEF]]--
  
  local print
  
  do
    local sub = string.sub
    local ctab = aux.chartable
    print = function(str,x,y,x_end,y_end)
      local x = x or 0
      local y = y or 0
      local x_end = x_end or display.width
      local y_end = y_end or display.height
      local x_max = x
      local xat = x - 1
      local yat = y
      local l = #str
      local str = str:lower()
      local pixrow = display.pixels[yat]
      local i = 1
      while i <= l do
        xat = xat + 1
        local char = sub(str,i,i)
        if char == "\n" or xat == x_end then
          if xat ~= x_end then i = i + 1 end
          yat = yat + 1
          xat = x - 1
          pixrow = display.pixels[yat]
          if yat == y_end then
            break
          end
        else
          if xat > x_max then x_max = xat end
          local blockID = ctab[char]
          i = i + 1
          if blockID then
            pixrow[xat] = blockID
          end
        end
      end
      return {x,y,x_max,yat}
    end
  end

  --[[END PRINT DEF]]--

-- Put your program here!

  --[[ BEGIN ORBIT PROGRAM ]]--

local SCENE = "NONE"
local FRAME_COUNTER = 0

local playerScore = 0

--[[
PERSONAL REFERENCE

print(str,x,y,x_end,y_end) -- Returns box where printed stuff is at.

DISPLAY_CONFIG.width = 80
DISPLAY_CONFIG.height = 60
]]--

local SCENE_INIT = {
  menu = function()
    display.setcamera(nil,nil,101)
    local box = print("orbit",38,20)
    display.updaterect(unpack(box))
    box = print("press space to play",31,45)
    display.updaterect(unpack(box))
  end,
  game = function()
    display.fillrect(15,2,65,46,0)
    display.updatepixels()
    aux.chat("Move with WASD or arrow keys. Rotate orbs with Q/E",0x00aaaa)
  end,
  score = function()
    display.fillrect(0,0,79,59,0)
    local pstr = "Your score is " .. playerScore
    print(pstr,40 - math.floor((#pstr)/2),20)
    display.updatepixels()
    aux.chat("Game over!",0xaa0000)
  end,
}

local setScene

local SCENE_FRAME = {}

do  --[[ MENU SCENE: FRAME ]]--
  local theta = (math.pi * 0.5)
  local RATE = 0.035
  local RAD = 16
  local CX = 40
  local CY = 20
  local sin = math.sin
  local cos = math.cos
  local floor = math.floor
  local min = math.min
  local max = math.max
  local OFF = {0,math.pi}
  local COL = {24,68}

  SCENE_FRAME["menu"] = function()
    for i=1,#OFF do
      local o = OFF[i]
      local x = floor(RAD*cos(theta + o) + 0.5) + CX
      local y = floor(RAD*sin(theta + o) + 0.5) + CY
      local nx = floor(RAD*cos(theta + RATE + o) + 0.5) + CX
      local ny = floor(RAD*sin(theta + RATE + o) + 0.5) + CY
      display.fillrect(x-1,y-1,x+1,y+1,0)
      display.fillrect(nx-1,ny-1,nx+1,ny+1,COL[i])
      display.updaterect(min(x-1,nx-1),min(y-1,ny-1),max(x+1,nx+1),max(y+1,ny+1))
    end
    --
    if aux.keypressed("SPACE") then
      aux.chat("Start game!")
      setScene("game")
    end
    --
    theta = theta + RATE
  end

end



do --[[ GAME SCENE: FRAME ]]--
  local gameFrames = 0

  -- Function caches
  local min = math.min
  local max = math.max -- kitty :3
  local sin = math.sin
  local cos = math.cos
  local lerp = math.lerp
  local floor = math.floor
  local sqrt = math.sqrt

  -- Player data
  local HEALTH = 3
  local playerPos = {x = 40, y = 30}
  local playerTarget = {x = 40, y = 30} -- Also determines orb target
  local playerFactor = 0.15
  local scoreMultiplier = 1
  local multTime = 600 -- How many frames between multiplier increase

  -- Orb Data
  local orbCount = 1
  local orbPos = {{x = 40, y = 30}}
  local orbFactor = 0.12
  local orbDistance = 8
  local orbAngle = 0 -- Determines orb target.
  local orbTime = 600 -- How many frames between new orb?
  local orbColors = {24,68,19,31,67,76,148} -- red yellow pink cyan

  

  -- Enemy data
  local objList = {length = 0}

  -- Individual enemy: {x = val, y = val, c = val}

  -- Rendering garbage
  local DrawQueue = {}
  local DQLength = 0
  local UpdateQueue = {}
  local QueueLength = 0

  local function collides(obj)
    local x,y,c = obj.x, obj.y, obj.c
    local orb = orbPos[c]
    if orb then
      local dx,dy = x - orb.x, y - orb.y
      local distance = dx*dx + dy*dy
      if distance < 2 then
        return 1
      end
    end
    dx,dy = x - playerPos.x, y - playerPos.y
    distance = dx*dx + dy*dy
    if distance < 3 then
      return 2
    end
    return 0
  end
  --[[ collides(obj)
    Returns 0 if no important collision
    Returns 1 if collision with corresponding orb (Clears object, increments score)
    Returns 2 if collision with central orb (Clears entire object list, decrements health)
  ]]--

  local PLAYER_VELOCITY = 0.5
  local PLAYER_TURNVELOCITY = 0.1

  local function handlePlayer()
    if gameFrames%multTime == 0 then
      scoreMultiplier = scoreMultiplier + 1
    end
    local keypressed = aux.keypressed
    if keypressed("W") or keypressed("UP") then
      playerTarget.y = playerTarget.y - PLAYER_VELOCITY
    end
    if keypressed("A") or keypressed("LEFT") then
      playerTarget.x = playerTarget.x - PLAYER_VELOCITY
    end
    if keypressed("S") or keypressed("DOWN") then
      playerTarget.y = playerTarget.y + PLAYER_VELOCITY
    end
    if keypressed("D") or keypressed("RIGHT") then
      playerTarget.x = playerTarget.x + PLAYER_VELOCITY
    end
    playerTarget.x = max(1,min(79,playerTarget.x))
    playerTarget.y = max(1,min(59,playerTarget.y))
    if keypressed("Q") then
      orbAngle = orbAngle - PLAYER_TURNVELOCITY
    end
    if keypressed("E") then
      orbAngle = orbAngle + PLAYER_TURNVELOCITY
    end
    local oldX,oldY = playerPos.x,playerPos.y
    local newX = lerp(oldX,playerTarget.x,playerFactor)
    local newY = lerp(oldY,playerTarget.y,playerFactor)
    playerPos.x = newX; playerPos.y = newY;
    oldX,oldY,newX,newY = floor(oldX),floor(oldY),floor(newX),floor(newY)
    DQLength = DQLength + 2
    DrawQueue[DQLength] = {oldX-1,oldY-1,oldX+1,oldY+1,0}
    DrawQueue[DQLength - 1] = {newX-1,newY-1,newX+1,newY+1,79}
    QueueLength = QueueLength + 1
    UpdateQueue[QueueLength] = {min(oldX-1,newX-1),min(oldY-1,newY-1),max(oldX+1,newX+1),max(oldY+1,newY+1)}
  end

  local function handleOrbs()
    if gameFrames%orbTime == 0 and orbCount < 6 then
      orbCount = orbCount + 1
      orbPos[orbCount] = {x = playerPos.x, y = playerPos.y}
    end
    for i = 1, orbCount do
      local orbP = orbPos[i]
      local targetAngle = orbAngle + (i-1)*6.28318530717959/orbCount
      local targetX = orbDistance * cos(targetAngle) + playerTarget.x
      local targetY = orbDistance * sin(targetAngle) + playerTarget.y
      local oldX,oldY = orbP.x,orbP.y
      local newX,newY = lerp(oldX,targetX,orbFactor),lerp(oldY,targetY,orbFactor)
      orbP.x = newX; orbP.y = newY;
      oldX,oldY,newX,newY = floor(oldX+0.5),floor(oldY+0.5),floor(newX+0.5),floor(newY+0.5)
      DQLength = DQLength + 2
      DrawQueue[DQLength] = {oldX-1,oldY-1,oldX,oldY,0}
      DrawQueue[DQLength - 1] = {newX-1,newY-1,newX,newY,orbColors[i]}
      QueueLength = QueueLength + 1
      UpdateQueue[QueueLength] = {min(oldX-1,newX-1),min(oldY-1,newY-1),max(oldX,newX),max(oldY,newY)}
    end
  end

  local function spawnEnemy()
    local newX = math.random(0,40)
    if newX > 20 then
      newX = newX + 60
    else
      newX = newX - 21
    end
    local newY = math.random(0,30)
    if newY > 15 then
      newY = newY + 60
    else
      newY = newY - 16
    end
    local newCol = math.random(1,orbCount)
    objList.length = objList.length + 1
    objList[objList.length] = {x = newX, y = newY, c = newCol}
  end

  local lastSpawn = 0
  local enemySpeed = 0.2

  local function handleEnemies()
    local preEnemyDQLength = DQLength
    if math.random() < (0.014 + scoreMultiplier/1000) or (gameFrames - lastSpawn) > 90 then
      lastSpawn = gameFrames
      spawnEnemy()
    end
    local modifiedSpeed = enemySpeed + (scoreMultiplier/150)
    for i=objList.length,1,-1 do -- Reverse traversal allows gaming.
      local obj = objList[i]
      local oldX, oldY = obj.x,obj.y
      local dx,dy = playerPos.x - oldX, playerPos.y - oldY
      local dist = sqrt(dx*dx + dy*dy)
      obj.x = oldX + modifiedSpeed*dx/dist; obj.y = oldY + modifiedSpeed*dy/dist;
      local c = collides(obj)
      if c == 1 then
        table.remove(objList,i)
        DQLength = DQLength + 1
        DrawQueue[DQLength] = {floor(oldX+0.5),floor(oldY+0.5),0}
        QueueLength = QueueLength + 1
        UpdateQueue[QueueLength] = {floor(oldX+0.5),floor(oldY+0.5)}
        aux.playsound(38,1)
        playerScore = playerScore + scoreMultiplier
        objList.length = objList.length - 1
      elseif c == 2 then
        DQLength = preEnemyDQLength + 1
        QueueLength = 1
        DrawQueue[DQLength] = {0,0,79,59,0}
        UpdateQueue[QueueLength] = {0,0,79,59}
        aux.playsound(3,2.5)
        objList = {length = 0}
        HEALTH = HEALTH - 1
        break
      else
        local newX,newY = obj.x,obj.y
        DQLength = DQLength + 2
        DrawQueue[DQLength] = {floor(oldX+0.5),floor(oldY+0.5),0}
        DrawQueue[DQLength - 1] = {floor(newX+0.5),floor(newY+0.5),orbColors[obj.c]}
        QueueLength = QueueLength + 2
        UpdateQueue[QueueLength] = {floor(oldX+0.5),floor(oldY+0.5)}
        UpdateQueue[QueueLength - 1] = {floor(newX+0.5),floor(newY+0.5)}
      end
    end
  end

  local function handleUpdates()
    for i = DQLength,1,-1 do
      local dreq = DrawQueue[i]
      DrawQueue[i] = nil
      if #dreq == 5 then
        display.fillrect(unpack(dreq))
      elseif #dreq == 3 then
        local ux, uy, uc = unpack(dreq)
        if ux >= 0 and ux < 80 and uy >= 0 and uy < 60 then
          display.setpixel(ux,uy,uc)
        end
      else
        aux.chat("WARNING! Malformed draw request! Printed content dump.",0xff0000)
        local eStr = ""
        for j=1,#dreq do
          eStr = eStr .. "\n" .. i .. ": ".. dreq[i]
        end
        aux.chat("ID: ".. i .. "\nLength: ".. #dreq .. eStr)
      end
    end
    DQLength = 0
    local b1 = print(tostring(playerScore),0,0)
    local b2 = print(tostring(scoreMultiplier) .. "x",0,59)
    display.updaterect(unpack(b1))
    display.updaterect(unpack(b2))
    for i = QueueLength,1,-1 do
      local box = UpdateQueue[i]
      UpdateQueue[i] = nil
      if #box == 4 then
        display.updaterect(unpack(box))
      elseif #box == 2 then
        local ux, uy = unpack(box)
        if ux >= 0 and ux < 80 and uy >= 0 and uy < 60 then
          display.updatepixel(ux,uy)
        end
      else
        aux.chat("WARNING! Malformed update request! Printed content dump.",0xff0000)
        local eStr = ""
        for j=1,#box do
          eStr = eStr .. "\n" .. i .. ": ".. box[i]
        end
        aux.chat("ID: ".. i .. "\nLength: ".. #box .. eStr)
      end
    end
    QueueLength = 0
  end

  SCENE_FRAME["game"] = function()
    gameFrames = gameFrames + 1
    handlePlayer()
    handleOrbs()
    handleEnemies()
    if HEALTH == 0 then
      setScene("score")
      return
    end
    handleUpdates()
  end

end

SCENE_FRAME["NONE"] = function()
  if FRAME_COUNTER > 0 then
    setScene("menu")
  end
end

SCENE_FRAME["score"] = function()

end

setScene = function(name)
  if SCENE_INIT[name] then SCENE_INIT[name]() end
  if SCENE_FRAME[name] then SCENE = name end
end

function program_init()
  player.alert("Oh noes! Evil spiky things are attacking you. (You just so happen to be a white blob that can spawn dots of various colors that oh so handily kill evil spiky things.)")
end


function program_frame()
  SCENE_FRAME[SCENE]()
  FRAME_COUNTER = FRAME_COUNTER + 1
end

  --[[ END ORBIT PROGRAM ]]--
