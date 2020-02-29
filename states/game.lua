local note_speed = 260 --pixels per seconds
local note_width, note_height = 50, 8
local note_spacing = 10
local note_y = 40

local note_offset = {
    left = -100 - note_spacing - note_spacing / 2,
    down = -50 - note_spacing / 2,
    up = 0 + note_spacing / 2,
    right = 50 + note_spacing + note_spacing / 2
}

--TODO whenever a bad note pressed, a note should be played but u hit the wrong one, emit red, and count it as a miss, even if also the correct notes were played to prevent note spamming

local start_wait_duration = 1
local end_wait_duration = 1

function math.round(number) --you should really give it another name though
    return math.floor(number + 0.5)
end

local function round_second_decimal(number)
    return math.round(number * 100) * 0.01
end

local state = {}

function state:on_first_enter()
    self.okay_time = 0.1 --how much grace time allowed to let player hit note?
    self.perfect_time = 0.05
    self.great_time = 0.08

    local white_canvas = love.graphics.newCanvas(note_width, note_height)

    love.graphics.setCanvas(white_canvas)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, white_canvas:getDimensions())
    love.graphics.setCanvas()

    self.particles = love.graphics.newParticleSystem(love.graphics.newImage(white_canvas:newImageData()), 4)
    self.particles:setParticleLifetime(0.12)
    self.particles:setSizes(0.9, 1.1)
    self.particles:setColors(colors.blue[1], colors.blue[2], colors.blue[3], 1, 1, 1, 1, 1)
end

function state:on_enter(song_name)

    local bpm

    if song_name == "bits_1" then
        bpm = 160
    elseif song_name == "bits_2" then
        bpm = 165
    elseif song_name == "boss_6" then
        bpm = 105
    elseif song_name == "some_piano" then
        bpm = 103
    else
        assert("Telly Tubby Alert")
    end

    bpm = bpm * 8

    local bps = bpm / 60
    local interval = 1 / bps

    self.current_song_name = song_name
    self.current_song = assets.audio[song_name]
    self.current_beatmap = table.copy(beatmaps[song_name])
    self.current_notes = {}

    self.song_duration = self.current_song:getDuration()
    self.time_passed = 0
    self.combo = 0
    self.max_combo = 0
    self.misses = 0
    self.score = 0
    self.perfect = 0
    self.good = 0
    self.great = 0

    self.hit_text = ""

    self.health = 50
    self.max_health = 100

    self.song_started_playing = false
    self.paused = true

    local count = 0

    for k, v in pairs(self.current_beatmap) do
        local remainder = v[1] % interval

        if remainder < interval / 2 then
            v[1] = v[1] - (v[1] % interval) --this quantizes to nearest whole note
            print(v[1])
        else
            v[1] = v[1] - (v[1] % interval) + interval--this quantizes to nearest whole note
            print(v[1])
        end

        table.insert(self.current_notes, {
            x = center_x + note_offset[v[2]],
            start_y = v[1] * note_speed + note_y + (note_speed * start_wait_duration),
            y = v[1] * note_speed + note_y + (note_speed * start_wait_duration),
            w = note_width,
            h = note_height,
            alpha = 1,
            key = v[2],
            time = v[1],
            color = v[1] % interval == 0 and colors.pink or colors.blue --whole notes
                --v[1] % interval / 2 == 0 and colors.blue --half notes
        })
    end

    self.current_song:setVolume(0.2)

    fade_in(fade_time, function()
        self.paused = false
    end)
end

local highscore_font = assets.fonts[18]
local combo_font = love.graphics.newFont(24)
local health_w, health_h = 200, 20
local health_x, health_y = center_x - health_w / 2, 5

function state:draw()
    self:draw_arrows()
    self:draw_notes()
    self:draw_healthbar()
    self:draw_particles()
    self:draw_text()
end

function state:draw_particles()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.particles, 0, 0)
end

function state:draw_text()
    love.graphics.setFont(combo_font)

    love.graphics.setColor(1, 1, 1)
    draw_shadowed_text(nil, "x" .. self.combo, 535, 28)
    draw_shadowed_text(nil, self.hit_text, 530, 69)

    local score = math.ceil(self.score)
    love.graphics.setFont(highscore_font)
    draw_shadowed_text(colors.blue, score, center_x - highscore_font:getWidth(score) / 2, health_y)
end

function state:draw_notes()
    for _, note in pairs(self.current_notes) do
        if note.y < scr_h then
            love.graphics.setColor(note.color)
            love.graphics.rectangle("fill", note.x, note.y, note.w, note.h)
            --love.graphics.print(_, note.x, note.y)
        end
    end
end

function state:draw_arrows() 
    love.graphics.setColor(1, 1, 1)

    for direction, offset in pairs(note_offset) do
        love.graphics.rectangle("line", center_x + offset, note_y, note_width, note_height)
    end
end

function state:draw_healthbar()
    local fraction = self.health / self.max_health
    local health_width = health_w * fraction

    love.graphics.setColor(colors.pink)
    love.graphics.rectangle("fill", center_x - health_width / 2, health_y, health_width, health_h)
end

function state:update(dt)
    if not self.paused then
        self.particles:update(dt)

        self.time_passed = self.time_passed + dt

        if not self.song_started_playing then 
            if self.time_passed >= start_wait_duration then
                self.song_started_playing = true
                self.current_song:seek(self.time_passed - start_wait_duration)
                self.current_song:play()
            end
        end

        for _, note in pairs(self.current_notes) do
            note.y = note.y - note_speed * dt
        end

        local note = self.current_notes[1]

        if note and note.y < note_y - (note_speed * self.okay_time) then
            table.remove(self.current_notes, 1)

            self.combo = 0
            self.misses = self.misses + 1
            self.hit_text = "MISS"
            self.health = math.max(self.health - 2, 0)
        end

        --state change needs to happen last in state:update() or else bad things will happen at hogwarts.
        if self.time_passed >= self.current_song:getDuration() + end_wait_duration then
            self.paused = true

            fade_out(fade_time, function()
                states.set_current_state("score_screen", self.current_song_name, {
                    max_combo = self.max_combo,
                    score = math.ceil(self.score),
                    perfect = self.perfect,
                    great = self.great,
                    good = self.good,
                    misses = self.misses
                })
            end)

            if file then
                io.write("}\nreturn beats")
                io.close(file)
                file = nil
                print("stopping recording")
            end
        end
    end
end

local keys = {
    left = true,
    down = true,
    up = true,
    right = true
}

local last_time

function state:keypressed(key)
    if not self.paused then
        local scheme = controls[current_control_scheme]

        if scheme[key] then
            self.particles:setPosition(center_x + note_offset[scheme[key]] + note_width / 2, note_y + note_height / 2)
            self.particles:emit(1)

            if file then
                if last_time and math.abs(self.current_song:tell() - last_time) <= 0.1 then
                    io.write(string.format("\t{%s, '%s'},\n", round_second_decimal(last_time), scheme[key]))
                else
                    io.write(string.format("\t{%s, '%s'},\n", round_second_decimal(self.current_song:tell()), scheme[key]))
                end

                last_time = self.current_song:tell()
            else
                for i = 1, 10 do
                    local note = self.current_notes[i]
            
                    if note then
                        if note.key == scheme[key] then
                            local absolute_time = math.abs(note.time - self.current_song:tell())

                            if absolute_time <= self.okay_time then
                                local score_gain = 5
                                self.hit_text = "Good"

                                table.remove(self.current_notes, i)

                                self.combo = self.combo + 1

                                if self.combo > self.max_combo then
                                    self.max_combo = self.combo
                                end

                                if absolute_time <= self.perfect_time then
                                    score_gain = 30
                                    self.hit_text = "PERFECT"
                                    self.perfect = self.perfect + 1
                                elseif absolute_time <= self.great_time then
                                    score_gain = 10
                                    self.hit_text = "Great"
                                    self.great = self.great + 1
                                else
                                    --then tis only a good
                                    self.good = self.good + 1
                                end

                                self.score = self.score + score_gain * (self.combo / 50 + 1)
                                self.health = math.min(self.max_health, self.health + 1)

                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if key == "r" then

            --this is how we create beatmaps at hogwarts.
        if file then
            io.close(file)
        end

        self.current_song:seek(0)
 
        file = io.open(self.current_song_name .. ".lua", "w")
        io.output(file)
        io.write("local beats = {\n")

        print("recording now")

    end

    if key == "escape" then
        fade_out(fade_time, function()
            states.set_current_state("menu")
        end)
    end
end

function state:on_state_changed()
    self.current_song:stop()
end

function state:quit()
    if file then
        file:close()
    end
end

return state