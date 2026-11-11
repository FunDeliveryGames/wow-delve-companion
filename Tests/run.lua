--- Offline test runner. Usage (from anywhere): lua Tests/run.lua
--- Requires Lua 5.2+ (uses loadfile with a custom environment). WoW runs Lua 5.1: avoid 5.2-only features in addon code.
---@diagnostic disable: undefined-global

local testsDir = (arg and arg[0] or ""):match("^(.*)[/\\][^/\\]+$") or "."

local T = dofile(testsDir .. "/framework.lua")
local Harness = dofile(testsDir .. "/stubs/wow.lua")
Harness.root = testsDir .. "/.."

local SPECS = {
    "spec/LibResetTracker_spec.lua",
    "spec/DelvesData_spec.lua",
    "spec/UISkin_spec.lua"
}

for _, spec in ipairs(SPECS) do
    local chunk = assert(loadfile(testsDir .. "/" .. spec))
    chunk(T, Harness)
end

os.exit(T.Run() == 0 and 0 or 1)
