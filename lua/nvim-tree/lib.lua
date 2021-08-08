local api = vim.api
local luv = vim.loop

local renderer = require'nvim-tree.renderer'
local config = require'nvim-tree.config'
local git = require'nvim-tree.git'
local diagnostics = require'nvim-tree.diagnostics'
local utils = require'nvim-tree.utils'
local view = require'nvim-tree.view'
local events = require'nvim-tree.events'

local M = {}

-- local function get_node_at_line(line)
--   local index = 2
--   local function iter(entries)
--     for _, node in ipairs(entries) do
--       if index == line then
--         return node
--       end
--       index = index + 1
--       if node.open == true then
--         local child = iter(node.entries)
--         if child ~= nil then return child end
--       end
--     end
--   end
--   return iter
-- end

-- local function get_line_from_node(node, find_parent)
--   local node_path = node.absolute_path

--   if find_parent then
--     node_path = node.absolute_path:match("(.*)"..utils.path_separator)
--   end

--   local line = 2
--   local function iter(entries, recursive)
--     for _, entry in ipairs(entries) do
--       if node_path:match('^'..entry.match_path..'$') ~= nil then
--         return line, entry
--       end

--       line = line + 1
--       if entry.open == true and recursive then
--         local _, child = iter(entry.entries, recursive)
--         if child ~= nil then return line, child end
--       end
--     end
--   end
--   return iter
-- end

-- function M.get_node_at_cursor()
--   local cursor = api.nvim_win_get_cursor(view.get_winnr())
--   local line = cursor[1]
--   if view.is_help_ui() then
--     local help_lines, _ = renderer.draw_help()
--     local help_text = get_node_at_line(line+1)(help_lines)
--     return {name = help_text}
--   else
--     if line == 1 and M.Tree.cwd ~= "/" then
--       return { name = ".." }
--     end

--     if M.Tree.cwd == "/" then
--       line = line + 1
--     end
--     return get_node_at_line(line)(M.Tree.entries)
--   end
-- end



-- -- TODO update only entries where directory has changed
-- local function refresh_nodes(node)
--   refresh_entries(node.entries, node.absolute_path or node.cwd, node)
--   for _, entry in ipairs(node.entries) do
--     if entry.entries and entry.open then
--       refresh_nodes(entry)
--     end
--   end
-- end

-- function M.set_index_and_redraw(fname)
--   local i
--   if M.Tree.cwd == '/' then
--     i = 0
--   else
--     i = 1
--   end
--   local reload = false

--   local function iter(entries)
--     for _, entry in ipairs(entries) do
--       i = i + 1
--       if entry.absolute_path == fname then
--         return i
--       end

--       if fname:match(entry.match_path..utils.path_separator) ~= nil then
--         if #entry.entries == 0 then
--           reload = true
--           populate(entry.entries, entry.absolute_path, entry)
--           git.analyze_cwd(entry.absolute_path)
--         end
--         if entry.open == false then
--           reload = true
--           entry.open = true
--         end
--         if iter(entry.entries) ~= nil then
--           return i
--         end
--       elseif entry.open == true then
--         iter(entry.entries)
--       end
--     end
--   end

--   local index = iter(M.Tree.entries)
--   if not view.win_open() then
--     M.Tree.loaded = false
--     return
--   end
--   renderer.draw(reload)
--   if index then
--     view.set_cursor({index, 0})
--   end
-- end

-- function M.change_dir(name)
--   local changed_win = vim.v.event and vim.v.event.changed_window
--   local foldername = name == '..' and vim.fn.fnamemodify(M.Tree.cwd, ':h') or name
--   local no_cwd_change = vim.fn.expand(foldername) == M.Tree.cwd
--   if changed_win or no_cwd_change then
--     return
--   end

--   vim.cmd('lcd '..foldername)
--   M.Tree.cwd = foldername
--   M.Tree.entries = {}
--   M.init(false, true)
-- end

-- function M.sibling(node, direction)
--   if not direction then return end

--   local iter = get_line_from_node(node, true)
--   local node_path = node.absolute_path

--   local line = 0
--   local parent, _

--   -- Check if current node is already at root entries
--   for index, entry in ipairs(M.Tree.entries) do
--     if node_path:match('^'..entry.match_path..'$') ~= nil then
--       line = index
--     end
--   end

--   if line > 0 then
--     parent = M.Tree
--   else
--     _, parent = iter(M.Tree.entries, true)
--     if parent ~= nil and #parent.entries > 1 then
--       line, _ = get_line_from_node(node)(parent.entries)
--     end

--     -- Ignore parent line count
--     line = line - 1
--   end

--   local index = line + direction
--   if index < 1 then
--     index = 1
--   elseif index > #parent.entries then
--     index = #parent.entries
--   end
--   local target_node = parent.entries[index]

--   line, _ = get_line_from_node(target_node)(M.Tree.entries, true)
--   view.set_cursor({line, 0})
--   renderer.draw(true)
-- end

-- function M.close_node(node)
--   M.parent_node(node, true)
-- end

-- function M.parent_node(node, should_close)
--   if node.name == '..' then return end
--   should_close = should_close or false

--   local iter = get_line_from_node(node, true)
--   if node.open == true and should_close then
--     node.open = false
--   else
--     local line, parent = iter(M.Tree.entries, true)
--     if parent == nil then
--       line = 1
--     elseif should_close then
--       parent.open = false
--     end
--     api.nvim_win_set_cursor(view.get_winnr(), {line, 0})
--   end
--   renderer.draw(true)
-- end

-- function M.toggle_ignored()
--   pops.show_ignored = not pops.show_ignored
--   return M.refresh_tree()
-- end

-- function M.toggle_dotfiles()
--   pops.show_dotfiles = not pops.show_dotfiles
--   return M.refresh_tree()
-- end

function M.toggle_help()
  view.toggle_help()
  return renderer.draw(true)
end

-- function M.dir_up(node)
--   if not node or node.name == ".." then
--     return M.change_dir('..')
--   else
--     local newdir = vim.fn.fnamemodify(M.Tree.cwd, ':h')
--     M.change_dir(newdir)
--     return M.set_index_and_redraw(node.absolute_path)
--   end
-- end

-- REFACTO AFTER THIS COMMENT

local has_drawn = false

local function add_callback(f)
  return function(callback)
    f()
    if type(callback) == "function" then
      callback()
    end
  end
end

local function open()
  require'nvim-tree.opener'.set_target_win()
  view.open()
  if not has_drawn then
    renderer.draw(true)
  end
end

function M.toggle()
  if view.win_open() then
    view.close()
  else
    if vim.g.nvim_tree_follow == 1 then
      -- M.find_file(true)
    end
    if not view.win_open() then
      open()
    end
  end
end

function M.close()
  if view.win_open() then
    view.close()
    return true
  end
end

function M.tab_change()
  vim.schedule(function()
    if not view.win_open() and view.win_open({ any_tabpage = true }) then
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname:match("Neogit") ~= nil or bufname:match("--graph") ~= nil then
        return
      end
      view.open({ focus_tree = false })
    end
  end)
end

M.open = add_callback(open)

-- this is get_current_node
function M.get_node_at_cursor()
  local idx = vim.api.nvim_win_get_cursor(view.get_winnr())[1]
  return M.Tree:get_current_node(idx - 1)
end

function M.toggle_collapse(node)
  if M.Tree:toggle_collapse(node) then
    git.analyze_cwd(node.link_to or node.absolute_path)
  end
  renderer.draw(true)
  vim.schedule(diagnostics.update)
end

-- this is reload_entry or refresh_children
function M.refresh_path(path)
  git.reload(path, function()
    M.Tree:reload(path)
    renderer.draw(true)
    vim.schedule(diagnostics.update)
  end)
end

-- TODO: rewrite this one
function M.on_setup(opts)
  local bufnr = api.nvim_get_current_buf()
  local bufname = api.nvim_buf_get_name(bufnr)
  local buftype = api.nvim_buf_get_option(bufnr, 'filetype')
  local ft_ignore = vim.g.nvim_tree_auto_ignore_ft or {}

  local stats = luv.fs_stat(bufname)
  local is_dir = stats and stats.type == 'directory'

  local netrw_disabled = opts.disable_netrw or opts.hijack_netrw
  return {
    cwd = is_dir and vim.fn.expand(bufname) or vim.loop.cwd(),
    open = ((is_dir and netrw_disabled) or bufname == '') and not vim.tbl_contains(ft_ignore, buftype)
  }
end

function M.setup(opts)
  local v = M.on_setup(opts)

  git.analyze_cwd(v.cwd, function()
    M.Tree = require'nvim-tree.tree'.Tree:new(opts, v.cwd)
    -- handle logic for auto open here
    if v.open and opts.open_on_setup then
      M.open()
      renderer.draw(true)
      has_drawn = true
    end

    events._dispatch_ready()
  end)
end

return M
