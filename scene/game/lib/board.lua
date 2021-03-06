-- game.scene.board 

-- Our skateboard class

local M = {}

local color = require "com.ponywolf.ponycolor"
local composer = require "composer"

function M.new(instance, boardColor)
  local scene = composer.getScene(composer.getSceneName("current"))

  physics.addBody(instance, "dynamic", { friction = 1.0, bounce = 0.5, box = { halfWidth=64, halfHeight=8, x=0, y=8, angle=0 }, filter = { groupIndex = -1 } } )

  instance.isBoard = true
  instance.inAir = true
  instance.isJumping = true
  instance.level = false
  instance:setFillColor(color.hex2rgb(boardColor))

  function instance:reset()
    self.rotation = 0
    self:translate(0,-128)
    self.timeout = 0
    self.isUpsideDown = false  
  end

  function instance:postCollision(event)
    --print (event.force, event.other)
    if event.force > 0.15 and not self.isUpsideDown then
      if event.other.isRail then
        audio.play(scene.sounds.grind)
      else
        audio.play(scene.sounds.land)
      end
    end
  end

  function instance:collision(event)
    if event.phase == "began" then
      if event.other.isRail and not self.isUpsideDown then 
        scene.score:add(150)        
        self.isSparking = true
        self.isJumping = false
        self.inAir = false
      elseif event.other.isGround then
        self.isSparking = false
        self.inAir = false
        self.isJumping = false
        self.onRail = false
      end
    elseif event.phase == "ended" then
      if event.other.isRail then
        self.isSparking = false
        audio.play(scene.sounds.ride)
      end
      self.inAir = true
      --self.isJumping = true
    end
  end

  instance:addEventListener("collision") 
  instance:addEventListener("postCollision") 

  local lastEvent = {}
  local function key(event)
    --print(event.phase, event.keyName)
    if ( event.phase == lastEvent.phase ) and ( event.keyName == lastEvent.keyName ) then return false end  -- Filter repeating keys
    if event.phase == "down" and instance and not instance.isUpsideDown then
      if event.keyName == "right" then 
        instance.pump = true
        audio.play(scene.sounds.push)
      elseif event.keyName == "left" then 
        instance.level = true
      elseif (event.keyName == "space" or event.keyName:find("button")) and not instance.isJumping then 
        audio.play(scene.sounds.jump)
        instance.inAir = true
        instance.isJumping = true
        instance:applyForce( 0, -20.5, instance.x, instance.y )
      end
    elseif event.phase == "up" then 
      if event.keyName == "right" then
        instance.pump = false
      elseif event.keyName == "left" then 
        instance.level = false
      end
    end
    lastEvent = event
  end

  function instance:finalize()
    Runtime:removeEventListener("key", key)  
  end

  instance:addEventListener("finalize")
  Runtime:addEventListener("key", key)  

  return instance
end


return M