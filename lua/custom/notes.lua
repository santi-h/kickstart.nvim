-- [[ Notes ]]
-- Thin wrapper around ~/scripts-private/notes (needs GIT_NOTES_DIRECTORY and PYENV_ROOT in the env).
--  <leader>nn  / <leader>ngn  new note (today's dates dir / global dir)
--  <leader>nl  / <leader>ngl  list notes (today's dates dir / global dir)

local notes_bin = vim.fn.expand '~/scripts-private/notes'

-- Runs the notes script and returns its stdout lines, or nil on failure
local function run_notes(args)
  local out = vim.fn.systemlist(vim.list_extend({ notes_bin }, args))
  if vim.v.shell_error ~= 0 then
    vim.notify(table.concat(out, '\n'), vim.log.levels.ERROR, { title = 'notes' })
    return nil
  end
  return out
end

local function new_note(global)
  vim.ui.input({ prompt = (global and 'New global note' or 'New note') .. ' name (optional): ' }, function(name)
    if name == nil then return end -- cancelled

    -- -n forces a new file without prompting, -f only prints the path
    local args = { '-n', '-f' }
    if global then table.insert(args, '-g') end
    if vim.trim(name) ~= '' then table.insert(args, name) end

    local out = run_notes(args)
    if not out or #out == 0 then return end
    vim.cmd.edit(vim.fn.fnameescape(out[#out]))
  end)
end

local function list_notes(global)
  local args = { '-l', '-f' }
  if global then table.insert(args, '-g') end

  local paths = run_notes(args)
  if not paths then return end
  if #paths == 0 then
    vim.notify('No notes found', vim.log.levels.INFO, { title = 'notes' })
    return
  end

  -- Telescope picker (instead of vim.ui.select) so we get a file preview.
  -- File entries already open the selected path on <CR>.
  local conf = require('telescope.config').values
  require('telescope.pickers')
    .new({}, {
      prompt_title = global and 'Global notes' or 'Notes',
      finder = require('telescope.finders').new_table {
        results = paths,
        entry_maker = require('telescope.make_entry').gen_from_file { path_display = { 'tail' } },
      },
      sorter = conf.file_sorter {},
      previewer = conf.file_previewer {},
    })
    :find()
end

vim.keymap.set('n', '<leader>nn', function() new_note(false) end, { desc = '[N]otes: [N]ew' })
vim.keymap.set('n', '<leader>nl', function() list_notes(false) end, { desc = '[N]otes: [L]ist' })
vim.keymap.set('n', '<leader>ngn', function() new_note(true) end, { desc = '[N]otes [G]lobal: [N]ew' })
vim.keymap.set('n', '<leader>ngl', function() list_notes(true) end, { desc = '[N]otes [G]lobal: [L]ist' })
