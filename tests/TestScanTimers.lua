-- The enemy-scan escalation and the auto-close window both hinge on state a later timer
-- reads after an earlier one, or after a fresh ping, has changed it. These drive C_Timer.After
-- one callback at a time (see PingScanEnv.lua) to prove the ordering, not just the end state.

local fw = require("TestFramework")
local env = require("PingScanEnv")
local WowMock = require("WowMock")

local ENEMY_SOUND = "Interface\\AddOns\\PingScan\\Media\\scan_enemy.ogg"

fw.describe("PingScan - enemy scan escalation", function()
	fw.it("plays the repeat sound while isEnemyScanning stays true", function()
		local filters, sounds, scheduled = env.StubWithTimers()
		env.Load()

		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")
		env.RunNextTimer(scheduled, 2)

		fw.eq(sounds[2], ENEMY_SOUND, "enemy sound played on the hit")

		env.RunNextTimer(scheduled, 3)

		fw.eq(sounds[3], ENEMY_SOUND, "repeat sound plays because scanning stayed active")
	end)

	fw.it("a scan reset before the repeat timer fires plays nothing", function()
		local filters, sounds, scheduled = env.StubWithTimers()
		env.Load()

		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")
		env.RunNextTimer(scheduled, 2)

		fw.eq(sounds[#sounds], ENEMY_SOUND, "enemy sound played on the first hit")

		-- a fresh ping resets isEnemyScanning to false before the stale repeat timer fires
		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")

		local countAfterReset = #sounds

		env.RunNextTimer(scheduled, 3)

		fw.eq(#sounds, countAfterReset, "the stale repeat timer played nothing after the reset")
	end)
end)

fw.describe("PingScan - auto-close", function()
	fw.it("hides after the close window when no newer ping has landed", function()
		local filters, _, scheduled = env.StubWithTimers()
		env.Load()

		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")
		WowMock.AdvanceTime(6)
		env.RunNextTimer(scheduled, 6)

		fw.falsy(_G.PingScanFrame:IsShown(), "radar hidden after the close window")
	end)

	fw.it("a second ping inside the close window keeps the radar shown", function()
		local filters, _, scheduled = env.StubWithTimers()
		env.Load()

		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")
		WowMock.AdvanceTime(3)
		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")
		WowMock.AdvanceTime(3)

		-- fires the first ping's own close timer; lastPing has since moved forward from the
		-- second ping, so it must not hide
		env.RunNextTimer(scheduled, 6)

		fw.truthy(_G.PingScanFrame:IsShown(), "radar still shown")
	end)
end)
