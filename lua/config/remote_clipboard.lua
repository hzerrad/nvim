-- Clipboard for sessions whose yanks may need to reach another machine:
-- every copy is emitted as OSC 52 (inside tmux this becomes a tmux buffer,
-- rebroadcast to every attached client, local or SSH). Paste prefers the
-- local clipboard (Wayland, or pbpaste on macOS) when one is available, so
-- content copied in other apps remains pasteable; without one, paste is an
-- OSC 52 query that tmux (or the terminal) answers. Set
-- vim.g.remote_clipboard_osc52 = false to stop emitting OSC 52 on copy.
local M = {}

local function proc_lines(pid, file)
  local ok, lines = pcall(vim.fn.readfile, "/proc/" .. pid .. "/" .. file)
  return ok and lines or {}
end

local function proc_ppid(pid)
  for _, line in ipairs(proc_lines(pid, "status")) do
    local ppid = line:match("^PPid:%s+(%d+)")
    if ppid then
      return tonumber(ppid)
    end
  end
end

local function ancestor_process_named(name)
  local pid = vim.fn.getpid()

  for _ = 1, 16 do
    local ppid = proc_ppid(pid)
    if not ppid or ppid <= 1 then
      return false
    end

    local comm = proc_lines(ppid, "comm")[1] or ""
    if comm:find(name, 1, true) then
      return true
    end

    pid = ppid
  end

  return false
end

function M.setup()
  local in_tmux = vim.env.TMUX ~= nil
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
  local in_herdr = vim.env.HERDR_PANE_ID ~= nil or ancestor_process_named("herdr")

  if not (in_tmux or in_ssh or in_herdr) then
    return
  end

  local osc52 = require("vim.ui.clipboard.osc52")
  local local_clipboard = M.local_clipboard(in_ssh)

  local function copy(register)
    local emit = osc52.copy(register)

    return function(lines)
      if local_clipboard then
        vim.fn.system(local_clipboard.copy(register), lines)
      end

      if vim.g.remote_clipboard_osc52 ~= false then
        emit(lines)
      end
    end
  end

  local function paste(register)
    if not local_clipboard then
      return osc52.paste(register)
    end

    return function()
      local lines = vim.fn.systemlist(local_clipboard.paste(register), "", 1)
      return vim.v.shell_error == 0 and lines or {}
    end
  end

  vim.g.clipboard = {
    name = "RemoteClipboard",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
    cache_enabled = 0,
  }
end

-- The clipboard of the machine Neovim runs on, if it has one it can reach:
-- Wayland on Linux, pbcopy/pbpaste on macOS (skipped over SSH, where that
-- would be the remote Mac's clipboard rather than the one in front of you).
-- Returns nil when there is none, leaving OSC 52 as the only channel.
function M.local_clipboard(in_ssh)
  if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
    return {
      copy = function(register)
        local cmd = { "wl-copy", "--sensitive", "--type", "text/plain" }
        if register == "*" then
          cmd[#cmd + 1] = "--primary"
        end
        return cmd
      end,
      paste = function(register)
        local cmd = { "wl-paste", "--no-newline" }
        if register == "*" then
          cmd[#cmd + 1] = "--primary"
        end
        return cmd
      end,
    }
  end

  if vim.fn.has("mac") == 1 and not in_ssh and vim.fn.executable("pbcopy") == 1 then
    return {
      copy = function()
        return { "pbcopy" }
      end,
      paste = function()
        return { "pbpaste" }
      end,
    }
  end
end

return M
