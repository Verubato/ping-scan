-- size of the radar
local radarSize = 400
-- degrees per second
local rotationSpeed = math.rad(180)
-- the frame containing all the elements
local radarFrame
local lastPing
-- closer after X seconds
local closeAfter = 6
-- true when the radar has hit the enemy scan phase
local isEnemyScanning = false

local function CreateRadar()
	local frame = CreateFrame("Frame", "PingScanFrame", UIParent)
	frame:Hide()
	frame:SetSize(radarSize, radarSize)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(true)

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	text:SetPoint("BOTTOM", frame, "TOP", 0, 8)
	text:SetText("Get ping scanned!")
	text:SetFont("Fonts\\FRIZQT__.TTF", 30)
	text:SetAlpha(0.85)

	frame:SetScript("OnMouseDown", function(self, btn)
		if btn ~= "LeftButton" then
			return
		end

		self:StartMoving()
	end)

	frame:SetScript("OnMouseUp", function(self, btn)
		if btn ~= "LeftButton" then
			return
		end

		self:StopMovingOrSizing()
		self:SetUserPlaced(true)
	end)

	-- circle mask
	local mask = frame:CreateMaskTexture()
	mask:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	mask:SetAllPoints(frame)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(true)
	bg:AddMaskTexture(mask)
	bg:SetColorTexture(1, 1, 1, 1)
	bg:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.10), CreateColor(1, 1, 1, 0.02))

	-- outer ring
	local ring = frame:CreateTexture(nil, "ARTWORK")
	ring:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	ring:SetAllPoints(true)
	ring:SetVertexColor(1, 1, 1, 0.50)
	ring:AddMaskTexture(mask)

	-- crosshairs
	local hline = frame:CreateTexture(nil, "OVERLAY")
	hline:SetColorTexture(1, 1, 1, 0.20)
	hline:SetSize(radarSize, 1)
	hline:SetPoint("CENTER")
	hline:AddMaskTexture(mask)

	local vline = frame:CreateTexture(nil, "OVERLAY")
	vline:SetColorTexture(1, 1, 1, 0.20)
	vline:SetSize(1, radarSize)
	vline:SetPoint("CENTER")
	vline:AddMaskTexture(mask)

	local sweepTexture = frame:CreateTexture(nil, "OVERLAY")
	sweepTexture:SetPoint("CENTER")
	sweepTexture:SetSize(radarSize * 1.2, radarSize * 0.03)
	sweepTexture:AddMaskTexture(mask)
	sweepTexture:SetColorTexture(1, 1, 1, 0.45)

	local dot = frame:CreateTexture(nil, "OVERLAY")
	dot:SetPoint("CENTER")
	dot:SetSize(6, 6)
	dot:AddMaskTexture(mask)
	dot:SetColorTexture(1, 1, 1, 1)

	local rotationAngle = 0
	frame:SetScript("OnUpdate", function(_, elapsed)
		rotationAngle = rotationAngle - rotationSpeed * elapsed

		if rotationAngle < 0 then
			rotationAngle = rotationAngle + math.pi * 2
		end

		sweepTexture:SetRotation(rotationAngle)
	end)

	frame.text = text
	frame.bg = bg
	frame.ring = ring
	frame.hline = hline
	frame.vline = vline
	frame.sweep = sweepTexture
	frame.dot = dot

	return frame
end

local function ResetRadarColors()
	-- White theme values
	local textA = 0.85
	local bgA = 0.10
	local ringA = 0.50
	local lineA = 0.20
	local sweepA = 0.45
	local dotA = 1.00

	radarFrame.text:SetTextColor(1, 1, 1, textA)
	radarFrame.bg:SetVertexColor(1, 1, 1, bgA)
	radarFrame.ring:SetVertexColor(1, 1, 1, ringA)
	radarFrame.hline:SetColorTexture(1, 1, 1, lineA)
	radarFrame.vline:SetColorTexture(1, 1, 1, lineA)
	radarFrame.sweep:SetColorTexture(1, 1, 1, sweepA)
	radarFrame.dot:SetColorTexture(1, 1, 1, dotA)
end

local function ScheduleEnemyHit()
	local start = 2

	C_Timer.After(start, function()
		isEnemyScanning = true

		local r, g, b = 1, 0, 0

		radarFrame.text:SetTextColor(r, g, b, 1.0)
		radarFrame.bg:SetVertexColor(r, g, b, 0.10)
		radarFrame.ring:SetVertexColor(r, g, b, 0.50)
		radarFrame.hline:SetColorTexture(r, g, b, 0.20)
		radarFrame.vline:SetColorTexture(r, g, b, 0.20)
		radarFrame.sweep:SetColorTexture(r, g, b, 0.45)
		radarFrame.dot:SetColorTexture(r, g, b, 1.0)

		PlaySoundFile("Interface\\AddOns\\PingScan\\Media\\scan_enemy.ogg", "Master")
	end)

	local times = 5

	for i = start + 1, times, 1 do
		C_Timer.After(i, function()
			if not isEnemyScanning then
				return
			end

			PlaySoundFile("Interface\\AddOns\\PingScan\\Media\\scan_enemy.ogg", "Master")
		end)
	end
end

local function PingScan()
	radarFrame:Show()

	isEnemyScanning = false
	PlaySoundFile("Interface\\AddOns\\PingScan\\Media\\scan.ogg", "Master")
	FlashClientIcon()
	ResetRadarColors()
	ScheduleEnemyHit()

	lastPing = GetTime()

	C_Timer.After(closeAfter, function()
		local timeSincePinged = GetTime() - lastPing

		-- subtract 1 second because we started the timer exactly at closeAfter seconds
		if timeSincePinged >= closeAfter - 1 then
			radarFrame:Hide()
		end
	end)
end

local function PingWhisperFilter(_, _, msg)
	if not msg then
		return false
	end

	local trimmed = msg:match("^%s*(.-)%s*$")

	if trimmed and trimmed:lower() == "ping" then
		PingScan()
		return true
	end

	return false
end

local function Init()
	radarFrame = CreateRadar()

	SLASH_PINGSCAN1 = "/pingscan"
	SLASH_PINGSCAN2 = "/scan"
	SLASH_PINGSCAN3 = "/ps"

	SlashCmdList["PINGSCAN"] = function()
		PingScan()
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", PingWhisperFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", PingWhisperFilter)
end

Init()
