
-- debuff data
local raid_debuffs = {
--  [spell] = priority,
    [GetSpellInfo(xxx)] = 10,
    [GetSpellInfo(zzz)] = 11,
--  ...
}
-- we can generate them
local raid_debuffs = {}
for _, id in ipairs{
    -- spellIDs
    123,
    456,
} do
    local spell = GetSpellInfo(id)
    if(spell) then
        raid_debuffs = k+10
    end
end


local styleFunc = function(self, unit)
--  ...
    -- create the icon frame
    self.RaidDebuffs = CreateFrame('Frame', nil, self)
    self.RaidDebuffs:SetHeight(20)
    self.RaidDebuffs:SetWidth(20)
    self.RaidDebuffs:SetPoint('CENTER', self)
    self.RaidDebuffs:SetFrameStrata'HIGH'

    -- debuff type color
    self.RaidDebuffs:SetBackdrop({
        bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
        insets = {top = -1, left = -1, bottom = -1, right = -1},
    })

    -- icon
    self.RaidDebuffs.icon = self.RaidDebuffs:CreateTexture(nil, 'OVERLAY')
    self.RaidDebuffs.icon:SetAllPoints(self.RaidDebuffs)

    -- cd
    self.RaidDebuffs.cd = CreateFrame('Cooldown', nil, self.RaidDebuffs)
    self.RaidDebuffs.cd:SetAllPoints(self.RaidDebuffs)

    -- cd timer, if you don't use omnicc
    --self.RaidDebuffs.time = self.RaidDebuffs:CreateFontString(nil, 'OVERLAY')
    --self.RaidDebuffs.time:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
    --self.RaidDebuffs.time:SetPoint('CENTER', self.RaidDebuffs, 'CENTER', 0, 0)
    --self.RaidDebuffs.time:SetTextColor(1, .9, 0)

    -- count
    self.RaidDebuffs.count = self.RaidDebuffs:CreateFontString(nil, 'OVERLAY')
    self.RaidDebuffs.count:SetFont(STANDARD_TEXT_FONT, 8, 'OUTLINE')
    self.RaidDebuffs.count:SetPoint('BOTTOMRIGHT', self.RaidDebuffs, 'BOTTOMRIGHT', 2, 0)
    self.RaidDebuffs.count:SetTextColor(1, .9, 0)

    -- set the debuffs table
    self.RaidDebuffs.Debuffs = raid_debuffs

    -- some options you might want
    self.RaidDebuffs.ShowDispelableDebuff = true
    self.RaidDebuffs.FilterDispelableDebuff = true
    self.RaidDebuffs.MatchBySpellName = true
    --self.RaidDebuffs.DispelPriority = {}
    --self.RaidDebuffs.DispelFilter = {}
    --self.RaidDebuffs.DispelColor = {}
    --self.RaidDebuffs.SetBackdropColor = function(r,g,b) --[[ debuff type color ]] end
end


