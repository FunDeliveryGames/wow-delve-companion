--- Minimal test framework: suites, cases, assertions. No dependencies.

local T = {}

local suites = {}

local function Dump(value)
    if type(value) == "string" then
        return string.format("%q", value)
    end

    return tostring(value)
end

--- Create a suite. Returns a function to add cases: `Case("name", function() ... end)`.
---@param name string
---@return fun(caseName: string, fn: function)
function T.Suite(name)
    local suite = { name = name, cases = {} }
    suites[#suites + 1] = suite

    return function(caseName, fn)
        suite.cases[#suite.cases + 1] = { name = caseName, fn = fn }
    end
end

local function Fail(message, default)
    error((message and (message .. ": ") or "") .. default, 3)
end

function T.Equals(actual, expected, message)
    if actual ~= expected then
        Fail(message, ("expected %s, got %s"):format(Dump(expected), Dump(actual)))
    end
end

function T.True(value, message)
    if value ~= true then
        Fail(message, ("expected true, got %s"):format(Dump(value)))
    end
end

function T.False(value, message)
    if value ~= false then
        Fail(message, ("expected false, got %s"):format(Dump(value)))
    end
end

function T.Nil(value, message)
    if value ~= nil then
        Fail(message, ("expected nil, got %s"):format(Dump(value)))
    end
end

function T.NotNil(value, message)
    if value == nil then
        Fail(message, "expected a value, got nil")
    end
end

--- Compare two arrays element by element (shallow).
function T.ListEquals(actual, expected, message)
    if type(actual) ~= "table" then
        Fail(message, ("expected a list, got %s"):format(Dump(actual)))
    end

    if #actual ~= #expected then
        Fail(message, ("expected %d element(s), got %d"):format(#expected, #actual))
    end

    for index = 1, #expected do
        if actual[index] ~= expected[index] then
            Fail(message, ("element %d: expected %s, got %s"):format(index, Dump(expected[index]), Dump(actual[index])))
        end
    end
end

--- Compare the keys of a set-like table `{ [key] = true }` with a list of expected keys.
function T.KeysEqual(actual, expectedKeys, message)
    local expected = {}
    for _, key in ipairs(expectedKeys) do
        expected[key] = true
        if not actual[key] then
            Fail(message, ("missing key %s"):format(Dump(key)))
        end
    end

    for key in pairs(actual) do
        if not expected[key] then
            Fail(message, ("unexpected key %s"):format(Dump(key)))
        end
    end
end

--- Assert that `fn` raises an error whose message contains `fragment` (plain text).
function T.Errors(fn, fragment, message)
    local ok, err = pcall(fn)
    if ok then
        Fail(message, "expected an error, none raised")
    end

    if fragment and not string.find(tostring(err), fragment, 1, true) then
        Fail(message, ("expected error containing %s, got %s"):format(Dump(fragment), Dump(err)))
    end
end

--- Run all suites. Returns the number of failed cases.
---@return integer failures
function T.Run()
    local passed, failed = 0, 0

    for _, suite in ipairs(suites) do
        print(suite.name)

        for _, case in ipairs(suite.cases) do
            local ok, err = xpcall(case.fn, debug.traceback)
            if ok then
                passed = passed + 1
                print("  ok    " .. case.name)
            else
                failed = failed + 1
                print("  FAIL  " .. case.name)
                print("        " .. tostring(err):gsub("\n", "\n        "))
            end
        end
    end

    print(("\n%d passed, %d failed"):format(passed, failed))
    return failed
end

return T
