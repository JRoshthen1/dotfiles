return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu",
    },
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      require("ayu").setup({
        mirage = false,
        terminal = true,
        overrides = function()
          return {
            LineNr = { fg = "#3f4759" },
            NonText = { fg = "#303744" },
          }
        end,
      })
    end,
  },
}
