package = 'proj'
version = 'scm-1'
source = {
   url = 'git+https://github.com/lalawue/cincau.git'
}
description = {
   summary = 'A project dependency description base on cincau luarock spec',
   detailed = [[
      A project dependency description base on cincau luarock spec,
      for create clean library directory
   ]],
   homepage = 'https://github.com/lalawue/cincau',
   maintainer = 'lalawue <suchaaa@gmail.com>',
   license = 'MIT/X11'
}
dependencies = {
   "lua >= 5.1",
   "mooncake",
   "linked-list",
   "mnet",
   "ffi-hyperparser",
   "sql-orm",
   "lua-resp",
   "lua-bitcask",
   "lua-cjson",
}
build = {
   type = "builtin",
   modules = {
      ["mnet-server"] = {
         sources = { "lua/cincau/engine/mnet/mnet_server.c" },
         incdirs = { "src" },
         libraries = {"pthread"},
      },
      ["cincau_prepare"] = "bin/cincau_prepare.lua"
   },
}