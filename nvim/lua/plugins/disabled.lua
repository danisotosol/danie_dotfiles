-- This file contains the configuration for disabling specific Neovim plugins.

return {
  {
    -- Plugin: bufferline.nvim
    -- URL: https://github.com/akinsho/bufferline.nvim
    -- Description: A snazzy buffer line (with tabpage integration) for Neovim.
    "akinsho/bufferline.nvim",
    enabled = false, -- Disable this plugin
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
  },
  {
    "NickvanDyke/opencode.nvim",
    enabled = false,
  },
  {
    "olimorris/codecompanion.nvim",
    enabled = false,
  },
  {
    "tris203/precognition.nvim",
    enabled = false,
  },

  {
    "sphamba/smear-cursor.nvim",
    enabled = false,
  },
  {
    -- Plugin: claude-code.nvim
    -- URL: https://github.com/greggh/claude-code.nvim
    -- Description: Neovim integration for Claude Code AI assistant
    "coder/claudecode.nvim",
    enabled = true,
  },
  {
    -- Plugin: gemini-cli.nvim
    -- URL: https://github.com/jonroosevelt/gemini-cli.nvim
    -- No lo va a usar - desactivado para que no pregunte por instalar el CLI al abrir nvim
    "jonroosevelt/gemini-cli.nvim",
    enabled = false,
  },
}
