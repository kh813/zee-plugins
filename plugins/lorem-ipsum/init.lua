-- Zee Plugin: lorem-ipsum
-- Generates placeholder Latin text.

local M = {}

local PARAGRAPH = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

local SENTENCE = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

function M.execute_command(command, _text)
    if command == "lorem_sentence" then
        return SENTENCE
    elseif command == "lorem_paragraph" then
        return PARAGRAPH
    elseif command == "lorem_paragraphs_3" then
        return PARAGRAPH .. "\n\n" .. PARAGRAPH .. "\n\n" .. PARAGRAPH
    else
        return PARAGRAPH
    end
end

return M
