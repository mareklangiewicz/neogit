local eq = assert.are.same
local git_harness = require("tests.util.git_harness")
local git_repo = require("neogit.lib.git.repository")
local state = require("neogit.lib.state")

describe("lib.state", function()
  -- Remembered popup options used to be keyed by the nvim cwd at first setup, so every
  -- repository opened from the same cwd (e.g. `:Neogit cwd=...` from ~) shared one file.
  it("scopes remembered settings to the repository, not the cwd", function()
    require("neogit").setup { remember_settings = true, use_per_project_settings = true }

    local repo_a = git_harness.prepare_repository()
    local repo_b = git_harness.prepare_repository()
    vim.api.nvim_set_current_dir("/")

    git_repo.instance(repo_a)
    state._reset()
    state.set({ "NeogitLogPopup", "" }, [["a/only/"]])
    eq([["a/only/"]], state.get({ "NeogitLogPopup", "" }, ""))

    git_repo.instance(repo_b)
    state._reset()
    eq("", state.get({ "NeogitLogPopup", "" }, ""))

    git_repo.instance(repo_a)
    eq([["a/only/"]], state.get({ "NeogitLogPopup", "" }, ""))
  end)
end)
