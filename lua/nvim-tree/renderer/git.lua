local icon_state = require'nvim-tree.config'.get_icon_state()
local warn = require'nvim-tree.utils'.echo_warning

local M = {}

local GIT_HL_STATE = {
  ["M "] = { { hl = "NvimTreeFileStaged" } },
  [" M"] = { { hl = "NvimTreeFileDirty" } },
  [" T"] = { { hl = "NvimTreeFileDirty" } },
  ["MM"] = {
    { hl = "NvimTreeFileStaged" },
    { hl = "NvimTreeFileDirty" }
  },
  ["A "] = {
    { hl = "NvimTreeFileStaged" },
    { hl = "NvimTreeFileNew" }
  },
  ["AU"] = {
    { hl = "NvimTreeFileMerge" },
    { hl = "NvimTreeFileStaged" },
  },
  -- not sure about this one
  ["AA"] = {
    { hl = "NvimTreeFileMerge" },
    { hl = "NvimTreeFileStaged" }
  },
  ["AD"] = {
    { hl = "NvimTreeFileStaged" },
  },
  ["MD"] = {
    { hl = "NvimTreeFileStaged" },
  },
  ["AM"] = {
    { hl = "NvimTreeFileStaged" },
    { hl = "NvimTreeFileNew" },
    { hl = "NvimTreeFileDirty" }
  },
  ["??"] = { { hl = "NvimTreeFileNew" } },
  ["R "] = { { hl = "NvimTreeFileRenamed" } },
  ["UU"] = { { hl = "NvimTreeFileMerge" } },
  ["UD"] = { { hl = "NvimTreeFileMerge" } },
  [" D"] = { { hl = "NvimTreeFileDeleted" } },
  ["DD"] = { { hl = "NvimTreeFileDeleted" } },
  ["RD"] = { { hl = "NvimTreeFileDeleted" } },
  ["D "] = {
    { hl = "NvimTreeFileDeleted" },
    { hl = "NvimTreeFileStaged" }
  },
  ["DU"] = {
    { hl = "NvimTreeFileDeleted" },
    { hl = "NvimTreeFileMerge" }
  },
  [" A"] = { { hl = "none" } },
  ["RM"] = { { hl = "NvimTreeFileRenamed" } },
  ["!!"] = { { hl = "NvimTreeGitIgnored" } },
  dirty = { { hl = "NvimTreeFileDirty" } },
}

local function get_git_hl(node)
  local git_status = node.git
  if not git_status then return end

  local icons = GIT_HL_STATE[git_status]

  if icons == nil then
    warn('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
    icons = GIT_HL_STATE.dirty
  end

  -- TODO: how would we determine hl color when multiple git status are active ?
  return icons[1].hl
  -- return icons[#icons].hl
end

local GIT_ICON_STATE = {
  ["M "] = { { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" } },
  [" M"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
  [" T"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
  ["MM"] = {
    { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
    { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
  },
  ["MD"] = {
    { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
  },
  ["A "] = {
    { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
  },
  ["AD"] = {
    { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
  },
  [" A"] = {
    { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
  },
  -- not sure about this one
  ["AA"] = {
    { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
    { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
  },
  ["AU"] = {
    { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
    { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
  },
  ["AM"] = {
    { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
    { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
  },
  ["??"] = { { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitDirty" } },
  ["R "] = { { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" } },
  ["RM"] = {
    { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" },
    { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" },
  },
  ["UU"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
  ["UD"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
  [" D"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
  ["D "] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
  ["RD"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
  ["DD"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
  ["DU"] = {
    { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" },
    { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" },
  },
  ["!!"] = { { icon = icon_state.icons.git_icons.ignored, hl = "NvimTreeGitIgnored" } },
  dirty = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
}

local icon_padding = vim.g.nvim_tree_icon_padding or " "

local function get_git_icons(node, line, depth, icon_len, hl)
  local git_status = node.git
  if not git_status then return "" end

  local icon = ""
  local icons = GIT_ICON_STATE[git_status]
  if not icons then
    if vim.g.nvim_tree_git_hl ~= 1 then
      warn('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
    end
    icons = GIT_ICON_STATE.dirty
  end
  for _, v in ipairs(icons) do
    table.insert(hl, { v.hl, line, depth+icon_len+#icon, depth+icon_len+#icon+#v.icon })
    icon = icon..v.icon..icon_padding
  end

  return icon
end

local function get_empty_string()
  return ""
end

local function get_nil()
  return nil
end

function M.load()
  if vim.g.nvim_tree_git_hl == 1 then
    M.get_hl = get_git_hl
  else
    M.get_hl = get_nil
  end

  if icon_state.show_git_icon then
    M.get_icons = get_git_icons
  else
    M.get_icons = get_empty_string
  end
end

return M
