-- Loads the whole addon into a mocked client and drives it through login.
-- PingScanEnv stubs the client APIs the shared mock doesn't carry; see its comments for why.

local smoke = require("SmokeTest")
local env = require("PingScanEnv")

env.Stub()

smoke.Run("PingScan", { install = false })
