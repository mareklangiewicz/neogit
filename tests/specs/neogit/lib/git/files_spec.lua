local eq = assert.are.same
local files = require("neogit.lib.git.files")

describe("lib.git.files", function()
  describe("with_dirs", function()
    it("includes directories that only contain subdirectories", function()
      eq({
        "a/",
        "a/b/",
        "a/b/c/",
        "a/b/c/x.lua",
        "a/b/d/",
        "a/b/d/y.lua",
        "top.lua",
      }, files.with_dirs { "a/b/c/x.lua", "a/b/d/y.lua", "top.lua" })
    end)

    it("returns the files unchanged when none are nested", function()
      eq({ "x.lua", "y.lua" }, files.with_dirs { "y.lua", "x.lua" })
    end)
  end)
end)
