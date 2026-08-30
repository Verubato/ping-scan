-- Support for PingScan's own tests: stubs for the client APIs the shared mock
-- (build/Lua/WowMock.lua) doesn't carry, plus a way to drive C_Timer.After one callback at
-- a time. Nothing under build/ is edited; this is the addon-specific extension point.

local WowMock = require("WowMock")
local harness = require("AddonHarness")

local M = {}

---Resets the mock and stubs the client APIs PingScan calls that WowMock doesn't carry: it
---has no chat frame to register a message filter with, and no screen-flash API. Returns the
---table each registered filter lands in, keyed by event name.
---@return table filters
function M.Stub()
	WowMock.Install()

	local filters = {}
	_G.ChatFrame_AddMessageEventFilter = function(event, filter)
		filters[event] = filter
	end

	_G.FlashClientIcon = function() end

	return filters
end

---Stub() plus a recording PlaySoundFile and a C_Timer.After that queues callbacks instead of
---running them. WowMock's own C_Timer only drains everything pending at once, which is too
---coarse to prove the enemy-scan escalation and the auto-close window: both depend on which
---generation of a repeating schedule fires, and in what order relative to a fresh ping.
---@return table filters, table sounds, table scheduled
function M.StubWithTimers()
	local filters = M.Stub()

	local sounds = {}
	_G.PlaySoundFile = function(path)
		sounds[#sounds + 1] = path
	end

	local scheduled = {}
	_G.C_Timer.After = function(delay, callback)
		scheduled[#scheduled + 1] = { delay = delay, callback = callback }
	end

	return filters, sounds, scheduled
end

---Loads PingScan. Call Stub() or StubWithTimers() first.
---@return table context
function M.Load()
	return harness.Load("PingScan", { install = false })
end

---Runs and removes the oldest still-pending timer scheduled with this exact delay, so a test
---can fire one generation of a repeating schedule without also firing a newer one.
---@param scheduled table
---@param delay number
function M.RunNextTimer(scheduled, delay)
	for i, timer in ipairs(scheduled) do
		if timer.delay == delay then
			table.remove(scheduled, i)
			timer.callback()
			return
		end
	end

	error("no pending timer with delay " .. tostring(delay), 2)
end

return M
