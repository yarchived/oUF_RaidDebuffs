--[[
    Copyright (c) 2010 yaroot(@gmail.com)

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.
--]]

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF RaidDebuffs: unable to locate oUF')

local DispelColor = {
    ['Magic']   = {.2, .6, 1},
    ['Curse']   = {.6, 0, 1},
    ['Disease'] = {.6, .4, 0},
    ['Poison']  = {0, .6, 0},
    ['none'] = {0, 0, 0},
}

local DispelPriority = {
    ['Magic']   = 4,
    ['Curse']   = 3,
    ['Disease'] = 2,
    ['Poison']  = 1,
}

local DispelFilter = ({
    PIREST = {
        Magic = true,
        Disease = true,
    },
    SHAMAN = {
        --Magic = true,
        Curse = true,
    },
    PALADIN = {
        --Magic = false,
        Poison = true,
        Disease = true,
    },
    MAGE = {
        Curse = true,
    },
    DRUID = {
        --Magic = true,
        Curse = true,
        Poison = true,
    },
})[select(2, UnitClass'player')]

local formatTime = function(s)
    if s > 60 then
        return format('%dm', s/60), s%60
    else
        return format('%d', s), s - floor(s)
    end
end

local UpdateTimer = function(self)
    local timeLeft = self.endTime - GetTime()
    if(timeLeft > 0) then
        local text, nextUpdate = formatTime(timeLeft)
        self.time:SetText(text)
        self.nextUpdate = nextUpdate
    else
        self:SetScript('OnUpdate', nil)
        self.time:Hide()
    end
end

local OnUpdate = function(self, elps)
    self.nextUpdate = self.nextUpdate - elps
    if(self.nextUpdate <= 0)then
        UpdateTimer(self)
    end
end

local UpdateDebuff = function(self)
    local rd = self.RaidDebuffs

    if(rd.PreUpdate) then
        rd:PreUpdate()
    end

    if(rd.index and rd.type) then
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff = UnitAura(self.unit, rd.index, rd.Filter or 'HARMFUL')

        rd.icon:SetTexture(icon)
        rd.icon:Show()

        if(rd.count) then
            if count and (count > 0) then
                rd.count:SetText(count)
                rd.count:Show()
            else
                rd.count:Hide()
            end
        end

        if(rd.time) then
            if(duration and (duration > 0)) then
                rd.endTime = endTime
                rd.nextUpdate = 0
                rd:SetScript('OnUpdate', OnUpdate)
                rd.time:Show()
            else
                rd:SetScript('OnUpdate', nil)
                rd.time:Hide()
            end
        end

        if(rd.cd) then
            if(duration and (duration > 0)) then
                rd.cd:SetCooldown(endTime - duration, duration)
                rd.cd:Show()
            else
                rd.cd:Hide()
            end
        end

        if(rd.SetBackdropColor) then
            local dispelColor = rd.DispelColor or DispelColor
            local c = dispelColor[debuffType] or dispelColor.none or DispelColor.none
            rd:SetBackdropColor(unpack(c))
        end

        rd:Show()
    else
        rd:Hide()
    end

    if(rd.PostUpdate) then
        rd:PostUpdate()
    end
end

local Update = function(self, event, unit)
    if(unit ~= self.unit) then return end
    local rd = self.RaidDebuffs
    rd.priority = -1

    local i = 0
    while(true) do
        i = i + 1
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff = UnitAura(unit, i, rd.Filter or 'HARMFUL')
        if (not name) then break end

        if(rd.ShowBossDebuff and isBossDebuff) then
            local priority = rd.BossDebuffPriority or 999999999
            if(priority and priority > rd.priority) then
                rd.priority = priority
                rd.index = i
                rd.type = 'Boss'
            end
        end

        if(rd.ShowDispelableDebuff and debuffType) then
            local dispelPriority = rd.DispelPriority or DispelPriority
            local priority
            if(rd.FilterDispelableDebuff) then
                priority = (rd.DispelFilter or DispelFilter)[debuffType] and dispelPriority[debuffType]
            else
                priority = dispelPriority[debuffType]
            end

            if(priority and (priority > rd.priority)) then
                rd.priority = priority
                rd.index = i
                rd.type = 'Dispel'
            end
        end

        local priority = rd.Debuffs and rd.Debuffs[rd.MatchBySpellName and name or spellId]
        if(priority and (priority > rd.priority)) then
            rd.priority = priority
            rd.index = i
            rd.type = 'Custom'
        end
    end

    if(rd.priority == -1) then
        rd.index = nil
        rd.type = nil
    end

    UpdateDebuff(self)
end

local f

local searchFor = function(spell, i)
    local spellName = GetSpellInfo(spell)
    local found
    for j = 1, GetNumSpellTabs() do
        for k = 1, GetNumTalents(j) do
            local talentName, _, _, _, rank = GetTalentInfo(j, k)
            if(talentName and talentName == spellName) then
                return true
            end
        end
    end
end

local spellCheck = function()
    local _, class = UnitClass'player'
    if(class == 'PALADIN') then
        -- http://www.wowhead.com/spell=53551
        -- Sacred Cleansing
        DispelFilter.Magic = searchFor(53551)
    elseif(class == 'SHAMAN') then
        -- http://www.wowhead.com/spell=77130
        -- Improved Cleanse Spirit
        DispelFilter.Magic = searchFor(77130)
    elseif(class == 'DRUID') then
        -- http://www.wowhead.com/spell=88423
        -- Nature's Cure
        DispelFilter.Magic = searchFor(88423)
    end
end

local Path = function(self, ...)
    return (self.RaidDebuffs.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
    return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
    local rd = self.RaidDebuffs
    if(rd) then
        self:RegisterEvent('UNIT_AURA', Path)
        rd.ForceUpdate = ForceUpdate

        if(not f and not rd.DispelFilter and not rd.Override) then
            f = CreateFrame'Frame'
            f:SetScript('OnEvent', spellCheck)
            f:RegisterEvent('PLAYER_TALENT_UPDATE')
            f:RegisterEvent('CHARACTER_POINTS_CHANGED')
            spellCheck()
        end

        return true
    end
end

local Disable = function(self)
    if(self.RaidDebuffs) then
        self:UnregisterEvent('UNIT_AURA', Path)
        self.RaidDebuffs:Hide()
    end
end

oUF:AddElement('RaidDebuffs', Update, Enable, Disable)

