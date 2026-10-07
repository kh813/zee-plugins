-- Zee Plugin: case-converter
-- Converts text between various casing conventions.

local M = {}

-- Split string by whitespace, underscores, hyphens, or uppercase letter boundaries
local function split_words(str)
    local words = {}
    -- First replace hyphens and underscores with spaces
    local normalized = str:gsub("[-_]", " ")
    -- Insert spaces before capital letters if preceded by lowercase letter
    normalized = normalized:gsub("(%l)(%u)", "%1 %2")
    
    for word in normalized:gmatch("%S+") do
        table.insert(words, word:lower())
    end
    return words
end

function M.to_snake_case(text)
    local words = split_words(text)
    return table.concat(words, "_")
end

function M.to_kebab_case(text)
    local words = split_words(text)
    return table.concat(words, "-")
end

function M.to_constant_case(text)
    local words = split_words(text)
    local upper_words = {}
    for _, w in ipairs(words) do
        table.insert(upper_words, w:upper())
    end
    return table.concat(upper_words, "_")
end

function M.to_camel_case(text)
    local words = split_words(text)
    if #words == 0 then return text end
    
    local result = { words[1] }
    for i = 2, #words do
        local w = words[i]
        table.insert(result, w:sub(1, 1):upper() .. w:sub(2))
    end
    return table.concat(result, "")
end

-- Primary entry point for Zee command execution
function M.execute_command(command, text)
    if command == "to_snake_case" then
        return M.to_snake_case(text)
    elseif command == "to_kebab_case" then
        return M.to_kebab_case(text)
    elseif command == "to_constant_case" then
        return M.to_constant_case(text)
    elseif command == "to_camel_case" then
        return M.to_camel_case(text)
    else
        return text
    end
end

return M
