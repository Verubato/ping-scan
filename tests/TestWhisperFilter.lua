-- The whisper filter is PingScan's entire trigger surface: every other behaviour in the
-- addon runs off a ping this filter decides to answer.

local fw = require("TestFramework")
local env = require("PingScanEnv")

local SCAN_SOUND = "Interface\\AddOns\\PingScan\\Media\\scan.ogg"

fw.describe("PingScan - whisper filter trim and case", function()
	local filter

	fw.before_each(function()
		local filters = env.Stub()
		env.Load()
		filter = filters["CHAT_MSG_WHISPER"]
	end)

	fw.it("suppresses a bare ping", function()
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "ping"), true, "ping")
	end)

	fw.it("suppresses ping padded with whitespace", function()
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "  ping  "), true, "  ping  ")
	end)

	fw.it("suppresses PING and Ping regardless of case", function()
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "PING"), true, "PING")
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "Ping"), true, "Ping")
	end)

	fw.it("does not suppress a message that only contains the word ping", function()
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "pinged"), false, "pinged")
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", "ping me"), false, "ping me")
	end)

	fw.it("does not suppress an empty or nil message", function()
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", ""), false, "empty string")
		fw.eq(filter(nil, "CHAT_MSG_WHISPER", nil), false, "nil")
	end)
end)

fw.describe("PingScan - whisper trigger", function()
	fw.it("registers the same filter for CHAT_MSG_WHISPER and CHAT_MSG_BN_WHISPER", function()
		local filters = env.Stub()
		env.Load()

		fw.not_nil(filters["CHAT_MSG_WHISPER"], "CHAT_MSG_WHISPER filter")
		fw.eq(filters["CHAT_MSG_BN_WHISPER"], filters["CHAT_MSG_WHISPER"], "same filter both events")
	end)

	fw.it("a non-matching whisper does not show the radar", function()
		local filters = env.Stub()
		env.Load()

		local suppressed = filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "hello")

		fw.eq(suppressed, false, "suppressed")
		fw.falsy(_G.PingScanFrame:IsShown(), "radar shown")
	end)

	fw.it("a matching whisper shows the radar and plays the scan sound", function()
		local filters, sounds = env.StubWithTimers()
		env.Load()

		filters["CHAT_MSG_WHISPER"](nil, "CHAT_MSG_WHISPER", "ping")

		fw.truthy(_G.PingScanFrame:IsShown(), "radar shown")
		fw.eq(sounds[1], SCAN_SOUND, "scan sound played")
	end)
end)

fw.describe("PingScan - slash commands", function()
	fw.it("registers /pingscan, /scan and /ps", function()
		env.Stub()
		env.Load()

		fw.eq(_G.SLASH_PINGSCAN1, "/pingscan", "primary alias")
		fw.eq(_G.SLASH_PINGSCAN2, "/scan", "second alias")
		fw.eq(_G.SLASH_PINGSCAN3, "/ps", "third alias")
	end)

	fw.it("triggers a scan", function()
		local _, sounds = env.StubWithTimers()
		env.Load()

		_G.SlashCmdList["PINGSCAN"]("")

		fw.truthy(_G.PingScanFrame:IsShown(), "radar shown")
		fw.eq(sounds[1], SCAN_SOUND, "scan sound played")
	end)
end)
