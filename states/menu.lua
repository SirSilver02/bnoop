local state = {}

function state:on_first_enter()
    self.ordered_beatmaps = {}
    
    for song_name, beatmap in pairs(beatmaps) do
        table.insert(self.ordered_beatmaps, {
            song_name = song_name,
            highscore = highscores[song_name],
            --x,
            --y
            --w,
            --h = 
            --doing this change for tweening
        })
    end
    
    self.selected_index = 1
end

local volume = {0}
local volume_timer

function state:play_selected_song()
    self:stop_playing_selected_song()

    local song_name = self.ordered_beatmaps[self.selected_index].song_name

    self.playing_song = assets.audio[song_name]:clone()
    self.playing_song:setLooping(true)
    self.playing_song:setVolume(0)
    self.playing_song:play()

    volume[1] = 0

    if volume_timer then
        timer.cancel(volume_timer)
    end

    volume_timer = timer.tween(0.5, volume, {0.2}, "in-cubic")
end

function state:stop_playing_selected_song()
    if self.playing_song then
        self.playing_song:stop()
        self.playing_song = nil
    end
end

function state:on_enter()
    fade_in(0.5, function()
        self:play_selected_song()
        love.keyboard.setKeyRepeat(true)
    end)
end

function state:update(dt)
    if self.playing_song then
        self.playing_song:setVolume(volume[1])
    end
end

local song_w, song_h = 300, 60
local vertical_spacing = 10
local horizontal_spacing = 40

function state:draw()
    self:draw_beatmaps()
    self:draw_text()
end

function state:draw_beatmaps()
    local font = assets.fonts[18]
    love.graphics.setFont(font)

    for i = 1, #self.ordered_beatmaps do
        local minus_one = i - 1
        local x =  center_x - song_w / 2
        x = x + math.abs(self.selected_index - i) * horizontal_spacing
        local y = center_y - song_h / 2 + song_h * (i - 1) - song_h * (self.selected_index - 1) - (self.selected_index - i) * vertical_spacing

        if i == self.selected_index then
            love.graphics.setColor(colors.pink)
            love.graphics.rectangle("fill", x, y, song_w, song_h)
        end

        local song_name = self.ordered_beatmaps[i].song_name

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, y, song_w, song_h)

        draw_shadowed_text(nil, song_name, x + song_w / 2 - font:getWidth(song_name) / 2, y + 5)

        local rank = ranks[song_name]

        if rank then
            draw_shadowed_text(nil, rank, x + song_w / 2 - font:getWidth(rank) / 2, y + font:getHeight() + 5)
        end
    end
end

local controls_changed_text = "Controls updated."

function state:draw_text()
    local left, down, up, right

    for k, v in pairs(controls[current_control_scheme]) do
        if v == "left" then
            left = k
        elseif v == "down" then
            down = k
        elseif v == "up" then
            up = k
        elseif v == "right" then
            right = k
        end
    end

    local text = string.format("[%s] [%s] [%s] [%s] to play. Enter to select. Z/X for volume. Tab for controls.", left, down, up, right)
    local font = love.graphics.getFont()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, center_x - font:getWidth(text) / 2, scr_h - font:getHeight() - 5)

    local font = assets.fonts[48]
    local text = "bnoop"
    love.graphics.setFont(font)
    love.graphics.print(text, 80, 54)
end

function state:keypressed(key)
    local scheme = controls[current_control_scheme]

    if scheme[key] == "up" or scheme[key] == "left" then
        self.selected_index = self.selected_index - 1

        if self.selected_index == 0 then
            self.selected_index = #self.ordered_beatmaps
        end
        
        self:play_selected_song()

        local sound = assets.audio.click:clone()
        sound:setVolume(0.2)
        sound:play()

        --trying to tween the positions of hte menu buttons to move over time instead of "snapping" timer.tween(0.2)--

    elseif scheme[key] == "down" or scheme[key] == "right" then
        self.selected_index = (self.selected_index % #self.ordered_beatmaps) + 1
        self:play_selected_song()

        local sound = assets.audio.click:clone()
        sound:setVolume(0.2)
        sound:play()
    end

    if key == "return" or key == "space" then
        fade_out(0.5, function()
            local song_name = self.ordered_beatmaps[self.selected_index].song_name
            states.set_current_state("game", song_name)
        end)
    end
end

function state:on_state_changed()
    self:stop_playing_selected_song()
    love.keyboard.setKeyRepeat(false)
end

return state