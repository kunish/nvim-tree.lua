local utils = require'nvim-tree.utils'

local M = {
  show_ignored = false,
  show_dotfiles = vim.g.nvim_tree_hide_dotfiles ~= 1,
}

local function should_ignore_git()
end

local IGNORE_LIST = {}

local function should_ignore(path)
  local basename = utils.path_basename(path)
  if IGNORE_LIST[basename] or IGNORE_LIST[path] then
    return true
  end

  local idx = path:match(".+()%.%w+$")
  if idx then
    if IGNORE_LIST['*'..string.sub(path, idx)] then
      return true
    end
  end
end

local function return_false()
  return false
end

function M.load()
  if not M.show_ignored and vim.g.nvim_tree_gitignore == 1 then
    M.should_ignore_git = should_ignore_git
  else
    M.should_ignore_git = return_false
  end

  if not M.show_ignored and #(vim.g.nvim_tree_ignore or {}) > 0 then
    for _, entry in pairs(vim.g.nvim_tree_ignore) do
      IGNORE_LIST[entry] = true
    end
    M.should_ignore = should_ignore
  else
    M.should_ignore = return_false
  end
end

function M.filter_ignored(entries)
  return entries
  -- return vim.tbl_filter(function(node)
  --   return not M.should_ignore(node.absolute_path)
  -- end, entries)
end

M.load()

return M

-- local function gen_ignore_check(cwd)
--   if not cwd then cwd = luv.cwd() end

--   ---Check if the given path should be ignored.
--   ---@param path string Absolute path
--   ---@return boolean
--   return function(path)
--     local basename = utils.path_basename(path)

--     if not M.show_ignored then
--       if vim.g.nvim_tree_gitignore == 1 then
--         if git.should_gitignore(path) then return true end
--       end

--       local relpath = utils.path_relative(path, cwd)
--       if ignore_list[relpath] == true or ignore_list[basename] == true then
--         return true
--       end

--       local idx = path:match(".+()%.%w+$")
--       if idx then
--         if ignore_list['*'..string.sub(path, idx)] == true then return true end
--       end
--     end

--     if not M.show_dotfiles then
--       if basename:sub(1, 1) == '.' then return true end
--     end

--     return false
--   end
-- end

-- local should_ignore = gen_ignore_check()
--
-- local function git_update_callback(git_root, git_status, entries, parent_node)
--   if not parent_node then parent_node = {} end

--   local matching_cwd = utils.path_to_matching_str( utils.path_add_trailing(git_root) )

--   for _, node in pairs(entries) do
--     if parent_node.git_status == "!!" then
--       node.git_status = "!!"
--     else
--       local relpath = node.absolute_path:gsub(matching_cwd, '')
--       if node.entries ~= nil then
--         relpath = utils.path_add_trailing(relpath)
--         node.git_status = nil
--       end

--       local status = git_status[relpath]
--       if status then
--         node.git_status = status
--       elseif node.entries ~= nil then
--         for path, entry_status in pairs(git_status) do
--           if entry_status ~= "!!" and utils.match_path(path, relpath) then
--             node.git_status = entry_status
--             break
--           end
--         end
--       else
--         node.git_status = nil
--       end
--     end
--   end
-- end
