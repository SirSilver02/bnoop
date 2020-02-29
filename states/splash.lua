local image = assets.graphics.splash

local time_passed = 0
local lerp_duration = 0.8
local hold_duration = 1.6
local end_wait_duration = 0.5
local alpha = 1

local can_skip = false
local skip_duration = 1

local particles = love.graphics.newParticleSystem(love.graphics.newImage(white_canvas:newImageData()), 4)
particles:setPosition(162, 270)
particles:setParticleLifetime(1)
particles:setColors(1, 1, 0, 1, 1, 1, 1, 0)
particles:setSizes(0, 40, 20, 0)
particles:setSpin(math.pi)

local has_twinkled = false
local twinkle_time = lerp_duration + 0.4

local state = {}

function state:update(dt)
    time_passed = time_passed + dt

    if time_passed >= skip_duration then
        can_skip = true
    end

    if time_passed < lerp_duration then
        alpha = smooth_lerp(0, 1, math.min(1, time_passed / lerp_duration))
    elseif time_passed >= lerp_duration + hold_duration then
        alpha = smooth_lerp(1, 0, math.min(1, (time_passed - lerp_duration - hold_duration) / lerp_duration))
    end

    if time_passed >= lerp_duration * 2 + hold_duration + end_wait_duration then
        states.set_current_state("menu")
    end

    if time_passed >= twinkle_time then
        if not has_twinkled then
            has_twinkled = true
            particles:emit(1)

            particles:setRotation(math.pi / 4)
            particles:emit(1)

            local sound = assets.audio.sparkle:clone()
            sound:setVolume(0.2)
            sound:play()
        end
    end

    particles:update(dt)
end

local scale = scr_w / image:getWidth()

function state:draw()
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", 0, 0, scr_w, scr_h)

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, 0, 0, 0, scale, scale)

    love.graphics.draw(particles)
end

function state:keypressed(key)
    if can_skip then
        states.set_current_state("menu")
    end
end

function state:mousepressed(x, y, button)
    if can_skip then
        states.set_current_state("menu")
    end
end

return state