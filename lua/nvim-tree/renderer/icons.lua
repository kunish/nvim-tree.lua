local web_devicons = require'nvim-web-devicons'

local M = {
  icons = require'nvim-tree.config'.get_icon_state().icons
}

local icon_padding = vim.g.nvim_tree_icon_padding or " "

local function empty_folder_icon()
  return ""
end

local function get_folder_icon(open, is_symlink, has_children)
  local n
  if is_symlink and open then
    n = M.icons.folder_icons.symlink_open
  elseif is_symlink then
    n = M.icons.folder_icons.symlink
  elseif open then
    if has_children then
      n = M.icons.folder_icons.open
    else
      n = M.icons.folder_icons.empty_open
    end
  else
    if has_children then
      n = M.icons.folder_icons.default
    else
      n = M.icons.folder_icons.empty
    end
  end
  return n..icon_padding
end

local function simple_folder_hl(line, depth, git_icon_len, _, hl_group, hl)
  table.insert(hl, {hl_group, line, depth+git_icon_len, -1})
end

local function get_trailing_length()
  return vim.g.nvim_tree_add_trailing and 1 or 0
end

local function set_folder_hl(line, depth, icon_len, name_len, hl_group, hl)
  table.insert(hl, {hl_group, line, depth+icon_len, depth+icon_len+name_len+get_trailing_length()})
  local hl_icon = (vim.g.nvim_tree_highlight_opened_files or 0) ~= 0 and hl_group or 'NvimTreeFolderIcon'
  table.insert(hl, {hl_icon, line, depth, depth+icon_len})
end

local function get_file_icon(fname, extension, line, depth, hl)
  local icon, hl_group = web_devicons.get_icon(fname, extension)

  if icon and hl_group ~= "DevIconDefault" then
    if hl_group then
      table.insert(hl, { hl_group, line, depth, depth + #icon + 1 })
    end
    return icon..icon_padding
  elseif string.match(extension, "%.(.*)") then
    -- If there are more extensions to the file, try to grab the icon for them recursively
    return get_file_icon(fname, string.match(extension, "%.(.*)"), line, depth, hl)
  else
    return #M.icons.default > 0 and M.icons.default..icon_padding or ""
  end
end

local function get_default_icon()
  return M.icons.default
end

local function get_symlink_icon()
  return M.icons.symlink
end

local function get_icon_with_padding(name)
  return function()
    return #M.icons[name] > 0 and M.icons[name]..icon_padding or ""
  end
end

function M.load()
  local icon_state = require'nvim-tree.config'.get_icon_state()
  M.icons = icon_state.icons

  if icon_state.show_folder_icon then
    M.get_folder_icon = get_folder_icon
    M.set_folder_hl = set_folder_hl
  else
    M.get_folder_icon = empty_folder_icon
    M.set_folder_hl = simple_folder_hl
  end

  if icon_state.show_file_icon then
    M.get_file_icon = get_file_icon
    M.get_special_icon = get_icon_with_padding('default')
  else
    M.get_file_icon = get_default_icon
    M.get_special_icon = get_default_icon
  end

  if icon_state.show_file_icon then
    M.get_symlink_icon = get_icon_with_padding('symlink')
  else
    M.get_symlink_icon = get_symlink_icon
  end
end

return M
