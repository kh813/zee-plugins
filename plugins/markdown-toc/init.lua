-- Zee Plugin: markdown-toc
-- Scans markdown headings and generates a linked Markdown Table of Contents.

local M = {}

local function slugify(text)
    local slug = text:lower()
    -- Remove non-alphanumeric characters except spaces and hyphens
    slug = slug:gsub("[^%w%s%-]", "")
    -- Replace spaces with hyphens
    slug = slug:gsub("%s+", "-")
    return slug
end

function M.generate_toc(content)
    local toc_lines = {}
    local in_code_block = false

    for line in content:gmatch("[^\r\n]+") do
        -- Toggle code block state
        if line:match("^%s*```") then
            in_code_block = not in_code_block
        elseif not in_code_block then
            -- Match headings # to ######
            local hashes, title = line:match("^(#+)%s+(.-)%s*$")
            if hashes and title then
                local level = #hashes
                local indent = string.rep("  ", level - 1)
                local anchor = slugify(title)
                local entry = string.format("%s- [%s](#%s)", indent, title, anchor)
                table.insert(toc_lines, entry)
            end
        end
    end

    if #toc_lines == 0 then
        return "<!-- No Markdown headings found -->"
    end

    return "## Table of Contents\n\n" .. table.concat(toc_lines, "\n") .. "\n"
end

function M.execute_command(command, content)
    if command == "generate_toc" then
        return M.generate_toc(content)
    else
        return content
    end
end

return M
