--[[
Copyright (c) 2008 Chris Bannister,
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local print = function(str) return ChatFrame3:AddMessage(tostring(str)) end
local printf = function(...) return ChatFrame3:AddMessage(string.format(...)) end
local _G = getfenv(0)
local oUF = _G.oufgrid or _G.oUF

if not oUF then
	return error("oUF Grid requires oUF")
end

local UnitName = UnitName
local UnitClass = UnitClass
local select = select
local unpack = unpack
local UnitDebuff = UnitDebuff
local UnitInRaid = UnitInRaid

local width, height = 50, 50

local texture = [[Interface\AddOns\oUF_Grid\media\gradient32x32.tga]]
local hightlight = [[Interface\AddOns\oUF_Grid\media\mouseoverHighlight.tga]]

local colors = {
	class ={
		-- I accept patches you know
		["DEATHKNIGHT"] = { 0.77, 0.12, 0.23 },
		["DRUID"] = { 1.0 , 0.49, 0.04 },
		["HUNTER"] = { 0.67, 0.83, 0.45 },
		["MAGE"] = { 0.41, 0.8 , 0.94 },
		["PALADIN"] = { 0.96, 0.55, 0.73 },
		["PRIEST"] = { 1.0 , 1.0 , 1.0 },
		["ROGUE"] = { 1.0 , 0.96, 0.41 },
		["SHAMAN"] = { 0,0.86,0.73 },
		["WARLOCK"] = { 0.58, 0.51, 0.7 },
		["WARRIOR"] = { 0.78, 0.61, 0.43 },
	},
}
setmetatable(colors.class, {
	__index = function(self, key)
		return { 0.78, 0.61, 0.43 }
	end
})

local GetClassColor = function(unit)
	return unpack(oUF.colors.class[select(2, UnitClass(unit))])
end

local ColorGradient = function(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 0.66 then
		return { r3, g3, b3 }
	elseif perc >= 0.33 then
		return { r2, g2, b2 }
	else
		return { r1, g1, b1 }
	end

end


local function HasDebuffType(unit, t)
	for i=1,40 do
		local name, _, _, _, debuffType = UnitDebuff(unit, i)
		if not name then return
		elseif debuffType == t then return true end
	end
end

local round = function(x, y)
	return math.floor((x * 10 ^ y)+ 0.5) / 10 ^ y
end

oUF.Tags["[tekdisease]"] = function(u) return HasDebuffType(u, "Disease") and "|cff996600Di|r" or "" end
oUF.Tags["[tekmagic]"]   = function(u) return HasDebuffType(u, "Magic")   and "|cff3399FFMa|r" or "" end
oUF.Tags["[tekcurse]"]   = function(u) return HasDebuffType(u, "Curse")   and "|cff9900FFCu|r" or "" end
oUF.Tags["[tekpoison]"]  = function(u) return HasDebuffType(u, "Poison")  and "|cff009900Po|r" or "" end
oUF.Tags["[tekdead]"]  = function(u) return UnitIsDead(u) and "|cff990000Dead|r" end
oUF.Tags["[tekghost]"]  = function(u) return UnitIsGhost(u) and "|cff990000Ghost|r" end
oUF.Tags["[tekDC]"]  = function(u) return not UnitIsConnected(u) and "|cff999999D/C|r" end
oUF.Tags["[tekname]"]  = function(u)
	if HasDebuffType(u, "Poison") or HasDebuffType(u, "Disease") or HasDebuffType(u, "Magic") or HasDebuffType(u, "Curse") then return end
	local c, m, n = UnitHealth(u), UnitHealthMax(u), UnitName(u)
	return UnitIsConnected(u) and not (UnitIsDead(u) or UnitIsGhost(u)) and c >= m and string.sub(n, 1, math.max(string.len(n), 5))
end
oUF.Tags["[tekhp]"]  = function(u)
	if HasDebuffType(u, "Poison") or HasDebuffType(u, "Disease") or HasDebuffType(u, "Magic") or HasDebuffType(u, "Curse") then return end
	local c, m, n = UnitHealth(u), UnitHealthMax(u)
	return UnitIsConnected(u) and not (UnitIsDead(u) or UnitIsGhost(u)) and c < m and "-"..oUF.Tags["[missinghp]"](u)
end
oUF.TagEvents["[tekdisease]"] = "UNIT_AURA"
oUF.TagEvents["[tekmagic]"]   = "UNIT_AURA"
oUF.TagEvents["[tekcurse]"]   = "UNIT_AURA"
oUF.TagEvents["[tekpoison]"]  = "UNIT_AURA"
oUF.TagEvents["[tekdead]"] = "UNIT_HEALTH"
oUF.TagEvents["[tekghost]"] = "UNIT_HEALTH"
oUF.TagEvents["[tekDC]"] = "UNIT_HEALTH"
oUF.TagEvents["[tekname]"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE"
oUF.TagEvents["[tekhp]"] = "UNIT_HEALTH UNIT_MAXHEALTH"

local tagstr = "[tekdisease][tekmagic][tekcurse][tekpoison][tekdead][tekghost][tekDC][raidcolor][tekname][tekhp]"


local PostUpdateHealth = function(self, event, unit, bar, current, max)
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		bar.bg:SetVertexColor(0.3, 0.3, 0.3)
	else
		bar.bg:SetVertexColor(GetClassColor(unit))
	end
end

local OnEnter = function(self)
	UnitFrame_OnEnter(self)
	self.Highlight:Show()
end

local OnLeave = function(self)
	UnitFrame_OnLeave(self)
	self.Highlight:Hide()
end

local frame = function(settings, self, unit)
	self.menu = menu

	self:EnableMouse(true)

	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:RegisterForClicks("anyup")

	self:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		insets = {left = -2, right = -2, top = -2, bottom = -2},
	})
	self:SetBackdropColor(0, 0, 0, 1)

	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp:SetStatusBarTexture(texture)
	hp:SetOrientation("VERTICAL")
	hp:SetFrameLevel(5)
	hp:SetStatusBarColor(0, 0, 0)
	hp:SetAlpha(0.8)

	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg:SetAlpha(1)

	local heal = hp:CreateTexture(nil, "OVERLAY")
	heal:SetHeight(height)
	heal:SetWidth(width)
	heal:SetPoint("BOTTOM")
	heal:SetTexture(texture)
	heal:SetVertexColor(0, 1, 0)
	heal:Hide()

	self.heal = heal

	hp.bg = hpbg
	self.Health = hp
	self.PostUpdateHealth = PostUpdateHealth

	local hl = hp:CreateTexture(nil, "OVERLAY")
	hl:SetAllPoints(self)
	hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	hl:SetBlendMode("ADD")
	hl:Hide()

	self.Highlight = hl

	local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	name:SetPoint("CENTER")
	name:SetJustifyH("CENTER")
	name:SetShadowColor(0,0,0,1)
	name:SetShadowOffset(1, -1)
	name:SetTextColor(1, 1, 1, 1)

	self:Tag(name, tagstr)

	local border = hp:CreateTexture(nil, "OVERLAY")
	border:SetPoint("LEFT", self, "LEFT", -4, 0)
	border:SetPoint("RIGHT", self, "RIGHT", 4, 0)
	border:SetPoint("TOP", self, "TOP", 0, 4)
	border:SetPoint("BOTTOM", self, "BOTTOM", 0, -4)
	border:SetTexture([[Interface\AddOns\oUF_Kanne_Grid\media\Normal.tga]])
	border:Hide()
	border:SetVertexColor(1, 1, 1)

	self.border = border

	local icon = hp:CreateTexture(nil, "OVERLAY")
	icon:SetPoint("CENTER")
	icon:SetHeight(20)
	icon:SetWidth(20)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:Hide()

	icon.ShowText = function(s)
		self.Name:Hide()
		s:Show()
	end

	icon.HideText = function(s)
		self.Name:Show()
		s:Hide()
	end

	self.Icon = icon

	self.Range = true
	self.inRangeAlpha = 1
	self.outsideRangeAlpha = 0.4

	return self
end

local style = setmetatable({
	["initial-height"] = height,
	["initial-width"] = width,
}, {
	__call = frame,
})

oUF:RegisterStyle("Kanne-Grid", style)
oUF:SetActiveStyle("Kanne-Grid")

local raid = {}
for i = 1, 8 do
	local r = oUF:Spawn("header", "oUF_Raid" .. i)
	r:SetPoint("TOP", UIParent, "TOP", 0, -100)
	if i == 1 then
		r:SetPoint("LEFT", UIParent, "LEFT", 80, 0)
		r:SetAttribute("showParty", true)
		r:SetAttribute("showPlayer", true)
		r:SetAttribute("showSolo", true)
	else
		r:SetPoint("LEFT", raid[i - 1], "RIGHT", 6, 0)
	end

	r:SetManyAttributes(
		"showRaid", true,
		"groupFilter", i,
		"yOffset", -10
	)

	r:Show()
	raid[i] = r
end
