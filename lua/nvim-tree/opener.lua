local a = vim.api
local view = require'nvim-tree.view'
local config = require'nvim-tree.config'
local utils = require'nvim-tree.utils'
local renderer = require'nvim-tree.renderer'

local M = {
  target_winid = nil
}

function M.set_target_win()
  local id = a.nvim_get_current_win()
  local tree_id = view.get_winnr()
  if tree_id and id == tree_id then
    M.target_winid = 0
    return
  end

  M.target_winid = id
end

---Get user to pick a window. Selectable windows are all windows in the current
---tabpage that aren't NvimTree.
---@return integer|nil -- If a valid window was picked, return its id. If an
---       invalid window was picked / user canceled, return nil. If there are
---       no selectable windows, return -1.
function M.pick_window()
  local tabpage = a.nvim_get_current_tabpage()
  local win_ids = a.nvim_tabpage_list_wins(tabpage)
  local tree_winid = view.get_winnr(tabpage)
  local exclude = config.window_picker_exclude()

  local selectable = vim.tbl_filter(function (id)
    local bufid = a.nvim_win_get_buf(id)
    for option, v in pairs(exclude) do
      local ok, option_value = pcall(a.nvim_buf_get_option, bufid, option)
      if ok and vim.tbl_contains(v, option_value) then
        return false
      end
    end

    local win_config = a.nvim_win_get_config(id)
    return id ~= tree_winid
      and win_config.focusable
      and not win_config.external
  end, win_ids)

  -- If there are no selectable windows: return. If there's only 1, return it without picking.
  if #selectable == 0 then return -1 end
  if #selectable == 1 then return selectable[1] end

  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  if vim.g.nvim_tree_window_picker_chars then
    chars = tostring(vim.g.nvim_tree_window_picker_chars):upper()
  end

  local i = 1
  local win_opts = {}
  local win_map = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2

  -- Setup UI
  for _, id in ipairs(selectable) do
    local char = chars:sub(i, i)
    local ok_status, statusline = pcall(a.nvim_win_get_option, id, "statusline")
    local ok_hl, winhl = pcall(a.nvim_win_get_option, id, "winhl")

    win_opts[id] = {
      statusline = ok_status and statusline or "",
      winhl = ok_hl and winhl or ""
    }
    win_map[char] = id

    a.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=")
    a.nvim_win_set_option(
      id, "winhl", "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker"
    )

    i = i + 1
    if i > #chars then break end
  end

  vim.cmd("redraw")
  print("Pick window: ")
  local _, resp = pcall(utils.get_user_input_char)
  resp = (resp or ""):upper()
  utils.clear_prompt()

  -- Restore window options
  for _, id in ipairs(selectable) do
    for opt, value in pairs(win_opts[id]) do
      a.nvim_win_set_option(id, opt, value)
    end
  end

  vim.o.laststatus = laststatus

  return win_map[resp]
end

function M.open_file(mode, filename)
  if mode == "tabnew" then
    M.open_file_in_tab(filename)
    return
  end

  local tabpage = a.nvim_get_current_tabpage()
  local win_ids = a.nvim_tabpage_list_wins(tabpage)

  local target_winid
  if vim.g.nvim_tree_disable_window_picker == 1 then
    target_winid = M.target_winid
  else
    target_winid = M.pick_window()
  end

  if target_winid == -1 then
    target_winid = M.target_winid
  elseif target_winid == nil then
    return
  end

  local do_split = mode == "split" or mode == "vsplit"
  local vertical = mode ~= "split"

  -- Check if filename is already open in a window
  local found = false
  for _, id in ipairs(win_ids) do
    if filename == a.nvim_buf_get_name(a.nvim_win_get_buf(id)) then
      if mode == "preview" then return end
      found = true
      a.nvim_set_current_win(id)
      break
    end
  end

  if not found then
    if not target_winid or not vim.tbl_contains(win_ids, target_winid) then
      -- Target is invalid, or window does not exist in current tabpage: create
      -- new window
      vim.cmd(config.window_options().split_command .. " vsp")
      target_winid = a.nvim_get_current_win()
      M.target_winid = target_winid

      -- No need to split, as we created a new window.
      do_split = false
    elseif not vim.o.hidden then
      -- If `hidden` is not enabled, check if buffer in target window is
      -- modified, and create new split if it is.
      local target_bufid = a.nvim_win_get_buf(target_winid)
      if a.nvim_buf_get_option(target_bufid, "modified") then
        do_split = true
      end
    end

    local cmd
    if do_split then
      cmd = string.format("%ssplit ", vertical and "vertical " or "")
    else
      cmd = "edit "
    end

    cmd = cmd .. vim.fn.fnameescape(filename)
    a.nvim_set_current_win(target_winid)
    vim.cmd(cmd)
    view.resize()
  end

  if mode == "preview" then
    view.focus()
    return
  end

  if vim.g.nvim_tree_quit_on_open == 1 then
    view.close()
  end

  renderer.draw(false)
end

function M.open_file_in_tab(filename)
  local close = vim.g.nvim_tree_quit_on_open == 1
  if close then
    view.close()
  else
    -- Switch window first to ensure new window doesn't inherit settings from
    -- NvimTree
    if M.target_winid > 0 and a.nvim_win_is_valid(M.target_winid) then
      a.nvim_set_current_win(M.target_winid)
    else
      vim.cmd("wincmd p")
    end
  end

  -- This sequence of commands are here to ensure a number of things: the new
  -- buffer must be opened in the current tabpage first so that focus can be
  -- brought back to the tree if it wasn't quit_on_open. It also ensures that
  -- when we open the new tabpage with the file, its window doesn't inherit
  -- settings from NvimTree, as it was already loaded.

  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  local alt_bufid = vim.fn.bufnr("#")
  if alt_bufid ~= -1 then
    a.nvim_set_current_buf(alt_bufid)
  end

  if not close then
    vim.cmd("wincmd p")
  end

  vim.cmd("tabe " .. vim.fn.fnameescape(filename))
end

return M
