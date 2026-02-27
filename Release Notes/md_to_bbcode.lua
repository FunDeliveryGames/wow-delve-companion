local inputFile = arg[1]
if not inputFile then
    error("No input file provided.")
end

local outputFile = arg[2]

local function read_file(path)
    local f = assert(io.open(path, "r"))
    local content = f:read("*a")
    f:close()
    return content
end

local function write_file(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
end

---------------------------------------------------
-- Inline formatting
---------------------------------------------------

local function convert_inline(line)
    -- Remove HTML <br> tags (all common variants, case-insensitive)
    line = line:gsub("<%s*[bB][rR]%s*/?%s*>", "")

    -- Images: ![alt text](url)
    -- Must run BEFORE link conversion
    line = line:gsub("!%[.-%]%((.-)%)", function(url)
        return "[img]" .. url .. "[/img]"
    end)

    -- Links: [text](url)
    line = line:gsub("%[([^%!][^%]]-)%]%((.-)%)", function(text, url)
        return "[url=" .. url .. "]" .. text .. "[/url]"
    end)

    -- Bold: **text**
    line = line:gsub("%*%*(.-)%*%*", "[b]%1[/b]")

    return line
end

---------------------------------------------------
-- Main conversion
---------------------------------------------------

local function convert(md)
    local output = {}
    local listStack = 0

    local function closeLists(toLevel)
        while listStack > toLevel do
            table.insert(output, string.rep("    ", listStack - 1) .. "[/list]")
            listStack = listStack - 1
        end
    end

    for rawLine in md:gmatch("([^\n]*)\n?") do
        local line = rawLine

        -- Headings
        if line:match("^##%s+") then
            closeLists(0)
            local text = line:gsub("^##%s+", "")
            table.insert(output, "[size=4][b]" .. convert_inline(text) .. "[/b][/size]")
        elseif line:match("^###%s+") then
            closeLists(0)
            local text = line:gsub("^###%s+", "")
            table.insert(output, "[b]" .. convert_inline(text) .. "[/b]")

            -- List item
        elseif line:match("^%s*%- ") then
            local indent = line:match("^(%s*)%- ")
            local level = math.floor(#indent / 4) + 1 -- 4 spaces per indent

            -- Adjust list depth
            if level > listStack then
                while listStack < level do
                    table.insert(output, string.rep("    ", listStack) .. "[list]")
                    listStack = listStack + 1
                end
            elseif level < listStack then
                closeLists(level)
            end

            local content = line:gsub("^%s*%- ", "")
            content = convert_inline(content)

            table.insert(output,
                string.rep("    ", listStack) .. "[*]" .. content
            )

            -- Empty line
        elseif line:match("^%s*$") then
            closeLists(0)
            table.insert(output, "")

            -- Horizontal rule (*** or ---)
        elseif line:match("^%s*%*%*%*%s*$")
            or line:match("^%s*%-%-%-%s*$") then
            closeLists(0)

            table.insert(output, "────────────────────────────────────────")

            -- Normal paragraph
        else
            closeLists(0)
            table.insert(output, convert_inline(line))
        end
    end

    -- Final safety close
    closeLists(0)

    return table.concat(output, "\n")
end

---------------------------------------------------

local content = read_file(inputFile)
local converted = convert(content)
write_file(outputFile, converted)

print("Converted:", inputFile, "→", outputFile)
