CheckboxItem = {}
CheckboxItem.__index = CheckboxItem

setmetatable(CheckboxItem, {
    __index = Item,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:Init(...)
        return self
    end
})

function CheckboxItem:Init(menu, text, checked, textColor, disabledTextColor, bgColor, bgHoveredColor, opacity)
    Item.Init(self, menu, text, textColor, disabledTextColor, bgColor, bgHoveredColor, opacity)
    
    self.checked = checked or false
    
    self.colors.sprite = Colors.White
    self.colors.disabledSprite = Colors.LightGrey
    
    self.rightSprite = Sprite("commonmenu", self.checked and "shop_box_tick" or "shop_box_blank", nil, vector2(0.015, 0.015 * GetAspectRatio(false)))
end

function CheckboxItem:Process(cursorPosition)
    Item.Process(self, cursorPosition)
    
    -- Met à jour le sprite selon l'état
    self.rightSprite.textureName = self.checked and "shop_box_tick" or "shop_box_blank"
end

function CheckboxItem:Clicked()
    if (not self.enabled) then
        return
    end
    
    -- Toggle l'état
    self.checked = not self.checked
    
    -- Met à jour le sprite immédiatement
    self.rightSprite.textureName = self.checked and "shop_box_tick" or "shop_box_blank"
    
    Citizen.CreateThread(function()
        self.OnClick()
    end)
end

function CheckboxItem:SetChecked(checked)
    self.checked = checked
    self.rightSprite.textureName = self.checked and "shop_box_tick" or "shop_box_blank"
end

function CheckboxItem:IsChecked()
    return self.checked
end