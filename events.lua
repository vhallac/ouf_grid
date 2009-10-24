local print = function(...)
	local str = ""
	for i = 1, select("#", ...) do
		str = str .. " " .. tostring(select(i, ...))
	end

	return ChatFrame3:AddMessage(str)
end

local printf = function(...) return ChatFrame3:AddMessage(string.format(...)) end
local _G = getfenv(0)
local oUF

do
	if _G.oufgrid then
		oUF = _G.oufgrid
		_G.oufgrid = nil
	elseif _G.oUF then
		oUF = _G.oUF
	else
		return
	end
end

local select = select
local UnitInRaid = UnitInRaid

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, evnet, ...)
	return self[event](self, ...)
end)

local SubGroups
do
	local t = {}
	SubGroups = function()
		for i = 1, 8 do t[i] = 0 end
		for i = 1, GetNumRaidMembers() do
			local s = select(3, GetRaidRosterInfo(i))
			t[s] = t[s] + 1
		end
		return t
	end
end

-- BG
local bg = CreateFrame("Frame")
bg:SetPoint("LEFT", _G["oUF_Raid1"], "LEFT", 0, -8)
bg:SetBackdrop({
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
	insets = {left = 2, right = 2, top = 2, bottom = 2}
})
bg:SetBackdropColor(0, 0, 0, 0.6)
bg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
bg:SetFrameLevel(0)
bg:Show()

function f:RAID_ROSTER_UPDATE()
	if not UnitInRaid("player") then
		return bg:Hide()
	else
		bg:Show()
	end

	local roster = SubGroups()

	local h, last, first = 1
	for k, v in ipairs(roster) do
		if v > 0 then
			if not first then
				first = k
			end
			last = k
		end
		if v > roster[h] then
			h = k
		end
	end

	bg:SetPoint("TOP", _G["oUF_Raid" .. first], "TOP", 0, 8)
	bg:SetPoint("BOTTOM", _G["oUF_Raid" .. last], "BOTTOM", 0, -8)
	bg:SetPoint("RIGHT", _G["oUF_Raid" .. h], "RIGHT", 8, 0)
end

f.PLAYER_LOGIN = f.RAID_ROSTER_UPDATE
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_LOGIN")
