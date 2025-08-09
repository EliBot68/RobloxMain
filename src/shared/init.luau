-- init.luau
-- Main shared module entry point
-- This properly exports shared utilities and constants

local Shared = {}

-- Core utilities (safe for both client and server)
Shared.Constants = require(script.constants.GameConstants)
Shared.Utils = require(script.utilities.SharedUtils)
Shared.SafeRequire = require(script.utilities.SafeRequire)

-- Return the shared module
return Shared
