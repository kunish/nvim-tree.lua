local icon_state = require'nvim-tree.config'.get_icon_state()

local M = {}

local function get_simple_padding(depth)
  return string.rep(' ', depth)
end

local function get_icon_padding(depth, _, _, node)
  if node.children then
    local icon = icon_state.icons.folder_icons[node.open and 'arrow_open' or 'arrow_closed']
    return string.rep(' ', depth - 2)..icon..' '
  end
  return string.rep(' ', depth)
end

local function get_indent_markers(depth, idx, tree, _, markers)
  local padding = ""
  if depth ~= 0 then
    local rdepth = depth/2
    markers[rdepth] = idx ~= #tree.children
    for i=1,rdepth do
      if idx == #tree.children and i == rdepth then
        padding = padding..'└ '
      elseif markers[i] then
        padding = padding..'│ '
      else
        padding = padding..'  '
      end
    end
  end
  return padding
end

function M.load()
  if vim.g.nvim_tree_indent_markers == 1 then
    M.get = get_indent_markers
  elseif icon_state.show_folder_icon and icon_state.show_folder_arrows then
    M.get = get_icon_padding
  else
    M.get = get_simple_padding
  end
end

return M
