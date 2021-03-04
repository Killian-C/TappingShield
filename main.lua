-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')

-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
love.graphics.setDefaultFilter("nearest")

-- Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio
if arg[#arg] == "-debug" then require("mobdebug").start() end

function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

function math.prandom(min, max) return love.math.random() * (max - min) + min end

function convertAngleRocketArc(pAngleArc) return 360 - pAngleArc end

function usinageShieldDeg(pX, pY, pR, pNbArcs, pShield)
  
  local i = 0
  local a1 = 0
  local a2 = 360 / pNbArcs
  
  for i=1,pNbArcs do
    local arc = {}
    arc.x = pX
    arc.y = pY
    arc.r = pR
    
    arc.a1 = a1
    arc.a2 = a2
    
    table.insert(pShield, arc)
    
    a1 = a2
    a2 = a2 + (360 / pNbArcs)
  end
  
end

function createArc(pX, pY, pR, pA1, pA2, pArcList)
  local arc = {}
  arc.x = pX
  arc.y = pY
  arc.r = pR
  arc.a1 = pA1
  arc.a2 = pA2
  arc.remove = false
  
  table.insert(pArcList, arc)
end

function createRocket(pPlanet, pRocketsList, pnbArcsShield)
  local vitesseRocket = math.prandom(2.8, 4)
  local rocket = {}
  rocket.distApparition = 550
  rocket.w = 0
  rocket.h = 0
  --temporaire
  rocket.r = 10
  --
  
  -- Génération aléatoire d'un angle en fonction du nb d'arcs du shield
  randomDirection = math.random(pnbArcsShield)
  coeffDirection = randomDirection - 1
  rocket.angle = (360/(pnbArcsShield*2)) + ((360/pnbArcsShield) * coeffDirection)
  
  local a = math.rad(rocket.angle)
  rocket.x = pPlanet.x + (math.cos(a)*rocket.distApparition)
  rocket.y = pPlanet.y - (math.sin(a)*rocket.distApparition)
  rocket.vx = vitesseRocket * math.cos(a)
  rocket.vy = vitesseRocket * math.sin(a)
  rocket.remove = false
  
  table.insert(pRocketsList, rocket)
end


function love.load()
  
  math.randomseed(love.timer.getTime())
  
  largeur_ecran = love.graphics.getWidth()
  hauteur_ecran = love.graphics.getHeight()
  
  gameState = true
  
  planet = {}
  planet.x = largeur_ecran / 2
  planet.y = hauteur_ecran / 2
  planet.r = 70
  planet.hover = false
  
  shield = {}
  nbArcs = 8
  arcRayon = 100 --rayon planete 70 + 30
  usinageShieldDeg(planet.x, planet.y, arcRayon, nbArcs, shield)
  shield.arc = {}
  shield.arc.number = 3
  
  rockets = {}
  nbRocketsOfThisLevel = 30
  nbRocketsRemaining = nbRocketsOfThisLevel
  launchTime = math.prandom(0.5, 1)
  
  mouse = {}
  mouse.x = 0
  mouse.y = 0
  clickIsDown = false
  
  angleDeg = 0
  
  timer = 0
  
end

function love.update(dt)
  
  --récup coordo souris
  mouse.x = love.mouse.getX()
  mouse.y = love.mouse.getY()
  

  
  --gestion des arcs
    --test angle degré + remise à zéro
  local a = math.deg(math.angle(planet.x, planet.y, mouse.x, mouse.y))
  if a < 0 then 
    angleDeg = a + 360
  else 
    angleDeg = a
  end
    --hover des arcs + créations
    --test planet hover
  if math.dist(planet.x, planet.y, mouse.x, mouse.y) <= (arcRayon) then
    planet.hover = true
  else
    planet.hover = false
  end
    --
  for i=1,#shield do
    local arc = shield[i]
    if angleDeg > arc.a1 and angleDeg < arc.a2 and planet.hover == true then
      arc.hover = true
      if love.mouse.isDown(1) and #shield.arc < shield.arc.number then 
        if clickIsDown == false then
          createArc(arc.x, arc.y, arc.r, arc.a1, arc.a2, shield.arc) 
          clickIsDown = true
        end
      else
          clickIsDown = false
      end
    else
      arc.hover = false
    end
  end
  
  for i=#shield.arc,1,-1 do
    local arc = shield.arc[i]
    arc.angle1 = convertAngleRocketArc(arc.a1)
    arc.angle2 = convertAngleRocketArc(arc.a2)
    for j=#rockets,1,-1 do
      local rocket = rockets[j]
      if rocket.angle < arc.angle1 and rocket.angle > arc.angle2 and math.dist(rocket.x, rocket.y, arc.x, arc.y) <= arcRayon then
        --if math.dist(rocket.x, rocket.y, arc.x + arcRayon, arc.y + arcRayon) <= (arcRayon - 1) then
          rocket.remove = true
          if rocket.remove == true then
            print("rocket removed")
            table.remove(rockets, j)
          end
          arc.remove = true
          if arc.remove == true then
            print("arc removed")
            table.remove(shield.arc, i)
          end
        --end
      end
    end
  end
  
  --gestion rockets
    --créations aléatoires
  timer = timer + dt
  if nbRocketsRemaining > 0 then
    if nbRocketsRemaining == nbRocketsOfThisLevel then
      createRocket(planet, rockets, nbArcs)
      nbRocketsRemaining = nbRocketsRemaining - 1
    elseif nbRocketsRemaining < nbRocketsOfThisLevel and timer >= launchTime then
      createRocket(planet, rockets, nbArcs)
      nbRocketsRemaining = nbRocketsRemaining - 1
      --définition d'un nv launchTime
      launchTime = launchTime + math.prandom(0.5,1)
    end
  end
    --déplacements
  for i=#rockets,1,-1 do
    rocket = rockets[i]
    rocket.x = rocket.x - rocket.vx
    rocket.y = rocket.y + rocket.vy
    
    if math.dist(planet.x, planet.y, rocket.x, rocket.y) <= planet.r then
      gameState = false
      rocket.remove = true
    end
    --suppresion
    if rocket.remove == true then
      print("rocket on the planet")
      table.remove(rockets, i)
    end
  end
  
  


end

function love.draw()
  
  --TEXTES DE TESTS
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(tostring(#shield.arc), 20, 20)
  love.graphics.print(tostring(#rockets), 20, 40)
  love.graphics.print(tostring(timer), 20, 80)
  love.graphics.print(tostring(nbRocketsRemaining), 20, 100)
  if #rockets > 0 and #shield.arc > 0 then
    love.graphics.print(tostring(math.dist(rockets[1].x, rockets[1].y, shield.arc[1].x + arcRayon, shield.arc[1].y + arcRayon)), 20, 120)
  end
  if #shield.arc > 0 then
    love.graphics.print(tostring(math.dist(mouse.x, mouse.y, shield.arc[1].x, shield.arc[1].y)), 20, 140)
  end
  --game over
  if gameState == false then
    love.graphics.print("GAME OVER !!!!", 20, 60)
  end
  --love.graphics.line(planet.x, planet.y, planet.x + (math.cos(math.rad(45))*550), planet.y + (math.sin(math.rad(45))*550))
  --love.graphics.line(planet.x, planet.y, planet.x + (math.cos(math.rad(45))*550), planet.y - (math.sin(math.rad(45))*550))
  --love.graphics.line(planet.x, planet.y, planet.x - (math.cos(math.rad(45))*550), planet.y + (math.sin(math.rad(45))*550))
  --love.graphics.line(planet.x, planet.y, planet.x - (math.cos(math.rad(45))*550), planet.y - (math.sin(math.rad(45))*550))
  ------------------------------------
  
  --Planète
  love.graphics.setColor(0,0,255)
  love.graphics.circle("fill", planet.x, planet.y, planet.r)
  
  --Shield limit
  love.graphics.setColor(255,255,255,0.2)
  for i=1,#shield do
    local arc = shield[i]
    love.graphics.arc("line", arc.x, arc.y, arc.r, math.rad(arc.a1), math.rad(arc.a2))
  end
  --Shield part hover
  love.graphics.setColor(255,255,0,0.5)
  for i=1,#shield do
    local arc = shield[i]
    if arc.hover == true and planet.hover == true then
      love.graphics.arc("line", planet.x, planet.y, arcRayon, math.rad(arc.a1), math.rad(arc.a2))
    end
  end
  
  --Shield Arc
  love.graphics.setColor(255,255,0,0.3)
  for i=1,#shield.arc do
    local arc = shield.arc[i]
    love.graphics.arc("fill", arc.x, arc.y, arc.r, math.rad(arc.a1), math.rad(arc.a2))
  end
  
  --Rockets
  love.graphics.setColor(255,0,0)
  for i=#rockets,1,-1 do
    local rocket = rockets[i]
    love.graphics.circle("fill", rocket.x, rocket.y, rocket.r)
  end
  
  
  
end

  
  


