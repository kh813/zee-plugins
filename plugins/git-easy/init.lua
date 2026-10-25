-- Zee Plugin: Git Easy
-- Simple, personal Git version control for Markdown documents and skills.

local M = {}

-- ---------------------------------------------------------------------------
-- Constants & Templates
-- ---------------------------------------------------------------------------

-- Cross-platform OS & Editor ignore patterns grouped by platform
local OS_SECTIONS = {
    {
        name = "macOS",
        patterns = {
            ".DS_Store",
            ".DS_Store?",
            "._*",
            ".Spotlight-V100",
            ".Trashes",
            ".AppleDouble",
            ".LSOverride",
        }
    },
    {
        name = "Windows",
        patterns = {
            "Thumbs.db",
            "Thumbs.db:encryptable",
            "ehthumbs.db",
            "ehthumbs_vista.db",
            "desktop.ini",
            "$RECYCLE.BIN/",
        }
    },
    {
        name = "Linux & Temporary Files",
        patterns = {
            "*~",
            ".fuse_hidden*",
            ".directory",
            "*.swp",
            "*.swo",
            "*.tmp",
            "*.bak",
            ".zee/",
        }
    }
}

local DEFAULT_GITIGNORE = [[# ==============================================================================
# OS Generated Files (macOS, Windows, Linux)
# ==============================================================================
# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
.AppleDouble
.LSOverride

# Windows
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
ehthumbs_vista.db
desktop.ini
$RECYCLE.BIN/

# Linux
*~
.fuse_hidden*
.directory

# ==============================================================================
# Editor & Temporary Files
# ==============================================================================
*.swp
*.swo
*.tmp
*.bak
.zee/

# ==============================================================================
# Build & Cache Artifacts
# ==============================================================================
target/
dist/
node_modules/
]]

-- ---------------------------------------------------------------------------
-- Shell & Git Utilities
-- ---------------------------------------------------------------------------

local function get_workspace_root()
    local ws = os.getenv("ZEE_WORKSPACE_ROOT")
    if ws and ws ~= "" then
        return ws
    end
    return nil
end

local function git_exec(cmd_str)
    local ws = get_workspace_root()
    local cmd
    if ws and ws ~= "" then
        cmd = string.format('git -C "%s" %s 2>&1', ws:gsub('"', '\\"'), cmd_str)
    else
        cmd = "git " .. cmd_str .. " 2>&1"
    end
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute git process"
    end
    local output = handle:read("*a") or ""
    local ok = handle:close()
    -- Clean trailing whitespace/newlines
    output = output:gsub("[\r\n]+$", "")
    return output, ok
end

local function is_git_installed()
    local _, ok = git_exec("--version")
    return ok
end

local function get_repo_root()
    local ws = get_workspace_root()
    if ws and ws ~= "" then
        return ws
    end
    local root, ok = git_exec("rev-parse --show-toplevel")
    if ok and root and root ~= "" then
        return root
    end
    return "."
end

local function cleanup_tracked_os_garbage()
    -- Automatically detect and untrack OS garbage files if they were accidentally tracked
    local tracked_files, ok = git_exec("ls-files")
    if ok and tracked_files and tracked_files ~= "" then
        for line in tracked_files:gmatch("[^\r\n]+") do
            local basename = line:match("([^/]+)$") or line
            if basename == ".DS_Store" or basename == "Thumbs.db" or basename == "desktop.ini" or basename:match("^%._") then
                git_exec(string.format('rm --cached --quiet "%s"', line:gsub('"', '\\"')))
            end
        end
    end
end

local function ensure_gitignore()
    local root = get_repo_root()
    local gitignore_path = root .. "/.gitignore"
    local f = io.open(gitignore_path, "r")
    if not f then
        -- Create fresh .gitignore with full defaults
        local wf = io.open(gitignore_path, "w")
        if wf then
            wf:write(DEFAULT_GITIGNORE)
            wf:close()
        end
    else
        -- If .gitignore already exists, check what is already configured
        local existing = f:read("*a") or ""
        f:close()

        -- Parse all non-comment active rules
        local existing_rules = {}
        for line in existing:gmatch("[^\r\n]+") do
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
            if #trimmed > 0 and not trimmed:match("^#") then
                existing_rules[trimmed] = true
            end
        end

        -- Check if any cross-platform OS pattern is missing
        local has_missing = false
        for _, section in ipairs(OS_SECTIONS) do
            for _, pat in ipairs(section.patterns) do
                if not existing_rules[pat] then
                    has_missing = true
                    break
                end
            end
            if has_missing then break end
        end

        if has_missing then
            local buf = {}
            if #existing > 0 and existing:sub(-1) ~= "\n" then
                table.insert(buf, "")
            end
            table.insert(buf, "")
            table.insert(buf, "# ==============================================================================")
            table.insert(buf, "# Protected by Git Easy (Cross-Platform OS & Editor Ignores)")
            table.insert(buf, "# ==============================================================================")

            for _, section in ipairs(OS_SECTIONS) do
                table.insert(buf, "# " .. section.name)
                for _, pat in ipairs(section.patterns) do
                    if existing_rules[pat] then
                        table.insert(buf, "# " .. pat .. " (already in .gitignore)")
                    else
                        table.insert(buf, pat)
                        existing_rules[pat] = true
                    end
                end
                table.insert(buf, "")
            end

            local af = io.open(gitignore_path, "a")
            if af then
                af:write(table.concat(buf, "\n"))
                af:close()
            end
        end
    end

    -- Clean any accidentally tracked OS files from index
    cleanup_tracked_os_garbage()
end

local function ensure_git_repo()
    local _, ok = git_exec("rev-parse --is-inside-work-tree")
    if not ok then
        git_exec("init")
        -- Initialize with default main branch
        git_exec("branch -M main")
    end
    ensure_gitignore()
end

local function get_current_branch()
    local branch, ok = git_exec("branch --show-current")
    if ok and branch and branch ~= "" then
        return branch
    end
    -- Fallback for detached HEAD
    local head_rev, _ = git_exec("rev-parse --short HEAD")
    if head_rev and head_rev ~= "" then
        return "(detached " .. head_rev .. ")"
    end
    return "main"
end

local function get_main_branch()
    local _, ok_main = git_exec("rev-parse --verify refs/heads/main")
    if ok_main then return "main" end
    local _, ok_master = git_exec("rev-parse --verify refs/heads/master")
    if ok_master then return "master" end
    return "main"
end

local function get_last_draft()
    local val, ok = git_exec("config --local git-easy.last-draft")
    if ok and val and val ~= "" then
        return val
    end
    -- Fallback: check most recent draft branch
    local branch_list, b_ok = git_exec("branch --list 'draft/*' --sort=-committerdate")
    if b_ok and branch_list and branch_list ~= "" then
        for b in branch_list:gmatch("[^\r\n]+") do
            local clean = b:gsub("^[%*%s]+", "")
            if clean ~= "" then
                return clean
            end
        end
    end
    return nil
end

local function set_last_draft(branch_name)
    if branch_name and branch_name ~= "" then
        git_exec(string.format("config --local git-easy.last-draft '%s'", branch_name))
    end
end

-- Get files modified in the last commit
local function get_last_commit_files()
    local output, ok = git_exec("diff-tree --no-commit-id --name-only -r HEAD")
    local files = {}
    if ok and output and output ~= "" then
        for line in output:gmatch("[^\r\n]+") do
            table.insert(files, line)
        end
    end
    return files
end

-- Find modified files in git status
local function get_modified_files()
    local output, ok = git_exec("status --porcelain")
    local files = {}
    if ok and output and output ~= "" then
        for line in output:gmatch("[^\r\n]+") do
            local file = line:sub(4)
            -- Trim quotes if any
            file = file:gsub('^"', ''):gsub('"$', '')
            table.insert(files, file)
        end
    end
    return files
end

-- Read file from disk
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- Slugify a string for branch name
local function slugify(str)
    local slug = str:lower()
    slug = slug:gsub("[^%w%s%-]", "")
    slug = slug:gsub("%s+", "-")
    slug = slug:gsub("^%-+", ""):gsub("%-+$", "")
    if #slug == 0 then
        slug = "draft"
    end
    return slug:sub(1, 30)
end

-- Extract first Markdown heading from content
local function extract_heading(content)
    for line in content:gmatch("[^\r\n]+") do
        local hashes, title = line:match("^(#+)%s+(.-)%s*$")
        if hashes and title then
            title = title:gsub("[%*_`]", "")
            if #title > 0 then
                return title:sub(1, 40)
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Core Git Easy Commands
-- ---------------------------------------------------------------------------

-- 1. Save Snapshot (Commit)
function M.save_snapshot(content)
    ensure_git_repo()

    local timestamp = os.date("%Y-%m-%d %H:%M")
    local commit_msg = nil

    -- Check if content looks like a short selection used as commit message
    -- (e.g. user selected text under 80 chars without newlines)
    if #content > 0 and #content <= 80 and not content:find("\n") then
        commit_msg = string.format("Snapshot: %s (%s)", content, timestamp)
    else
        local heading = extract_heading(content)
        if heading then
            commit_msg = string.format("Snapshot: [%s] %s", heading, timestamp)
        else
            commit_msg = string.format("Snapshot: %s", timestamp)
        end
    end

    -- Stage all changes and commit
    git_exec("add -A")
    local _, _ = git_exec(string.format('commit -m "%s"', commit_msg:gsub('"', '\\"')))

    -- Always return the original content so editor buffer is preserved intact
    return content
end

-- 2. New Draft (Create and switch to a draft branch)
function M.new_draft(content)
    ensure_git_repo()

    -- Automatically save current work first
    M.save_snapshot(content)

    local branch_suffix = nil
    -- If user selected short text, use it as draft branch name
    if #content > 0 and #content <= 50 and not content:find("\n") then
        branch_suffix = slugify(content)
    else
        local heading = extract_heading(content)
        if heading then
            branch_suffix = slugify(heading) .. "-" .. os.date("%m%d-%H%M")
        else
            branch_suffix = "rev-" .. os.date("%Y%m%d-%H%M%S")
        end
    end

    local branch_name = "draft/" .. branch_suffix
    local _, ok = git_exec(string.format("checkout -b '%s'", branch_name))
    if ok then
        set_last_draft(branch_name)
    end

    return content
end

-- 3. Merge Draft (Apply draft branch into main)
function M.merge_draft(content)
    ensure_git_repo()

    local current = get_current_branch()
    local main_branch = get_main_branch()

    -- Check if currently on a draft branch
    if current == main_branch or not current:match("^draft/") then
        -- Already on main or not a draft, nothing to merge
        return content
    end

    -- Save any remaining uncommitted changes in the draft
    M.save_snapshot(content)

    -- Switch to main branch
    local _, switch_ok = git_exec(string.format("checkout '%s'", main_branch))
    if not switch_ok then
        return content
    end

    -- Merge draft into main with --no-ff to record explicit merge snapshot
    local merge_msg = string.format("Apply draft '%s' into %s", current, main_branch)
    local _, _ = git_exec(string.format('merge --no-ff "%s" -m "%s"', current, merge_msg))

    -- Try to reload the active file from disk if modified
    local commit_files = get_last_commit_files()
    if #commit_files >= 1 then
        local disk_content = read_file(commit_files[1])
        if disk_content then
            return disk_content
        end
    end

    return content
end

-- 4. Switch Draft / Main (Toggle between draft and main)
function M.switch_draft(content)
    ensure_git_repo()

    local current = get_current_branch()
    local main_branch = get_main_branch()
    local target_branch = nil

    -- Save changes before switching
    M.save_snapshot(content)

    if current:match("^draft/") then
        -- Remember this draft before switching back to main
        set_last_draft(current)
        target_branch = main_branch
    else
        -- Currently on main, switch to last active draft
        local last_draft = get_last_draft()
        if last_draft then
            target_branch = last_draft
        else
            -- No prior draft found, create a new one
            return M.new_draft(content)
        end
    end

    local _, ok = git_exec(string.format("checkout '%s'", target_branch))
    if ok then
        -- Try to reload file content from disk after branch checkout
        local mod_files = get_modified_files()
        if #mod_files == 1 then
            local disk_content = read_file(mod_files[1])
            if disk_content then
                return disk_content
            end
        end
    end

    return content
end

-- 5. Restore Latest (Rollback buffer to HEAD snapshot)
function M.restore_latest(content)
    ensure_git_repo()

    -- Look for the modified file in status
    local mod_files = get_modified_files()
    if #mod_files >= 1 then
        local target_file = mod_files[1]
        local head_content, ok = git_exec(string.format("show HEAD:'%s'", target_file))
        if ok and head_content and head_content ~= "" then
            return head_content
        end
    end

    -- Fallback: checkout working directory to HEAD
    git_exec("checkout HEAD -- .")
    if #mod_files >= 1 then
        local disk_content = read_file(mod_files[1])
        if disk_content then
            return disk_content
        end
    end

    return content
end

-- 6. View History (Insert/update version history markdown block)
function M.history(content)
    ensure_git_repo()

    local current_branch = get_current_branch()
    local log_out, ok = git_exec('log -n 8 --pretty=format:"* %ad [%h] %s" --date=format:"%Y-%m-%d %H:%M"')

    local history_body = ""
    if ok and log_out and log_out ~= "" then
        history_body = log_out
    else
        history_body = "* (No snapshot history found yet)"
    end

    local block = string.format(
        "<!-- BEGIN Git Easy History -->\n### 📜 Version History (Branch: `%s`)\n%s\n<!-- END Git Easy History -->",
        current_branch,
        history_body
    )

    -- If history block already exists in document, replace it
    if content:find("<!%-%- BEGIN Git Easy History %-%->") then
        local pattern = "<!%-%- BEGIN Git Easy History %-%->.-<!%-%- END Git Easy History %-%->"
        local updated, count = content:gsub(pattern, block)
        if count > 0 then
            return updated
        end
    end

    -- If user selected text, replace the selection with the history block
    if #content > 0 and #content <= 120 and not content:find("\n") then
        return block
    end

    -- Otherwise append to end of document
    if content:sub(-1) == "\n" then
        return content .. "\n" .. block .. "\n"
    else
        return content .. "\n\n" .. block .. "\n"
    end
end

-- 7. Show Status (Insert/update status banner)
function M.status(content)
    ensure_git_repo()

    local branch = get_current_branch()
    local last_log, _ = git_exec('log -1 --pretty=format:"[%h] %s (%cr)"')
    if not last_log or last_log == "" then
        last_log = "No commits yet"
    end

    local mod_files = get_modified_files()
    local status_desc = ""
    if #mod_files == 0 then
        status_desc = "Clean (all saved)"
    else
        status_desc = string.format("%d file(s) modified", #mod_files)
    end

    local block = string.format(
        "<!-- BEGIN Git Easy Status -->\n> [!NOTE]\n> **Git Easy Status**\n> - **Current Branch**: `%s`\n> - **Last Snapshot**: %s\n> - **Working Tree**: %s\n<!-- END Git Easy Status -->",
        branch,
        last_log,
        status_desc
    )

    -- If status block already exists, update in place
    if content:find("<!%-%- BEGIN Git Easy Status %-%->") then
        local pattern = "<!%-%- BEGIN Git Easy Status %-%->.-<!%-%- END Git Easy Status %-%->"
        local updated, count = content:gsub(pattern, block)
        if count > 0 then
            return updated
        end
    end

    -- Otherwise prepend or append
    return block .. "\n\n" .. content
end

-- 8. Add File to Version Control (git add)
function M.add_file(content, target_file)
    ensure_git_repo()

    local file_to_add = target_file
    if not file_to_add or file_to_add == "" then
        -- If content is a single filename (short, single-line)
        if #content > 0 and #content <= 200 and not content:find("\n") then
            file_to_add = content:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    if file_to_add and file_to_add ~= "" then
        git_exec(string.format('add "%s"', file_to_add:gsub('"', '\\"')))
    else
        git_exec("add -A")
    end

    return content
end

-- 9. Exclude File from Version Control (add to .gitignore & unstage)
function M.ignore_file(content, target_file)
    ensure_git_repo()

    local file_to_ignore = target_file
    if not file_to_ignore or file_to_ignore == "" then
        if #content > 0 and #content <= 200 and not content:find("\n") then
            file_to_ignore = content:gsub("^%s+", ""):gsub("%s+$", "")
        else
            local mod_files = get_modified_files()
            if #mod_files >= 1 then
                file_to_ignore = mod_files[1]
            end
        end
    end

    if not file_to_ignore or file_to_ignore == "" then
        return content
    end

    local root = get_repo_root()
    local gitignore_path = root .. "/.gitignore"

    -- Read existing .gitignore
    local existing = ""
    local rf = io.open(gitignore_path, "r")
    if rf then
        existing = rf:read("*a") or ""
        rf:close()
    else
        existing = DEFAULT_GITIGNORE
    end

    -- Clean target filename
    local clean_name = file_to_ignore:gsub("^%./", "")

    -- Check if already present in .gitignore
    local escaped_name = clean_name:gsub("%-", "%%-"):gsub("%.", "%%.")
    local pattern = "(^|[\r\n])" .. escaped_name .. "([\r\n]|$)"
    if not existing:find(pattern) then
        local wf = io.open(gitignore_path, "a")
        if wf then
            if #existing > 0 and existing:sub(-1) ~= "\n" then
                wf:write("\n")
            end
            wf:write(clean_name .. "\n")
            wf:close()
        end
    end

    -- If file is already tracked by git, remove it from git cache (untrack)
    git_exec(string.format('rm --cached "%s"', clean_name:gsub('"', '\\"')))

    return content
end

-- 9b. Remove File from .gitignore (Unignore)
function M.unignore_file(content, target_file)
    ensure_git_repo()

    local file_to_unignore = target_file
    if not file_to_unignore or file_to_unignore == "" then
        if #content > 0 and #content <= 200 and not content:find("\n") then
            file_to_unignore = content:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end

    if not file_to_unignore or file_to_unignore == "" then
        return content
    end

    local root = get_repo_root()
    local gitignore_path = root .. "/.gitignore"
    local rf = io.open(gitignore_path, "r")
    if not rf then
        return content
    end

    local lines = {}
    local clean_name = file_to_unignore:gsub("^%./", "")
    for line in rf:lines() do
        local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= clean_name and trimmed ~= ("/" .. clean_name) then
            table.insert(lines, line)
        end
    end
    rf:close()

    local wf = io.open(gitignore_path, "w")
    if wf then
        wf:write(table.concat(lines, "\n") .. "\n")
        wf:close()
    end

    return content
end

-- 10. Inspect File Version State (Helper for UI & right-click menu)
-- Returns: "untracked" | "modified" | "clean" | "ignored"
function M.get_file_state(filepath)
    ensure_git_repo()
    if not filepath or filepath == "" then return "clean" end

    local clean = filepath:gsub("^%./", "")
    local out, ok = git_exec(string.format('status --porcelain "%s"', clean:gsub('"', '\\"')))
    if not ok or not out or out == "" then
        local ign_out, ign_ok = git_exec(string.format('check-ignore "%s"', clean:gsub('"', '\\"')))
        if ign_ok and ign_out and ign_out ~= "" then
            return "ignored"
        end
        return "clean"
    end

    local code = out:sub(1, 2)
    if code:find("?") then
        return "untracked"
    elseif code:find("M") or code:find("A") or code:find("D") then
        return "modified"
    end
    return "clean"
end

-- ---------------------------------------------------------------------------
-- Plugin Entry Points
-- ---------------------------------------------------------------------------

function M.execute_command(command, content)
    if not is_git_installed() then
        return content
    end

    if command == "git_easy_snapshot" then
        return M.save_snapshot(content)
    elseif command == "git_easy_new_draft" then
        return M.new_draft(content)
    elseif command == "git_easy_merge_draft" then
        return M.merge_draft(content)
    elseif command == "git_easy_switch_draft" then
        return M.switch_draft(content)
    elseif command == "git_easy_restore_latest" then
        return M.restore_latest(content)
    elseif command == "git_easy_history" then
        return M.history(content)
    elseif command == "git_easy_status" then
        return M.status(content)
    elseif command == "git_easy_add_file" then
        return M.add_file(content)
    elseif command == "git_easy_ignore_file" then
        return M.ignore_file(content)
    elseif command == "git_easy_unignore_file" then
        return M.unignore_file(content)
    else
        return content
    end
end

function M.transform_text(command, content)
    return M.execute_command(command, content)
end

return M
