assets = require("assets")
states = require("libraries.state")
timer = require("libraries.vendor.timer")

--color code notes based on their interval
--

local function load_beatmaps()
    beatmaps = {}

    for _, file_name in pairs(love.filesystem.getDirectoryItems("beatmaps")) do
        local song_name = file_name:sub(1, -5)
        beatmaps[song_name] = require("beatmaps/" .. song_name)        
    end
end

local function load_highscores()
    highscores = {}

    local chunk, error = love.filesystem.load("highscores.txt")

    if not error then
        setfenv(chunk, highscores)()
    end
end

function save_highscore(song_name, highscore)
    local save_string = string.format(song_name .. "=" .. highscore .. "\n")

    if love.filesystem.getInfo("highscores.txt") then
        --todo, not this...
        --instead figure out what line the previous score is on, replace the score with new highscore.
        love.filesystem.append("highscores.txt", save_string)
    else
        love.filesystem.write("highscores.txt", save_string)
    end

    highscores[song_name] = tonumber(highscore)
end

local function load_ranks()
    ranks = {}

    local chunk, error = love.filesystem.load("ranks.txt")

    if not error then
        setfenv(chunk, ranks)()
    end
end

function save_rank(song_name, rank)
    local save_string = string.format(song_name .. "='" .. rank .. "'\n")

    if love.filesystem.getInfo("ranks.txt") then

        love.filesystem.append("ranks.txt", save_string)
    else
        love.filesystem.write("ranks.txt", save_string)
    end

    ranks[song_name] = rank
end

local alpha = {0}
local alpha_timer = nil
fade_time = 0.5

function fade_in(duration, after)
    if not alpha_timer then
        alpha_timer = timer.tween(duration, alpha, {0}, "linear", function()
            alpha_timer = nil
            after()
        end)
    end
end

function fade_out(duration, after)
    if not alpha_timer then
        alpha_timer = timer.tween(duration, alpha, {1}, "linear", function()
            alpha_timer = nil
            after()
        end)
    end
end

function get_rank(fraction)
    if fraction == 1 then
        return "SS"
    elseif fraction == 0.98 then
        return "S"
    elseif fraction >= 0.9 then
        return "A"
    elseif fraction >= 0.8 then
        return "B"
    elseif fraction >= 0.7 then
        return "C"
    elseif fraction >= 0.6 then
        return "D"
    end
end

function love.load()
    scr_w, scr_h = love.graphics.getDimensions()
    center_x, center_y = scr_w / 2, scr_h / 2

    colors = {
        pink = {1, 20 / 255, 147 / 255},
        blue = {82 / 255, 242 / 255, 242 / 2},
        background = {40 / 255, 31 / 255, 38 / 255}
    }

    white_canvas = love.graphics.newCanvas(1, 1)

    love.graphics.setCanvas(white_canvas)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 1, 1)
    love.graphics.setCanvas()

    love.graphics.setBackgroundColor(colors.background)
    love.graphics.setDefaultFilter("nearest", "nearest")

    load_beatmaps()
    load_highscores()
    load_ranks()

    states.load_states("states")
    states.set_current_state("splash")

    love.audio.setVolume(0.5)
end

local old_update = love.update

function love.update(dt)
    old_update(dt)
    timer.update(dt)
end

local old_draw = love.draw

function love.draw()
    old_draw()
    --welcome to hogwarts baby
    love.graphics.setColor(0, 0, 0, alpha[1])
    love.graphics.rectangle("fill", 0, 0, scr_w, scr_h)
end

local old_keypressed = love.keypressed

current_control_scheme = 1

controls = {
    {left = "left", down = "down", up = "up", right = "right"},
    {a = "left", s = "down", w = "up", d = "right"},
    {a = "left", s = "down", k = "up", l = "right"},
    {d = "left", f = "down", j = "up", k = "right"}
}

function love.keypressed(key)
    old_keypressed(key)

    if key == "z" then
        love.audio.setVolume(math.max(0, love.audio.getVolume() - 0.1))
    elseif key == "x" then
        love.audio.setVolume(math.min(love.audio.getVolume() + 0.1, 1))
    end

    if key == "tab" then
        current_control_scheme = (current_control_scheme % #controls) + 1
    end
end

function table.copy(t, copy)
    print(copy)
    local copy = copy or {}
   
    for k, v in pairs(t) do
        if type(v) == "table" then
        	copy[k] = {}
            table.copy(v, copy[k])
        else
        	copy[k] = v 
        end
    end

    return copy
end

function draw_shadowed_text(color, text, x, y)
    color = color or {love.graphics.getColor()}
    x, y = x or 0, y or 0

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + 2, y + 2)

    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end

function lerp(a, b, t) 
    return a * (1 - t) + b * t
end

function smooth_lerp(a, b, t)
    t = t ^ 2 * (3 - 2 * t)

    return lerp(a, b, t)
end