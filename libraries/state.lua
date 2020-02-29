--todo: Fix bug with not letting love.keypressed work unless in an active state.

local state = {
    initialized = false
}

state.__index = state

function state:on_first_enter()
	--Called when the state is entered for the first time, only happens once.
end

function state:on_enter()
	--called when the state is entered, regardless of if it's the first time.
end

function state:on_state_changed()
	--called when changing to a different state.
end

function state:update(dt)
	--Default function for override.
end

function state:draw()
	--Default function for override.
end

for event in pairs(love.handlers) do
	state[event] = function()
		--Default event for override.
	end
end

local states = {
	gamestates = {}
}

function states.get_state(name)
	return states.gamestates[name]
end

function states.set_current_state(name, ...)
	local current_state = states.current_state
	local next_state = states.gamestates[name]

	assert(next_state, "State \"" .. tostring(name) .. "\" doesn't exist.")

	if current_state and next_state ~= current_state then
		current_state:on_state_changed()
	end

	states.current_state = next_state
	
	if not next_state.initialized then
		next_state:on_first_enter(...)
		next_state.initialized = true
	end

	if current_state ~= next_state then
		next_state:on_enter(...)
	end
end

function states.load_states(folder)
	for _, item in pairs(love.filesystem.getDirectoryItems(folder)) do
		local file_path = folder .. "/" .. item

		if love.filesystem.getInfo(file_path, "file") then
			local new_state = setmetatable(require(file_path:gsub(".lua", "")), state)
			states.gamestates[item:gsub(".lua", "")] = new_state
		end
	end
end

--detour default love events

function love.update(dt)
	if states.current_state then
		states.current_state:update(dt)
	end
end

function love.draw()
	if states.current_state then
		states.current_state:draw()
	end
end

function love.quit()
	if states.current_state then
		states.current_state:quit()
	end
end

for event in pairs(love.handlers) do
	love[event] = function(...)
		if states.current_state then
			states.current_state[event](states.current_state, ...)
		end
	end
end

return states