local utils = require'nvim-tree.utils'
local config = require'nvim-tree.config'

local M = {
  -- a list of absolute path with git status info
  status = {},
  roots = {},
}

local running_jobs = {}
local is_win32 = vim.fn.has('win32') == 1

local function apply_status_update(root)
  return function(_, data)
    local statuses = type(data[1]) == 'table' and data[1] or data

    for _, v in pairs(statuses) do
      if v ~= "" then
        local head = v:sub(0, 2)
        local body = v:sub(4, -1)
        if body:match('%->') ~= nil then
          body = body:gsub('^.* %-> ', '')
        end

        M.status[
          utils.path_remove_trailing(utils.path_join({root, body}))
        ] = head
      end
    end
  end
end

local function run_status_update(root, on_stdout, callback)
  return function(_, data)
    local job = { 'git', 'status', '--porcelain=v1' }
    if vim.trim(data[1]) ~= 'false' then
      table.insert(job, '-u')
    end

    if vim.g.nvim_tree_gitignore ~= -1 then
      table.insert(job, '--ignored=matching')
    end

    vim.fn.jobstart(job, {
      stdin = nil,
      detach = true,
      cwd = root,
      on_stdout = on_stdout,
      on_exit = function(_, code)
        if code ~= 0 then
          return
        end
        running_jobs[root] = nil
        if #running_jobs == 0 then
          callback()
        end
      end,
    })
  end
end

local function run_show_untracked(root, on_stdout)
  local job = { 'git', 'config', '--type=bool', 'status.showUntrackedFiles' }
  vim.fn.jobstart(job, {
    stdin = nil,
    detach = true,
    cwd = root,
    stdout_buffered = true,
    on_stdout = on_stdout
  })
end

local function update(root, callback)
  running_jobs[root] = true
  run_show_untracked(
    root, run_status_update(
      root,
      apply_status_update(root),
      callback
    )
  )
end

local function create_root(cwd, callback)
  return function(_, data)
    local root = data[1]

    if not root or #root == 0 or root:match('fatal') then
      M.roots[cwd] = false
      return callback()
    end

    if is_win32 then
      root = root:gsub("/", "\\")
    end

    M.roots[root] = true
    update(root, callback)
  end
end

local function run_create_root(cwd, callback)
  vim.fn.jobstart({
    'git',
    'rev-parse',
    '--show-toplevel'
  }, {
      stdin = nil,
      detach = true,
      cwd = cwd,
      on_stdout = create_root(cwd, callback),
      stdout_buffered = true,
    })
end

local function is_in_git(path)
  if M.roots[path] then
    return path
  end

  for name, status in pairs(M.roots) do
    if status then
      if utils.match_path(path, name) then
        return name
      end
    end
  end
end

function M.analyze_cwd(cwd, callback)
  if not config.use_git() or not cwd then
    return callback()
  end

  if is_in_git(cwd) then
    return callback()
  end

  run_create_root(cwd, callback)
end


local function reload_path(path, callback)
  local keys = vim.tbl_filter(function(p)
    return utils.match_path(p, path)
  end, vim.tbl_keys(M.status))

  M.status = vim.tbl_map(function(k)
    return { [k] = M.status[k] }
  end, keys)

  for root, status in pairs(M.roots) do
    if status and utils.match_path(path, root) then
      return update(root, callback)
    end
  end

  callback()
end

function M.reload(path, callback)
  if not config.use_git() or #running_jobs > 0 then
    return callback()
  end

  if path then
    return reload_path(path, callback)
  end

  local will_update = false
  M.status = {}
  for root, status in pairs(M.roots) do
    if status then
      will_update = true
      update(root, callback)
    end
  end
  if not will_update then
    callback()
  end
end

return M

