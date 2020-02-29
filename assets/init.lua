local fonts = {}

local assets = {
    audio       = {},

    fonts       = setmetatable({}, {
        __index = function(t, font_name)
            if type(font_name) == "number" then
                local font = love.graphics.newFont(font_name)
                rawset(t, font_name, font)

                return font
            end
            
            if fonts[font_name] then
                local useable_fonts = setmetatable({}, {
                    __index = function(t, size)
                        local font = love.graphics.newFont(fonts[font_name], size)
                        rawset(t, size, font)

                        return font
                    end
                })

                rawset(t, font_name, useable_fonts)

                return useable_fonts
            end
        end
    }),

    graphics    = {},
    maps        = {},
    shaders     = {}
}

local folder = (...):gsub("%.", "/")

for _, folder_name in pairs(love.filesystem.getDirectoryItems(folder)) do
    local folder_path = folder .. "/" .. folder_name

    if love.filesystem.getInfo(folder_path, "directory") then
        for _, file_name in pairs(love.filesystem.getDirectoryItems(folder_path)) do
            local file_path = folder_path .. "/" .. file_name
            file_name = file_name:gsub("%.(.+)", "")

            if folder_name == "audio" then
                assets[folder_name][file_name] = love.audio.newSource(file_path, "static")
            elseif folder_name == "fonts" then
                --assets[folder_name][file_name] = file_path
                fonts[file_name] = file_path
            elseif folder_name == "graphics" then
                    assets[folder_name][file_name] = love.graphics.newImage(file_path)
            elseif folder_name == "maps" then
                if file_path:find("lua") then
                    file_path = file_path:gsub(".lua", "")
                    assets[folder_name][file_name] = require(file_path)
                end
            elseif folder_name == "shaders" then
                assets[folder_name][file_name] = love.graphics.newShader(file_path)
            end
        end
    end
end

return assets