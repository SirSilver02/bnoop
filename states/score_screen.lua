local skip_duration = 1

local state = {}

function state:on_first_enter()
    self.particles = love.graphics.newParticleSystem(love.graphics.newImage(white_canvas:newImageData()), 100)
    self.particles:setParticleLifetime(1)
    self.particles:setDirection(-math.pi / 2)
    self.particles:setLinearAcceleration(-20, 200, 20, 200)
    self.particles:setSpeed(200)
    self.particles:setSpread(math.pi * 2)
    self.particles:setPosition(center_x, center_y)
    self.particles:setColors(1, 0, 0, 1, 0, 0, 0, 0)
    self.particles:setSizes(2, 1)
end

function state:on_enter(song_name, score_args)
    self.skip_duration = 1
    
    self.song_name = song_name
    self.score_args = score_args
    self.rank =  get_rank((self.score_args.perfect + self.score_args.great + self.score_args.good) / #beatmaps[song_name])

    self.lerping_args = {}

    for k, v in pairs(self.score_args) do
        self.lerping_args[k] = 0
    end

    self.time_passed = 0
    
    local highscore = highscores[song_name]
    local current_score = score_args.score

    if highscore then
        if highscore < current_score then
            print("Woooow wowww you beat your previous highscore! Let me emit some particles for you! (after a delay of course~)")
            save_highscore(song_name, current_score)
            save_rank(song_name, self.rank)
        end
    else
        save_highscore(song_name, current_score)
        save_rank(song_name, self.rank)
    end

    fade_in(fade_time, function()
        timer.tween(2, self.lerping_args, self.score_args, "linear", function()
            if highscore then
                if highscore < current_score then
                    self.particles:emit(100)

                    self.particle_timer = timer.every(2, function()
                        self.particles:emit(100)
                        --make those qt3.14s feel gud
                    end)
                end
            else
                self.particles:emit(100)

                self.particle_timer = timer.every(2, function()
                    self.particles:emit(100)
                    --make those qt3.14s feel gud
                end)
            end
        end)
    end)
end

function state:update(dt)
    self.time_passed = self.time_passed + dt
    self.particles:update(dt)
end

function state:draw()
    local font = assets.fonts[18]
    love.graphics.setFont(font)

    love.graphics.setColor(1, 1, 1)

    local args = self.lerping_args

    local text = "Perfect x" .. math.ceil(args.perfect)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2)

    local text = "Great x" .. math.ceil(args.great)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2 + font:getHeight())

    local text = "Good x" .. math.ceil(args.good)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2 + font:getHeight() * 2)

    local text = "Misses x" .. math.ceil(args.misses)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2 + font:getHeight() * 3)

    local text = "Max Combo x" .. math.ceil(args.max_combo)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2 + font:getHeight() * 4)

    local text = "Rank " .. self.rank
    love.graphics.print(text, center_x - font:getWidth(text) / 2, center_y - font:getHeight() / 2 + font:getHeight() * 5)

    local text = "Press any key to continue."
    love.graphics.print(text, center_x - font:getWidth(text) / 2, scr_h - font:getHeight() - 5)

    love.graphics.draw(self.particles)
end

function state:keypressed(key)
    if self.time_passed >= self.skip_duration then
        fade_out(fade_time, function()
            states.set_current_state("menu")
        end)
    else

    end
end

function state:on_state_changed()
    if self.particle_timer then
        timer.cancel(self.particle_timer)
        self.particle_timer = nil
    end
end

return state