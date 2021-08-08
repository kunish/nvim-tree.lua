local uv = vim.loop

local utils = require'nvim-tree.utils'
local explorer = require'nvim-tree.explore'

-- TODO:
-- handle refresh event
-- find a proper way to manage ignore

local M = {}

local Tree = {}
Tree.__index = Tree

local function set_timeout(timeout, callback)
  local timer = uv.new_timer()
  timer:start(timeout, 0, function()
    timer:stop()
    timer:close()
    vim.schedule_wrap(callback())
  end)
  return timer
end

local path_refresh_running = {}

local function new_watcher(path)
  local handle = uv.new_fs_event()
  uv.fs_event_start(handle, path, {}, function(err)
    if err or path_refresh_running[path] then
      return
    end
    path_refresh_running[path] = true

    local function refresh()
      require'nvim-tree.lib'.refresh_path(path)
    end
    vim.schedule(refresh)
    set_timeout(300, function()
      path_refresh_running[path] = false
    end)
  end)
  return handle
end

function Tree.new(_, opts, cwd)
  return setmetatable({
    cwd = cwd,
    children = explorer.scan_folder(cwd),
    group_empty = opts.group_empty or true,
    watcher = new_watcher(cwd),
  }, Tree)
end

function Tree:get_current_node(idx)
  return utils.find_node(
    self.children,
    function(_, i)
      return i == idx
    end
  )
end

function Tree:get_node_from_path(path)
  if path == self.cwd then
    return self
  end
  return utils.find_node(
    self.children,
    function(node)
      return node.absolute_path == path
    end
  )
end

function Tree:reload(path)
  local node = self:get_node_from_path(path)
  if not node then
    return
  end

  -- rescan the path, filter entry that might be removed, add existing entries
  if node.cwd then
    node.children = explorer.scan_folder(self.cwd)
  else
    node.children = {}
    node.open = false
    self:toggle_collapse(node)
  end
end

local function should_group(nodes)
  return #nodes == 1 and nodes[1].children ~= nil
end

local function should_populate(node)
  return node.open and #node.children == 0
end

function Tree:toggle_collapse(node)
  node.open = not node.open

  if should_populate(node) then
    local cwd = node.link_to or node.absolute_path
    node.children = explorer.scan_folder(cwd, node)
    node.watcher = node.watcher or new_watcher(cwd)
    if self.group_empty and should_group(node.children) then
      self:toggle_collapse(node.children[1])
    end
  end
end

function Tree.get_last_grouped_node(node)
  local next = node
  while next.children and #next.children == 1 and next.children[1].children do
    next = next.children[1]
  end
  return next
end

M.Tree = Tree

return M
