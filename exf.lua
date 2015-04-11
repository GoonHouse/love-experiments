local ProFi = require 'examples.vendor.ProFi'
local List = require 'list'
local mountme = require 'mountme'

local exf = {
	current = nil,
	available = {},
	exdir = 'examples',
}

local function getn(n)
	local s = ""
	n = tonumber(n)
	local r = n
	if r <= 0 then error("Example IDs must be bigger than 0. (Got: " .. r .. ")") end
	if r >= 10000 then error("Example IDs must be less than 10000. (Got: " .. r .. ")") end
	while r < 1000 do
		s = s .. "0"
		r = r * 10
	end
	s = s .. n
	return s
end

local function intable(t, e)
	for k, v in ipairs(t) do
		if v == e then return true end
	end
	return false
end

local function empty() end

function exf:loadExamples(dir)
	dir = dir or 'examples'
	self.exdir = dir

	local files =  love.filesystem.getDirectoryItems(dir)
	local n = 0

	for i, v in ipairs(files) do
		local is_file = love.filesystem.isFile(dir.."/".. v )
		local is_folder = love.filesystem.isDirectory(dir.."/".. v )
		if is_file then
			n = n + 1
			table.insert(exf.available, v);
			local file = love.filesystem.newFile(v, love.file_read)
			file:open("r")
			local contents = love.filesystem.read(dir .. "/" .. v, 100)
			local s, e, c = string.find(contents, "Example: ([%a%p ]-)[\r\n]")
			file:close(file)
			if not c then c = "Untitled" end
			local title = getn(n) .. " " .. c .. " (" .. v .. ")"
			self.list:add(title, v)
		elseif is_folder then
			if love.filesystem.isFile(dir.."/"..v.."/main.lua") then
				local tv = v .. "/main.lua"
				n = n + 1
				table.insert(self.available, v);
				local file = love.filesystem.newFile(dir .. "/" .. tv, love.file_read)
				file:open("r")
				local contents = love.filesystem.read(dir .. "/" .. tv, 100)
				local s, e, c = string.find(contents, "Example: ([%a%p ]-)[\r\n]")
				file:close(file)
				if not c then c = "Untitled" end
				local title = getn(n) .. " " .. c .. " (" .. v .. ")"
				self.list:add(title, v)
			end
		end
	end
end

function exf:load()
	self.list = List:new()
	self.list.start_callback = function(i, f) self:start(i, f) end
	self.smallfont = love.graphics.newFont(love._vera_ttf,12)
	self.bigfont = love.graphics.newFont(love._vera_ttf, 24)
	self.list.font = self.smallfont

	self.bigball = love.graphics.newImage("examples/gfx/love-big-ball.png")
	
	self:loadExamples('examples')

	self.list:done()
	self:resume()
end

function exf:update(dt)
	local d = self.list
	d:update(dt)
end

function exf:draw()
	love.graphics.setBackgroundColor(0, 0, 0)

	love.graphics.setColor(48, 156, 225)
	love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())

	love.graphics.setColor(255, 255, 255, 191)
	love.graphics.setFont(self.bigfont)
	love.graphics.print("Examples:", 50, 50)

	love.graphics.setFont(self.smallfont)
	love.graphics.print("Browse and click on the example you \nwant to run. To return the the example \nselection screen, press escape.", 500, 80)

	self.list:draw()

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(self.bigball, 800 - 128, 600 - 128, love.timer.getTime(), 1, 1, self.bigball:getWidth() * 0.5, self.bigball:getHeight() * 0.5)
end

function exf:keypressed(k)
end

function exf.keyreleased(k)
end

function exf:mousepressed(x, y, b)
	self.list:mousepressed(x, y, b)
end

function exf:mousereleased(x, y, b)
	self.list:mousereleased(x, y, b)
end

function exf:start(item, file)
	local e_id = string.sub(item, 1, 4)
	local e_rest = string.sub(item, 5)
	local unused1, unused2, n = string.find(item, "(%s)%.lua")

	if intable(self.available, file) then
		if not love.filesystem.exists(self.exdir .. "/" .. file) then
			print("Could not load game .. " .. file)
		else
			local is_file = love.filesystem.isFile(self.exdir .. "/" .. file)
			local is_folder = love.filesystem.isDirectory(self.exdir .. "/" .. file)

			-- Clear all callbacks.
			love.load = empty
			love.update = empty
			love.draw = empty
			love.keypressed = empty
			love.keyreleased = empty
			love.mousepressed = empty
			love.mousereleased = empty
			
			if is_file then
				love.filesystem.load(self.exdir .. "/" .. file)()
			elseif is_folder then
				mountme:wrap()
				mountme:setBase(self.exdir .. "/" .. file)
				self.current = self.exdir .. "/" .. file
				love.filesystem.load(self.exdir .. "/" .. file .. "/main.lua")()
			end
			self:clear()

			--love.window.setTitle(e_rest)

			-- Redirect keypress
			local o_keypressed = love.keypressed
			love.keypressed = function(k)
				if k == "escape" then
					self:resume()
				end
				o_keypressed(k)
			end

			love.load()
		end
	else
		print("Example ".. e_id .. " does not exist.")
	end
end

function exf:clear()
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.setColor(255, 255, 255)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("smooth")
	love.graphics.setBlendMode("alpha")
	love.mouse.setVisible(true)
end

function exf:resume()
	ProFi:stop()
	ProFi:writeReport( 'light_world_profiling_report.txt' )

	if self.current ~= nil then
		mountme:unwrap()
	end

	load = nil
	love.update = function(dt) self:update(dt) end
	love.draw = function() self:draw() end
	love.keypressed = function(k) self:keypressed(k) end
	love.keyreleased = function(k) self:keyreleased(k) end
	love.mousepressed = function(x,y,b) self:mousepressed(x,y,b) end
	love.mousereleased = function(x,y,b) self:mousereleased(x,y,b) end

	love.mouse.setVisible(true)
	love.window.setTitle("LOVE Example Browser")
end

return exf