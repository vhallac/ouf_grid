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

local UnitName = UnitName
local UnitClass = UnitClass
local select = select
local unpack = unpack
local UnitDebuff = UnitDebuff
local UnitInRaid = UnitInRaid

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, evnet, ...)
	return self[event](self, ...)
end)

local PLAYERCLASS = select(2, UnitClass("player"))
local playername, playerrealm = UnitName("player"), GetRealmName()

local coloredFrame      -- Selected Raid Member

local UpdateRoster

local width, height = 32, 32

local debuffs = {
	["Viper Sting"] = 12,

	["Wound Poison"] = 9,
	["Mortal Strike"] = 8,
	["Aimed Shot"] = 8,

	["Counterspell - Silenced"] = 11,
	["Counterspell"] = 10,

	["Blind"] = 10,
	["Cyclone"] = 10,

	["Polymorph"] = 7,

	["Entangling Roots"] = 7,
	["Freezing Trap Effect"] = 7,

	["Crippling Poison"] = 6,
	["Hamstring"] = 5,
	["Wingclip"] = 5,

	["Fear"] = 3,
	["Psycic Scream"] = 3,
	["Howl of Terror"] = 3,
}

local dispellClass
do
	local t = {
		["PRIEST"] = {
			["Magic"] = true,
			["Disease"] = true,
		},
		["SHAMAN"] = {
			["Poision"] = true,
			["Disease"] = true,
		},
		["PALADIN"] = {
			["Poison"] = true,
			["Magic"] = true,
			["Disease"] = true,
		},
		["MAGE"] = {
			["Curse"] = true,
		},
		["DRUID"] = {
			["Curse"] = true,
			["Poison"] = true,
		},
	}
	if t[PLAYERCLASS] then
		dispellClass = {}
		for k, v in pairs(t[PLAYERCLASS]) do
			dispellClass[k] = v
		end
		t = nil
	end
end

local dispellPiority = {
	["Magic"] = 4,
	["Poison"] = 3,
	["Disease"] = 1,
	["Curse"] = 2,
}

local name, rank, buffTexture, count, duration, timeLeft, dtype
function f:UNIT_AURA(unit)
	if not oUF.units[unit] then return end

	local frame = oUF.units[unit]

	if not frame.Icon then return end
	local current, bTexture, dispell, dispellTexture
	for i = 1, 40 do
		name, rank, buffTexture, count, dtype, duration, timeLeft = UnitDebuff(unit, i)
		if not name then break end

		if dispellClass and dispellClass[dtype] then
			dispell = dispell or dtype
			dispellTexture = dispellTexture or buffTexture
			if dispellPiority[dtype] > dispellPiority[dispell] then
				dispell = dtype
				dispellTexture = buffTexture
			end
		end

		if debuffs[name] then
			current = current or name
			bTexture = bTexture or buffTexture

			local prio = debuffs[name]
			if prio > debuffs[current] then
				current = name
				bTexture = buffTexture
			end
		end
	end

	if dispellClass then
		if dispell then
			if dispellClass[dispell] then
				local col = DebuffTypeColor[dispell]
				frame.border:Show()
				frame.border:SetVertexColor(col.r, col.g, col.b)
				frame.Dispell = true
				if not bTexture and dispellTexture then
					current = dispell
					bTexture = dispellTexture
				end
			end
		else
			frame.border:SetVertexColor(1, 1, 1)
			frame.Dispell = false
			if coloredFrame then
				if unit ~= coloredFrame then
					frame.border:Hide()
				end
			else
				frame.border:Hide()
			end
		end
	end

	if current and bTexture then
		frame.IconShown = true
		frame.Icon:SetTexture(bTexture)
		frame.Icon:ShowText()
		frame.DebuffTexture = true
	else
		frame.IconShown = false
		frame.DebuffTexture = false
		frame.Icon:HideText()
	end
end

function f:PLAYER_TARGET_CHANGED()
	local id = UnitInRaid("target") and UnitInRaid("target") + 1
	local frame = id and UnitInRaid("target") and oUF.units["raid" .. id]
	if not frame then
		if coloredFrame then
			if not oUF.units[coloredFrame].Dispell then
				oUF.units[coloredFrame].border:Hide()
			end
			coloredFrame = nil
		end
		return
	end

	if coloredFrame and not oUF.units[coloredFrame].Dispell then
		oUF.units[coloredFrame].border:Hide()
	end

	if not frame.Dispell and frame.border then
		frame.border:SetVertexColor(1, 1, 1)
		frame.border:Show()
	end

	coloredFrame = UnitInRaid("target") and "raid" .. id
end


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
bg:SetPoint("TOP", _G["oUF_Raid1"], "TOP", 0, 8)
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

	bg:SetPoint("LEFT", _G["oUF_Raid" .. first], "LEFT", -8 , 0)
	bg:SetPoint("RIGHT", _G["oUF_Raid" .. last], "RIGHT", 8, 0)
	bg:SetPoint("BOTTOM", _G["oUF_Raid" .. h], "BOTTOM", 0, -8)
end

f.PLAYER_LOGIN = f.RAID_ROSTER_UPDATE
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_LOGIN")
