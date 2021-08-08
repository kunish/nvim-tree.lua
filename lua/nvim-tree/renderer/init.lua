local utils = require'nvim-tree.utils'
-- local ignore = require'nvim-tree.ignore'
local help = require'nvim-tree.renderer.help'
local rgit = require'nvim-tree.renderer.git'
local padd = require'nvim-tree.renderer.padding'
local icons = require'nvim-tree.renderer.icons'

local api = vim.api

local M = {}

local lines = {}
local hl = {}
local index = 0
local namespace_id = api.nvim_create_namespace('NvimTreeHighlights')

local should_hl_opened_files = (vim.g.nvim_tree_highlight_opened_files or 0) ~= 0

local picture = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
}

local special = vim.g.nvim_tree_special_files or {
  ["Cargo.toml"] = true,
  Makefile = true,
  ["README.md"] = true,
  ["readme.md"] = true,
}

local root_folder_modifier = vim.g.nvim_tree_root_folder_modifier or ':~'

local function handle_node_with_children(node, offset, git_hl, padding, depth, markers)
  local has_children = #node.children ~= 0
  local icon = icons.get_folder_icon(node.open, node.link_to ~= nil, has_children)
  local git_icon = rgit.get_icons(node, index, offset, #icon+1, hl) or ""
  -- INFO: this is mandatory in order to keep gui attributes (bold/italics)
  local folder_hl = "NvimTreeFolderName"
  local name = node.name
  local next = #node.children == 1 and node.children[1].children and node.children[1]
  while next do
    name = name .. "/" .. next.name
    next = next.children and #next.children == 1 and next.children[1].children and next.children[1]
  end
  node = require'nvim-tree.tree'.Tree.get_last_grouped_node(node)
  if not has_children then folder_hl = "NvimTreeEmptyFolderName" end
  if node.open then folder_hl = "NvimTreeOpenedFolderName" end
  icons.set_folder_hl(index, offset, #icon, #name+#git_icon, folder_hl, hl)
  if git_hl then
    icons.set_folder_hl(index, offset, #icon, #name+#git_icon, git_hl, hl)
  end
  index = index + 1
  if node.open then
    table.insert(lines, padding..icon..git_icon..name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
    M.update_draw_data(node, depth + 2, markers)
  else
    table.insert(lines, padding..icon..git_icon..name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
  end
end

local function handle_link(node, offset, git_hl, padding)
  local icon = icons.get_symlink_icon()
  local link_hl = git_hl or 'NvimTreeSymlink'
  local arrow = vim.g.nvim_tree_symlink_arrow or ' ➛ '
  table.insert(hl, { link_hl, index, offset, -1 })
  table.insert(lines, padding..icon..node.name..arrow..node.link_to)
end

local function handle_file(node, offset, git_hl, padding)
  local icon
  local git_icons
  if special[node.name] then
    icon = icons.get_special_icon()
    git_icons = rgit.get_icons(node, index, offset, 0, hl)
    table.insert(hl, {'NvimTreeSpecialFile', index, offset+#git_icons, -1})
  else
    icon = icons.get_file_icon(node.name, node.extension, index, offset, hl)
    git_icons = rgit.get_icons(node, index, offset, #icon, hl)
  end
  table.insert(lines, padding..icon..git_icons..node.name)

  if node.executable then
    table.insert(hl, {'NvimTreeExecFile', index, offset+#icon+#git_icons, -1 })
  elseif picture[node.extension] then
    table.insert(hl, {'NvimTreeImageFile', index, offset+#icon+#git_icons, -1 })
  end

  if should_hl_opened_files then
    if vim.fn.bufloaded(node.absolute_path) > 0 then
      if vim.g.nvim_tree_highlight_opened_files == 1 then
        table.insert(hl, {'NvimTreeOpenedFile', index, offset, offset+#icon })  -- highlight icon only
      elseif vim.g.nvim_tree_highlight_opened_files == 2 then
        table.insert(hl, {'NvimTreeOpenedFile', index, offset+#icon+#git_icons, offset+#icon+#git_icons+#node.name })  -- highlight name only
      elseif vim.g.nvim_tree_highlight_opened_files == 3 then
        table.insert(hl, {'NvimTreeOpenedFile', index, offset, -1 })  -- highlight whole line
      end
    end
  end

  if git_hl then
    table.insert(hl, {git_hl, index, offset+#icon+#git_icons, -1 })
  end
end

function M.update_draw_data(tree, depth, markers)
  if tree.cwd and tree.cwd ~= '/' then
    local root_name = utils.path_join({
      utils.path_remove_trailing(vim.fn.fnamemodify(tree.cwd, root_folder_modifier)),
      ".."
    })
    table.insert(lines, root_name)
    table.insert(hl, {'NvimTreeRootFolder', index, 0, string.len(root_name)})
    index = 1
  end

  -- local ignored_entries = ignore.filter_ignored(tree.entries)
  for idx, node in ipairs(tree.children) do
    local padding = padd.get(depth, idx, tree, node, markers)
    local offset = string.len(padding)
    if depth > 0 then
      table.insert(hl, { 'NvimTreeIndentMarker', index, 0, offset })
    end

    local git_hl = rgit.get_hl(node)

    if node.children then
      -- draw directory or directory with link
      handle_node_with_children(node, offset, git_hl, padding, depth, markers)
    elseif node.link_to then
      handle_link(node, offset, git_hl, padding)
      index = index + 1
    else
      handle_file(node, offset, git_hl, padding)
      index = index + 1
    end
  end
end

local function reload_modules()
  padd.load()
  icons.load()
  rgit.load()
end

reload_modules()

function M.draw(reload)
  local tree = require'nvim-tree.lib'.Tree
  local view = require'nvim-tree.view'
  if not api.nvim_buf_is_loaded(view.View.bufnr) then return end
  local cursor
  if view.win_open() then
    cursor = api.nvim_win_get_cursor(view.get_winnr())
  end

  if view.is_help_ui() then
    lines, hl = help.get_data()
  elseif reload then
    index = 0
    lines = {}
    hl = {}

    local icon_state = require'nvim-tree.config'.get_icon_state()
    local show_arrows = icon_state.show_folder_icon and icon_state.show_folder_arrows
    -- local tree = require'nvim-tree.lib'.Tree
    M.update_draw_data(tree, show_arrows and 2 or 0, {})
  end

  api.nvim_buf_set_option(view.View.bufnr, 'modifiable', true)
  api.nvim_buf_set_lines(view.View.bufnr, 0, -1, false, lines)
  M.render_hl(view.View.bufnr)
  api.nvim_buf_set_option(view.View.bufnr, 'modifiable', false)

  if cursor and #lines >= cursor[1] then
    api.nvim_win_set_cursor(view.get_winnr(), cursor)
  end
  if cursor then
    api.nvim_win_set_option(view.get_winnr(), 'wrap', false)
  end
end

function M.render_hl(bufnr)
  if not api.nvim_buf_is_loaded(bufnr) then return end
  api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl) do
    api.nvim_buf_add_highlight(bufnr, namespace_id, data[1], data[2], data[3], data[4])
  end
end

return M
