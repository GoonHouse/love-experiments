local mountme = {
	base = '',
	olds = {},
}

function mountme:setBase(newBase)
	self.base = newBase
end

function mountme:evalPath(path)
	if type(path) == "string" then
		if love.filesystem.isFile(path) then
			return path
		elseif love.filesystem.isFile(self.base .. '/' .. path) then
			return self.base .. '/' .. path
		else
			-- it could have been string data of a file!
			return path
		end
	else
		-- probably wasn't a path we got
		return path
	end
end

function mountme:wrap()
	self.olds = {
		newImageData = love.image.newImageData,
		newImage = love.graphics.newImage,
		newSource = love.audio.newSource,
		packagePath = package.path,
	}
	love.image.newImageData = function(p, ...) return self.olds.newImageData(self:evalPath(p), ...) end
	love.graphics.newImage = function(p, ...) return self.olds.newImage(self:evalPath(p), ...) end
	love.audio.newSource = function(p, ...) return self.olds.newSource(self:evalPath(p), ...) end
	package.path = package.path .. ';./'..self.base..'/?.lua'
end

function mountme:unwrap()
	love.image.newImageData = self.olds.newImageData
	love.graphics.newImage = self.olds.newImage
	package.path = self.olds.packagePath
end

return mountme